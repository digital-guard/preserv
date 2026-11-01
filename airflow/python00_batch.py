#!/usr/bin/env python3
"""
python00_batch: percorre /var/gits/_dg/preserv-*/data, confere o make_conf.yaml de cada
pacote _pkNNNN.NN e roda a cadeia python01 -> python02 -> python03 (-> python04) por pacote.

Erros nao interrompem o lote: o texto completo (stdout+stderr) de cada passo que falhou
e salvo em DG_PG_IO/batch/<carimbo>/<pais>_<pacote>.<passo>.err e o lote segue para o
proximo pacote (--stop-on-error interrompe). No fim: tabela de status por pacote e passo,
JSON com tudo, e-mail.

Verificacoes de nome antes de rodar:
  * so vale `make_conf.yaml` (exato, minusculo) dentro de uma pasta `_pk<digitos>.<digitos>`;
  * variantes (make_conf.yml, Make_conf.yaml, makeconf.yaml, *.yaml fora do padrao) e
    pastas _pk* sem yaml sao listadas como "nome incorreto" / "sem yaml" e nao rodam.

Uso:
  python00_batch.py --pg-db ingest20 --dry-run                      # valida tudo sem gravar
  python00_batch.py --pg-db ingest20 --steps 1 --filter preserv-BR/data/RS   # so ingestao, so RS
  python00_batch.py --pg-db ingest20 --steps 1,2,3 --out-root /tmp/pg_io/cutgeo_test
  python00_batch.py --pg-db ingest20 --only /var/gits/_dg/preserv-BR/data/RS/PortoAlegre/_pk0018.01

A aprovacao (python03 --approve) NUNCA e feita em lote: fica para a decisao humana.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import dg_common as dg

LOG = dg.LOG
HERE = Path(__file__).resolve().parent
PK_DIR_RE = re.compile(r"^_pk\d{4}\.\d{2}$")
STEPS = {
    "1": ("python01_ingest.py", "ingest"),
    "2": ("python02_publish.py", "publish"),
    "3": ("python03_promote.py", "promote"),
    "4": ("python04_clean.py", "clean"),
}


def discover(root, filt=None):
    """Pastas _pk* sob <root>/preserv-*/data; separa validas, nome incorreto e sem yaml."""
    ok, bad_name, no_yaml = [], [], []
    for repo in sorted(Path(root).glob("preserv-*")):
        data = repo / "data"
        if not data.is_dir():
            continue
        for d in sorted(p for p in data.rglob("_pk*") if p.is_dir()):
            rel = str(d.relative_to(root))
            if filt and filt not in rel:
                continue
            if not PK_DIR_RE.match(d.name):
                bad_name.append((rel, f"pasta fora do padrao _pkNNNN.NN: {d.name}"))
                continue
            yamls = [f for f in d.iterdir() if f.is_file() and re.search(r"\.ya?ml$", f.name, re.I)]
            exact = d / "make_conf.yaml"
            if exact.exists():
                ok.append(d)
                others = [f.name for f in yamls if f.name != "make_conf.yaml" and f.name.lower().startswith("make")]
                if others:
                    bad_name.append((rel, f"alem de make_conf.yaml existem: {others}"))
            elif yamls:
                bad_name.append((rel, f"yaml com nome incorreto: {[f.name for f in yamls]} (esperado make_conf.yaml)"))
            else:
                no_yaml.append(rel)
    return ok, bad_name, no_yaml


def run_step(step, pack_dir, args, errdir, label):
    script, name = STEPS[step]
    cmd = [sys.executable, str(HERE / script), str(pack_dir), "--pg-db", args.pg_db, "--pg-uri", args.pg_uri,
           "--pg-datalake", args.pg_datalake, "--no-mail"]
    if args.dry_run:
        cmd.append("--dry-run")
    if args.layers and step in ("1", "2", "3"):
        cmd += ["--layers", args.layers]
    if step == "1" and not args.keep_sandbox:
        cmd.append("--clean-sandbox")       # em lote o sandbox de cada pacote e apagado (DG_SANDBOX_ROOT pode ser tmpfs)
    if step == "1" and args.drop_tables:
        cmd.append("--drop-tables")
    if step == "2" and args.out_root:
        cmd += ["--out-root", args.out_root]
    if step == "3":
        cmd += ["--regenerate"] if args.regenerate else []
    t0 = time.time()
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=args.timeout)
        rc, out, err = r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired as e:
        rc, out, err = 124, (e.stdout or ""), (e.stderr or "") + f"\nTIMEOUT apos {args.timeout}s"
    dur = round(time.time() - t0, 1)
    res = {"step": name, "rc": rc, "seconds": dur}
    if rc != 0:
        # ultima linha significativa como resumo; texto completo no .err
        lines = [l for l in (err + "\n" + out).splitlines() if l.strip()]
        res["error"] = next((l for l in reversed(lines) if not l.startswith(" ")), "?")[:300]
        errfile = errdir / f"{label}.{name}.err"
        errfile.write_text(f"$ {' '.join(cmd)}\n\n=== STDERR ===\n{err}\n=== STDOUT ===\n{out}", encoding="utf-8")
        res["errfile"] = str(errfile)
    else:
        m = re.search(r"^- .*unsupported.*$", out, re.M)
        if m:
            res["note"] = "layers nao suportados (osm2sql)"
    return res


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=dg.CFG["gits"], help=f"raiz dos repos preserv-* (default {dg.CFG['gits']})")
    ap.add_argument("--filter", default=None, help="substring do caminho relativo, ex. preserv-BR/data/RS")
    ap.add_argument("--only", action="append", default=[], help="pasta(s) de pacote especifica(s)")
    ap.add_argument("--steps", default="1,2,3", help="passos a rodar, ex. 1 ou 1,2,3 ou 1,2,3,4 (default 1,2,3)")
    ap.add_argument("--pg-uri", default=dg.CFG["pg_uri"])
    ap.add_argument("--pg-db", default=dg.CFG["pg_db"], required=dg.CFG["pg_db"] is None, help="banco de ingestao (obrigatorio; ou env DG_PG_DB)")
    ap.add_argument("--pg-datalake", default=dg.CFG["pg_datalake"])
    ap.add_argument("--layers", "--layer", default="", help="repassado ao python01/02/03 (ex. via ou via,nsvia)")
    ap.add_argument("--out-root", default=None, help="repassado ao python02 (publicacao de teste)")
    ap.add_argument("--no-regenerate", dest="regenerate", action="store_false", help="python03 sem --regenerate")
    ap.add_argument("--keep-sandbox", action="store_true", help="python01 sem --clean-sandbox (default em lote: limpar)")
    ap.add_argument("--drop-tables", action="store_true", help="python01 com --drop-tables (nao deixar tabelas/views de analise)")
    ap.add_argument("--timeout", type=int, default=4 * 3600, help="segundos por passo (default 4h)")
    ap.add_argument("--stop-on-error", action="store_true")
    ap.add_argument("--dry-run", action="store_true", help="repassa --dry-run a todos os scripts")
    ap.add_argument("--mail-to", default=None)
    ap.add_argument("--no-mail", action="store_true")
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args()
    dg.setup_logging(args.verbose)
    dg.apply_args(args)
    steps = [s.strip() for s in args.steps.split(",") if s.strip()]
    bad = [s for s in steps if s not in STEPS]
    if bad:
        ap.error(f"passos invalidos {bad}; validos: {sorted(STEPS)}")

    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    errdir = Path(dg.CFG["pg_io"]) / "batch" / stamp
    errdir.mkdir(parents=True, exist_ok=True)

    if args.only:
        packs, bad_name, no_yaml = [Path(p).resolve() for p in args.only], [], []
    else:
        packs, bad_name, no_yaml = discover(args.root, args.filter)
    LOG.info("%d pacotes validos, %d com nome incorreto, %d sem yaml | passos %s | %s",
             len(packs), len(bad_name), len(no_yaml), steps, "DRY-RUN" if args.dry_run else "EXECUCAO REAL")

    results = []
    for i, d in enumerate(packs, 1):
        rel = str(d).replace(str(Path(args.root)) + "/", "")
        label = rel.replace("/data/", "_").replace("/", "_")
        LOG.info("[%d/%d] %s", i, len(packs), rel)
        entry = {"package": rel, "steps": []}
        for s in steps:
            res = run_step(s, d, args, errdir, label)
            entry["steps"].append(res)
            LOG.info("    %-8s rc=%s %ss %s", res["step"], res["rc"], res["seconds"], res.get("error", res.get("note", "")))
            if res["rc"] != 0:
                break  # nao publica nem promove o que nao ingeriu
        results.append(entry)
        if args.stop_on_error and any(r["rc"] != 0 for r in entry["steps"]):
            LOG.error("--stop-on-error: parando em %s", rel)
            break

    # ---------------- resumo
    def status(entry):
        done = {r["step"]: r for r in entry["steps"]}
        cells = []
        for s in steps:
            r = done.get(STEPS[s][1])
            cells.append("-" if r is None else ("ok" if r["rc"] == 0 else "ERRO"))
        return cells
    failed = [e for e in results if any(r["rc"] != 0 for r in e["steps"])]
    rows = [{"pacote": e["package"], **{STEPS[s][1]: c for s, c in zip(steps, status(e))},
             "erro": next((r["error"] for r in e["steps"] if r["rc"] != 0), "")} for e in results]
    cols = ["pacote"] + [STEPS[s][1] for s in steps] + ["erro"]
    text = (
        f"python00_batch {'DRY-RUN ' if args.dry_run else ''}| raiz {args.root} | banco {args.pg_db} | passos {','.join(steps)}\n"
        f"pacotes: {len(results)} rodados, {len(results) - len(failed)} ok, {len(failed)} com erro | "
        f"{len(bad_name)} nome incorreto | {len(no_yaml)} sem yaml\n"
        f"erros salvos em: {errdir}\n\n"
        + dg.fmt_table(rows, cols)
        + ("\n\nNome incorreto / fora do padrao:\n" + "\n".join(f"- {p}: {m}" for p, m in bad_name) if bad_name else "")
        + ("\n\nPastas _pk sem yaml:\n" + "\n".join(f"- {p}" for p in no_yaml) if no_yaml else "")
        + "\n"
    )
    payload = {"root": args.root, "pg_db": args.pg_db, "steps": steps, "dry_run": args.dry_run,
               "results": results, "bad_name": bad_name, "no_yaml": no_yaml, "errdir": str(errdir)}
    (errdir / "summary.json").write_text(json.dumps(payload, indent=2, default=str), encoding="utf-8")
    (errdir / "summary.txt").write_text(text, encoding="utf-8")
    dg.finish("python00_batch", f"[preserv] lote {'dry-run ' if args.dry_run else ''}{args.pg_db}: {len(failed)} erro(s) em {len(results)} pacotes",
              text, payload, args)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
