# Passos gerais para adicionar/atualizar geometrias jurisdicionais:

1. Dump de `dl03t_main`, antes de qualquer alteração;

2. Download dos dados do _OpenStreetMap_ e criação do _make_conf_;

3. Criar uma base `ingest` especifica;

4. Processo de ingestão (`make openstreetmap`);

5. Avaliar os dados já disponíveis em [optim.jurisdiction](https://github.com/digital-guard/preserv/blob/main/src/optim-step1-ini.sql#L9) e [optim.jurisdiction_geom](https://github.com/digital-guard/preserv/blob/main/src/optim-step1-ini.sql#L52);

6. Preparar os dados na `ingest`;

7. Dump da `ingest` para `dl03t_main`;

7. Insert/Update em [optim.jurisdiction](https://github.com/digital-guard/preserv/blob/main/src/optim-step1-ini.sql#L9) e [optim.jurisdiction_geom](https://github.com/digital-guard/preserv/blob/main/src/optim-step1-ini.sql#L52);

8. Realizar o update de `info` das geometrias atualizadas. Ver [optim-step6-metrics](https://github.com/digital-guard/preserv/blob/main/src/optim-step6-metrics.sql);

9. Drop do dump vindo da ingest.
