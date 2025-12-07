# OSM Boundaries Ingest

Sistema moderno para importação de limites administrativos (boundaries) do OpenStreetMap para PostgreSQL/PostGIS usando `osm2pgsql` com flex output.

## Pré-requisitos

- PostgreSQL com extensão PostGIS
- osm2pgsql >= 1.3.0 (com suporte a flex output)
- Arquivo .osm.pbf (dados do OpenStreetMap)

## Uso Rápido

```bash
./modern_osm_ingest.sh [DB_NAME] [DB_USER] [DB_HOST] [PBF_FILE] [LUA_CONFIG]
```

### Exemplo

```bash
./modern_osm_ingest.sh ingest1 postgres localhost brazil-latest.osm.pbf boundaries_only.lua

#./modern_osm_ingest.sh ingest1 postgres localhost brazil-latest.osm.pbf boundaries_maritime_only.lua # Para zona contígua e econômica exclusiva
```

## Parâmetros

| Parâmetro | Descrição | Padrão |
|-----------|-----------|--------|
| `DB_NAME` | Nome do banco de dados | `ingest1` |
| `DB_USER` | Usuário PostgreSQL | `postgres` |
| `DB_HOST` | Host do banco | `localhost` |
| `PBF_FILE` | Arquivo OSM em formato PBF | - |
| `LUA_CONFIG` | Arquivo de configuração Lua | - |

### Variáveis de Ambiente

```bash
NUM_PROCESSES=8 ./modern_osm_ingest.sh ...
```

- `NUM_PROCESSES`: Número de processos paralelos

## Estrutura da Tabela

A tabela `jplanet_osm_boundaries` criada contém:

- `osm_id`: ID da relation no OSM
- `admin_level`: Nível administrativo (1-10)
- `name`: Nome do limite administrativo
- `tags`: Todas as tags em formato JSONB
- `geom`: Geometria multipolygon (SRID 4326)

Índices criados automaticamente em `tags` (GIN) e `geom` (GiST).

## O que é importado

- **Apenas relations** do tipo `boundary=administrative`
- Níveis administrativos de 1 a 10
- Geometrias válidas em formato multipolygon

## Notas

- O script valida todas as dependências antes de iniciar
- Usa processamento paralelo para melhor performance
- Tags desnecessárias (`created_by`, `source`) são removidas automaticamente
- Geometrias inválidas são ignoradas com warning no log

## Consultas Úteis

```sql
-- Listar todos os estados (admin_level 4 no Brasil)
SELECT name, admin_level FROM jplanet_osm_boundaries 
WHERE admin_level = 4 ORDER BY name;

-- Buscar por tag específica
SELECT name FROM jplanet_osm_boundaries 
WHERE tags->>'ISO3166-2' = 'BR-RS';

-- Contar boundaries por nível
SELECT admin_level, COUNT(*) FROM jplanet_osm_boundaries 
GROUP BY admin_level ORDER BY admin_level;
```

## Troubleshooting

**Erro de conexão com banco**: Verifique se o PostgreSQL está rodando e as credenciais estão corretas

**PostGIS não encontrado**: Execute `CREATE EXTENSION postgis;` no banco

**Geometrias NULL**: Algumas relations OSM têm geometrias incompletas - isso é normal e elas são ignoradas

## Arquivos

- `modern_osm_ingest.sh`: Script principal de importação
- `boundaries_only.lua`: Configuração osm2pgsql para boundaries
