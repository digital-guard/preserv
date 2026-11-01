#!/usr/bin/env python3
"""
python04_clean: limpeza no fim do ciclo de um pacote.

Remove o que o python01 deixa de proposito para o analista:
  * tabelas brutas  pk<packvers>_p<N>_<layer>  (e foreign tables de csv)
  * views tecnicas  vw<N>_pk<packvers>_p<N>_<layer>
  * views legiveis  vw_<isolabel>_<layer>
  * sandbox         /tmp/sandbox/_pk<pack_id>_<pkversion>
  * temporarios     /tmp/pg_io/tmpfile_<PAIS><pack_id>_*  e  /tmp/pg_io/reports mais antigos que --reports-days

Nao toca em ingest.donated_packcomponent, feature_asis nem nos geojsons publicados.

Uso:
  python04_clean.py <pasta_do_pacote> --pg-db ingest20            # um pacote
  python04_clean.py <pasta_do_pacote> --pg-db ingest20 --dry-run
  python04_clean.py --all --pg-db ingest20                         # todas as tabelas pk*_p*_* e views vw*_pk* do banco
"""
import argparse
import glob
import os
import shutil
import sys
import time
from pathlib import Path

import dg_common as dg

LOG = dg.LOG


def list_objects(conn, like_tab, like_view, like_nice):
    rows = dg.sql(conn, """
        SELECT c.relname, c.relkind FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
        WHERE n.nspname='public' AND (
              (c.relkind IN ('r','f') AND c.relname LIKE %s)
           OR (c.relkind = 'v' AND (c.relname LIKE %s OR c.relname LIKE %s)))
        ORDER BY c.relkind DESC, c.relname""", (like_tab, like_view, like_nice))
    return rows


def drop_objects(conn, rows, dry):
    kinds = {"r": "TABLE", "f": "FOREIGN TABLE", "v": "VIEW"}
    done = []
    for r in rows:  # views primeiro (ORDER BY relkind DESC: v, r, f)
        dg.sql(conn, f"DROP {kinds[r['relkind']]} IF EXISTS {r['relname']} CASCADE", fetch=False, dry_run=dry)
        done.append(f"{kinds[r['relkind']].lower()} {r['relname']}")
    return done


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("pack_dir", nargs="?", help="pasta do pacote (omitir com --all)")
    ap.add_argument("--all", action="store_true", help="limpar objetos de analise de todos os pacotes no banco")
    ap.add_argument("--pg-uri", default=dg.CFG["pg_uri"])
    ap.add_argument("--pg-db", default=dg.CFG["pg_db"], required=dg.CFG["pg_db"] is None, help="banco de ingestao (obrigatorio; ou env DG_PG_DB)")
    ap.add_argument("--pg-datalake", default=dg.CFG["pg_datalake"])
    ap.add_argument("--keep-sandbox", action="store_true")
    ap.add_argument("--reports-days", type=int, default=90, help="apagar relatorios em DG_PG_IO/reports mais antigos que N dias (0 = nao apagar)")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--mail-to", default=None)
    ap.add_argument("--no-mail", action="store_true")
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args()
    if not args.all and not args.pack_dir:
        ap.error("informe a pasta do pacote ou --all")
    dg.setup_logging(args.verbose)
    dg.apply_args(args)
    conn = dg.connect(args.pg_db)

    removed, label = [], "todos os pacotes"
    if args.all:
        rows = list_objects(conn, "pk%\\_p%\\_%", "vw%\\_pk%\\_p%\\_%", "vw\\_%")
        removed += drop_objects(conn, rows, args.dry_run)
        if not args.keep_sandbox:
            for sb in glob.glob(os.path.join(dg.CFG["sandbox_root"], "_pk*")):
                LOG.info("rm -rf %s", sb)
                if not args.dry_run:
                    shutil.rmtree(sb, ignore_errors=True)
                removed.append(f"sandbox {sb}")
    else:
        pkg = dg.Package(args.pack_dir, conn, dg.connect(args.pg_datalake))
        label = str(pkg)
        for item in pkg.layer_items():
            pv, p, name = item["packvers_id"], item["p"], item["name"]
            nice = "vw_" + "".join(ch if ch.isalnum() else "_" for ch in f"{pkg.isolabel_ext}_{name}".lower()).strip("_")
            rows = list_objects(conn, f"pk{pv}\\_p{p}\\_{name}", f"vw{p}\\_pk{pv}\\_p{p}\\_{name}", nice)
            removed += drop_objects(conn, rows, args.dry_run)
        if not args.keep_sandbox and pkg.sandbox.exists():
            LOG.info("rm -rf %s", pkg.sandbox)
            if not args.dry_run:
                shutil.rmtree(pkg.sandbox, ignore_errors=True)
            removed.append(f"sandbox {pkg.sandbox}")
        for tmp in glob.glob(os.path.join(dg.CFG["pg_io"], f"tmpfile_{pkg.country}{pkg.conf['pack_id']}_*")):
            LOG.info("rm %s", tmp)
            if not args.dry_run:
                os.remove(tmp)
            removed.append(f"tmp {tmp}")

    if args.reports_days > 0:
        cutoff = time.time() - args.reports_days * 86400
        for rep in glob.glob(os.path.join(dg.CFG["pg_io"], "reports", "*")):
            if os.path.getmtime(rep) < cutoff:
                if not args.dry_run:
                    os.remove(rep)
                removed.append(f"report {os.path.basename(rep)}")

    text = (f"python04_clean OK | {label} | banco {args.pg_db}{' (dry-run)' if args.dry_run else ''}\n\n"
            + ("\n".join(f"- {r}" for r in removed) if removed else "- nada a remover") + "\n")
    dg.finish("python04_clean", f"[preserv] limpeza: {label}", text, {"removed": removed, "pg_db": args.pg_db}, args)


if __name__ == "__main__":
    main()
