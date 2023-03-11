CREATE or replace FUNCTION optim.jsonb_mustache_prepare(
  dict jsonb,  -- input
  p_type text DEFAULT 'make_conf'
) RETURNS jsonb  AS $f$
DECLARE
 packvers_id bigint;
 key text;
 method text;
 sql_select text;
 sql_view text;
 bt jsonb := 'true'::jsonb;
 bf jsonb := 'false'::jsonb;
 codec_value text[];
 orig_filename_ext text[]; 
 orig_filename_string text;
 multiple_files jsonb; 
 codec_desc_global jsonb;
 housenumber_system text;

 codec_desc0 jsonb DEFAULT NULL;
 codec_desc_default0 jsonb DEFAULT NULL;
 codec_desc_sobre0 jsonb DEFAULT NULL;
 codec_extension0 text DEFAULT NULL;
 codec_descr_mime0 jsonb DEFAULT NULL;

 codec_desc jsonb;
 codec_desc_default jsonb;
 codec_desc_sobre jsonb;
 codec_extension text;
 codec_descr_mime jsonb;
BEGIN
 CASE p_type -- preparing types
 WHEN 'make_conf', NULL THEN

    IF dict?'codec:descr_encode'
    THEN
        codec_desc_global := jsonb_object(regexp_split_to_array ( dict->>'codec:descr_encode','(;|=)'));

        -- Compatibilidade com sql_view de BR-MG-BeloHorizonte/_pk0008.01
        dict := dict || codec_desc_global;

        RAISE NOTICE 'codec_desc_global : %', codec_desc_global;
    END IF;

    IF dict?'srid_proj'
    THEN
        codec_desc_global := jsonb_build_object('srid', (SELECT 952022 + floor(random()*100)));

        -- Compatibilidade com srid_proj de BR-RS-PortoAlegre/_pk0018.01
        dict := dict || codec_desc_global;

        RAISE NOTICE 'codec_desc_global : %', codec_desc_global;
    END IF;

    IF dict?'openstreetmap'
    THEN
        IF codec_desc_global IS NOT NULL
        THEN
            dict := jsonb_set( dict, array['openstreetmap','file_data'] , to_jsonb(jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.openstreetmap.file)')::jsonpath  )->0->>'file'));
            
            dict := jsonb_set( dict, array['openstreetmap'], (dict->>'openstreetmap')::jsonb || codec_desc_global::jsonb );
        END IF;
    END IF;

    IF dict?'to-do'
    THEN
        dict := jsonb_set( dict, array['has_to-do'], bt);
    END IF;

    IF dict?'license_evidences'
    THEN
      IF dict->'license_evidences'?'file'
      THEN
          dict := jsonb_set( dict, array['license_evidences','file_7'], to_jsonb( substring(dict->'license_evidences'->>'file', '^([0-9a-f]{7}).+$') ) );
          dict := jsonb_set( dict, array['license_evidences','file_7_ext'], to_jsonb( substring(dict->'license_evidences'->>'file', '^([0-9a-f]{7}).+$') || '...' || substring(dict->'license_evidences'->>'file', '^.+\.([a-z0-9]+)$') ) );
      END IF;

      IF dict->'license_evidences'?'uri_evidency'
      THEN
        IF EXISTS (SELECT 1 FROM regexp_matches(dict->'layers'->key->>'codec','^.+\.eml$'))
        THEN
          dict := jsonb_set( dict, array['license_evidences','is_uri_evidency_eml'], bt );
          dict := jsonb_set( dict, array['license_evidences','uri_evidency_7'], to_jsonb( substring(dict->'license_evidences'->>'uri_evidency', '^([0-9a-f]{7}).+$') ) );
          dict := jsonb_set( dict, array['license_evidences','uri_evidency_7_ext'], to_jsonb( substring(dict->'license_evidences'->>'uri_evidency', '^([0-9a-f]{7}).+$') || '...' || substring(dict->'license_evidences'->>'uri_evidency', '^.+\.([a-z0-9]+)$') ) );
        ELSE
          dict := jsonb_set( dict, array['license_evidences','is_uri_evidency_eml'], bf );
        END IF;
      END IF;
    END IF;

    FOREACH key IN ARRAY jsonb_object_keys_asarray(dict->'layers')
    LOOP
        method := dict->'layers'->key->>'method';
        
        RAISE NOTICE 'layer : %, method: %', key, method;

        -- id_profile_params default values
        IF NOT dict->'layers'->key?'id_profile_params'
        THEN
            CASE key
            WHEN 'geoaddress'  THEN dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb(1));
            WHEN 'via'         THEN dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb(5));
            ELSE
                dict := jsonb_set( dict, array['layers',key,'id_profile_params'], to_jsonb(5));
            END CASE;
        END IF;

        -- buffer_type default: 1 small buffer (50 m). 0 no buffer, 2 big buffer (500 m).
        IF NOT dict->'layers'->key?'buffer_type'
        THEN
            dict := jsonb_set( dict, array['layers',key,'buffer_type'], to_jsonb(1));
        END IF;

        codec_desc := codec_desc0;
        codec_desc_default := codec_desc_default0;
        codec_desc_sobre := codec_desc_sobre0;
        codec_extension := codec_extension0;
        codec_descr_mime := codec_descr_mime0;

        dict := jsonb_set( dict, array['layers',key,'isCsv'],        IIF(method='csv2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isOgr'],        IIF(method='ogr2ogr',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isOgrWithShp'], IIF(method='ogrWshp',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isShp'],        IIF(method='shp2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isOsm'],        IIF(method='osm2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isGdb'],        IIF(method='gdb2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isGeojson'],    IIF(method='geojson2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isTxt2sql'],    IIF(method='txt2sql',bt,bf) );
        dict := jsonb_set( dict, array['layers',key,'isGeoaddress'], IIF(key='geoaddress',bt,bf) );

        IF dict->'layers'->key?'standardized_fields'
        THEN
            dict := jsonb_set( dict, array['layers',key,'has_standardized_fields'], bt);
        END IF;

        IF dict->'layers'->key?'other_fields'
        THEN
            dict := jsonb_set( dict, array['layers',key,'has_other_fields'], bt);
        END IF;

        dict := jsonb_set( dict, array['layers',key,'file_data'] , to_jsonb(jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0));

        IF dict->'layers'->key->'file_data'?'size'
        THEN
            dict := jsonb_set( dict, array['layers',key,'file_data','size_mb_round2'], to_jsonb(ROUND(((dict->'layers'->key->'file_data'->'size')::bigint / 1048576.0),0.01)));
            dict := jsonb_set( dict, array['layers',key,'file_data','size_mb_round4'], to_jsonb(ROUND(((dict->'layers'->key->'file_data'->'size')::bigint / 1048576.0),0.0001)));
        END IF;
        
        IF dict?'orig'
        THEN
            dict := jsonb_set( dict, array['layers',key,'file_data','path'] , to_jsonb((dict->>'orig') || '/' || (dict->'layers'->key->'file_data'->>'file') ));
        END IF;

        SELECT id, housenumber_system_type FROM optim.vw01full_packfilevers WHERE hashedfname = dict->'layers'->key->'file_data'->>'file' INTO packvers_id, housenumber_system;

        dict := jsonb_set( dict, array['layers',key,'packvers_id'] , to_jsonb(packvers_id));
        dict := jsonb_set( dict, array['layers',key,'layername_root'] , to_jsonb(key));
        dict := jsonb_set( dict, array['layers',key,'layername'] , to_jsonb(key || '_' || (dict->'layers'->key->>'subtype') ));
        dict := jsonb_set( dict, array['layers',key,'tabname'] , to_jsonb('pk' || packvers_id || '_p' || (dict->'layers'->key->>'file') || '_' || key));
        dict := jsonb_set( dict, array['layers',key,'isolabel_ext'] , to_jsonb((SELECT isolabel_ext FROM optim.vw01full_packfilevers WHERE id=packvers_id)));
        dict := jsonb_set( dict, array['layers',key,'path_cutgeo_server'] , to_jsonb((SELECT path_cutgeo_server || '/' || key FROM optim.vw01full_packfilevers WHERE id=packvers_id)));
        dict := jsonb_set( dict, array['layers',key,'path_cutgeo_git'] , to_jsonb((SELECT path_cutgeo_git || '/' || key FROM optim.vw01full_packfilevers WHERE id=packvers_id)));

        dict := jsonb_set( dict, array['packtpl_id'] , to_jsonb((SELECT packtpl_id FROM optim.vw01full_packfilevers WHERE id=packvers_id)));

        -- dict := jsonb_set( dict, array['layers',key,'full_name_layer'] , to_jsonb((SELECT full_name_layer FROM optim.vw01full_packfilevers_ftype WHERE id=packvers_id AND ftid=(SELECT ftid::int FROM optim.feature_type WHERE ftname=lower(key)) )));

        -- Caso de BR-PR-Araucaria/_pk0061.01
        IF jsonb_typeof(dict->'layers'->key->'orig_filename') = 'array'
        THEN
            SELECT to_jsonb(array_agg(jsonb_build_object(
                    'name_item',n,
                    'sql_select_item',s,
                    'orig_filename_array_first',(to_jsonb(((dict->'layers'->key->'orig_filename'))->0)),
                    'isFirst', iif(row_num=1,'true'::jsonb,'false'::jsonb))))
            FROM (
                SELECT row_number() OVER () AS row_num, t.*
                FROM  unnest(ARRAY(SELECT jsonb_array_elements_text(dict->'layers'->key->'orig_filename')),ARRAY(SELECT jsonb_array_elements(dict->'layers'->key->'sql_select'))) t(n,s)
            ) r
            INTO multiple_files;

            RAISE NOTICE 'multiple_files_array : %', multiple_files;
            dict := jsonb_set( dict, array['layers',key,'multiple_files'], 'true'::jsonb );
            dict := jsonb_set( dict, array['layers',key,'multiple_files_array'], multiple_files );

            SELECT string_agg($$'*$$ || trim(txt::text, $$"$$) || $$*'$$, ' ') FROM jsonb_array_elements(dict->'layers'->key->'orig_filename') AS txt INTO orig_filename_string;
            dict := jsonb_set( dict, array['layers',key,'orig_filename_string_extract'], to_jsonb(orig_filename_string) );

            dict := jsonb_set( dict, array['layers',key,'orig_filename_array_first'], (to_jsonb(((dict->'layers'->key->'orig_filename'))->0)) );

            SELECT $$\( $$ || string_agg($$-iname '*$$ || trim(txt::text, $$"$$) || $$*.shp'$$, ' -o ') || $$ \)$$ FROM jsonb_array_elements(dict->'layers'->key->'orig_filename') AS txt INTO orig_filename_string;
            dict := jsonb_set( dict, array['layers',key,'orig_filename_string_find'], to_jsonb(orig_filename_string) );
        END IF;

        IF dict->'layers'->key?'sql_select'
        THEN
            sql_select :=  replace(dict->'layers'->key->>'sql_select',$$\"$$,E'\u130C9');
            dict := jsonb_set( dict, array['layers',key,'sql_select'], sql_select::jsonb );
        END IF;

        IF dict->'layers'->key?'sql_view'
        THEN
            sql_view := replace(dict->'layers'->key->>'sql_view',$$"$$,E'\u130C9');
            dict := jsonb_set( dict, array['layers',key,'sql_view'], to_jsonb(sql_view) );
        END IF;

        -- obtem codec a partir da extensão do arquivo
        IF jsonb_typeof(dict->'layers'->key->'orig_filename') <> 'array'
        THEN
            orig_filename_ext := regexp_matches(dict->'layers'->key->>'orig_filename','\.(\w+)$');
            
            IF orig_filename_ext IS NOT NULL
            THEN
                SELECT extension, descr_mime, descr_encode FROM optim.codec_type WHERE (array[extension] = orig_filename_ext) INTO codec_extension, codec_descr_mime, codec_desc_default;
                dict := jsonb_set( dict, array['layers',key,'orig_filename_with_extension'], 'true'::jsonb );
                RAISE NOTICE 'orig_filename_ext : %', orig_filename_ext;
                RAISE NOTICE 'codec_desc_default from extension: %', codec_desc_default;
            END IF;
        END IF;

        IF dict->'layers'->key?'codec'
        THEN
            -- 1. Extensão, variação e sobrescrição. Descarta a variação.
            IF EXISTS (SELECT 1 FROM regexp_matches(dict->'layers'->key->>'codec','^(.*)~(.*);(.*)$'))
            THEN
                    SELECT extension, descr_mime, descr_encode FROM optim.codec_type WHERE (extension = lower(split_part(dict->'layers'->key->>'codec', '~', 1)) AND variant = '') INTO codec_extension, codec_descr_mime, codec_desc_default;

                codec_desc_sobre := jsonb_object(regexp_split_to_array (split_part(regexp_replace(dict->'layers'->key->>'codec', ';','~'),'~',3),'(;|=)'));

                RAISE NOTICE '1. codec_desc_default : %', codec_desc_default;
                RAISE NOTICE '1. codec_desc_sobre : %', codec_desc_sobre;
            END IF;

            -- 2. Extensão e sobrescrição, sem variação
            IF EXISTS (SELECT 1 FROM regexp_matches(dict->'layers'->key->>'codec','^([^;~]*);(.*)$'))
            THEN
                SELECT extension, descr_mime, descr_encode FROM optim.codec_type WHERE (extension = lower(split_part(dict->'layers'->key->>'codec', ';', 1)) AND variant = '') INTO codec_extension, codec_descr_mime, codec_desc_default;

                codec_desc_sobre := jsonb_object(regexp_split_to_array (split_part(regexp_replace(dict->'layers'->key->>'codec', ';','~'),'~',2),'(;|=)'));

                RAISE NOTICE '2. codec_desc_default : %', codec_desc_default;
                RAISE NOTICE '2. codec_desc_sobre : %', codec_desc_sobre;
            END IF;

            -- 3. Extensão e variação ou apenas extensão, sem sobrescrição
            IF EXISTS (SELECT 1 FROM regexp_matches(dict->'layers'->key->>'codec','^(.*)~([^;]*)$')) OR EXISTS (SELECT 1 FROM regexp_matches(dict->'layers'->key->>'codec','^([^~;]*)$'))
            THEN
                codec_value := regexp_split_to_array( dict->'layers'->key->>'codec' ,'(~)');

                SELECT extension, descr_mime, descr_encode FROM optim.codec_type WHERE (array[upper(extension), variant] = codec_value AND cardinality(codec_value) = 2) OR (array[upper(extension)] = codec_value AND cardinality(codec_value) = 1 AND variant = '') INTO codec_extension, codec_descr_mime, codec_desc_default;

                RAISE NOTICE '3. codec_desc_default : %', codec_desc_default;
            END IF;

            dict := jsonb_set( dict, array['layers',key,'isXlsx'], IIF(lower(codec_extension) = 'xlsx',bt,bf) );
        END IF;

        -- codec resultante
        -- global sobrescreve default e é sobrescrito por sobre
        IF codec_desc_default IS NOT NULL
        THEN
            codec_desc := codec_desc_default;

            IF codec_desc_global IS NOT NULL
            THEN
                codec_desc := codec_desc || codec_desc_global;

                IF codec_desc_global?'srid'
                THEN
                    dict := jsonb_set( dict, array['layers',key,'insertSrid'], 'true'::jsonb );
                END IF;

            END IF;

            IF codec_desc_sobre IS NOT NULL
            THEN
                codec_desc := codec_desc || codec_desc_sobre;

                IF codec_desc_sobre?'srid'
                THEN
                    dict := jsonb_set( dict, array['layers',key,'insertSrid'], 'false'::jsonb );
                END IF;

            END IF;
        ELSE
            IF codec_desc_global IS NOT NULL
            THEN
                codec_desc := codec_desc_global;

                IF codec_desc_global?'srid'
                THEN
                    dict := jsonb_set( dict, array['layers',key,'insertSrid'], 'true'::jsonb );
                END IF;

            END IF;

            IF codec_desc_sobre IS NOT NULL
            THEN
                codec_desc := codec_desc || codec_desc_sobre;

                IF codec_desc_sobre?'srid'
                THEN
                    dict := jsonb_set( dict, array['layers',key,'insertSrid'], 'false'::jsonb );
                END IF;

            END IF;
        END IF;

        IF codec_desc IS NOT NULL
        THEN
            dict := jsonb_set( dict, array['layers',key], (dict->'layers'->>key)::jsonb || codec_desc::jsonb );
            
            RAISE NOTICE 'codec resultante : %', codec_desc;
        END IF;

        IF codec_extension IS NOT NULL
        THEN
            dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb(codec_extension) );
            RAISE NOTICE 'codec_extension : %', codec_extension;
        ELSE
            CASE method
            WHEN 'csv2sql'  THEN dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb('csv'::text) );
            WHEN 'shp2sql'  THEN dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb('shp'::text) );
            WHEN 'geojson2sql'  THEN dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb('geojson'::text) );
            ELSE
                --  do nothing
            END CASE;
            
            RAISE NOTICE 'codec_extension from method: %', dict->'layers'->key->'extension';
        END IF;
                
        IF codec_descr_mime IS NOT NULL
        THEN
            dict := jsonb_set( dict, array['layers',key], (dict->'layers'->>key)::jsonb || codec_descr_mime::jsonb );
        END IF;

        IF codec_descr_mime?'mime' AND codec_descr_mime->>'mime' = 'application/zip' OR codec_descr_mime->>'mime' = 'application/gzip'
        THEN
            dict := jsonb_set( dict, array['layers',key,'multiple_files'], 'true'::jsonb );
            dict := jsonb_set( dict, array['layers',key,'extension'], to_jsonb((regexp_matches(codec_extension,'(.*)\.\w+$'))[1]) );
        END IF;

        IF key='address' OR key='cadparcel' OR key='cadvia'
        THEN
            dict := jsonb_set( dict, array['layers',key,'isCadLayer'], 'true'::jsonb );
        END IF;

        IF dict->'layers'?key AND dict->'layers'?('cad'||key)
            AND dict->'layers'->key->>'subtype' = 'ext'
            AND dict->'layers'->('cad'||key)->>'subtype' = 'cmpl'
            AND dict->'layers'->key?'join_id' AND dict->'layers'->('cad'||key)?'join_id'
        THEN
            dict := jsonb_set( dict, '{joins}', '{}'::jsonb );
            dict := jsonb_set( dict, array['joins',key] , jsonb_build_object(
                'layer',           key || '_ext'
                ,'cadLayer',        'cad' || key || '_cmpl'
                ,'layerColumn',     dict->'layers'->key->'join_id'
                ,'cadLayerColumn',  dict->'layers'->('cad'||key)->'join_id'
                ,'layerFile',       jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0->>'file'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.cad'|| key ||'.file)')::jsonpath  )->0->>'file'
                -- check by dict @? ('$.files[*].p ? (@ == $.layers.'|| key ||'.file)')
            ));
            dict := jsonb_set( dict, array['layers',key,'join_data'] , jsonb_build_object(
                'cadLayer',        'cad' || key
                ,'cadLayerColumn',  dict->'layers'->('cad'||key)->'join_id'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.cad'|| key ||'.file)')::jsonpath  )->0->>'file'
            ));
            dict := jsonb_set( dict, array['layers','cad'||key,'join_data'] , jsonb_build_object(
                'cadLayer',         key
                ,'cadLayerColumn',  dict->'layers'->key->'join_id'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0->>'file'
            ));
        END IF;

        IF key='geoaddress' AND dict->'layers'?'address'
            AND dict->'layers'->key->>'subtype' = 'ext'
            AND dict->'layers'->'address'->>'subtype' = 'cmpl'
        AND dict->'layers'->key?'join_id'
            AND dict->'layers'->'address'?'join_id'
        THEN
            dict := jsonb_set( dict, '{joins}', '{}'::jsonb );
            dict := jsonb_set( dict, array['joins',key] , jsonb_build_object(
                'layer',           key || '_ext'
                ,'cadLayer',        'address_cmpl'
                ,'layerColumn',     dict->'layers'->key->'join_id'
                ,'cadLayerColumn',  dict->'layers'->'address'->'join_id'
                ,'layerFile',       jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0->>'file'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.address.file)')::jsonpath  )->0->>'file'
            ));
            dict := jsonb_set( dict, array['layers',key,'join_data'] , jsonb_build_object(
                'cadLayer',        'address'
                ,'cadLayerColumn',  dict->'layers'->('cad'||key)->'join_id'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.cad'|| key ||'.file)')::jsonpath  )->0->>'file'
            ));
            dict := jsonb_set( dict, array['layers','cad'||key,'join_data'] , jsonb_build_object(
                'cadLayer',         key
                ,'cadLayerColumn',  dict->'layers'->key->'join_id'
                ,'cadLayerFile',    jsonb_path_query_array(  dict, ('$.files[*] ? (@.p == $.layers.'|| key ||'.file)')::jsonpath  )->0->>'file'
            ));
        END IF;
	 END LOOP;

    IF housenumber_system IS NOT NULL
    THEN
        dict := jsonb_set( dict, array['housenumber_system_type'], to_jsonb(housenumber_system) );
    END IF;

	 IF jsonb_array_length(to_jsonb(jsonb_object_keys_asarray(dict->'joins'))) > 0
	 THEN
        dict := dict || jsonb_build_object( 'joins_keys', jsonb_object_keys_asarray(dict->'joins') );
	 END IF;

	 dict := dict || jsonb_build_object( 'layers_keys', jsonb_object_keys_asarray(dict->'layers') );
	 dict := jsonb_set( dict, array['pkversion'], to_jsonb(to_char((dict->>'pkversion')::int,'fm000')) );
	 dict := jsonb_set( dict, '{files,-1,last}','true'::jsonb);

	 dict := jsonb_set( dict, array['data_packtpl'] , to_jsonb((SELECT (jsonb_agg(t))[0] FROM (SELECT * FROM optim.vw01full_donated_PackTpl WHERE packtpl_id=((dict->>'packtpl_id')::bigint)) t)));
 -- CASE ELSE ...?
 END CASE;
 RETURN dict;
END;
$f$ language PLpgSQL;
-- SELECT optim.jsonb_mustache_prepare( yamlfile_to_jsonb('/var/gits/_dg/preserv-BR/data/ES/CachoeiroItapemirim/_pk0091.01/make_conf.yaml') );
-- SELECT optim.jsonb_mustache_prepare( yamlfile_to_jsonb('/var/gits/_dg/preserv-PE/data/CUS/Cusco/_pk0001.01/make_conf.yaml') ); 
-- SELECT optim.jsonb_mustache_prepare( yamlfile_to_jsonb('/var/gits/_dg/preserv-BR/data/SP/SaoPaulo/_pk0033.01/make_conf.yaml') );
-- SELECT optim.jsonb_mustache_prepare( yamlfile_to_jsonb('/var/gits/_dg/preserv-BR/data/DF/Brasilia/_pk0068.01/make_conf.yaml') );

CREATE or replace FUNCTION optim.generate_commands(
    jurisd  text,
    p_path_pack text,
    p_path  text DEFAULT '/var/gits/_dg'  -- git path
) RETURNS text AS $f$
    DECLARE
        q_query text;
        p_yaml jsonb;
        mkme_srcTpl text;
        output_file text;
    BEGIN

    SELECT yaml_to_jsonb(pg_read_file(p_path_pack ||'/make_conf.yaml' )) ||
           yamlfile_to_jsonb(p_path || '/preserv' || CASE WHEN jurisd ='INT' THEN '' ELSE '-' || upper(jurisd) END || '/src/maketemplates/commomFirst.yaml')
    INTO p_yaml;

    SELECT pg_read_file(p_path || '/preserv/src/maketemplates/reproducibility/make_' || lower(p_yaml->>'schemaId_template') || '.mustache.mk')
    INTO mkme_srcTpl;

    SELECT replace(jsonb_mustache_render(mkme_srcTpl, optim.jsonb_mustache_prepare(p_yaml),p_path ||'/preserv/src/maketemplates/reproducibility/'),E'\u130C9',$$\"$$)
    INTO q_query;

    RETURN q_query;

    END;
$f$ LANGUAGE PLpgSQL;
-- SELECT optim.generate_commands('BR','/var/gits/_dg/preserv-BR/data/RJ/Niteroi/_pk0016.01','/var/gits/_dg');

CREATE or replace VIEW optim.reproducibility AS
    SELECT pt.*, optim.generate_commands(split_part(pt.isolabel_ext,'-',1), path_preserv_server, '/var/gits/_dg') AS commands
    FROM optim.vw01full_donated_PackTpl pt
    WHERE path_preserv_server <> '/var/gits/_dg/preserv-BR/data/PR/Curitiba/_pk0002.01'
    ORDER BY packtpl_id
;

CREATE or replace FUNCTION optim.generate_makefile(
    jurisd  text,
    pack_id text,
    p_output text,
    p_path_pack text,
    p_path  text DEFAULT '/var/gits/_dg'  -- git path
) RETURNS text AS $f$
    DECLARE
        q_query text;
        p_yaml jsonb;
        mkme_tpl text;
    BEGIN

    SELECT yaml_to_jsonb(pg_read_file(p_path_pack ||'/make_conf.yaml' )) ||
           yamlfile_to_jsonb(p_path || '/preserv' || CASE WHEN jurisd ='INT' THEN '' ELSE '-' || upper(jurisd) END || '/src/maketemplates/commomFirst.yaml')
    INTO p_yaml;

    SELECT pg_read_file(p_path || '/preserv/src/maketemplates/make_' || lower(p_yaml->>'schemaId_template') || '.mustache.mk') ||
           pg_read_file(p_path || '/preserv/src/maketemplates/commomLast.mustache.mk')
    INTO mkme_tpl;

    SELECT replace(jsonb_mustache_render(mkme_tpl, optim.jsonb_mustache_prepare(p_yaml)),E'\u130C9',$$\"$$) INTO q_query; -- "

    SELECT volat_file_write(p_output,q_query) INTO q_query;

    RETURN q_query;
    END;
$f$ LANGUAGE PLpgSQL;
-- SELECT optim.generate_makefile('BR','21.1','/tmp/pg_io/testemakefile','/var/gits/_dg/preserv-BR/data/SP/Atibaia/_pk0021.01','/var/gits/_dg');

CREATE or replace FUNCTION optim.generate_reproducibility(
    jurisd  text,
    pack_id text,
    p_output text,
    p_path_pack text,
    p_path  text DEFAULT '/var/gits/_dg'  -- git path
) RETURNS text AS $f$
    DECLARE
        q_query text;
        p_yaml jsonb;
    BEGIN

    SELECT yaml_to_jsonb(pg_read_file(p_path_pack ||'/make_conf.yaml' )) ||
           yamlfile_to_jsonb(p_path || '/preserv' || CASE WHEN jurisd ='INT' THEN '' ELSE '-' || upper(jurisd) END || '/src/maketemplates/commomFirst.yaml')
    INTO p_yaml;

    SELECT commands FROM optim.reproducibility WHERE packtpl_id= (p_yaml->>'packtpl_id')::bigint INTO q_query;

    SELECT volat_file_write(p_output,q_query) INTO q_query;

    RETURN q_query;
    END;
$f$ LANGUAGE PLpgSQL;
-- SELECT optim.generate_reproducibility('BR','21.1','/tmp/pg_io/reproducibility.sh','/var/gits/_dg/preserv-BR/data/SP/Atibaia/_pk0021.01','/var/gits/_dg');

CREATE or replace FUNCTION optim.generate_readme(
    jurisd  text,
    pack_id text,
    p_output text,
    p_path_pack text,
    p_path  text DEFAULT '/var/gits/_dg'  -- git path
) RETURNS text AS $f$
    DECLARE
        q_query text;
        conf_yaml jsonb;
        p_yaml jsonb;
        readme text;
        reproducibility text;
    BEGIN

    SELECT optim.jsonb_mustache_prepare(
           yaml_to_jsonb(pg_read_file(p_path_pack ||'/make_conf.yaml' )) ||
           yamlfile_to_jsonb(p_path || '/preserv' || CASE WHEN jurisd ='INT' THEN '' ELSE '-' || upper(jurisd) END || '/src/maketemplates/commomFirst.yaml')
    ) INTO p_yaml;

    SELECT commands FROM optim.reproducibility WHERE packtpl_id= (p_yaml->>'packtpl_id')::bigint INTO reproducibility;

    SELECT p_yaml || jsonb_build_object('layers',list) || jsonb_build_object('data_packcsv',s.csv[0]) || jsonb_build_object( 'reproducibility', to_jsonb(reproducibility) )
    FROM
    (
      SELECT jsonb_agg(g) AS list
      FROM
      (
        SELECT t.value || jsonb_build_object('publication_data',COALESCE(u.l,'{}'::jsonb)) AS value
        FROM jsonb_each(p_yaml->'layers') t(key,value)
        LEFT JOIN
        (
          SELECT jsonb_array_elements(page->'layers') AS l
          FROM optim.vw03publication
          WHERE pack_number = ('_pk' || (p_yaml->'data_packtpl'->>'pack_number')::text) AND  isolabel_ext = p_yaml->'data_packtpl'->>'isolabel_ext'
        ) u
        ON u.l->'class_ftname' = t.value->'layername_root'
      ) g
    ) r,
    LATERAL
    (
      SELECT jsonb_agg(to_jsonb(t.*)) AS csv
      FROM api.donatedpacks_donor t
      WHERE t.pack_id = (p_yaml->'data_packtpl'->>'pack_number_donatedpackcsv')::int
    ) s
    INTO conf_yaml;

    RAISE NOTICE 'conf: %', conf_yaml;

    SELECT pg_read_file(p_path || '/preserv/src/maketemplates/readme_' || CASE WHEN jurisd ='BR' THEN 'ptbr' ELSE 'es' END || '.mustache') INTO readme;

    SELECT jsonb_mustache_render(readme, conf_yaml) ||
           (CASE WHEN file_exists(p_yaml->'data_packtpl'->>'path_preserv_server' ||'/attachment.md') THEN pg_read_file(p_yaml->'data_packtpl'->>'path_preserv_server' ||'/attachment.md') ELSE '' END)
    INTO q_query;

    SELECT volat_file_write(p_output,regexp_replace(q_query, '(\n\n\n)\n*', E'\n\n', 'g')) INTO q_query;

    RETURN q_query;
    END;
$f$ LANGUAGE PLpgSQL;
-- SELECT optim.generate_readme('BR','21.1','/tmp/pg_io/testereadme','/var/gits/_dg/preserv-BR/data/SP/Atibaia/_pk0021.01','/var/gits/_dg');

CREATE or replace FUNCTION optim.insert_bytesize(
  dict   jsonb,  -- input
  p_orig text DEFAULT '/tmp' --folder with file
) RETURNS jsonb  AS $f$
DECLARE
 a text;
 sz bigint;
BEGIN
    FOR i in 0..(select jsonb_array_length(dict->'files')-1)
    LOOP
        a := format($$ {files,%s,file} $$, i )::text[];

        SELECT size::bigint FROM pg_stat_file(concat(p_orig,'/',dict#>>a::text[])) INTO sz;

        a := format($$ {files,%s,size} $$, i );
        dict := jsonb_set( dict, a::text[],to_jsonb(sz));
    END LOOP;
 RETURN dict;
END;
$f$ language PLpgSQL;
--SELECT optim.insert_bytesize( yamlfile_to_jsonb('/var/gits/_dg/preserv-BR/data/RS/SantaMaria/_pk0019.01/make_conf.yaml') );

CREATE or replace FUNCTION optim.generate_make_conf_with_size(
    jurisd      text,
    pack_id     text,
    p_output    text,
    p_path_pack text,
    p_path      text DEFAULT '/var/gits/_dg', -- git path
    p_orig      text DEFAULT '/tmp'
) RETURNS text AS $f$
    DECLARE
        q_query     text;
        conf_yaml   jsonb;
        conf_yaml_t text;
    BEGIN

    SELECT pg_read_file(p_path_pack ||'/make_conf.yaml') INTO conf_yaml_t;
    SELECT yaml_to_jsonb(conf_yaml_t) ||
           yamlfile_to_jsonb(p_path || '/preserv' || CASE WHEN jurisd ='INT' THEN '' ELSE '-' || upper(jurisd) END || '/src/maketemplates/commomFirst.yaml')
    INTO conf_yaml;

    --SELECT jsonb_to_yaml(optim.insert_bytesize(conf_yaml)::text) INTO q_query;
    SELECT regexp_replace( conf_yaml_t , '\n*files: *(\n *\-[^\n]*|\n[\t ]+[^\n]+)+\n*', E'\n\n' || jsonb_to_yaml((jsonb_build_object('files',optim.insert_bytesize(conf_yaml,p_orig)->'files'))::text) || E'\n', 'n') INTO q_query;

    SELECT volat_file_write(p_output,q_query) INTO q_query;

    RETURN q_query;
    END;
$f$ LANGUAGE PLpgSQL;
-- SELECT optim.generate_make_conf_with_size('BR','21.1','/tmp/pg_io/testereadme','/var/gits/_dg/preserv-BR/data/SP/Atibaia/_pk0021.01','/var/gits/_dg');

CREATE or replace FUNCTION optim.generate_make_conf_with_license(
    jurisd      text,
    pack_id     text,
    p_output    text,
    p_path_pack text,
    p_path  text DEFAULT '/var/gits/_dg'  -- git path
) RETURNS text AS $f$
    DECLARE
        q_query text;
        p_yaml jsonb;
        p_yaml_t text;
        license_evidences jsonb;
        definition jsonb;
        license_explicit boolean;
    BEGIN

    SELECT pg_read_file(p_path_pack ||'/make_conf.yaml') INTO p_yaml_t;
    SELECT yaml_to_jsonb(p_yaml_t) ||
           yamlfile_to_jsonb(p_path || '/preserv' || CASE WHEN jurisd ='INT' THEN '' ELSE '-' || upper(jurisd) END || '/src/maketemplates/commomFirst.yaml')
    INTO p_yaml;

    SELECT to_jsonb(ARRAY[name, family, url]), CASE WHEN lower(license_is_explicit)='yes' THEN TRUE ELSE FALSE END FROM tmp_orig.tmp_pack_licenses WHERE tmp_orig.tmp_pack_licenses.pack_id = (to_char(substring(p_yaml->>'pack_id','^([^\.]*)')::int,'fm000') || to_char(substring(p_yaml->>'pack_id','([^\.]*)$')::int,'fm00')) INTO definition, license_explicit;

    IF license_explicit
    THEN
      IF p_yaml?'license_evidences'
      THEN
          license_evidences := p_yaml->'license_evidences' || jsonb_build_object('definition',null);

          SELECT regexp_replace( p_yaml_t , '\n*license_evidences: *(\n *\-[^\n]*|\n[\t ]+[^\n]+)+\n*', E'\n\n' || regexp_replace(jsonb_to_yaml(jsonb_build_object('license_evidences',license_evidences)::text)::text,'definition: null\n', 'definition: ' || jsonb_to_yaml(definition::text,True)::text) || E'\n', 'n') INTO q_query;
      ELSE
          license_evidences := jsonb_build_object('license_evidences',jsonb_build_object('definition',null));

          SELECT regexp_replace( p_yaml_t , '\n*files: *(\n *\-[^\n]*|\n[\t ]+[^\n]+)+\n*', E'\n\n' || jsonb_to_yaml((p_yaml->'files')::text)::text || E'\n' || regexp_replace(jsonb_to_yaml(jsonb_build_object('license_evidences',license_evidences)::text)::text,'definition: null', 'definition: ' || jsonb_to_yaml(definition::text,True)::text) || E'\n', 'n') INTO q_query;
      END IF;
    ELSE
      SELECT 'licença implícita.' INTO q_query;
    END IF;

    SELECT volat_file_write(p_output,q_query) INTO q_query;

    RETURN q_query;
    END;
$f$ LANGUAGE PLpgSQL;
-- SELECT optim.generate_make_conf_with_license('BR','16.1','/tmp/pg_io/testmakel','/var/gits/_dg/preserv-BR/data/RJ/Niteroi/_pk0016.01','/var/gits/_dg');
-- SELECT optim.generate_make_conf_with_license('BR','9.1','/tmp/pg_io/testmakel','/var/gits/_dg/preserv-BR/data/MG/Contagem/_pk0009.01','/var/gits/_dg');


---

--DROP VIEW optim.vw01donorEvidenceCMD;
CREATE or replace VIEW optim.vw01donorEvidenceCMD AS
SELECT isolabel_ext, iso, line, p, path,
       CASE
       WHEN is_cctld IS TRUE AND upper(p[array_upper(p,1)]) = 'BR' THEN concat('mkdir -p ', path, ' && wget https://rdap.registro.br/domain/', line, ' > ', path, '/rdap.json')
       ELSE concat('mkdir -p ', path, ' && rdap -v -j ', line, ' > ', path, '/rdap.json')
       END AS commandline_rdap
FROM
(
    SELECT isolabel_ext, iso, line, p, is_cctld,
        CASE cardinality(p)
        WHEN 2 THEN concat('/var/gits/_dg/preserv-',iso,'/data/_donorEvidence/',p[2],'/',p[1],'.',p[2])
        WHEN 3 THEN concat('/var/gits/_dg/preserv-',iso,'/data/_donorEvidence/',p[3],'/',p[2],'.',p[3],'/',p[1],'.',p[2],'.',p[3])
        WHEN 4 THEN concat('/var/gits/_dg/preserv-',iso,'/data/_donorEvidence/',p[4],'/',p[3],'.',p[4],'/',p[2],'.',p[3],'.',p[4],'/',p[1],'.',p[2],'.',p[3],'.',p[4])
        WHEN 5 THEN concat('/var/gits/_dg/preserv-',iso,'/data/_donorEvidence/',p[5],'/',p[4],'.',p[5],'/',p[3],'.',p[4],'.',p[5],'/',p[2],'.',p[3],'.',p[4],'.',p[5],'/',p[1],'.',p[2],'.',p[3],'.',p[4],'.',p[5])
        WHEN 6 THEN concat('/var/gits/_dg/preserv-',iso,'/data/_donorEvidence/',p[6],'/',p[5],'.',p[6],'/',p[4],'.',p[5],'.',p[6],'/',p[3],'.',p[4],'.',p[5],'.',p[6],'/',p[2],'.',p[3],'.',p[4],'.',p[5],'.',p[6],'/',p[1],'.',p[2],'.',p[3],'.',p[4],'.',p[5],'.',p[6])
        ELSE ''
        END AS path
    FROM
    (
        SELECT isolabel_ext, iso, line, p,
            CASE
            WHEN upper(p[array_upper(p,1)]) IN (SELECT isolabel_ext FROM optim.jurisdiction WHERE isolevel = 1) THEN TRUE
            ELSE false
            END AS is_cctld
        FROM
        (
            SELECT DISTINCT isolabel_ext , split_part(isolabel_ext,'-',1) AS iso ,  line , regexp_split_to_array (line,'\.') as p
            FROM
            (
                SELECT j.isolabel_ext, str_url_todomain(url) as line
                FROM optim.donor dn
                LEFT JOIN optim.jurisdiction j
                ON dn.scope_osm_id=j.osm_id

                UNION

                SELECT isolabel_ext, str_url_todomain(packtpl_info->>'uri') as line
                FROM optim.vw01full_donated_PackTpl
            ) t1
            WHERE line>''
            ORDER BY 1,2
        ) t2
    ) t3
) t4
;
COMMENT ON VIEW optim.vw01donorEvidenceCMD
  IS 'Generate commands to update or create evidences for donor and donatedPack.'
;
