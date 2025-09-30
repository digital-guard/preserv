#!/bin/bash
# https://osm2pgsql.org/doc/manual.html

set -e  # Para na primeira falha

# ==================== CONFIGURAÇÕES ====================
DB_NAME=${1:-}
DB_USER=${2:-}
DB_HOST=${3:-}
PBF_FILE=${4:-}
LUA_CONFIG=${5:-}
NUM_PROCESSES=${NUM_PROCESSES:-$(nproc 2>/dev/null)} # Auto-detecta CPUs

# ==================== SISTEMA DE CORES E LOGGING ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

section() {
    echo ""
    echo -e "${PURPLE}=== $1 ===${NC}"
}

show_help() {
cat << EOF
    ${CYAN}modern_osm_ingest.sh - Importador OSM Modernizado${NC}

    Uso: $0 [DB_NAME] [DB_USER] [DB_HOST] [PBF_FILE] [LUA_CONFIG]

    Parâmetros:
      DB_NAME     - Nome do banco de dados
      DB_USER     - Usuário do PostgreSQL
      DB_HOST     - Host do banco
      PBF_FILE    - Arquivo .osm.pbf para importar
      LUA_CONFIG  - Arquivo de config Lua

    Variáveis de ambiente opcionais:
      NUM_PROCESSES  - Processos paralelos

    Exemplo:
      $0 ingest1 postgres localhost /tmp/brazil.osm.pbf boundaries_only.lua

EOF
}

check_dependencies() {
    # Verifica comandos: osm2pgsql e psql
    for cmd in osm2pgsql psql; do
        command -v "$cmd" >/dev/null 2>&1 || error "$cmd não encontrado."
    done

    # Verifica versão do osm2pgsql
    OSM2PGSQL_VERSION=$(osm2pgsql --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    info "osm2pgsql versão: $OSM2PGSQL_VERSION"

    # Verifica suporte a flex output
    osm2pgsql --help | grep -q flex && success "Flex output suportado" || error "osm2pgsql sem suporte a flex. Use versão >= 1.3.0"

    # Conexão com banco
    CONN="postgres://${DB_USER}@${DB_HOST}/${DB_NAME}"
    psql "$CONN" -c "SELECT 1;" >/dev/null 2>&1 && success "Conexão com o database ${DB_NAME}@${DB_HOST} OK" || error "Falha na conexão com o banco: $CONN"

    # Verifica PostGIS
    psql "$CONN" -t -c "SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis');" 2>/dev/null | grep -q t \
        && success "PostGIS instalado." || error "PostGIS não instalado. Execute: CREATE EXTENSION postgis;"

    # Verifica arquivos
    [[ -f "$LUA_CONFIG" ]] && info "Encontrado arquivo de configuração: $LUA_CONFIG" || error "Arquivo Lua não encontrado: $LUA_CONFIG"
    [[ -f "$PBF_FILE" ]]   && info "Encontrado arquivo PBF: $(basename "$PBF_FILE")" || error "Arquivo PBF não encontrado: $PBF_FILE"
}

run_osm2pgsql() {
    local OSM2PGSQL_PARAMS=(
        --create
        --database "$DB_NAME"
        --user "$DB_USER"
        --host "$DB_HOST"
        --output flex               # Usa flex output
        --style "$LUA_CONFIG"       # Arquivo de configuração Lua
        --number-processes "$NUM_PROCESSES"  # Número de processos paralelos
        --verbose                   # Output verboso
    )

    info "Processos: $NUM_PROCESSES"
    log "Iniciando importação OSM com Flex Output..."
    log "Comando executado: osm2pgsql ${OSM2PGSQL_PARAMS[*]} $PBF_FILE"

    osm2pgsql "${OSM2PGSQL_PARAMS[@]}" "$PBF_FILE" || error "Falha na importação osm2pgsql"
}

main() {
    local script_start=$(date +%s)

    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    INGESTÃO OSM MODERNIZADA                          ║"
    echo "║                     osm2pgsql Flex Output                            ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_dependencies
    run_osm2pgsql

    local script_end=$(date +%s)
    local total_duration=$((script_end - script_start))
    local total_min=$((total_duration / 60))
    local total_sec=$((total_duration % 60))

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    IMPORTAÇÃO CONCLUÍDA!                             ║${NC}"
    echo -e "${GREEN}║                                                                      ║${NC}"
    printf  "${GREEN}║  %-68s║${NC}\n" "Tempo total: ${total_min}m ${total_sec}s"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Captura Ctrl+C e outros sinais para limpeza
trap 'error "Processo interrompido pelo usuário"; exit 1' INT TERM

# Verifica se foi pedida ajuda
if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    show_help
    exit 0
fi

# Executa função principal com todos os argumentos
main "$@"
