#!/usr/bin/env python3
"""
python01_ingest: make_conf.yaml -> ingestao no banco de ingestao (ex. ingest20).

Substitui o makefile gerado por mustache. A interpretacao do yaml (codec -> srid,
charset, delimiter, extensao; orig_tabname; tabname; layername; joins) vem da mesma
funcao que alimenta os templates, optim.jsonb_mustache_prepare no datalake, para
que este script e o makefile nunca divirjam. Para cada layer:

  1. garante o arquivo original em DG_ORIG (baixa de dl.digital-guard.org se faltar);
  2. extrai com 7z (ou copia, se `uncompacted`) para /tmp/sandbox/_pk<pack_id>_<pkversion>;
  3. carrega a tabela bruta, espelhando o template common003_shp2pgsql.mustache:
       shp2sql            ogr2ogr com convencao shp2pgsql (gid, geom, MULTI*), CRS nativo
       shp2sqlparalell    idem, todos os .shp acumulados numa tabela, um any_load
       gdb2sql / ogr2ogr  ogr2ogr <fonte> <orig_tabname> -lco GEOMETRY_NAME=geom -a_srs EPSG:<srid>
       geojson2sql        SQL: geojson_readfile_features_jgeom (jgeom/properties), com split se > 150 MB
       csv2sql            xlsx2csv / iconv+dos2unix se preciso, depois ingest.fdw_generate_direct_csv
       txt2sql            ingest.copy_tabular_data
       osm2sql            NAO suportado aqui (fluxo OpenStreetMap: osm2pgsql + ingest.osm_load)
  4. aplica sql_view (se houver) e chama ingest.any_load() (ou any_load_loop com partition_by),
     que valida geometrias, deduplica e grava ingest.donated_packcomponent (lineage);
  5. joins: ingest.join() para cada par da chave 'joins' do dicionario preparado
     (equivale ao all_joins do makefile; --no-join desliga);
  6. relatorio a partir de ingest.vw06ingest_report, por e-mail.

CRS: nunca reprojeta. sql_view roda no CRS nativo (st_area/st_length em metros) e o
any_load converte para 4326. srid_proj do yaml vai em -a_srs como string proj, sem
inserir SRID aleatorio em spatial_ref_sys.

Idempotente: antes de carregar, remove o componente anterior do mesmo
(packvers_id, ftid) e suas features (--no-reset desliga).

Ciclo do analista (dado novo que da erro):
  * a tabela bruta pk<packvers>_p<N>_<layer>, a view tecnica vw<N>_pk..._<layer>
    (= sql_view do yaml) e a view legivel vw_<isolabel>_<layer> ficam no banco
    apos a execucao e sao recriadas a cada rodada (--drop-tables limpa no fim);
  * --stage load carrega e cria as views sem chamar any_load, para testar o
    sql_view no psql/QGIS; depois corrige make_conf.yaml e roda de novo;
  * --layer via reexecuta so um layer (e so os joins em que ele participa);
    o sandbox e mantido (--clean-sandbox apaga).

Uso:
  python01_ingest.py /var/gits/_dg/preserv-BR/data/RS/PortoAlegre/_pk0018.01 --pg-db ingest20
  python01_ingest.py <pasta> --pg-db ingest20 --layer via --stage load
"""
import argparse
import glob
import os
import re
import shlex
import shutil
import sys
from pathlib import Path

import dg_common as dg

LOG = dg.LOG

OGR_SHP = {"shp2sql", "shp2sqlparalell"}
OGR_OTHER = {"gdb2sql", "ogr2ogr"}
SQL_TABULAR = {"csv2sql", "txt2sql"}
SUPPORTED = OGR_SHP | OGR_OTHER | SQL_TABULAR | {"geojson2sql"}
GEOJSON_SPLIT_BYTES = 157286400  # 150 MB, como no template
METHOD_EXT = {"shp2sql": "shp", "shp2sqlparalell": "shp", "gdb2sql": "gdb", "geojson2sql": "geojson",
              "csv2sql": "csv", "txt2sql": "txt"}  # fallback quando o gerador nao devolveu 'extension'
JUNK_RE = re.compile(r"(^|/)(\._[^/]*|__MACOSX(/.*)?|\.DS_Store|Thumbs\.db)$")


# ----------------------------------------------------------------- helpers
def is_junk(path):
    """Lixo de empacotamento (AppleDouble ._x.shp, __MACOSX, .DS_Store) que casa com *nome*.ext."""
    return bool(JUNK_RE.search(path))


def ensure_orig_file(fname, dry_run):
    path = Path(dg.CFG["orig"]) / fname
    if path.exists():
        return path
    LOG.warning("arquivo %s nao existe em %s; baixando", fname, dg.CFG["orig"])
    dg.run(["wget", "-q", "-P", dg.CFG["orig"], f"{dg.CFG['dl_url']}/{fname}"], dry_run=dry_run)
    dg.run(["sudo", "chown", "postgres:www-data", str(path)], dry_run=dry_run, check=False)
    return path


def names_of(item):
    """orig_filename(s) a procurar: orig_subfilename > orig_filename_array > orig_filename."""
    lconf, prep = item["conf"], item["prep"]
    n = lconf.get("orig_subfilename") or prep.get("orig_filename_array") or lconf.get("orig_filename")
    n = n if isinstance(n, list) else [n]
    return [str(x) for x in n if x]


def filename_with_ext(item, name=None):
    """Nome do arquivo no sandbox como o template monta: orig_filename[.extension]."""
    lconf, prep = item["conf"], item["prep"]
    name = name or str(lconf.get("orig_filename"))
    if prep.get("orig_filename_with_extension") or lconf.get("orig_filename_with_extension"):
        return name
    if prep.get("isXlsx"):
        return f"{name}.xlsx"
    ext = lconf.get("orig_ext") or prep.get("extension") or METHOD_EXT.get(item["method"], "")
    return f"{name}.{ext.lstrip('.')}" if ext else name


def charset_is_utf8(prep):
    cs = (prep.get("charset") or "UTF-8").upper().replace("-", "")
    return prep.get("isUtf8", cs in ("UTF8", "USASCII", "ASCII"))


def srs_args(pkg, item):
    """-a_srs: srid_proj (string proj) ou EPSG:<srid> resolvido pelo gerador (codec). Nunca -t_srs."""
    if pkg.srid_proj:
        return ["-a_srs", str(pkg.srid_proj)]
    srid = item["prep"].get("srid") or pkg.conf.get("srid")
    if srid:
        return ["-a_srs", f"EPSG:{srid}"]
    return []


def ogr_pg():
    return f"PG:dbname={dg.CFG['pg_db']} " + dg.pg_conn_kv()


# ------------------------------------------------------------ extracao
def extract(pkg, item, dry_run):
    lconf, prep, fconf = item["conf"], item["prep"], item["file"]
    sb = pkg.sandbox
    if not dry_run:
        sb.mkdir(parents=True, exist_ok=True)
        os.chmod(sb, 0o777)
    src = ensure_orig_file(fconf["file"], dry_run)
    if fconf.get("uncompacted") or (prep.get("file_data") or {}).get("uncompacted"):
        target = sb / filename_with_ext(item)
        LOG.info("copiando arquivo nao compactado -> %s", target)
        if not dry_run:
            shutil.copy(src, target)
    else:
        extract_str = prep.get("orig_filename_string_extract") or lconf.get("orig_filename_string_extract")
        if extract_str:
            patterns = shlex.split(str(extract_str))          # ja vem no formato de linha de comando
        else:
            patterns = [f"*{n}*" for n in (prep.get("orig_filename_array") or [lconf.get("orig_filename")]) if n] or ["*"]
        opts = str(lconf.get("7z_opts") or "").split()
        dg.run(["7z", *opts, "x", "-y", str(src), *patterns], cwd=str(sb), dry_run=dry_run)
    dg.run(f"chmod -R a+rwx {dg.sh_quote(str(sb))} 2>/dev/null || true", dry_run=dry_run, check=False)
    if lconf.get("after_extract"):
        LOG.info("after_extract")
        dg.run(str(lconf["after_extract"]), cwd=str(sb), dry_run=dry_run)


def find_sources(pkg, item, dry_run):
    """Arquivos de entrada do layer no sandbox.
    shp (e csv multiplo): find "*nome*.ext" como o makefile, ignorando lixo;
    gdb: diretorio *nome*; demais: caminho exato <sandbox>/<nome>[.ext] com fallback por glob."""
    method, lconf = item["method"], item["conf"]
    ext = (lconf.get("orig_ext") or item["prep"].get("extension") or METHOD_EXT.get(method, "")).lstrip(".")
    found = []
    for n in names_of(item):
        exact = pkg.sandbox / filename_with_ext(item, n)
        if method in OGR_SHP or lconf.get("orig_subfilename") or item["prep"].get("multiple_files"):
            pat = f"**/*{n}" if n.lower().endswith(f".{ext}") else f"**/*{n}*.{ext}"
        else:
            pat = f"**/{exact.name}" if not (exact.name.endswith(f".{ext}") and n.lower().endswith(f".{ext}")) else f"**/*{n}"
        hits = sorted({h for h in glob.glob(str(pkg.sandbox / pat), recursive=True) if not is_junk(h)})
        if exact.exists() and str(exact) in hits:
            hits = [str(exact)]
        hits = [h for h in hits if (os.path.isdir(h) if method == "gdb2sql" else os.path.isfile(h))]
        if not hits and dry_run:
            hits = [str(exact)]
        if not hits:
            raise FileNotFoundError(f"layer {item['name']}: nenhum '{pat}' em {pkg.sandbox}")
        if len(hits) > 1 and method != "shp2sqlparalell":
            LOG.warning("layer %s: %d arquivos casam com %s; carregados em sequencia: %s",
                        item["name"], len(hits), pat, [os.path.basename(h) for h in hits])
        found.extend(hits)
    return found


# ------------------------------------------------------------ carregadores
def drop_table(conn, item, dry):
    kind = "FOREIGN TABLE" if item["method"] == "csv2sql" else "TABLE"
    dg.sql(conn, f"DROP {kind} IF EXISTS {item['tabname']} CASCADE", fetch=False, dry_run=dry)


def load_shp(pkg, item, src, dry, append=False):
    """shp2pgsql -D [-W charset] -s srid: ogr2ogr com gid, geom, MULTI*, CRS nativo."""
    cmd = ["ogr2ogr", "-f", "PostgreSQL", ogr_pg(), src, "-nln", item["tabname"],
           "-append" if append else "-overwrite",
           "-lco", "GEOMETRY_NAME=geom", "-lco", "FID=gid", "-lco", "LAUNDER=YES", "-lco", "SPATIAL_INDEX=NONE",
           "-nlt", "PROMOTE_TO_MULTI", "--config", "PG_USE_COPY", "YES", "-skipfailures"]
    cmd += srs_args(pkg, item)
    cs = item["prep"].get("charset") or item["conf"].get("charset")
    if cs:
        cmd += ["--config", "SHAPE_ENCODING", str(cs)]
    if item["conf"].get("method_opts") and item["method"] in OGR_SHP:
        pass  # method_opts de shp2pgsql (ex. -S) nao tem equivalente direto; MULTI ja e o padrao
    dg.run(cmd, dry_run=dry)


def load_ogr(pkg, item, src, dry):
    """Template isGdb/isOgr: ogr2ogr -lco GEOMETRY_NAME=geom -overwrite <fonte> [orig_tabname] -nln tab -a_srs EPSG:srid method_opts."""
    cmd = ["ogr2ogr", "-lco", "GEOMETRY_NAME=geom", "-overwrite", "-f", "PostgreSQL", ogr_pg(), src]
    tabname_in = item["prep"].get("orig_tabname") or item["conf"].get("orig_tabname")
    if tabname_in:
        cmd.append(str(tabname_in))
    cmd += ["-nln", item["tabname"]] + srs_args(pkg, item)
    if item["conf"].get("method_opts"):
        cmd += str(item["conf"]["method_opts"]).split()
    dg.run(cmd, dry_run=dry)


def load_geojson(conn, pkg, item, src, dry):
    """Template isGeojson: tabela via geojson_readfile_features_jgeom (lido pelo servidor), com split > 150 MB."""
    tab = item["tabname"]
    size = os.path.getsize(src) if (not dry and os.path.exists(src)) else 0
    dg.sql(conn, f"DROP TABLE IF EXISTS {tab}", fetch=False, dry_run=dry)
    if size > GEOJSON_SPLIT_BYTES:
        LOG.info("geojson de %d MB: dividindo em blocos de 20000 feicoes", size // 2**20)
        dg.run(["bash", f"{dg.CFG['gits']}/preserv/src/splitGeojson.bash", os.path.basename(src), "20000"],
               cwd=os.path.dirname(src), dry_run=dry)
        parts = sorted(glob.glob(os.path.join(os.path.dirname(src), f"splited*_{os.path.basename(src)}")),
                       key=lambda p: int(re.search(r"splited(\d+)_", p).group(1)))
        for i, part in enumerate(parts):
            verb = f"CREATE TABLE {tab} AS" if i == 0 else f"INSERT INTO {tab}"
            dg.sql(conn, f"{verb} SELECT * FROM geojson_readfile_features_jgeom(%s, null) WHERE jgeom->'type' IS NOT NULL",
                   (part,), fetch=False, dry_run=dry)
    else:
        dg.sql(conn, f"CREATE TABLE {tab} AS SELECT * FROM geojson_readfile_features_jgeom(%s, null) WHERE jgeom->'type' IS NOT NULL",
               (src,), fetch=False, dry_run=dry)


def load_csv(conn, pkg, item, src, dry):
    """Template isCsv: xlsx2csv / iconv + dos2unix quando preciso, depois fdw_generate_direct_csv."""
    prep, lconf, tab = item["prep"], item["conf"], item["tabname"]
    delim = prep.get("delimiter") or lconf.get("delimiter") or ","
    path = src
    if prep.get("isXlsx"):
        csv_out = os.path.splitext(src)[0] + ".csv"
        dg.run(["xlsx2csv", "-i", *str(lconf.get("method_opts") or "").split(), src, csv_out], dry_run=dry)
        path = csv_out
    if not charset_is_utf8(prep):
        conv = os.path.splitext(path)[0] + ".unix_utf8.csv"
        dg.run(f"iconv -f {dg.sh_quote(prep.get('charset'))} -t UTF-8 {dg.sh_quote(path)} | dos2unix > {dg.sh_quote(conv)}", dry_run=dry)
        path = conv
    elif prep.get("lineending"):
        dg.run(["dos2unix", path], dry_run=dry)
    dg.sql(conn, f"DROP FOREIGN TABLE IF EXISTS {tab} CASCADE", fetch=False, dry_run=dry)
    dg.sql(conn, "SELECT ingest.fdw_generate_direct_csv(%s, %s, %s)", (path, tab, delim), dry_run=dry)
    return path


def load_txt(conn, pkg, item, src, dry):
    prep, lconf, tab = item["prep"], item["conf"], item["tabname"]
    delim = prep.get("delimiter") or lconf.get("delimiter") or ","
    enc = prep.get("charsetcopy") or prep.get("charset") or "UTF8"
    dg.sql(conn, f"DROP TABLE IF EXISTS {tab} CASCADE", fetch=False, dry_run=dry)
    dg.sql(conn, "SELECT ingest.copy_tabular_data(%s, %s, %s, %s)", (src, tab, enc, delim), dry_run=dry)


# ------------------------------------------------------------ ingestao
def clean_sql_view(text, tabname):
    """Remove continuacoes de linha '\\' (heranca do makefile) e substitui $(tabname)."""
    text = re.sub(r"\\\s*\n", "\n", text)
    return text.replace("$(tabname)", tabname)


def friendly_view(pkg, item):
    base = re.sub(r"[^a-z0-9]+", "_", f"{pkg.isolabel_ext}_{item['name']}".lower()).strip("_")
    return f"vw_{base}"


def table_info(conn, tab, dry_run):
    cols = dg.sql(conn, "SELECT column_name, data_type FROM information_schema.columns WHERE table_name=%s ORDER BY ordinal_position", (tab,), dry_run=dry_run)
    g = dg.sql_one(conn, "SELECT srid, type FROM geometry_columns WHERE f_table_name=%s", (tab,), dry_run=dry_run) or {}
    return [f"{r['column_name']}:{r['data_type']}" for r in cols], g.get("srid"), g.get("type")


def reset_layer(conn, item, dry_run):
    ft = dg.sql_one(conn, "SELECT ftid FROM ingest.fdw_feature_type WHERE ftname=%s", (item["layername"],), dry_run=dry_run)
    if dry_run:
        return
    if not ft:
        raise LookupError(f"ftname '{item['layername']}' nao existe em feature_type")
    ids = [r["id"] for r in dg.sql(conn, "SELECT id FROM ingest.donated_packcomponent WHERE packvers_id=%s AND ftid=%s",
                                   (item["packvers_id"], ft["ftid"]))]
    if ids:
        LOG.warning("reset: removendo componente(s) %s do layer %s", ids, item["layername"])
        for t in ("feature_asis", "feature_asis_discarded", "cadastral_asis"):
            dg.sql(conn, f"DELETE FROM ingest.{t} WHERE file_id = ANY(%s)", (ids,), fetch=False)
        dg.sql(conn, "DELETE FROM ingest.donated_packcomponent WHERE id = ANY(%s)", (ids,), fetch=False)


def any_load(conn, item, fileref, target, tabcols, is_first, dry):
    prep, lconf = item["prep"], item["conf"]
    id_profile = int(prep.get("id_profile_params") or lconf.get("id_profile_params") or (1 if item["name"] == "geoaddress" else 5))
    buffer_type = int(prep.get("buffer_type") or lconf.get("buffer_type") or 1)
    args = (item["method"], fileref, item["layername"], target, item["packvers_id"], item["file"]["file"],
            tabcols, id_profile, buffer_type, is_first)
    part = prep.get("partition_by") or lconf.get("partition_by")
    if part:
        dg.sql(conn, "CALL ingest.any_load_loop(%s, %s, %s, %s, %s::bigint, %s, %s::text[], %s, %s, %s, 'geom', true, %s)",
               args + (str(part),), fetch=False, dry_run=dry)
        return f"any_load_loop partition_by={part}"
    row = dg.sql_one(conn, "SELECT ingest.any_load(%s, %s, %s, %s, %s::bigint, %s, %s::text[], %s, %s, %s) AS msg", args, dry_run=dry)
    return (row or {}).get("msg", "")


def ingest_layer(conn, pkg, item, args):
    dry = args.dry_run
    method, lconf, prep, tab = item["method"], item["conf"], item["prep"], item["tabname"]
    LOG.info("==== %s | layer %s (%s) | tabela %s | packvers %s", pkg.isolabel_ext, item["layername"], method, tab, item["packvers_id"])
    if method == "none":
        return {"layer": item["layername"], "status": "skipped", "detail": "method none"}
    if method not in SUPPORTED:
        return {"layer": item["layername"], "status": "unsupported",
                "detail": "osm2sql: fluxo OpenStreetMap (osm2pgsql + ingest.osm_load)" if method == "osm2sql" else f"method {method}"}

    extract(pkg, item, dry)
    sources = find_sources(pkg, item, dry)
    if args.reset:
        reset_layer(conn, item, dry)

    sql_view = lconf.get("sql_view")
    sql_select = list(prep.get("sql_select") or lconf.get("sql_select") or [])
    view_tech, view_nice = f"vw{item['p']}_{tab}", friendly_view(pkg, item)
    objects = {"table": tab, "view": view_tech if sql_view else None, "view_analista": view_nice}
    msgs, columns = [], []

    # unidades de carga: (fonte para ogr/sql, fileref para any_load, is_first)
    if method == "shp2sqlparalell":
        units = [(sources, sources[0], True)]                    # tudo numa tabela, um any_load
    else:
        units = [([s], s, i == 0) for i, s in enumerate(sources)]

    for srcs, fileref, is_first in units:
        dg.sql(conn, f"DROP VIEW IF EXISTS {view_nice}", fetch=False, dry_run=dry)
        dg.sql(conn, f"DROP VIEW IF EXISTS {view_tech}", fetch=False, dry_run=dry)
        if method in OGR_SHP:
            for i, s in enumerate(srcs):
                load_shp(pkg, item, s, dry, append=(i > 0))
        elif method in OGR_OTHER:
            load_ogr(pkg, item, srcs[0], dry)
            if method == "gdb2sql":  # any_load faz pg_stat_file no fileref: gdb e diretorio, usa arquivo dummy (como o template)
                fileref = os.path.join(srcs[0], "random_data_file")
                dg.run(["dd", "if=/dev/urandom", f"of={fileref}", "bs=1M", "count=1", "status=none"], dry_run=dry)
        elif method == "geojson2sql":
            load_geojson(conn, pkg, item, srcs[0], dry)
        elif method == "csv2sql":
            fileref = load_csv(conn, pkg, item, srcs[0], dry)
        elif method == "txt2sql":
            load_txt(conn, pkg, item, srcs[0], dry)

        columns, srid, gtype = table_info(conn, tab, dry)
        LOG.info("%s: srid=%s tipo=%s colunas=%s", tab, srid, gtype, ", ".join(columns))
        objects["srid"] = srid
        if not dry and method in OGR_SHP | OGR_OTHER and srid in (None, 0):
            raise RuntimeError(f"{tab} carregada sem SRID: informe srid (codec:descr_encode) ou srid_proj no make_conf.yaml")

        target = tab
        if sql_view:
            target = view_tech
            dg.sql(conn, f"CREATE VIEW {view_tech} AS {clean_sql_view(sql_view, tab)}", fetch=False, dry_run=dry)
        dg.sql(conn, f"CREATE VIEW {view_nice} AS SELECT * FROM {target}", fetch=False, dry_run=dry)
        n = dg.sql_one(conn, f"SELECT count(*) AS n FROM {view_nice}", dry_run=dry) or {}
        LOG.info("%s: %s linhas", view_nice, n.get("n", "?"))
        if args.stage == "load":
            continue
        msgs.append(any_load(conn, item, fileref, target, [] if sql_view else sql_select, is_first, dry))

    if args.stage == "load":
        return {"layer": item["layername"], "status": "loaded", "sources": sources, "objects": objects, "columns": columns,
                "detail": f"so carga: testar com SELECT * FROM {view_nice} LIMIT 10"}
    if len(units) > 1:
        dg.sql(conn, "SELECT ingest.any_load_assign(%s, %s, %s::bigint)", (sources[0], item["layername"], item["packvers_id"]), dry_run=dry)
    if args.drop_tables:
        dg.sql(conn, f"DROP VIEW IF EXISTS {view_nice}", fetch=False, dry_run=dry)
        dg.sql(conn, f"DROP VIEW IF EXISTS {view_tech}", fetch=False, dry_run=dry)
        drop_table(conn, item, dry)
        objects = {}
    return {"layer": item["layername"], "status": "ok", "sources": sources, "any_load": msgs, "objects": objects, "columns": columns}


# ------------------------------------------------------------ joins
def component_exists(conn, packvers_id, ftname, dry_run):
    r = dg.sql_one(conn, "SELECT c.id FROM ingest.donated_packcomponent c JOIN ingest.fdw_feature_type f USING (ftid) "
                         "WHERE c.packvers_id=%s AND f.ftname=%s", (packvers_id, ftname), dry_run=dry_run)
    return dry_run or bool(r)


def run_joins(conn, pkg, args, wanted=None):
    """ingest.join(layer, col, file, cad, col, file) por par (chave 'joins' do gerador).
    Com --layer, so os pares que envolvem os layers pedidos (geometrico ou cadastral)."""
    results = []
    for j in pkg.joins():
        if wanted and not ({j["key"], j["cad"].rsplit("_", 1)[0]} & wanted):
            continue
        label = f"{j['layer']} x {j['cad']} ({j['layer_col']} = {j['cad_col']})"
        missing = [n for n, pv in ((j["layer"], j["layer_packvers"]), (j["cad"], j["cad_packvers"]))
                   if not component_exists(conn, pv, n, args.dry_run)]
        if missing:
            results.append({"join": label, "status": "skipped", "detail": f"nao ingerido: {missing}"})
            continue
        LOG.info("==== join %s", label)
        try:
            r = dg.sql_one(conn, "SELECT ingest.join(%s, %s, %s, %s, %s, %s) AS msg",
                           (j["layer"], j["layer_col"], j["layer_file"], j["cad"], j["cad_col"], j["cad_file"]), dry_run=args.dry_run)
            results.append({"join": label, "status": "ok", "detail": (r or {}).get("msg", "")})
        except Exception as e:  # noqa: BLE001
            LOG.exception("join %s falhou", label)
            results.append({"join": label, "status": "error", "detail": str(e)[:800]})
    return results


# ------------------------------------------------------------ main
def layer_line(r):
    o = r.get("objects") or {}
    objs = ", ".join(f"{k}={v}" for k, v in o.items() if v)
    line = f"- {r['layer']}: {r['status']} {r.get('detail', '')}"
    if objs:
        line += f"\n    analise: {objs}"
    if r.get("columns"):
        line += f"\n    colunas: {', '.join(r['columns'][:40])}"
    if r.get("retry"):
        line += f"\n    retry: {r['retry']}"
    return line


def main():
    ap = dg.common_args(argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter))
    ap.add_argument("--stage", choices=["load", "all"], default="all",
                    help="load: so carrega tabela bruta e cria views (sem any_load), para o analista testar")
    ap.add_argument("--no-join", dest="join", action="store_false", help="nao executar ingest.join dos pares layer_ext + cad*_cmpl")
    ap.add_argument("--no-reset", dest="reset", action="store_false", help="nao remover componente anterior do layer")
    ap.add_argument("--drop-tables", action="store_true", help="apagar tabela bruta e views no fim (default: manter para analise)")
    ap.add_argument("--clean-sandbox", action="store_true", help="apagar o sandbox no fim (default: manter)")
    args = ap.parse_args()
    dg.setup_logging(args.verbose)
    dg.apply_args(args)

    conn = dg.connect(args.pg_db)
    conn_dl = dg.connect(args.pg_datalake)
    pkg = dg.Package(args.pack_dir, conn, conn_dl)
    LOG.info("pacote: %s | sandbox %s | banco %s", pkg, pkg.sandbox, args.pg_db)
    if pkg.conf.get("openstreetmap") or pkg.prep.get("openstreetmap"):
        LOG.warning("pacote tem bloco 'openstreetmap' (osm2pgsql): nao tratado por este script")
    wanted = {l for l in (args.layers or "").split(",") if l}
    unknown = wanted - set(pkg.layers)
    if unknown:
        sys.exit(f"layer(s) {sorted(unknown)} nao existem no make_conf.yaml; disponiveis: {sorted(pkg.layers)}")

    results, failed = [], []
    for item in pkg.layer_items():
        if wanted and item["name"] not in wanted:
            continue
        try:
            results.append(ingest_layer(conn, pkg, item, args))
        except Exception as e:  # noqa: BLE001
            LOG.exception("layer %s falhou", item["name"])
            results.append({"layer": item["layername"], "status": "error", "detail": str(e)[:1500],
                            "objects": {"table": item["tabname"], "view_analista": friendly_view(pkg, item)},
                            "retry": f"python01_ingest.py {pkg.dir} --pg-db {args.pg_db} --layer {item['name']}"})
            failed.append(item["name"])

    joins = run_joins(conn, pkg, args, wanted) if (args.join and args.stage == "all") else []
    failed += [r["join"] for r in joins if r["status"] == "error"]

    if args.clean_sandbox and not args.dry_run and pkg.sandbox.exists():
        shutil.rmtree(pkg.sandbox, ignore_errors=True)

    rows = [] if args.dry_run else dg.report_rows(conn, pack_id=pkg.pack_id)
    cols = ["ftname", "file_id", "proc_step", "n_original", "n_feature_asis", "n_discarded", "pct_discarded",
            "duplicate", "nointersects", "invalid", "size", "size_unit", "bbox_km2"]
    status = "FALHOU" if failed else "OK"
    text = (
        f"python01_ingest {status} | {pkg} | banco {args.pg_db}\n"
        f"pasta: {pkg.dir}\n\n"
        + "\n".join(layer_line(r) for r in results)
        + ("\n\nJoins:\n" + "\n".join(f"- {r['join']}: {r['status']} {r.get('detail', '')}" for r in joins) if joins else "")
        + "\n\nValidacao (ingest.vw06ingest_report):\n" + dg.fmt_table(rows, cols)
        + f"\n\nSandbox mantido em {pkg.sandbox}. Objetos de analise ficam no banco {args.pg_db} ate a proxima execucao (ou --drop-tables)."
        + ("\n\nCorrija make_conf.yaml e reexecute o layer (ver 'retry' acima).\n" if failed
           else "\n\nTeste as views do analista e, se o sql_view estiver correto, rode novamente sem --stage load.\n" if args.stage == "load"
           else "\n\nProximo passo: revisar e, se aprovado, rodar python02_publish.py na mesma pasta.\n")
    )
    dg.finish("python01_ingest_" + pkg.isolabel_ext, f"[preserv] ingestao {status}: {pkg.isolabel_ext} _pk{pkg.pack_number}",
              text, {"package": str(pkg), "pg_db": args.pg_db, "results": results, "joins": joins, "report": rows}, args)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
