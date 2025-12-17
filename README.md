# semantic_view_hands_on

Snowflake Quickstart:  
https://www.snowflake.com/en/developers/guides/snowflake-semantic-view-agentic-analytics/

## セットアップ

## setup.sqlで生成されるオブジェクト

``` test
[ACCOUNT]   
  ├─ ロール  
  │    ├─ ACCOUNTADMIN     (既存ロール)  
  │    ├─ PUBLIC           (組み込みロール)  
  │    └─ AGENTIC_ANALYTICS_VHOL_ROLE   ← このスクリプトで作成  
  │  
  ├─ ユーザ  
  │    └─ current_user  
  │          ├─ ロール: ACCOUNTADMIN, AGENTIC_ANALYTICS_VHOL_ROLE  
  │          └─ デフォルト: ROLE=AGENTIC_ANALYTICS_VHOL_ROLE, WH=AGENTIC_ANALYTICS_VHOL_WH  
  │  
  ├─ アカウントレベルオブジェクト  
  │    ├─ WAREHOUSE  AGENTIC_ANALYTICS_VHOL_WH  
  │    └─ API INTEGRATION  GIT_API_INTEGRATION  
  │  
  └─ データベース  
       ├─ AGENTIC_ANALYTICS_VHOL  
       │     └─ SCHEMA AGENTS  
       └─ SV_VHOL_DB  
             └─ SCHEMA VHOL_SCHEMA  
                    ├─ FILE FORMAT CSV_FORMAT  
                    ├─ STAGE INTERNAL_DATA_STAGE  
                    ├─ GIT REPOSITORY AA_VHOL_REPO  
                    └─ 各種 TABLE（DIM/FCT/SF_*）  
```

## SCHEMA SV_VHOL_DB.VHOL_SCHEMA配下のテーブル

``` test
[SCHEMA SV_VHOL_DB.VHOL_SCHEMA]
  ├─ TABLE product_category_dim
  ├─ TABLE product_dim
  ├─ TABLE vendor_dim
  ├─ TABLE customer_dim
  ├─ TABLE account_dim
  ├─ TABLE department_dim
  ├─ TABLE region_dim
  ├─ TABLE sales_rep_dim
  ├─ TABLE campaign_dim
  ├─ TABLE channel_dim
  ├─ TABLE employee_dim
  ├─ TABLE job_dim
  ├─ TABLE location_dim
  ├─ TABLE sales_fact
  ├─ TABLE finance_transactions
  ├─ TABLE marketing_campaign_fact
  ├─ TABLE hr_employee_fact
  ├─ TABLE sf_accounts
  ├─ TABLE sf_opportunities
  └─ TABLE sf_contacts

OWNERは全て: AGENTIC_ANALYTICS_VHOL_ROLE
```

## ロールに付与した権限関係

``` text
[USER current_user]
   ├─ ROLE ACCOUNTADMIN
   │     ├─ OWNER: AGENTIC_ANALYTICS_VHOL_WH
   │     ├─ OWNER: GIT_API_INTEGRATION
   │     └─ OWNER: AGENTIC_ANALYTICS_VHOL (DB) / AGENTS (SCHEMA)
   │
   └─ ROLE AGENTIC_ANALYTICS_VHOL_ROLE
         ├─ 権限 (Accountレベル)
         │     └─ CREATE DATABASE ON ACCOUNT
         │
         ├─ 権限 (Warehouse)
         │     └─ USAGE ON WAREHOUSE AGENTIC_ANALYTICS_VHOL_WH
         │
         ├─ 権限 (Integration)
         │     └─ USAGE ON INTEGRATION GIT_API_INTEGRATION
         │
         ├─ OWNER: SV_VHOL_DB / VHOL_SCHEMA
         │
         ├─ OWNER: CSV_FORMAT / INTERNAL_DATA_STAGE / AA_VHOL_REPO
         │
         └─ OWNER: すべての DIM / FACT / SF_* テーブル
                （＋ それらへの COPY/SELECT/INSERT などすべて）

[ROLE PUBLIC]
   └─ USAGE ON DATABASE AGENTIC_ANALYTICS_VHOL
        └─ USAGE ON SCHEMA AGENTIC_ANALYTICS_VHOL.AGENTS
           （agents スキーマ内に今後作成されるオブジェクトは、
             オブジェクトごとに別途権限が必要）
``` 

# メインセクション1

## ER図

- ディメンション系テーブル：末尾にDIM  
- ファクト系テーブル：SALES_FACT, FINANCE_TRANSACTIONS, MARKETING_CAMPAIGN_FACT, HR_EMPLOYEE_FACT  
- SFDC系テーブル：SF_ACCOUNTS, SF_OPPORTUNITIES, SF_CONTACTS  

``` mermaid
erDiagram
  PRODUCT_CATEGORY_DIM {
    INT category_key PK
    VARCHAR category_name
    VARCHAR vertical
  }

  PRODUCT_DIM {
    INT product_key PK
    INT category_key FK
    VARCHAR product_name
  }

  VENDOR_DIM {
    INT vendor_key PK
    VARCHAR vendor_name
  }

  CUSTOMER_DIM {
    INT customer_key PK
    VARCHAR customer_name
  }

  ACCOUNT_DIM {
    INT account_key PK
    VARCHAR account_name
  }

  DEPARTMENT_DIM {
    INT department_key PK
    VARCHAR department_name
  }

  REGION_DIM {
    INT region_key PK
    VARCHAR region_name
  }

  SALES_REP_DIM {
    INT sales_rep_key PK
    VARCHAR rep_name
  }

  CAMPAIGN_DIM {
    INT campaign_key PK
    VARCHAR campaign_name
  }

  CHANNEL_DIM {
    INT channel_key PK
    VARCHAR channel_name
  }

  EMPLOYEE_DIM {
    INT employee_key PK
    VARCHAR employee_name
  }

  JOB_DIM {
    INT job_key PK
    VARCHAR job_title
  }

  LOCATION_DIM {
    INT location_key PK
    VARCHAR location_name
  }

  SALES_FACT {
    INT sale_id PK
    DATE date
    INT customer_key FK
    INT product_key FK
    INT sales_rep_key FK
    INT region_key FK
    INT vendor_key FK
  }

  FINANCE_TRANSACTIONS {
    INT transaction_id PK
    DATE date
    INT account_key FK
    INT department_key FK
    INT vendor_key FK
    INT product_key FK
    INT customer_key FK
    INT approver_id FK
  }

  MARKETING_CAMPAIGN_FACT {
    INT campaign_fact_id PK
    DATE date
    INT campaign_key FK
    INT product_key FK
    INT channel_key FK
    INT region_key FK
  }

  HR_EMPLOYEE_FACT {
    INT hr_fact_id PK
    DATE date
    INT employee_key FK
    INT department_key FK
    INT job_key FK
    INT location_key FK
  }

  SF_ACCOUNTS {
    VARCHAR account_id PK
    INT customer_key FK
  }

  SF_OPPORTUNITIES {
    VARCHAR opportunity_id PK
    INT sale_id FK
    VARCHAR account_id FK
    INT campaign_id FK
  }

  SF_CONTACTS {
    VARCHAR contact_id PK
    VARCHAR opportunity_id FK
    VARCHAR account_id FK
  }

  %% リレーション定義

  PRODUCT_CATEGORY_DIM ||--o{ PRODUCT_DIM : "category_key"

  CUSTOMER_DIM ||--o{ SALES_FACT : "customer_key"
  PRODUCT_DIM  ||--o{ SALES_FACT : "product_key"
  SALES_REP_DIM ||--o{ SALES_FACT : "sales_rep_key"
  REGION_DIM ||--o{ SALES_FACT : "region_key"
  VENDOR_DIM ||--o{ SALES_FACT : "vendor_key"

  ACCOUNT_DIM ||--o{ FINANCE_TRANSACTIONS : "account_key"
  DEPARTMENT_DIM ||--o{ FINANCE_TRANSACTIONS : "department_key"
  VENDOR_DIM ||--o{ FINANCE_TRANSACTIONS : "vendor_key"
  PRODUCT_DIM ||--o{ FINANCE_TRANSACTIONS : "product_key"
  CUSTOMER_DIM ||--o{ FINANCE_TRANSACTIONS : "customer_key"
  EMPLOYEE_DIM ||--o{ FINANCE_TRANSACTIONS : "approver_id"

  CAMPAIGN_DIM ||--o{ MARKETING_CAMPAIGN_FACT : "campaign_key"
  PRODUCT_DIM  ||--o{ MARKETING_CAMPAIGN_FACT : "product_key"
  CHANNEL_DIM  ||--o{ MARKETING_CAMPAIGN_FACT : "channel_key"
  REGION_DIM   ||--o{ MARKETING_CAMPAIGN_FACT : "region_key"

  EMPLOYEE_DIM   ||--o{ HR_EMPLOYEE_FACT : "employee_key"
  DEPARTMENT_DIM ||--o{ HR_EMPLOYEE_FACT : "department_key"
  JOB_DIM        ||--o{ HR_EMPLOYEE_FACT : "job_key"
  LOCATION_DIM   ||--o{ HR_EMPLOYEE_FACT : "location_key"

  CUSTOMER_DIM ||--o{ SF_ACCOUNTS : "customer_key"

  SF_ACCOUNTS    ||--o{ SF_OPPORTUNITIES : "account_id"
  SALES_FACT     ||--o{ SF_OPPORTUNITIES : "sale_id"
  CAMPAIGN_DIM   ||--o{ SF_OPPORTUNITIES : "campaign_id"

  SF_ACCOUNTS     ||--o{ SF_CONTACTS : "account_id"
  SF_OPPORTUNITIES ||--o{ SF_CONTACTS : "opportunity_id"
```
