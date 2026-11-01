#!/usr/bin/env python3
"""
python03_promote: leva a ingestao do pacote para o datalake (dl05s_main) e
atualiza os artefatos do repositorio preserv-<PAIS>.

Equivale, em preserv/src, a:
  make to_donated_packcomponent pg_db=<ingest> pg_datalake=<dl>   (fila de aprovacao)
  make approved_donated_packcomponent id=<N> pg_datalake=<dl>     (--approve)
e, na pasta do pacote:
  make readme / make me_reproducibility                           (--regenerate)

Passos:
  1. copia ingest.donated_packcomponent do pacote para optim.donated_packcomponent_not_approved
     (upsert pela chave packvers_id, ftid, lineage_md5), sem pg_dump; linhas antigas da fila
     para o mesmo (packvers_id, ftid) com outro lineage_md5 sao removidas, para a fila ter
     so a ultima ingestao de cada layer (--keep-old-queue mantem);
  2. compara com a versao ja aprovada em optim.donated_packcomponent (variacao de itens);
  3. --approve: chama optim.approved_packcomponent(id) para cada componente da fila;
  4. --regenerate: gera README.md e reproducibility.sh pelas funcoes optim.generate_*
     e copia para a pasta do pacote;
     --insert-size: grava `size:` de cada arquivo em files: do make_conf.yaml, medindo os
     zips em DG_ORIG no host (o `make insert_size` usa pg_stat_file no servidor, que no
     container nao enxerga /var/www);
     --insert-license: equivale a `make insert_license` (optim.generate_make_conf_with_license);
  5. --git-commit / --git-push no repositorio preserv-<PAIS>;
  6. relatorio por e-mail.

Uso:
  python03_promote.py /var/gits/_dg/preserv-BR/data/RS/PortoAlegre/_pk0018.01 --pg-db ingest20 --approve --regenerate
"""
import argparse
import difflib
import shutil
import sys
from pathlib import Path

import dg_common as dg

LOG = dg.LOG

UPSERT = """
INSERT INTO optim.donated_packcomponent_not_approved
       (packvers_id, ftid, is_evidence, proc_step, lineage, lineage_md5, kx_profile)
VALUES (%(packvers_id)s, %(ftid)s, %(is_evidence)s, %(proc_step)s, %(lineage)s, %(lineage_md5)s, %(kx_profile)s)
ON CONFLICT (packvers_id, ftid, lineage_md5) DO UPDATE
SET (is_evidence, proc_step, lineage, kx_profile) =
    (EXCLUDED.is_evidence, EXCLUDED.proc_step, EXCLUDED.lineage, EXCLUDED.kx_profile)
RETURNING id
"""


def to_queue(conn_ing, conn_dl, pkg, ids, dry, keep_old=False):
    rows = dg.sql(conn_ing,
                  "SELECT c.*, f.ftname FROM ingest.donated_packcomponent c JOIN ingest.fdw_feature_type f USING (ftid) "
                  "WHERE packvers_id = ANY(%s) ORDER BY packvers_id, ftid", (ids,), dry_run=dry)
    out = []
    for r in rows:
        params = {k: r[k] for k in ("packvers_id", "ftid", "is_evidence", "proc_step", "lineage_md5")}
        params["lineage"] = dg.Json(r["lineage"])
        params["kx_profile"] = dg.Json(r["kx_profile"]) if r["kx_profile"] is not None else None
        if not keep_old:
            old = dg.sql(conn_dl, "DELETE FROM optim.donated_packcomponent_not_approved "
                                  "WHERE packvers_id=%s AND ftid=%s AND lineage_md5<>%s RETURNING id, lineage_md5",
                         (r["packvers_id"], r["ftid"], r["lineage_md5"]), dry_run=dry)
            if old:
                LOG.warning("fila: removidas %d versao(oes) antiga(s) de (%s, ftid %s): %s", len(old), r["packvers_id"], r["ftid"], [o["id"] for o in old])
        q = dg.sql_one(conn_dl, UPSERT, params, dry_run=dry)
        prev = dg.sql_one(conn_dl,
                          "SELECT id, lineage->'feature_asis_summary'->>'n' AS n_prev, kx_profile->>'date_aprroved' AS approved_at "
                          "FROM optim.donated_packcomponent WHERE packvers_id=%s AND ftid=%s ORDER BY id DESC LIMIT 1",
                          (r["packvers_id"], r["ftid"]), dry_run=dry) or {}
        n_new = (r["lineage"].get("feature_asis_summary") or {}).get("n")
        n_prev = int(prev["n_prev"]) if prev.get("n_prev") else None
        var = round(100.0 * (n_new - n_prev) / n_prev, 1) if (n_new is not None and n_prev) else None
        out.append({"ftname": r["ftname"], "packvers_id": r["packvers_id"], "ftid": r["ftid"], "ingest_id": r["id"],
                    "queue_id": (q or {}).get("id"), "queue_removed": len(old) if (not keep_old and old) else 0,
                    "n_new": n_new, "n_prev": n_prev, "var_pct": var,
                    "prev_approved_at": prev.get("approved_at"), "proc_step": r["proc_step"]})
    return out


def approve(conn_dl, queued, dry):
    for q in queued:
        if q["queue_id"] is None:
            continue
        r = dg.sql_one(conn_dl, "SELECT optim.approved_packcomponent(%s) AS msg", (q["queue_id"],), dry_run=dry)
        q["approved"] = (r or {}).get("msg", "dry-run")
    return queued


def regenerate(conn_dl, pkg, dry):
    """README.md e reproducibility.sh via optim.generate_* (saida em DG_PG_IO, dono postgres)."""
    done = {}
    gens = {"README.md": "generate_readme", "reproducibility.sh": "generate_reproducibility"}
    for fname, fn in gens.items():
        out = Path(dg.CFG["pg_io"]) / f"tmpfile_{pkg.country}{pkg.conf['pack_id']}_{fname}"
        if out.exists() and not dry:
            out.unlink()
        dg.sql(conn_dl, f"SELECT optim.{fn}(%s, %s, %s, %s, %s)",
               (pkg.country, str(pkg.conf["pack_id"]), str(out), str(pkg.dir), dg.CFG["gits"]), dry_run=dry)
        dg.run(["sudo", "chmod", "666", str(out)], dry_run=dry, check=False)
        if dry:
            done[fname] = "dry-run"
            continue
        target = pkg.dir / fname
        old = target.read_text(encoding="utf-8", errors="replace").splitlines() if target.exists() else []
        new = out.read_text(encoding="utf-8", errors="replace").splitlines()
        diff = list(difflib.unified_diff(old, new, lineterm="", n=0))
        shutil.copy(out, target)
        done[fname] = f"{max(len(diff) - 2, 0)} linhas alteradas"
    return done


def insert_size(pkg, dry):
    """Edita make_conf.yaml em texto, preservando comentarios: size: <bytes> por arquivo."""
    import re
    text = pkg.yaml_path.read_text(encoding="utf-8")
    changed = []
    for f in pkg.files.values():
        path = Path(dg.CFG["orig"]) / f["file"]
        if not path.exists():
            changed.append(f"{f['file'][:12]}: ausente em {dg.CFG['orig']}")
            continue
        size = path.stat().st_size
        # bloco do arquivo: da linha "- file: <hash>" ate o proximo "- " ou chave de topo
        m = re.search(r"(^[ \t]*-[ \t]*file:[ \t]*" + re.escape(f["file"]) + r"[^\n]*\n)((?:[ \t]+[^-\s][^\n]*\n)*)", text, re.M)
        if not m:
            changed.append(f"{f['file'][:12]}: bloco nao encontrado no yaml")
            continue
        head, body = m.group(1), m.group(2)
        indent = re.match(r"^([ \t]*)-", head).group(1) + "  "
        if re.search(r"^[ \t]+size:", body, re.M):
            new_body = re.sub(r"^([ \t]+size:)[^\n]*$", rf"\g<1> {size}", body, flags=re.M)
        else:
            new_body = body + f"{indent}size: {size}\n"
        if new_body != body:
            text = text[:m.start(2)] + new_body + text[m.end(2):]
            changed.append(f"{f['file'][:12]}: size={size}")
    if changed and not dry:
        pkg.yaml_path.write_text(text, encoding="utf-8")
    return changed or ["sem alteracao"]


def insert_license(conn_dl, pkg, dry):
    out = Path(dg.CFG["pg_io"]) / f"tmpfile_{pkg.country}{pkg.conf['pack_id']}_make_conf.yaml"
    if out.exists() and not dry:
        out.unlink()
    dg.sql(conn_dl, "SELECT optim.generate_make_conf_with_license(%s, %s, %s, %s, %s)",
           (pkg.country, str(pkg.conf["pack_id"]), str(out), str(pkg.dir), dg.CFG["gits"]), dry_run=dry)
    dg.run(["sudo", "chmod", "666", str(out)], dry_run=dry, check=False)
    if dry:
        return "dry-run"
    old = pkg.yaml_path.read_text(encoding="utf-8", errors="replace").splitlines()
    new = out.read_text(encoding="utf-8", errors="replace").splitlines()
    n = max(len(list(difflib.unified_diff(old, new, lineterm="", n=0))) - 2, 0)
    shutil.copy(out, pkg.yaml_path)
    return f"{n} linhas alteradas"


def git_commit(pkg, args):
    repo = pkg.dir
    while repo != repo.parent and not (repo / ".git").exists():
        repo = repo.parent
    if not (repo / ".git").exists():
        return "sem git"
    dg.run(["git", "add", "--", "README.md", "reproducibility.sh", "make_conf.yaml"], cwd=str(pkg.dir), dry_run=args.dry_run, check=False)
    res = dg.run(["git", "commit", "-q", "-m", f"{pkg.isolabel_ext} _pk{pkg.pack_number}: artefatos regenerados (python03)"],
                 cwd=str(repo), dry_run=args.dry_run, check=False)
    if args.git_push:
        dg.run(["git", "push"], cwd=str(repo), dry_run=args.dry_run)
    return "commit ok" if res.returncode == 0 else "nada a commitar"


def main():
    ap = dg.common_args(argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter))
    ap.add_argument("--approve", action="store_true", help="aprovar (mover da fila para optim.donated_packcomponent)")
    ap.add_argument("--keep-old-queue", action="store_true", help="nao remover da fila versoes antigas do mesmo layer")
    ap.add_argument("--regenerate", action="store_true", help="regerar README.md e reproducibility.sh")
    ap.add_argument("--insert-size", action="store_true", help="gravar size: dos arquivos no make_conf.yaml (medido no host)")
    ap.add_argument("--insert-license", action="store_true", help="gravar license_evidences no make_conf.yaml (SQL)")
    ap.add_argument("--git-commit", action="store_true")
    ap.add_argument("--git-push", action="store_true")
    args = ap.parse_args()
    dg.setup_logging(args.verbose)
    dg.apply_args(args)

    conn_ing = dg.connect(args.pg_db)
    conn_dl = dg.connect(args.pg_datalake)
    pkg = dg.Package(args.pack_dir, conn_ing, conn_dl)
    wanted = {l for l in args.layers.split(",") if l}
    ids = sorted({it["packvers_id"] for it in pkg.layer_items() if not wanted or it["name"] in wanted})
    LOG.info("pacote: %s | packvers %s | %s -> %s", pkg, ids, args.pg_db, args.pg_datalake)

    queued = to_queue(conn_ing, conn_dl, pkg, ids, args.dry_run, keep_old=args.keep_old_queue)
    if args.approve:
        approve(conn_dl, queued, args.dry_run)
    regen = {}
    if args.insert_size:
        regen["make_conf.yaml size"] = insert_size(pkg, args.dry_run)
    if args.insert_license:
        regen["make_conf.yaml license"] = insert_license(conn_dl, pkg, args.dry_run)
    if args.regenerate:
        regen.update(regenerate(conn_dl, pkg, args.dry_run))
    git_status = git_commit(pkg, args) if (args.git_commit or args.git_push) else "nao solicitado"

    cols = ["ftname", "packvers_id", "proc_step", "queue_id", "queue_removed", "n_new", "n_prev", "var_pct", "prev_approved_at"] + (["approved"] if args.approve else [])
    warn = [q["ftname"] for q in queued if q["var_pct"] is not None and abs(q["var_pct"]) > 30]
    text = (
        f"python03_promote OK | {pkg} | {args.pg_db} -> {args.pg_datalake}\n"
        f"aprovado: {'sim' if args.approve else 'nao (fila optim.donated_packcomponent_not_approved)'}\n"
        f"artefatos: {regen or 'nao regenerados'}\ngit: {git_status}\n\n" + dg.fmt_table(queued, cols)
        + (f"\n\nATENCAO: variacao de itens acima de 30% em {warn}\n" if warn else "\n")
    )
    dg.finish("python03_promote_" + pkg.isolabel_ext, f"[preserv] promocao: {pkg.isolabel_ext} _pk{pkg.pack_number}",
              text, {"package": str(pkg), "queued": queued, "regenerated": regen, "git": git_status}, args)


if __name__ == "__main__":
    main()
