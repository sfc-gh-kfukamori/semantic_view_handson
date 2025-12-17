-- こすでに作成済みのファクト／ディメンションテーブルの上に、
-- 財務・売上・マーケティングの3つのセマンティックビューを定義し、
-- Cortex AnalystやSQLから使える ビジネス向けの意味レイヤーを作っています。

-- TABLES … どの物理テーブルを論理テーブルとして見せるか。
-- RELATIONSHIPS … テーブル間のリレーション（JOIN 関係）。正しく JOIN する道筋を理解できます。
-- FACTS … 明細値（元となる数値）
-- DIMENSIONS … 軸・属性（グルーピングに使う列）
-- METRICS … 集計指標（SUM / AVG / COUNT などのKPI）
-- WITH SYNONYMS / COMMENT … 自然言語での問い合わせ精度を上げるためのメタデータ

USE ROLE agentic_analytics_vhol_role;
USE DATABASE SV_VHOL_DB;
USE SCHEMA VHOL_SCHEMA;

-----------------------------
-- FINANCE SEMANTIC VIEW
-----------------------------
CREATE OR REPLACE SEMANTIC VIEW FINANCE_SEMANTIC_VIEW
    TABLES (
    --物理テーブルを、ビジネス的に分かりやすい論理テーブル名としてマッピング。
    -- PRIMARY KEYで、各論理テーブルの主キー列を宣言しています。
        TRANSACTIONS AS FINANCE_TRANSACTIONS PRIMARY KEY (TRANSACTION_ID) 
            WITH SYNONYMS = ('財務トランザクション','財務データ') --言い換え表現を登録することでAIの解釈精度を高める
            COMMENT = '部門横断のすべての財務トランザクション',

        ACCOUNTS AS ACCOUNT_DIM PRIMARY KEY (ACCOUNT_KEY)
            WITH SYNONYMS = ('勘定科目','アカウント種別')
            COMMENT = '財務カテゴリ用の勘定科目ディメンション',

        DEPARTMENTS AS DEPARTMENT_DIM PRIMARY KEY (DEPARTMENT_KEY)
            WITH SYNONYMS = ('事業部','部門')
            COMMENT = 'コストセンター分析向けの部門ディメンション',

        VENDORS AS VENDOR_DIM PRIMARY KEY (VENDOR_KEY)
            WITH SYNONYMS = ('サプライヤー','ベンダー')
            COMMENT = '支出分析向けのベンダー情報',

        PRODUCTS AS PRODUCT_DIM PRIMARY KEY (PRODUCT_KEY)
            WITH SYNONYMS = ('製品','商品')
            COMMENT = 'トランザクション分析用の製品ディメンション',

        CUSTOMERS AS CUSTOMER_DIM PRIMARY KEY (CUSTOMER_KEY)
            WITH SYNONYMS = ('顧客','クライアント')
            COMMENT = '売上分析用の顧客ディメンション'
    )
    RELATIONSHIPS (
    --TRANSACTIONS（ファクト）と各ディメンションテーブルとの リレーション（JOIN 関係）を宣言しています。
        TRANSACTIONS_TO_ACCOUNTS      AS TRANSACTIONS(ACCOUNT_KEY)    REFERENCES ACCOUNTS(ACCOUNT_KEY),
        TRANSACTIONS_TO_DEPARTMENTS   AS TRANSACTIONS(DEPARTMENT_KEY) REFERENCES DEPARTMENTS(DEPARTMENT_KEY),
        TRANSACTIONS_TO_VENDORS       AS TRANSACTIONS(VENDOR_KEY)     REFERENCES VENDORS(VENDOR_KEY),
        -- TRANSACTIONS_TO_PRODUCTS      AS TRANSACTIONS(PRODUCT_KEY)    REFERENCES PRODUCTS(PRODUCT_KEY), --コメントアウト
        TRANSACTIONS_TO_CUSTOMERS     AS TRANSACTIONS(CUSTOMER_KEY)   REFERENCES CUSTOMERS(CUSTOMER_KEY)
    )
    FACTS (
    -- 実際のトランザクションから発生するファクトの値
    -- 後の METRICS で SUM(amount) や COUNT(transaction_record) を定義するための素地です。
        TRANSACTIONS.TRANSACTION_AMOUNT AS amount
            COMMENT = '取引金額（ドル）',

        TRANSACTIONS.TRANSACTION_RECORD AS 1
            COMMENT = 'トランザクション件数'
    )
    DIMENSIONS (
    -- 分析の軸（ディメンション）を定義します。SQLのWhere句に該当する箇所と考えると分かりやすい。
        TRANSACTIONS.TRANSACTION_DATE AS date
            WITH SYNONYMS = ('日付','取引日')
            COMMENT = '財務トランザクションの日付',

        TRANSACTIONS.TRANSACTION_MONTH AS MONTH(date) --このように、同じ元カラムから派生するサマリー軸を定義できることもポイント。
            COMMENT = '取引月',

        TRANSACTIONS.TRANSACTION_YEAR AS YEAR(date)
            COMMENT = '取引年',

        ACCOUNTS.ACCOUNT_NAME AS account_name
            WITH SYNONYMS = ('勘定科目','アカウント名','アカウント種別')
            COMMENT = '勘定科目名',

        ACCOUNTS.ACCOUNT_TYPE AS account_type
            WITH SYNONYMS = ('種別','カテゴリ')
            COMMENT = 'アカウント種別（収益／費用）',

        DEPARTMENTS.DEPARTMENT_NAME AS department_name
            WITH SYNONYMS = ('部門','事業部')
            COMMENT = '部門名',

        VENDORS.VENDOR_NAME AS vendor_name
            WITH SYNONYMS = ('ベンダー','サプライヤー')
            COMMENT = 'ベンダー名',

        PRODUCTS.PRODUCT_NAME AS product_name
            WITH SYNONYMS = ('製品','商品')
            COMMENT = '製品名',

        CUSTOMERS.CUSTOMER_NAME AS customer_name
            WITH SYNONYMS = ('顧客','クライアント')
            COMMENT = '顧客名',

        TRANSACTIONS.APPROVAL_STATUS AS approval_status
            WITH SYNONYMS = ('承認','ステータス','承認状態')
            COMMENT = 'トランザクション承認ステータス（承認済み／保留／却下）',

        TRANSACTIONS.PROCUREMENT_METHOD AS procurement_method
            WITH SYNONYMS = ('調達','方法','購買方法')
            COMMENT = '調達方法（RFP／見積／緊急／契約など）',

        TRANSACTIONS.APPROVER_ID AS approver_id
            WITH SYNONYMS = ('承認者','承認者従業員ID')
            COMMENT = '人事データに紐づく承認者の従業員ID',

        TRANSACTIONS.APPROVAL_DATE AS approval_date
            WITH SYNONYMS = ('承認日','承認された日付')
            COMMENT = 'トランザクションが承認された日付',

        -- TRANSACTIONS.PURCHASE_ORDER_NUMBER AS purchase_order_number　--コメントアウト
        --     WITH SYNONYMS = ('発注番号','PO','購買発注書')
        --     COMMENT = 'トラッキング用の購買発注番号',

        TRANSACTIONS.CONTRACT_REFERENCE AS contract_reference
            WITH SYNONYMS = ('契約','契約番号','契約参照')
            COMMENT = '関連する契約の参照'
    )
    METRICS (
    -- 集計指標（KPI）を定義しています。
        TRANSACTIONS.AVERAGE_AMOUNT AS AVG(transactions.amount)
            COMMENT = '平均取引金額',

        -- TRANSACTIONS.TOTAL_AMOUNT AS SUM(transactions.amount)　--コメントアウト
        --     COMMENT = '取引金額合計',

        TRANSACTIONS.TOTAL_TRANSACTIONS AS COUNT(transactions.transaction_record)
            COMMENT = 'トランザクション件数合計'
    )
    COMMENT = '財務分析とレポーティング向けセマンティックビュー';

---------------------------
-- SALES SEMANTIC VIEW（日⽂）
---------------------------
CREATE OR REPLACE SEMANTIC VIEW SALES_SEMANTIC_VIEW
  TABLES (
    CUSTOMERS AS CUSTOMER_DIM PRIMARY KEY (CUSTOMER_KEY)
        WITH SYNONYMS = ('顧客','クライアント','アカウント')
        COMMENT = '売上分析用の顧客情報',

    PRODUCTS AS PRODUCT_DIM PRIMARY KEY (PRODUCT_KEY)
        WITH SYNONYMS = ('製品','商品','SKU')
        COMMENT = '売上分析用の製品カタログ',

    PRODUCT_CATEGORY_DIM PRIMARY KEY (CATEGORY_KEY),

    REGIONS AS REGION_DIM PRIMARY KEY (REGION_KEY)
        WITH SYNONYMS = ('テリトリー','地域','エリア')
        COMMENT = 'テリトリー分析用の地域情報',

    SALES AS SALES_FACT PRIMARY KEY (SALE_ID)
        WITH SYNONYMS = ('売上トランザクション','売上データ')
        COMMENT = 'すべての売上トランザクションと案件情報',

    SALES_REPS AS SALES_REP_DIM PRIMARY KEY (SALES_REP_KEY)
        WITH SYNONYMS = ('営業担当者','営業','セールス')
        COMMENT = '営業担当者情報',

    VENDORS AS VENDOR_DIM PRIMARY KEY (VENDOR_KEY)
        WITH SYNONYMS = ('サプライヤー','ベンダー')
        COMMENT = 'サプライチェーン分析用のベンダー情報'
  )
  RELATIONSHIPS (
    PRODUCT_TO_CATEGORY  AS PRODUCTS(CATEGORY_KEY)  REFERENCES PRODUCT_CATEGORY_DIM(CATEGORY_KEY),
    SALES_TO_CUSTOMERS   AS SALES(CUSTOMER_KEY)     REFERENCES CUSTOMERS(CUSTOMER_KEY),
    SALES_TO_PRODUCTS    AS SALES(PRODUCT_KEY)      REFERENCES PRODUCTS(PRODUCT_KEY),
    SALES_TO_REGIONS     AS SALES(REGION_KEY)       REFERENCES REGIONS(REGION_KEY),
    SALES_TO_REPS        AS SALES(SALES_REP_KEY)    REFERENCES SALES_REPS(SALES_REP_KEY),
    SALES_TO_VENDORS     AS SALES(VENDOR_KEY)       REFERENCES VENDORS(VENDOR_KEY)
  )
  FACTS (
    SALES.SALE_AMOUNT AS amount
        COMMENT = '売上金額（ドル）',

    SALES.SALE_RECORD AS 1
        COMMENT = '売上トランザクション件数',

    SALES.UNITS_SOLD AS units
        COMMENT = '販売数量'
  )
  DIMENSIONS (
    CUSTOMERS.CUSTOMER_INDUSTRY AS INDUSTRY
        WITH SYNONYMS = ('業種','顧客タイプ')
        COMMENT = '顧客の業種',

    CUSTOMERS.CUSTOMER_KEY AS CUSTOMER_KEY,

    CUSTOMERS.CUSTOMER_NAME AS customer_name
        WITH SYNONYMS = ('顧客','クライアント','アカウント名')
        COMMENT = '顧客名',

    PRODUCTS.CATEGORY_KEY AS CATEGORY_KEY
        WITH SYNONYMS = ('カテゴリID','製品カテゴリ','カテゴリコード','分類キー','グループキー','製品グループID')
        COMMENT = '製品カテゴリの一意キー',

    PRODUCTS.PRODUCT_KEY AS PRODUCT_KEY,

    PRODUCTS.PRODUCT_NAME AS product_name
        WITH SYNONYMS = ('製品','商品')
        COMMENT = '製品名',

    PRODUCT_CATEGORY_DIM.CATEGORY_KEY AS CATEGORY_KEY
        WITH SYNONYMS = ('カテゴリID','カテゴリコード','製品カテゴリ番号','カテゴリ識別子','分類キー')
        COMMENT = '製品カテゴリの一意キー',

    PRODUCT_CATEGORY_DIM.CATEGORY_NAME AS CATEGORY_NAME
        WITH SYNONYMS = ('カテゴリ名','製品グループ','分類名','カテゴリラベル','製品カテゴリ説明')
        COMMENT = '「家電」「衣料」「SaaS」などの製品カテゴリ',

    PRODUCT_CATEGORY_DIM.VERTICAL AS VERTICAL
        WITH SYNONYMS = ('業界','セクター','市場','カテゴリグループ','ビジネス領域','ドメイン')
        COMMENT = '製品が属する業界・セクター（リテール、テクノロジー、製造など）',

    REGIONS.REGION_KEY AS REGION_KEY,

    REGIONS.REGION_NAME AS region_name
        WITH SYNONYMS = ('地域','テリトリー','エリア')
        COMMENT = '地域名',

    SALES.CUSTOMER_KEY AS CUSTOMER_KEY,
    SALES.PRODUCT_KEY  AS PRODUCT_KEY,
    SALES.REGION_KEY   AS REGION_KEY,
    SALES.SALES_REP_KEY AS SALES_REP_KEY,

    SALES.SALE_DATE AS date
        WITH SYNONYMS = ('日付','売上日','取引日')
        COMMENT = '売上が発生した日付',

    SALES.SALE_ID AS SALE_ID,

    SALES.SALE_MONTH AS MONTH(date)
        COMMENT = '売上月',

    SALES.SALE_YEAR AS YEAR(date)
        COMMENT = '売上年',

    SALES.VENDOR_KEY AS VENDOR_KEY,

    SALES_REPS.SALES_REP_KEY AS SALES_REP_KEY,

    SALES_REPS.SALES_REP_NAME AS REP_NAME
        WITH SYNONYMS = ('営業担当','営業','セールス担当')
        COMMENT = '営業担当者名',

    VENDORS.VENDOR_KEY AS VENDOR_KEY,

    VENDORS.VENDOR_NAME AS vendor_name
        WITH SYNONYMS = ('ベンダー','サプライヤー','プロバイダー')
        COMMENT = 'ベンダー名'
  )
  METRICS (
    SALES.AVERAGE_DEAL_SIZE AS AVG(sales.amount)
        COMMENT = '平均案件金額',

    SALES.AVERAGE_UNITS_PER_SALE AS AVG(sales.units)
        COMMENT = '1件あたり平均販売数量',

    SALES.TOTAL_DEALS AS COUNT(sales.sale_record)
        COMMENT = '案件数合計',

    SALES.TOTAL_REVENUE AS SUM(sales.amount)
        COMMENT = '売上金額合計',

    SALES.TOTAL_UNITS AS SUM(sales.units)
        COMMENT = '販売数量合計'
  )
  COMMENT = '売上分析およびパフォーマンス管理向けセマンティックビュー';

------------------------------
-- MARKETING SEMANTIC VIEW（日⽂）
------------------------------
CREATE OR REPLACE SEMANTIC VIEW MARKETING_SEMANTIC_VIEW
  TABLES (
    ACCOUNTS AS SF_ACCOUNTS PRIMARY KEY (ACCOUNT_ID)
        WITH SYNONYMS = ('顧客','アカウント','クライアント')
        COMMENT = '売上分析用の顧客アカウント情報',

    CAMPAIGNS AS MARKETING_CAMPAIGN_FACT PRIMARY KEY (CAMPAIGN_FACT_ID)
        WITH SYNONYMS = ('マーケティングキャンペーン','キャンペーンデータ')
        COMMENT = 'マーケティングキャンペーンのパフォーマンスデータ',

    CAMPAIGN_DETAILS AS CAMPAIGN_DIM PRIMARY KEY (CAMPAIGN_KEY)
        WITH SYNONYMS = ('キャンペーン情報','キャンペーン詳細')
        COMMENT = 'キャンペーン名や目的などを持つディメンション',

    CHANNELS AS CHANNEL_DIM PRIMARY KEY (CHANNEL_KEY)
        WITH SYNONYMS = ('マーケティングチャネル','チャネル')
        COMMENT = 'マーケティングチャネル情報',

    CONTACTS AS SF_CONTACTS PRIMARY KEY (CONTACT_ID)
        WITH SYNONYMS = ('リード','コンタクト','見込み客')
        COMMENT = 'キャンペーンから生成されたコンタクトレコード',

    CONTACTS_FOR_OPPORTUNITIES AS SF_CONTACTS PRIMARY KEY (CONTACT_ID)
        WITH SYNONYMS = ('案件コンタクト')
        COMMENT = 'リードではなく案件に紐づくコンタクトレコード',

    OPPORTUNITIES AS SF_OPPORTUNITIES PRIMARY KEY (OPPORTUNITY_ID)
        WITH SYNONYMS = ('案件','商談','パイプライン')
        COMMENT = '案件・売上金額の情報',

    PRODUCTS AS PRODUCT_DIM PRIMARY KEY (PRODUCT_KEY)
        WITH SYNONYMS = ('製品','商品')
        COMMENT = 'キャンペーン別分析用の製品ディメンション',

    REGIONS AS REGION_DIM PRIMARY KEY (REGION_KEY)
        WITH SYNONYMS = ('テリトリー','地域','マーケット')
        COMMENT = 'キャンペーン分析用の地域情報'
  )
  RELATIONSHIPS (
    CAMPAIGNS_TO_CHANNELS       AS CAMPAIGNS(CHANNEL_KEY)    REFERENCES CHANNELS(CHANNEL_KEY),
    CAMPAIGNS_TO_DETAILS        AS CAMPAIGNS(CAMPAIGN_KEY)   REFERENCES CAMPAIGN_DETAILS(CAMPAIGN_KEY),
    CAMPAIGNS_TO_PRODUCTS       AS CAMPAIGNS(PRODUCT_KEY)    REFERENCES PRODUCTS(PRODUCT_KEY),
    CAMPAIGNS_TO_REGIONS        AS CAMPAIGNS(REGION_KEY)     REFERENCES REGIONS(REGION_KEY),
    CONTACTS_TO_ACCOUNTS        AS CONTACTS(ACCOUNT_ID)      REFERENCES ACCOUNTS(ACCOUNT_ID),
    CONTACTS_TO_CAMPAIGNS       AS CONTACTS(CAMPAIGN_NO)     REFERENCES CAMPAIGNS(CAMPAIGN_FACT_ID),
    CONTACTS_TO_OPPORTUNITIES   AS CONTACTS_FOR_OPPORTUNITIES(OPPORTUNITY_ID) REFERENCES OPPORTUNITIES(OPPORTUNITY_ID),
    OPPORTUNITIES_TO_ACCOUNTS   AS OPPORTUNITIES(ACCOUNT_ID) REFERENCES ACCOUNTS(ACCOUNT_ID),
    OPPORTUNITIES_TO_CAMPAIGNS  AS OPPORTUNITIES(CAMPAIGN_ID) REFERENCES CAMPAIGNS(CAMPAIGN_FACT_ID)
  )
  FACTS (
    PUBLIC CAMPAIGNS.CAMPAIGN_RECORD     AS 1        COMMENT = 'キャンペーンアクティビティ件数',
    PUBLIC CAMPAIGNS.CAMPAIGN_SPEND      AS spend    COMMENT = 'マーケティング費用（ドル）',
    PUBLIC CAMPAIGNS.IMPRESSIONS         AS IMPRESSIONS      COMMENT = 'インプレッション数',
    PUBLIC CAMPAIGNS.LEADS_GENERATED     AS LEADS_GENERATED  COMMENT = '獲得リード数',
    PUBLIC CONTACTS.CONTACT_RECORD       AS 1        COMMENT = '生成されたコンタクト件数',
    PUBLIC OPPORTUNITIES.OPPORTUNITY_RECORD AS 1     COMMENT = '生成された案件件数',
    PUBLIC OPPORTUNITIES.REVENUE         AS AMOUNT   COMMENT = '案件売上金額（ドル）'
  )
  DIMENSIONS (
    PUBLIC ACCOUNTS.ACCOUNT_ID   AS ACCOUNT_ID,

    PUBLIC ACCOUNTS.ACCOUNT_NAME AS ACCOUNT_NAME
        WITH SYNONYMS = ('顧客名','クライアント名','会社名')
        COMMENT = '顧客アカウント名',

    PUBLIC ACCOUNTS.ACCOUNT_TYPE AS ACCOUNT_TYPE
        WITH SYNONYMS = ('顧客タイプ','アカウントカテゴリ')
        COMMENT = '顧客アカウント種別',

    PUBLIC ACCOUNTS.ANNUAL_REVENUE AS ANNUAL_REVENUE
        WITH SYNONYMS = ('顧客売上','年間売上')
        COMMENT = '顧客の年間売上',

    PUBLIC ACCOUNTS.EMPLOYEES AS EMPLOYEES
        WITH SYNONYMS = ('企業規模','従業員数')
        COMMENT = '顧客企業の従業員数',

    PUBLIC ACCOUNTS.INDUSTRY AS INDUSTRY
        WITH SYNONYMS = ('業界','セクター')
        COMMENT = '顧客の業界',

    PUBLIC ACCOUNTS.SALES_CUSTOMER_KEY AS CUSTOMER_KEY
        WITH SYNONYMS = ('顧客番号','顧客ID')
        COMMENT = 'Salesforceアカウントと顧客テーブルを紐づけるキー',

    PUBLIC CAMPAIGNS.CAMPAIGN_DATE AS date
        WITH SYNONYMS = ('日付','キャンペーン日')
        COMMENT = 'キャンペーンアクティビティの日付',

    PUBLIC CAMPAIGNS.CAMPAIGN_FACT_ID AS CAMPAIGN_FACT_ID,
    PUBLIC CAMPAIGNS.CAMPAIGN_KEY     AS CAMPAIGN_KEY,

    PUBLIC CAMPAIGNS.CAMPAIGN_MONTH AS MONTH(date)
        COMMENT = 'キャンペーン月',

    PUBLIC CAMPAIGNS.CAMPAIGN_YEAR AS YEAR(date)
        COMMENT = 'キャンペーン年',

    PUBLIC CAMPAIGNS.CHANNEL_KEY AS CHANNEL_KEY,

    PUBLIC CAMPAIGNS.PRODUCT_KEY AS PRODUCT_KEY
        WITH SYNONYMS = ('製品ID','製品識別子')
        COMMENT = 'ターゲット製品の識別子',

    PUBLIC CAMPAIGNS.REGION_KEY AS REGION_KEY,

    PUBLIC CAMPAIGN_DETAILS.CAMPAIGN_KEY AS CAMPAIGN_KEY,

    PUBLIC CAMPAIGN_DETAILS.CAMPAIGN_NAME AS CAMPAIGN_NAME
        WITH SYNONYMS = ('キャンペーン','キャンペーン名')
        COMMENT = 'マーケティングキャンペーン名',

    PUBLIC CAMPAIGN_DETAILS.CAMPAIGN_OBJECTIVE AS OBJECTIVE
        WITH SYNONYMS = ('目的','ゴール','狙い')
        COMMENT = 'キャンペーン目的（認知向上／ブランディング／リード獲得／製品ローンチ／継続利用／アップセル など）',

    PUBLIC CHANNELS.CHANNEL_KEY AS CHANNEL_KEY,

    PUBLIC CHANNELS.CHANNEL_NAME AS CHANNEL_NAME
        WITH SYNONYMS = ('チャネル','マーケティングチャネル')
        COMMENT = 'マーケティングチャネル名',

    PUBLIC CONTACTS.ACCOUNT_ID AS ACCOUNT_ID,
    PUBLIC CONTACTS.CAMPAIGN_NO AS CAMPAIGN_NO,
    PUBLIC CONTACTS.CONTACT_ID AS CONTACT_ID,

    PUBLIC CONTACTS.DEPARTMENT AS DEPARTMENT
        WITH SYNONYMS = ('部署','部門','事業部')
        COMMENT = 'コンタクトの所属部署',

    PUBLIC CONTACTS.EMAIL AS EMAIL
        WITH SYNONYMS = ('メール','メールアドレス')
        COMMENT = 'コンタクトのメールアドレス',

    PUBLIC CONTACTS.FIRST_NAME AS FIRST_NAME
        WITH SYNONYMS = ('名','ファーストネーム','担当者名')
        COMMENT = 'コンタクトの名',

    PUBLIC CONTACTS.LAST_NAME AS LAST_NAME
        WITH SYNONYMS = ('姓','ラストネーム')
        COMMENT = 'コンタクトの姓',

    PUBLIC CONTACTS.LEAD_SOURCE AS LEAD_SOURCE
        WITH SYNONYMS = ('リードソース','流入元')
        COMMENT = 'コンタクトがどの経路で獲得されたか',

    PUBLIC CONTACTS.OPPORTUNITY_ID AS OPPORTUNITY_ID,

    PUBLIC CONTACTS.TITLE AS TITLE
        WITH SYNONYMS = ('役職','職位')
        COMMENT = 'コンタクトの役職',

    PUBLIC OPPORTUNITIES.ACCOUNT_ID AS ACCOUNT_ID,

    PUBLIC OPPORTUNITIES.CAMPAIGN_ID AS CAMPAIGN_ID
        WITH SYNONYMS = ('キャンペーンFACT ID','マーケティングキャンペーンID')
        COMMENT = '案件を起点とするマーケティングキャンペーンのID',

    PUBLIC OPPORTUNITIES.CLOSE_DATE AS CLOSE_DATE
        WITH SYNONYMS = ('クローズ日','予定クローズ日')
        COMMENT = '案件の予定または実際のクローズ日',

    PUBLIC OPPORTUNITIES.OPPORTUNITY_ID AS OPPORTUNITY_ID,

    PUBLIC OPPORTUNITIES.OPPORTUNITY_LEAD_SOURCE AS lead_source
        WITH SYNONYMS = ('案件ソース','商談ソース')
        COMMENT = '案件の獲得経路',

    PUBLIC OPPORTUNITIES.OPPORTUNITY_NAME AS OPPORTUNITY_NAME
        WITH SYNONYMS = ('案件名','商談名')
        COMMENT = '案件名',

    PUBLIC OPPORTUNITIES.OPPORTUNITY_STAGE AS STAGE_NAME
        COMMENT = '案件ステージ名（Closed Won は売上確定を示す）',

    PUBLIC OPPORTUNITIES.OPPORTUNITY_TYPE AS TYPE
        WITH SYNONYMS = ('案件タイプ','商談タイプ')
        COMMENT = '案件の種類',

    PUBLIC OPPORTUNITIES.SALES_SALE_ID AS SALE_ID
        WITH SYNONYMS = ('売上ID','請求書番号')
        COMMENT = 'sales_fact テーブルの Sales_ID。案件と売上レコードを紐づけるキー。',

    PUBLIC PRODUCTS.PRODUCT_CATEGORY AS CATEGORY_NAME
        WITH SYNONYMS = ('カテゴリ','製品カテゴリ')
        COMMENT = '製品カテゴリ',

    PUBLIC PRODUCTS.PRODUCT_KEY AS PRODUCT_KEY,

    -- PUBLIC PRODUCTS.PRODUCT_NAME AS PRODUCT_NAME
    --     WITH SYNONYMS = ('製品','商品','製品タイトル')
    --     COMMENT = 'プロモーション対象製品名',

    PUBLIC PRODUCTS.PRODUCT_VERTICAL AS VERTICAL
        WITH SYNONYMS = ('バーティカル','業界')
        COMMENT = '製品が属するビジネスバーティカル',

    PUBLIC REGIONS.REGION_KEY AS REGION_KEY,

    PUBLIC REGIONS.REGION_NAME AS REGION_NAME
        WITH SYNONYMS = ('地域','マーケット','テリトリー')
        COMMENT = '地域名'
  )
  METRICS (
    PUBLIC CAMPAIGNS.AVERAGE_SPEND AS AVG(CAMPAIGNS.spend)
        COMMENT = '平均キャンペーン費用',

    PUBLIC CAMPAIGNS.TOTAL_CAMPAIGNS AS COUNT(CAMPAIGNS.campaign_record)
        COMMENT = 'キャンペーンアクティビティ件数合計',

    PUBLIC CAMPAIGNS.TOTAL_IMPRESSIONS AS SUM(CAMPAIGNS.impressions)
        COMMENT = 'インプレッション合計',

    PUBLIC CAMPAIGNS.TOTAL_LEADS AS SUM(CAMPAIGNS.leads_generated)
        COMMENT = 'キャンペーン起点のリード獲得数合計',

    PUBLIC CAMPAIGNS.TOTAL_SPEND AS SUM(CAMPAIGNS.spend)
        COMMENT = 'マーケティング費用合計',

    PUBLIC CONTACTS.TOTAL_CONTACTS AS COUNT(CONTACTS.contact_record)
        COMMENT = 'キャンペーンから生成されたコンタクト数合計',

    PUBLIC OPPORTUNITIES.AVERAGE_DEAL_SIZE AS AVG(OPPORTUNITIES.revenue)
        COMMENT = 'マーケ起点案件の平均案件金額',

    PUBLIC OPPORTUNITIES.CLOSED_WON_REVENUE AS SUM(
        CASE WHEN OPPORTUNITIES.opportunity_stage = 'Closed Won'
             THEN OPPORTUNITIES.revenue ELSE 0 END)
        COMMENT = 'Closed Won 案件からの売上金額',

    -- PUBLIC OPPORTUNITIES.TOTAL_OPPORTUNITIES AS COUNT(OPPORTUNITIES.opportunity_record)
    --     COMMENT = 'マーケティング起点の案件数合計',

    PUBLIC OPPORTUNITIES.TOTAL_REVENUE AS SUM(OPPORTUNITIES.revenue)
        COMMENT = 'マーケティング起点案件からの売上合計'
  )
  COMMENT = 'マーケティングキャンペーン分析およびROI可視化向けセマンティックビュー';

-- 動作確認
SHOW SEMANTIC VIEWS;

-- 不足部分をGUIからのセマンティックビューで編集してみよう

--　作成したセマンティックビューに対してSQLでクエリしてみよう。

-- マーケティングチャネル（ディメンション）ごとに、リード数、コンタクト数、売り上げなどの指標（メトリクス）を集計するクエリ
SELECT
  CHANNEL_NAME,          -- チャネル名（DIMENSION）
  TOTAL_SPEND,           -- マーケティング費用合計
  TOTAL_LEADS,           -- リード獲得数合計
  TOTAL_CONTACTS,        -- 生成コンタクト数合計
  TOTAL_REVENUE          -- マーケ起点案件からの売上合計
FROM SEMANTIC_VIEW(
  SV_VHOL_DB.VHOL_SCHEMA.MARKETING_SEMANTIC_VIEW
  DIMENSIONS
    CHANNELS.CHANNEL_NAME --Dimensionsで切り口を指定
  METRICS --metricsで集計したい指標を集計
    CAMPAIGNS.TOTAL_SPEND,
    CAMPAIGNS.TOTAL_LEADS,
    CONTACTS.TOTAL_CONTACTS,
    OPPORTUNITIES.TOTAL_REVENUE
)
ORDER BY TOTAL_SPEND DESC;

-- 作成したセマンティックビューに対して、PlayGroundから動作確認してみよう
-- 2025年に最も多くの売上を生み出したマーケティングキャンペーン名はどれですか？チャネル別にマーケティングROIとリード単価を表示してください。
