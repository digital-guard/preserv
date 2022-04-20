## Diagrama DL03t_main

[Diagramas UML de classes](https://en.wikipedia.org/wiki/Class_diagram). Conforme **convenções** semânticas UML e detalhes [visuais Mermaid](https://mermaid-js.github.io/mermaid/#/classDiagram).

## Donated_PackTpl e Jurisdiction

```mermaid
classDiagram
    Jurisdiction *-- "0..1" Jurisdiction_geom
    Donated_PackTpl "0..1" -->  Jurisdiction: has scope
    Donated_PackTpl "*" --> Donor: has
    Donor "0..1" ..> Jurisdiction: has agg scope

    class Jurisdiction { osm_id bigint }
    class Jurisdiction_geom { osm_id bigint }
    class Donor {
      id integer
      scope_osm_id bigint
    }
    class Donated_PackTpl {
        id integer
        scope_osm_id bigint
        donor_id integer
    }
```

## Donated_PackTpl e seus componentes

```mermaid
classDiagram
  Donated_PackTpl "*" --> Donor: has
  Donated_PackFileVers "*" --* Donated_PackTpl: (pack_id)

  class Donor {
    id integer
    country_id integer
    local_serial integer
    scope_osm_id bigint
    -getFromGit()
    -input_donor()
  }
  class Donated_PackTpl {
    id bigint
    donor_id integer
    pk_count int
    scope_osm_id bigint
    user_resp text
    -getFromGit()
    -input_donated_PackTpl()
  }
  class Donated_PackFileVers {
    id bigint
    pack_id bigint
    user_resp text
    -getFromGit()
    -input_donated_PackFileVers()
  }
```

----

## Implementação

Os relacionamentos entre as classes foram implementados através de tabelas e chaves do [Modelo Relacional](https://en.wikipedia.org/wiki/Relational_model) (SQL), que ficam mais evidentes em [diagramas clássicos de Entidade-Relacionamento do tipo pé-de-galinha](https://en.wikipedia.org/wiki/Entity%E2%80%93relationship_model#Crow's_foot_notation).

```mermaid
erDiagram

    jurisdiction |o--o| jurisdiction : ""
    jurisdiction ||--o| jurisdiction_geom : ""

    donor }o--|| jurisdiction : ""
    donated_PackTpl }o--|| donor : ""
    donated_PackTpl }o--|| auth_user : ""
    donated_PackFileVers }|--|| donated_PackTpl : ""
    donated_PackFileVers }o--|| auth_user : ""

    donated_PackComponent }|--|| donated_PackFileVers : ""
    donated_PackComponent }o--|| feature_type : ""
    donated_PackComponent_not_approved }|--|| donated_PackFileVers : ""
    donated_PackComponent_not_approved }o--|| feature_type : ""

    jurisdiction {
        bigint osm_id PK
        bigint parent_id FK
    }
    jurisdiction_geom {
        bigint osm_id PK
    }
    auth_user {
        text username PK
    }
    donor {
        integer id PK
        bigint scope_osm_id FK
    }
    donated_PackTpl {
        integer id PK
        int donor_id FK
        text user_resp FK
    }
    donated_PackFileVers {
        bigint id PK
        bigint pack_id FK
        text user_resp FK
    }
    feature_type {
        smallint ftid PK
    }
    donated_PackComponent {
        bigserial id PK
        bigint packvers_id FK
        smallint ftid PK
    }
    donated_PackComponent_not_approved {
        bigserial id PK
        bigint packvers_id FK
        smallint ftid PK
    }
```


<!--
    class Donated_PackFileVers {
        id:bigint
        hashedfname:         text  
        pack_id:                bigin
        pack_item:              integer
        pack_item_accepted_date: date
        kx_pack_item_version:   integer
        user_resp:              text  
        info:                   jsonb
        -input_donated_packfilevers()
        insert_donor_pack()
    }

-->
