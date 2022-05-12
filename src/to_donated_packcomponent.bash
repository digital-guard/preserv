#!/bin/bash

sed -i 's/\(INSERT INTO\) ingest.donated_packcomponent (id, \(packvers_id, ftid, is_evidence, proc_step, lineage, lineage_md5, kx_profile) VALUES (\)[0-9]*,\(.*\);$/\1 optim\.donated_PackComponent_not_approved (\2\3  ON CONFLICT (packvers_id,ftid,lineage_md5) DO UPDATE SET (is_evidence, proc_step, lineage, kx_profile) = (EXCLUDED.is_evidence, EXCLUDED.proc_step, EXCLUDED.lineage, EXCLUDED.kx_profile);/g' $1
