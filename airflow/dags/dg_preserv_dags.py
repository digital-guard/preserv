"""
DAGs Airflow do Projeto Digital Preservation (digital-guard/preserv).

O Airflow roda em OUTRA maquina e executa os scripts no pk21 por SSH (SSHOperator,
provider apache-airflow-providers-ssh). Quatro DAGs disparadas manualmente, uma por
etapa; o disparo da etapa seguinte e o gate humano, depois de ler o e-mail da anterior.

  dg_01_ingest   -> python01_ingest.py   (yaml -> ingest<NN>)
  dg_02_publish  -> python02_publish.py  (ingest<NN> -> preservCutGeo-<PAIS>2021)
  dg_03_promote  -> python03_promote.py  (ingest<NN> -> datalake, fila de aprovacao, README/reproducibility)
  dg_04_clean    -> python04_clean.py    (tabelas/views de analise, sandbox)

Conexao: Airflow Connection do tipo SSH com id `pk21` (Variable dg_ssh_conn_id para trocar),
host pk21, login carlos, chave privada sem senha (a mesma que `ssh carlos@pk21` usa).

Variables opcionais: dg_ssh_conn_id (pk21), dg_preserv_airflow (/var/gits/_dg/preserv/airflow),
dg_pg_uri (postgres://postgres@localhost), dg_mail_to, dg_python (python3).

Parametros (Trigger DAG w/ config): pack_dir, pg_db (obrigatorio), pg_uri, layers, mail_to;
dg_02: git_commit, filtered, out_root; dg_03: pg_datalake, approve, regenerate, insert_size,
insert_license, git_commit; dg_04: all.

Os scripts enviam o e-mail de resultado (DG_MAIL_TO); o Airflow envia o de falha
(on_failure_callback, SMTP do airflow.cfg).
"""
from datetime import datetime, timedelta

from airflow import DAG
from airflow.models import Variable
from airflow.models.param import Param
from airflow.providers.ssh.operators.ssh import SSHOperator
from airflow.utils.email import send_email

SSH_CONN = Variable.get("dg_ssh_conn_id", default_var="pk21")
PRESERV_AIRFLOW = Variable.get("dg_preserv_airflow", default_var="/var/gits/_dg/preserv/airflow")
PG_URI = Variable.get("dg_pg_uri", default_var="postgres://postgres@localhost")
MAIL_TO = Variable.get("dg_mail_to", default_var="")
PYTHON = Variable.get("dg_python", default_var="python3")


def on_failure(context):
    ti = context["task_instance"]
    to = context["params"].get("mail_to") or MAIL_TO
    if not to:
        return
    send_email(
        to=to,
        subject=f"[preserv] FALHA {ti.dag_id}.{ti.task_id} - {context['params'].get('pack_dir')}",
        html_content=f"<pre>{context.get('exception')}</pre><p>Log: {ti.log_url}</p>",
    )


COMMON_PARAMS = {
    "pack_dir": Param("/var/gits/_dg/preserv-BR/data/RS/PortoAlegre/_pk0018.01", type="string"),
    "pg_db": Param(type="string", minLength=1, description="banco de ingestao, ex. ingest20"),
    "pg_uri": Param(PG_URI, type="string"),
    "layers": Param("", type="string"),
    "mail_to": Param(MAIL_TO, type="string"),
}
DEFAULT_ARGS = {"owner": "preserv", "retries": 0, "on_failure_callback": on_failure}
DAG_KW = dict(start_date=datetime(2026, 1, 1), schedule=None, catchup=False, default_args=DEFAULT_ARGS)


def remote(script, extra=""):
    """Linha executada no pk21 via SSH; variaveis de ambiente DG_* inline, sem depender do shell remoto."""
    return (
        "export DG_MAIL_TO='{{ params.mail_to }}' DG_PG_URI='{{ params.pg_uri }}'; "
        f"cd {PRESERV_AIRFLOW} && {PYTHON} {script} "
        "'{{ params.pack_dir }}' --pg-db '{{ params.pg_db }}' --pg-uri '{{ params.pg_uri }}' "
        "{% if params.layers %}--layers '{{ params.layers }}'{% endif %} "
        + extra
    )


def ssh_task(task_id, command):
    return SSHOperator(task_id=task_id, ssh_conn_id=SSH_CONN, command=command,
                       cmd_timeout=6 * 3600, get_pty=False, do_xcom_push=False)


with DAG(dag_id="dg_01_ingest", description="make_conf.yaml -> ingestao (python01_ingest.py no pk21)",
         params={**COMMON_PARAMS, "stage": Param("all", enum=["all", "load"])},
         tags=["preserv", "ingest"], **DAG_KW):
    ssh_task("ingest", remote("python01_ingest.py", "--stage '{{ params.stage }}'"))

with DAG(dag_id="dg_02_publish", description="publicar geojsons no CutGeo (python02_publish.py no pk21)",
         params={**COMMON_PARAMS, "git_commit": Param(False, type="boolean"), "filtered": Param(False, type="boolean"),
                 "out_root": Param("", type="string", description="raiz alternativa (teste), ex. /tmp/pg_io/cutgeo_test")},
         tags=["preserv", "publish"], **DAG_KW):
    ssh_task("publish", remote("python02_publish.py",
                               "{% if params.git_commit %}--git-commit {% endif %}"
                               "{% if params.filtered %}--filtered {% endif %}"
                               "{% if params.out_root %}--out-root '{{ params.out_root }}'{% endif %}"))

with DAG(dag_id="dg_03_promote", description="fila de aprovacao no datalake e artefatos (python03_promote.py no pk21)",
         params={**COMMON_PARAMS, "pg_datalake": Param("dl05s_main", type="string"),
                 "approve": Param(False, type="boolean"), "regenerate": Param(True, type="boolean"),
                 "insert_size": Param(False, type="boolean"), "insert_license": Param(False, type="boolean"),
                 "git_commit": Param(False, type="boolean")},
         tags=["preserv", "promote"], **DAG_KW):
    ssh_task("promote", remote("python03_promote.py",
                               "--pg-datalake '{{ params.pg_datalake }}' "
                               "{% if params.approve %}--approve {% endif %}"
                               "{% if params.regenerate %}--regenerate {% endif %}"
                               "{% if params.insert_size %}--insert-size {% endif %}"
                               "{% if params.insert_license %}--insert-license {% endif %}"
                               "{% if params.git_commit %}--git-commit{% endif %}"))

with DAG(dag_id="dg_04_clean", description="limpeza de tabelas/views de analise e sandbox (python04_clean.py no pk21)",
         params={**COMMON_PARAMS, "all": Param(False, type="boolean")},
         tags=["preserv", "clean"], **DAG_KW):
    ssh_task("clean", remote("python04_clean.py", "{% if params.all %}--all{% endif %}"))
