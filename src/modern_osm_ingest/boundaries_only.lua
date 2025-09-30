-- boundaries_only.lua
-- Configurações osm2pgsql APENAS para boundaries

-- CRÍTICO: Habilita geometrias de ways para relations
osm2pgsql.stage1_ways_are_used = true

-- Configurações
local CONFIG = {
    min_admin_level = 1,
    max_admin_level = 10,
    table_name = 'jplanet_osm_boundaries',
    srid = 4326
}

-- Tabela para boundaries
local boundaries_table = osm2pgsql.define_table{
    name = CONFIG.table_name,
    ids = { type = 'relation', id_column = 'osm_id' },
    columns = {
        { column = 'admin_level', type = 'integer' },
        { column = 'name', type = 'text' },
        { column = 'tags', type = 'jsonb' },
        { column = 'geom', type = 'multipolygon', projection = CONFIG.srid},
    },
    indexes = {
        { column = 'name', method = 'btree' },
        { column = 'tags', method = 'gin' },
        { column = 'geom', method = 'gist' },
    }
}

-- Função para limpar e filtrar tags
function clean_all_tags(tags)
    local clean = {}

    local skip_tags = {
        ['created_by'] = true,
        ['source'] = true,
    }

    for k, v in pairs(tags) do
        if not skip_tags[k] and v ~= nil then
            clean[k] = v
        end
    end

    return clean
end

-- Processa nodes (não faz nada, mas precisa estar definido)
function osm2pgsql.process_node(object)
end

-- Processa ways (não faz nada, mas precisa estar definido)
function osm2pgsql.process_way(object)
end

-- Seleciona members de relations que queremos processar
function osm2pgsql.select_relation_members(relation)
    if relation.tags.boundary == 'administrative' then
        return { ways = osm2pgsql.way_member_geoms }
    end
end

-- Processa relations (boundaries administrative)
function osm2pgsql.process_relation(object)
    local tags = object.tags

    if not (tags.boundary == 'administrative') then
        return
    end

    -- Só processa níveis administrativos relevantes
    local admin_level = tonumber(tags.admin_level)
    if not admin_level or admin_level < CONFIG.min_admin_level or admin_level > CONFIG.max_admin_level then
        return
    end

    -- Tenta criar a geometria (SEM is_valid)
    local geom = object:as_multipolygon()
    if not geom then
--     if not geom or not geom:is_valid() then
        print(string.format("WARNING: Geometria NULL para relation %d (%s)", object.id, tags.name or "sem nome"))
        return
    end

    -- Limpa as tags
    local clean_tags = clean_all_tags(tags)

    -- Extrai nome
    local name = tags.name or tags.official_name

    -- Insere na tabela
    boundaries_table:insert({
        osm_id = object.id,
        admin_level = admin_level,
        name = name,
        tags = clean_tags,
        geom = geom
    })
end

-- Mensagem de inicialização
print(string.format("Configuração carregada: %s (admin_level %d-%d)",
    CONFIG.table_name, CONFIG.min_admin_level, CONFIG.max_admin_level))
