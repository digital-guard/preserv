SELECT ingest.lix_insert('/var/gits/_dg/preserv-' || t || '/src/maketemplates/commomFirst.yaml') FROM unnest(ARRAY['AR','BO','BR','CL','CO','EC','PE','PY','SR','UY','VE']) t;
SELECT ingest.lix_insert('/var/gits/_dg/preserv-' || t || '/src/maketemplates/readme.mustache' ) FROM unnest(ARRAY['AR','BO','BR','CL','CO','EC','PE','PY','SR','UY','VE']) t;

SELECT ingest.lix_insert('/var/gits/_dg/preserv/src/maketemplates/make_ref027a.mustache.mk');
SELECT ingest.lix_insert('/var/gits/_dg/preserv/src/maketemplates/commomLast.mustache.mk');

SELECT ingest.lix_insert('/var/gits/_dg/preserv/src/maketemplates/commomFirst.yaml');
