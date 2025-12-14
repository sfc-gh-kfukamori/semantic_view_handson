# semantic_view_hands_on

## setup.sqlの実行

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

