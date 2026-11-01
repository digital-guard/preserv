#!/usr/bin/env python3
"""
dg_common: utilidades compartilhadas pelos scripts python01/02/03 do
Projeto Digital Preservation (digital-guard/preserv).

Resolve metadados do pacote a partir do make_conf.yaml e do datalake
(via FDW ingest.vw01full_packfilevers no banco de ingestao), executa
comandos de shell e SQL, e monta/envia relatorios por e-mail.

Configuracao por variaveis de ambiente (todas com default):
  DG_PG_URI        postgres://postgres@localhost          (servidor; ou --pg-uri)
  DG_PG_DB         sem default: obrigatorio via --pg-db   (banco de ingestao)
  DG_PG_DATALAKE   dl05s_main                             (banco optim; ou --pg-datalake)
  DG_ORIG          /var/www/dl.digital-guard.org          (zips originais)
  DG_SANDBOX_ROOT  /tmp/sandbox
  DG_PG_IO         /tmp/pg_io
  DG_GITS          /var/gits/_dg
  DG_DL_URL        https://dl.digital-guard.org
  DG_SMTP_HOST / DG_SMTP_PORT / DG_SMTP_USER / DG_SMTP_PASS / DG_SMTP_FROM
  DG_MAIL_TO       destinatarios separados por virgula
"""
import json
import logging
import os
import re
import shlex
import smtplib
import subprocess
import sys
from datetime import datetime, timezone
from email.message import EmailMessage
from pathlib import Path

import psycopg2
import psycopg2.extras
import yaml

LOG = logging.getLogger("dg")

CFG = {
    "pg_uri": os.environ.get("DG_PG_URI", "postgres://postgres@localhost"),
    "pg_db": os.environ.get("DG_PG_DB"),  # sem default: cada execucao informa o banco
    "pg_datalake": os.environ.get("DG_PG_DATALAKE", "dl05s_main"),
    "orig": os.environ.get("DG_ORIG", "/var/www/dl.digital-guard.org"),
    "sandbox_root": os.environ.get("DG_SANDBOX_ROOT", "/tmp/sandbox"),
    "pg_io": os.environ.get("DG_PG_IO", "/tmp/pg_io"),
    "gits": os.environ.get("DG_GITS", "/var/gits/_dg"),
    "dl_url": os.environ.get("DG_DL_URL", "https://dl.digital-guard.org"),
}


def setup_logging(verbose=False):
    logging.basicConfig(
        level=logging.DEBUG if verbose else logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        datefmt="%H:%M:%S",
    )


# --------------------------------------------------------------------- shell
def run(cmd, cwd=None, dry_run=False, check=True, env=None, input_text=None):
    """Executa um comando (lista ou string) e devolve CompletedProcess.
    Loga o comando; em dry_run apenas loga."""
    if isinstance(cmd, (list, tuple)):
        shown = " ".join(shlex.quote(str(c)) for c in cmd)
        shell = False
    else:
        shown = cmd
        shell = True
    LOG.info("$ %s", shown)
    if dry_run:
        return subprocess.CompletedProcess(cmd, 0, "", "")
    full_env = dict(os.environ)
    if env:
        full_env.update(env)
    res = subprocess.run(
        cmd, cwd=cwd, shell=shell, text=True, capture_output=True,
        env=full_env, input=input_text,
    )
    if res.stdout.strip():
        LOG.debug(res.stdout.strip())
    if res.returncode != 0:
        LOG.error("rc=%s stderr=%s", res.returncode, res.stderr.strip()[-2000:])
        if check:
            raise RuntimeError(f"comando falhou (rc={res.returncode}): {shown}")
    return res


# ------------------------------------------------------------------------ db
def connect(dbname=None, uri=None):
    """Conexao psycopg2 com autocommit, capturando NOTICEs em conn.notices."""
    uri = uri or CFG["pg_uri"]
    dbname = dbname or CFG["pg_db"]
    conn = psycopg2.connect(f"{uri}/{dbname}")
    conn.autocommit = True
    return conn


def pg_uri_db(dbname=None):
    return f"{CFG['pg_uri']}/{dbname or CFG['pg_db']}"


def sql(conn, query, params=None, fetch=True, dry_run=False):
    """Executa SQL; devolve lista de dicts (ou None). Loga NOTICEs."""
    shown = query if params is None else f"{query}  -- {params}"
    LOG.info("SQL> %s", re.sub(r"\s+", " ", shown).strip()[:600])
    if dry_run:
        return []
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute(query, params)
        for n in conn.notices:
            LOG.info("NOTICE %s", n.strip())
        del conn.notices[:]
        if fetch and cur.description:
            return [dict(r) for r in cur.fetchall()]
    return None


def sql_one(conn, query, params=None, dry_run=False):
    rows = sql(conn, query, params, dry_run=dry_run)
    return rows[0] if rows else None


# ---------------------------------------------------------------- make_conf
class Package:
    """Pacote _pkNNNN.NN: make_conf.yaml + metadados do datalake + dicionario preparado
    por optim.jsonb_mustache_prepare (o mesmo que alimenta os templates mustache do makefile).

    conn    : conexao ao banco de ingestao (FDW ingest.vw01full_packfilevers)
    conn_dl : conexao ao datalake (schema optim); se None, abre uma com CFG['pg_datalake']."""

    def __init__(self, pack_dir, conn, conn_dl=None):
        self.dir = Path(pack_dir).resolve()
        self.yaml_path = self.dir / "make_conf.yaml"
        if not self.yaml_path.exists():
            raise FileNotFoundError(self.yaml_path)
        with open(self.yaml_path, encoding="utf-8") as fh:
            self.conf = yaml.safe_load(fh)
        # pais a partir do caminho .../preserv-BR/data/...
        m = re.search(r"preserv-([A-Z]{2})/data/", str(self.dir))
        self.country = m.group(1) if m else "INT"
        self.pkversion = int(self.conf.get("pkversion", 1))
        self.files = {int(f["p"]): f for f in self.conf.get("files", [])}
        self.layers = self.conf.get("layers") or {}
        self.srid = self.conf.get("srid")
        self.srid_proj = self.conf.get("srid_proj")
        self.lint_errors, self.lint_warnings = self.lint()
        for w in self.lint_warnings:
            LOG.warning("make_conf.yaml: %s", w)
        if self.lint_errors:
            raise ValueError("make_conf.yaml invalido: " + "; ".join(self.lint_errors))
        self._resolve(conn)
        self._prepare(conn_dl or connect(CFG["pg_datalake"]))

    def _resolve(self, conn):
        """Resolve packvers_id de cada arquivo e dados da jurisdicao via FDW."""
        hashes = [f["file"] for f in self.files.values()]
        try:
            rows = sql(
                conn,
                "SELECT id, hashedfname, pack_id, pack_item, pack_number, isolabel_ext, "
                "       legalname, path_preserv_server, path_cutgeo_server, housenumber_system_type "
                "FROM ingest.vw01full_packfilevers WHERE hashedfname = ANY(%s)",
                (hashes,),
            )
        except psycopg2.errors.UndefinedTable as e:
            raise SystemExit(
                f"banco {CFG['pg_uri']}/{CFG['pg_db']} nao e um banco de ingestao (falta ingest.vw01full_packfilevers). "
                f"Crie com: cd {CFG['gits']}/preserv/src && make ini_ingest pg_db={CFG['pg_db']}\n{e}".strip()
            ) from e
        self.by_hash = {r["hashedfname"]: r for r in rows}
        missing = [h for h in hashes if h not in self.by_hash]
        if missing:
            raise LookupError(
                "arquivos do make_conf.yaml nao cadastrados em optim.donated_packfilevers "
                f"(datalake): {missing}"
            )
        first = next(iter(self.by_hash.values()))
        self.pack_id = int(first["pack_id"])
        self.pack_number = first["pack_number"]
        self.isolabel_ext = first["isolabel_ext"]
        self.legalname = first["legalname"]
        self.path_preserv_server = first["path_preserv_server"]
        self.path_cutgeo_server = first["path_cutgeo_server"]
        self.sandbox = Path(CFG["sandbox_root"]) / f"_pk{self.pack_id}_{self.pkversion:03d}"

    def packvers_id(self, p):
        return int(self.by_hash[self.files[int(p)]["file"]]["id"])

    def _prepare(self, conn_dl):
        """Dicionario resolvido pelo gerador SQL: srid, charset, delimiter, extensao,
        orig_tabname, tabname, layername, joins... Mesma entrada do optim.generate_makefile."""
        first = f"{CFG['gits']}/preserv{'' if self.country == 'INT' else '-' + self.country}/src/maketemplates/commomFirst.yaml"
        row = sql_one(conn_dl,
                      "SELECT optim.jsonb_mustache_prepare(yaml_to_jsonb(pg_read_file(%s)) || yamlfile_to_jsonb(%s)) AS d",
                      (str(self.yaml_path), first))
        self.prep = (row or {}).get("d") or {}
        if not self.prep:
            LOG.warning("optim.jsonb_mustache_prepare nao devolveu dicionario para %s (cadastro incompleto no datalake?); "
                        "usando so o make_conf.yaml", self.dir)
        self.prep_layers = self.prep.get("layers") or {}
        self.joins_prepared = self.prep.get("joins") or {}

    def layer_items(self):
        """Um dict por layer: conf bruta do yaml + chaves resolvidas pelo gerador (prep)."""
        for name, lconf in self.layers.items():
            if not lconf:
                continue
            prep = self.prep_layers.get(name) or {}
            p = int(lconf["file"])
            pv = int(prep.get("packvers_id") or self.packvers_id(p))
            yield {
                "name": name,
                "conf": lconf,
                "prep": prep,
                "subtype": lconf.get("subtype", "none"),
                "layername": prep.get("layername") or f"{name}_{lconf.get('subtype', 'none')}",
                "method": prep.get("method") or lconf.get("method", "none"),
                "tabname": prep.get("tabname") or f"pk{pv}_p{p}_{name}",
                "packvers_id": pv,
                "file": self.files[p],
                "p": p,
            }

    CAD_LAYERS = ("address", "cadparcel", "cadvia", "cadgeopoint")
    # chaves de layer conhecidas (inventario dos 107 yamls em 2026-10-31 + docs/man-makeConf.md)
    LAYER_KEYS = {"method", "file", "orig_filename", "subtype", "standardized_fields", "sql_select", "sql_view",
                  "codec", "other_fields", "join_id", "buffer_type", "orig_tabname", "orig_subfilename", "comments",
                  "partition_by", "method_opts", "after_extract", "extension", "id_profile_params", "orig_ext",
                  "7z_opts", "charset", "charsetcopy", "delimiter", "p", "orig_filename_with_extension",
                  "orig_filename_string_extract", "gdb_layer", "to-do"}

    def lint(self):
        """Erros (lista) e avisos (lista) de estrutura do make_conf.yaml antes de qualquer carga."""
        errors, warnings = [], []
        if not self.files:
            errors.append("sem 'files:'")
        if not self.layers:
            errors.append("sem 'layers:'")
        for name, l in self.layers.items():
            if not isinstance(l, dict):
                errors.append(f"layer {name}: nao e um mapeamento"); continue
            unknown = set(l) - self.LAYER_KEYS
            if unknown:
                warnings.append(f"layer {name}: chave(s) desconhecida(s) {sorted(unknown)} (erro de digitacao?)")
            for k in ("method", "file"):
                if k not in l:
                    errors.append(f"layer {name}: sem '{k}'")
            if l.get("method") not in (None, "none", "osm2sql") and "subtype" not in l:
                errors.append(f"layer {name}: sem 'subtype' (full/ext/none/cmpl/noid); nao da para resolver o feature type")
            if "file" in l and int(l["file"]) not in self.files:
                errors.append(f"layer {name}: file={l['file']} nao existe em files:")
            if l.get("method") not in (None, "none", "osm2sql") and not l.get("orig_filename"):
                errors.append(f"layer {name}: sem 'orig_filename'")
        return errors, warnings

    def is_cad(self, name):
        """Layer cadastral (sem geometria, vai para ingest.cadastral_asis)."""
        return name in self.CAD_LAYERS

    def joins(self):
        """Pares para ingest.join(). Fonte: chave 'joins' do dicionario preparado pelo gerador
        (optim.jsonb_mustache_prepare); fallback: mesma regra reimplementada em Python."""
        if self.joins_prepared:
            out = []
            for key, j in self.joins_prepared.items():
                cad_key = j["cadLayer"].rsplit("_", 1)[0]
                out.append({
                    "key": key,
                    "layer": j["layer"], "layer_col": str(j["layerColumn"]), "layer_file": j["layerFile"],
                    "layer_packvers": self.packvers_id(self.layers[key]["file"]),
                    "cad": j["cadLayer"], "cad_col": str(j["cadLayerColumn"]), "cad_file": j["cadLayerFile"],
                    "cad_packvers": self.packvers_id(self.layers[cad_key]["file"]),
                })
            return out
        out = []
        for key, lconf in self.layers.items():
            if not lconf or lconf.get("subtype") != "ext" or "join_id" not in lconf:
                continue
            cad_key = "address" if key == "geoaddress" else f"cad{key}"
            cconf = self.layers.get(cad_key)
            if not cconf or cconf.get("subtype") != "cmpl" or "join_id" not in cconf:
                continue
            out.append({
                "key": key,
                "layer": f"{key}_ext", "layer_col": str(lconf["join_id"]),
                "layer_file": self.files[int(lconf["file"])]["file"],
                "layer_packvers": self.packvers_id(lconf["file"]),
                "cad": f"{cad_key}_cmpl", "cad_col": str(cconf["join_id"]),
                "cad_file": self.files[int(cconf["file"])]["file"],
                "cad_packvers": self.packvers_id(cconf["file"]),
            })
        return out

    def __str__(self):
        return f"{self.isolabel_ext} _pk{self.pack_number} (pack_id={self.pack_id}, {len(self.layers)} layers)"


# ---------------------------------------------------------------- relatorio
def report_rows(conn, pack_id=None, packvers_ids=None):
    """Linhas da view de validacao ingest.vw06ingest_report."""
    where, params = "TRUE", []
    if packvers_ids:
        where = "packvers_id = ANY(%s)"
        params = [list(packvers_ids)]
    elif pack_id:
        where = "pack_id = %s"
        params = [pack_id]
    return sql(conn, f"SELECT * FROM ingest.vw06ingest_report WHERE {where} ORDER BY packvers_id, ftid", params)


def fmt_table(rows, cols):
    if not rows:
        return "(sem linhas)"
    widths = {c: max(len(c), *(len(str(r.get(c, ""))) for r in rows)) for c in cols}
    line = " | ".join(c.ljust(widths[c]) for c in cols)
    sep = "-+-".join("-" * widths[c] for c in cols)
    body = "\n".join(" | ".join(str(r.get(c, "")).ljust(widths[c]) for c in cols) for r in rows)
    return f"{line}\n{sep}\n{body}"


def write_report(name, payload, text):
    """Grava relatorio JSON e texto em DG_PG_IO/reports e devolve os caminhos."""
    out = Path(CFG["pg_io"]) / "reports"
    out.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    base = out / f"{name}_{stamp}"
    (base.with_suffix(".json")).write_text(json.dumps(payload, indent=2, default=str), encoding="utf-8")
    (base.with_suffix(".txt")).write_text(text, encoding="utf-8")
    LOG.info("relatorio: %s.{json,txt}", base)
    return str(base)


def send_mail(subject, body, to=None, dry_run=False):
    """Envia e-mail texto via SMTP (DG_SMTP_*). Sem DG_SMTP_HOST apenas loga."""
    to = to or os.environ.get("DG_MAIL_TO", "")
    host = os.environ.get("DG_SMTP_HOST")
    if not to:
        LOG.warning("sem destinatario (DG_MAIL_TO / --mail-to); e-mail nao enviado")
        return False
    if not host or dry_run:
        LOG.info("[mail nao enviado: host=%s dry_run=%s] %s -> %s", host, dry_run, subject, to)
        return False
    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = os.environ.get("DG_SMTP_FROM", "preserv@digital-guard.org")
    msg["To"] = to
    msg.set_content(body)
    port = int(os.environ.get("DG_SMTP_PORT", "587"))
    with smtplib.SMTP(host, port, timeout=60) as s:
        if port != 25:
            s.starttls()
        user, pwd = os.environ.get("DG_SMTP_USER"), os.environ.get("DG_SMTP_PASS")
        if user:
            s.login(user, pwd or "")
        s.send_message(msg)
    LOG.info("e-mail enviado para %s", to)
    return True


def common_args(parser):
    parser.add_argument("pack_dir", help="pasta do pacote, ex. /var/gits/_dg/preserv-BR/data/RS/PortoAlegre/_pk0018.01")
    parser.add_argument("--pg-uri", default=CFG["pg_uri"],
                        help=f"servidor Postgres, ex. postgres://postgres@localhost:5499 (default {CFG['pg_uri']}, env DG_PG_URI)")
    parser.add_argument("--pg-db", default=CFG["pg_db"], required=CFG["pg_db"] is None,
                        help="banco de ingestao, ex. ingest20 (obrigatorio; ou env DG_PG_DB)")
    parser.add_argument("--pg-datalake", default=CFG["pg_datalake"],
                        help=f"banco do datalake (schema optim: metadados e gerador), default {CFG['pg_datalake']} (env DG_PG_DATALAKE)")
    parser.add_argument("--layers", default="", help="lista de layers separada por virgula (default: todos)")
    parser.add_argument("--layer", dest="layers", help="um layer so (alias de --layers)")
    parser.add_argument("--dry-run", action="store_true", help="so mostra comandos e SQL")
    parser.add_argument("--mail-to", default=None, help="destinatarios do relatorio (default DG_MAIL_TO)")
    parser.add_argument("--no-mail", action="store_true")
    parser.add_argument("-v", "--verbose", action="store_true")
    return parser


def apply_args(args):
    """Aplica --pg-uri/--pg-db (e --pg-datalake se houver) na configuracao global."""
    CFG["pg_uri"] = args.pg_uri
    CFG["pg_db"] = args.pg_db
    if getattr(args, "pg_datalake", None):
        CFG["pg_datalake"] = args.pg_datalake
    LOG.info("postgres: %s | ingest=%s | datalake=%s", CFG["pg_uri"], CFG["pg_db"], CFG["pg_datalake"])


def finish(name, subject, text, payload, args):
    """Grava relatorio, imprime, envia e-mail."""
    base = write_report(name, payload, text)
    print(text)
    if not args.no_mail:
        send_mail(subject, text + f"\n\nRelatorio: {base}.json", to=args.mail_to, dry_run=args.dry_run)
    return base


def sh_quote(s):
    return shlex.quote(str(s))


def pg_conn_kv():
    """Converte DG_PG_URI (postgres://user[:pass]@host[:port]) em 'host=.. port=.. user=..' para o ogr2ogr."""
    from urllib.parse import urlparse
    u = urlparse(CFG["pg_uri"])
    parts = []
    if u.hostname:
        parts.append(f"host={u.hostname}")
    if u.port:
        parts.append(f"port={u.port}")
    if u.username:
        parts.append(f"user={u.username}")
    if u.password:
        parts.append(f"password={u.password}")
    return " ".join(parts)


def Json(obj):
    """Adaptador jsonb para psycopg2."""
    return psycopg2.extras.Json(obj)
