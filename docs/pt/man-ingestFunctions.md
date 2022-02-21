
## Funções ingestão

SQL Schema `ingest`.


<table>
<tr><td> Function / Description / Example </td></tr>
<tr>
<td>
<b><code>any_load(</code></b><i>text, text, text, text, bigint, text, ARRAY, integer, text, boolean</i><b><code>)</code> → </b> <i>text</i>
<p class="pgdoc_comment">Load (into ingest.feature_asis) shapefile or any other non-GeoJSON, of a separated table.</p>  
</td>
</tr><tr>
<td>
<b><code>any_load(</code></b><i>text, text, text, text, text, text, ARRAY, integer, text, boolean</i><b><code>)</code> → </b> <i>text</i>
<p class="pgdoc_comment">Wrap to ingest.any_load(1,2,3,4=real) using string format DD_DD.</p>  
</td>
</tr><tr>
<td>
<b><code>any_load_debug(</code></b><i>text, text, text, text, text, text, ARRAY, text, boolean</i><b><code>)</code> → </b> <i>jsonb</i>
</td>
</tr><tr>
<td>
<b><code>donated_packcomponent_distribution_prefixes(</code></b><i>integer</i><b><code>)</code> → </b> <i>_text</i>
</td>
</tr><tr>
<td>
<b><code>donated_packcomponent_geomtype(</code></b><i>bigint</i><b><code>)</code> → </b> <i>_text</i>
<p class="pgdoc_comment">[Geomtype,ftname,class_ftname,shortname_pt] of a layer_file.</p>  
</td>
</tr><tr>
<td>
<b><code>fdw_csv_paths(</code></b><i>text, text, text</i><b><code>)</code> → </b> <i>_text</i>
</td>
</tr><tr>
<td>
<b><code>fdw_generate(</code></b><i>text, text, text, ARRAY, boolean, text, text, boolean</i><b><code>)</code> → </b> <i>text</i>
<p class="pgdoc_comment">Generates a structure FOREIGN TABLE for ingestion.</p>  
</td>
</tr><tr>
<td>
<b><code>fdw_generate_direct_csv(</code></b><i>text, text, text, boolean, boolean</i><b><code>)</code> → </b> <i>text</i>
<p class="pgdoc_comment">Generates a FOREIGN TABLE for simples and direct CSV ingestion.</p>  
</td>
</tr><tr>
<td>
<b><code>fdw_generate_getclone(</code></b><i>text, text, text, ARRAY, ARRAY, text</i><b><code>)</code> → </b> <i>text</i>
<p class="pgdoc_comment">Generates a clone-structure FOREIGN TABLE for ingestion. Wrap for fdw_generate().</p>  
</td>
</tr><tr>
<td>
<b><code>fdw_generate_getcsv(</code></b><i>text, text, text, text</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr><tr>
<td>
<b><code>feature_asis_assign(</code></b><i>bigint</i><b><code>)</code> → </b> <i>jsonb</i>
</td>
</tr><tr>
<td>
<b><code>feature_asis_assign_format(</code></b><i>bigint, text, text, text</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr><tr>
<td>
<b><code>feature_asis_assign_signature(</code></b><i>bigint</i><b><code>)</code> → </b> <i>jsonb</i>
</td>
</tr><tr>
<td>
<b><code>feature_asis_assign_volume(</code></b><i>bigint, boolean</i><b><code>)</code> → </b> <i>jsonb</i>
</td>
</tr><tr>
<td>
<b><code>feature_asis_export(</code></b><i>bigint, text, integer, jsonb, USER-DEFINED</i><b><code>)</code> → </b> <i>record</i>
</td>
</tr><tr>
<td>
<b><code>feature_asis_geohashes(</code></b><i>bigint, integer</i><b><code>)</code> → </b> <i>jsonb</i>
</td>
</tr><tr>
<td>
<b><code>feature_asis_similarity(</code></b><i>bigint, USER-DEFINED, ARRAY</i><b><code>)</code> → </b> <i>jsonb</i>
</td>
</tr><tr>
<td>
<b><code>geojson_load(</code></b><i>text, integer, real, text, text, boolean</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr><tr>
<td>
<b><code>getmeta_to_file(</code></b><i>text, integer, bigint, text, integer, text</i><b><code>)</code> → </b> <i>int8</i>
<p class="pgdoc_comment">Reads file metadata and inserts it into ingest.donated_PackComponent. If proc_step=1 returns valid ID else NULL.</p>  
</td>
</tr><tr>
<td>
<b><code>getmeta_to_file(</code></b><i>text, integer, bigint</i><b><code>)</code> → </b> <i>int8</i>
<p class="pgdoc_comment">Reads file metadata and return id if exists in ingest.donated_PackComponent.</p>  
</td>
</tr><tr>
<td>
<b><code>getmeta_to_file(</code></b><i>text, text, bigint</i><b><code>)</code> → </b> <i>int8</i>
<p class="pgdoc_comment">Wrap para ingest.getmeta_to_file(text,int,bigint) usando ftName ao invés de ftID.</p>  
</td>
</tr><tr>
<td>
<b><code>getmeta_to_file(</code></b><i>text, text, bigint, text, integer, text</i><b><code>)</code> → </b> <i>int8</i>
<p class="pgdoc_comment">Wrap para ingest.getmeta_to_file() usando ftName ao invés de ftID.</p>  
</td>
</tr><tr>
<td>
<b><code>insert_bytesize(</code></b><i>jsonb</i><b><code>)</code> → </b> <i>jsonb</i>
</td>
</tr><tr>
<td>
<b><code>join(</code></b><i>text, text, text, text, text, text</i><b><code>)</code> → </b> <i>text</i>
<p class="pgdoc_comment">Join layer and cadlayer.</p>  
</td>
</tr><tr>
<td>
<b><code>jplanet_inserts_and_drops(</code></b><i>smallint, boolean</i><b><code>)</code> → </b> <i>void</i>
</td>
</tr><tr>
<td>
<b><code>jsonb_mustache_prepare(</code></b><i>jsonb, text</i><b><code>)</code> → </b> <i>jsonb</i>
</td>
</tr><tr>
<td>
<b><code>lix_generate_make_conf_with_license(</code></b><i>text, text</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr><tr>
<td>
<b><code>lix_generate_make_conf_with_size(</code></b><i>text, text</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr><tr>
<td>
<b><code>lix_generate_makefile(</code></b><i>text, text</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr><tr>
<td>
<b><code>lix_generate_readme(</code></b><i>text, text</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr><tr>
<td>
<b><code>lix_insert(</code></b><i>text</i><b><code>)</code> → </b> <i>void</i>
</td>
</tr><tr>
<td>
<b><code>load_codec_type(</code></b><i>text, text, text</i><b><code>)</code> → </b> <i>text</i>
<p class="pgdoc_comment">Load codec_type.csv.</p>  
</td>
</tr><tr>
<td>
<b><code>load_hcode_parameters(</code></b><i>text, text, text</i><b><code>)</code> → </b> <i>text</i>
<p class="pgdoc_comment">Load hcode_parameters.csv.</p>  
</td>
</tr><tr>
<td>
<b><code>osm_load(</code></b><i>text, text, text, bigint, text, ARRAY, integer, text, boolean</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr><tr>
<td>
<b><code>osm_load(</code></b><i>text, text, text, text, text, ARRAY, integer, text, boolean</i><b><code>)</code> → </b> <i>text</i>
<p class="pgdoc_comment">Wrap to ingest.osm_load(1,2,3,4=real) using string format DD_DD.</p>  
</td>
</tr><tr>
<td>
<b><code>package_layers_summary(</code></b><i>real, text, text</i><b><code>)</code> → </b> <i>xml</i>
</td>
</tr><tr>
<td>
<b><code>publicating_geojsons(</code></b><i>bigint, text, text</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr><tr>
<td>
<b><code>publicating_geojsons(</code></b><i>text, text, text</i><b><code>)</code> → </b> <i>text</i>
<p class="pgdoc_comment">Wrap to ingest.publicating_geojsons</p>  
</td>
</tr><tr>
<td>
<b><code>publicating_geojsons_p1(</code></b><i>bigint, text</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr><tr>
<td>
<b><code>publicating_geojsons_p2(</code></b><i>bigint, text, boolean</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr><tr>
<td>
<b><code>publicating_geojsons_p3(</code></b><i>bigint, text, text</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr><tr>
<td>
<b><code>publicating_geojsons_p4(</code></b><i>bigint, text, text</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr><tr>
<td>
<b><code>qgis_vwadmin_feature_asis(</code></b><i>text</i><b><code>)</code> → </b> <i>text</i>
</td>
</tr>
</table>
