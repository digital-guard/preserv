#!/bin/bash

sed -i 's/\(INSERT INTO.*\);$/\1 ON CONFLICT (packvers_id,ftid,lineage_md5) DO UPDATE SET (is_evidence, proc_step, lineage, kx_profile) = (EXCLUDED.is_evidence, EXCLUDED.proc_step, EXCLUDED.lineage, EXCLUDED.kx_profile);/g' $1
sed -i 's/ingest\.donated_packcomponent/optim\.donated_PackComponent_not_approved/g' $1
