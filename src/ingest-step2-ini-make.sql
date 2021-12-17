
SELECT ingest.lix_insert('BR','/var/gits/_dg/preserv-BR/src/maketemplates/commomFirst.yaml','first_yaml');
SELECT ingest.lix_insert('BR','/var/gits/_dg/preserv-BR/src/maketemplates/readme.mustache','readme');

SELECT ingest.lix_insert('PE','/var/gits/_dg/preserv-PE/src/maketemplates/commomFirst.yaml','first_yaml');
SELECT ingest.lix_insert('PE','/var/gits/_dg/preserv-PE/src/maketemplates/readme.mustache','readme');

SELECT ingest.lix_insert('CO','/var/gits/_dg/preserv-CO/src/maketemplates/commomFirst.yaml','first_yaml');
SELECT ingest.lix_insert('CO','/var/gits/_dg/preserv-CO/src/maketemplates/readme.mustache','readme');

SELECT ingest.lix_insert('INT','/var/gits/_dg/preserv/src/maketemplates/make_ref004a.mustache.mk','mkme_srcTpl');
SELECT ingest.lix_insert('INT','/var/gits/_dg/preserv/src/maketemplates/make_ref027a.mustache.mk','mkme_srcTpl');
SELECT ingest.lix_insert('INT','/var/gits/_dg/preserv/src/maketemplates/commomLast.mustache.mk','mkme_srcTplLast');

SELECT ingest.lix_insert('INT','/var/gits/_dg/preserv/src/maketemplates/commomFirst.yaml','first_yaml');
