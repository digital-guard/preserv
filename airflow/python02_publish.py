#!/usr/bin/env python3
"""
python02_publish: aprova a ingestao (decisao humana, tomada ao disparar este
script) e publica os geojsons do pacote em /var/gits/_dg/preservCutGeo-<PAIS>2021.

Equivale ao target `make all_publications pg_db=<ingest>` do makefile:
  para cada layer:  mkdir -m777 <path_cutgeo_server>/<layer>
                    rm <layer>/*.geojson
                    CALL ingest.ppublicating_geojsons(layer, isolabel_ext, pasta, buffer_type, 9, 3)
                    sudo bash preserv/src/fixaPermissoes.sh <pasta>
  depois:           auditoria dos arquivos gerados (n, media, min, max) e relatorio por e-mail.
  --git-commit      faz `git add` + `git commit` no repositorio CutGeo (se for um clone git);
  --git-push        tambem faz push.
  --out-root DIR    publica em DIR/<repo>/data/... em vez de /var/gits/_dg (teste sem tocar
                    no CutGeo real; DIR precisa ser visivel pelo servidor Postgres, ex. /tmp/pg_io/cutgeo_test).
  --threshold-sum N com --layer: equivale a `make change_parameters_<layer> threshold_sum=N`
                    (grava hcode_distribution_parameters.p_threshold_sum no lineage e republica).
  --filtered        depois de publicar, gera e sobe para a nuvem os "filtrados" (shapefile/csv)
                    de todos os layers nao cadastrais: equivale a `make all_filtered`
                    (source preserv/src/generateFiles.sh; gen_all <pg_db> <pack_id> true).

Uso:
  python02_publish.py /var/gits/_dg/preserv-BR/data/RS/PortoAlegre/_pk0018.01 --pg-db ingest20
"""
import argparse
import os
import statistics
import sys
from pathlib import Path

import dg_common as dg

LOG = dg.LOG


def audit_folder(folder):
    files = sorted(Path(folder).glob("*.geojson")) if Path(folder).exists() else []
    sizes = [f.stat().st_size for f in files]
    if not sizes:
        return {"n": 0}
    return {
        "n": len(sizes),
        "total_kib": round(sum(sizes) / 1024),
        "mean_kib": round(statistics.mean(sizes) / 1024),
        "median_kib": round(statistics.median(sizes) / 1024),
        "min_kib": round(min(sizes) / 1024),
        "max_kib": round(max(sizes) / 1024),
        "largest": max(files, key=lambda f: f.stat().st_size).name,
    }


def cutgeo_base(pkg, args):
    """Pasta do pacote no CutGeo; com --out-root, a mesma estrutura sob outra raiz."""
    real = Path(pkg.path_cutgeo_server)
    if not args.out_root:
        return real
    try:
        rel = real.relative_to(dg.CFG["gits"])
    except ValueError:
        rel = Path(*real.parts[-5:])
    return Path(args.out_root) / rel


def publish_layer(conn, pkg, item, args):
    dry = args.dry_run
    name = item["name"]
    folder = cutgeo_base(pkg, args) / name
    buffer_type = item["conf"].get("buffer_type", 1)
    LOG.info("==== publicando %s / %s -> %s", pkg.isolabel_ext, name, folder)
    comp = dg.sql_one(
        conn,
        "SELECT id, proc_step FROM ingest.vw03full_layer_file WHERE isolabel_ext=%s AND ftname=%s",
        (pkg.isolabel_ext, item["layername"]), dry_run=dry,
    )
    if not dry and not comp:
        return {"layer": name, "status": "skipped", "detail": "layer nao ingerido em ingest.donated_packcomponent"}
    if args.threshold_sum is not None:
        LOG.info("change_parameters: p_threshold_sum=%s no lineage do componente %s", args.threshold_sum, (comp or {}).get("id"))
        dg.sql(conn,
               "UPDATE ingest.donated_packcomponent SET lineage = jsonb_set(lineage, '{hcode_distribution_parameters}', "
               "jsonb_build_object('p_threshold_sum', %s::int), TRUE) WHERE id = %s",
               (int(args.threshold_sum), (comp or {}).get("id")), fetch=False, dry_run=dry)
    if not dry:
        if not folder.exists():
            folder.mkdir(parents=True, exist_ok=True)
            os.chmod(folder, 0o777)
        # pasta ja existente costuma pertencer a postgres:www-data (fixaPermissoes.sh); nao tentar chmod
        if args.clean:
            for f in folder.glob("*.geojson"):
                try:
                    f.unlink()
                except PermissionError:
                    dg.run(["sudo", "rm", "-f", str(f)], check=False)
    dg.sql(conn, "CALL ingest.ppublicating_geojsons(%s, %s, %s, %s, 9, %s)",
           (name, pkg.isolabel_ext, str(folder), int(buffer_type), int(args.pretty_opt)), fetch=False, dry_run=dry)
    dg.run(["sudo", "bash", "fixaPermissoes.sh", str(folder)], cwd=f"{dg.CFG['gits']}/preserv/src", dry_run=dry, check=False)
    audit = {} if dry else audit_folder(folder)
    return {"layer": name, "status": "ok", "folder": str(folder), "file_id": (comp or {}).get("id"), "audit": audit}


def filtered_files(pkg, args):
    """make all_filtered: gera shapefile/csv filtrados e sobe para a nuvem (generateFiles.sh)."""
    cmd = (f"source {dg.CFG['gits']}/preserv/src/generateFiles.sh && "
           f"gen_all {dg.CFG['pg_db']} {pkg.pack_id} true")
    res = dg.run(["bash", "-c", cmd], cwd=f"{dg.CFG['gits']}/preserv/src", dry_run=args.dry_run, check=False)
    return "ok" if res.returncode == 0 else f"rc={res.returncode}: {res.stderr.strip()[-400:]}"


def git_commit(pkg, results, args):
    repo = Path(pkg.path_cutgeo_server)
    while repo != repo.parent and not (repo / ".git").exists():
        repo = repo.parent
    if not (repo / ".git").exists():
        LOG.warning("%s nao esta em um clone git; commit ignorado", pkg.path_cutgeo_server)
        return "sem git"
    folders = [r["folder"] for r in results if r.get("folder")]
    dg.run(["git", "add", "--", *folders], cwd=str(repo), dry_run=args.dry_run)
    msg = f"{pkg.isolabel_ext} _pk{pkg.pack_number}: publicacao de {', '.join(r['layer'] for r in results if r.get('folder'))}"
    res = dg.run(["git", "commit", "-q", "-m", msg], cwd=str(repo), dry_run=args.dry_run, check=False)
    if args.git_push:
        dg.run(["git", "push"], cwd=str(repo), dry_run=args.dry_run)
    return "commit ok" if res.returncode == 0 else "nada a commitar"


def main():
    ap = dg.common_args(argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter))
    ap.add_argument("--no-clean", dest="clean", action="store_false", help="nao apagar *.geojson antigos da pasta")
    ap.add_argument("--pretty-opt", default=3, type=int)
    ap.add_argument("--git-commit", action="store_true")
    ap.add_argument("--git-push", action="store_true")
    ap.add_argument("--out-root", default=None, help="raiz alternativa de saida (teste), ex. /tmp/pg_io/cutgeo_test")
    ap.add_argument("--threshold-sum", type=int, default=None, help="com --layer: p_threshold_sum para hcode_distribution_parameters (change_parameters)")
    ap.add_argument("--filtered", action="store_true", help="gerar e subir os filtrados (shapefile/csv) apos publicar (all_filtered)")
    args = ap.parse_args()
    if args.threshold_sum is not None and len([l for l in (args.layers or "").split(",") if l]) != 1:
        ap.error("--threshold-sum exige exatamente um layer (--layer <nome>)")
    dg.setup_logging(args.verbose)
    dg.apply_args(args)

    conn = dg.connect(args.pg_db)
    pkg = dg.Package(args.pack_dir, conn)
    dest = cutgeo_base(pkg, args)
    LOG.info("pacote: %s | destino %s%s", pkg, dest, " (TESTE, --out-root)" if args.out_root else "")
    wanted = {l for l in args.layers.split(",") if l}

    results, failed = [], []
    for item in pkg.layer_items():
        if wanted and item["name"] not in wanted:
            continue
        if item["method"] == "none":
            continue
        if pkg.is_cad(item["name"]):
            LOG.info("layer cadastral %s nao e publicado (sem geometria)", item["name"])
            continue
        try:
            results.append(publish_layer(conn, pkg, item, args))
        except Exception as e:  # noqa: BLE001
            LOG.exception("layer %s falhou", item["name"])
            results.append({"layer": item["name"], "status": "error", "detail": str(e)})
            failed.append(item["name"])

    filt = filtered_files(pkg, args) if (args.filtered and not failed) else "nao solicitado"

    if args.out_root and (args.git_commit or args.git_push):
        git_status = "ignorado (--out-root)"
    else:
        git_status = git_commit(pkg, results, args) if (args.git_commit or args.git_push) else "nao solicitado"

    status = "FALHOU" if failed else "OK"
    lines = []
    for r in results:
        a = r.get("audit") or {}
        lines.append(f"- {r['layer']}: {r['status']} {r.get('detail', '')} "
                     + (f"| {a['n']} geojson, media {a.get('mean_kib')} KiB, min {a.get('min_kib')}, max {a.get('max_kib')} ({a.get('largest')})" if a.get("n") else ""))
    text = (
        f"python02_publish {status} | {pkg} | banco {args.pg_db}\n"
        f"destino: {dest}{' (TESTE, --out-root)' if args.out_root else ''}\ngit: {git_status}\nfiltrados (nuvem): {filt}\n"
        + (f"threshold_sum aplicado: {args.threshold_sum}\n" if args.threshold_sum is not None else "") + "\n" + "\n".join(lines)
        + "\n\nProximo passo: python03_promote.py para registrar no datalake (fila de aprovacao).\n"
    )
    dg.finish("python02_publish_" + pkg.isolabel_ext, f"[preserv] publicacao {status}: {pkg.isolabel_ext} _pk{pkg.pack_number}",
              text, {"package": str(pkg), "pg_db": args.pg_db, "results": results, "git": git_status, "filtered": filt}, args)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
