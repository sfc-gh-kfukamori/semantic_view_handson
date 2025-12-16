## 全体像：どんなデータ基盤ができるか

### データベース・スキーマ

* **SV_VHOL_DB.VHOL_SCHEMA** に、分析用の 20 テーブルが作成されます。
* テーブルは大きく次の 3 区分です。
  * **ディメンションテーブル（13 個）**
  * **ファクトテーブル（4 個）**
  * **Salesforce CRM テーブル（3 個）**

### ドメイン別に見ると

* **Sales（売上）領域**
  * ファクト: `sales_fact`
  * ディメンション: `product_dim`, `product_category_dim`, `customer_dim`, `vendor_dim`, `region_dim`, `sales_rep_dim`
* **Finance（財務）領域**
  * ファクト: `finance_transactions`
  * ディメンション: `account_dim`, `department_dim`, `vendor_dim`, `product_dim`, `customer_dim`, `employee_dim`（承認者）
* **Marketing（マーケティング）領域**
  * ファクト: `marketing_campaign_fact`
  * ディメンション: `campaign_dim`, `channel_dim`, `product_dim`, `region_dim`
* **HR（人事）領域**
  * ファクト: `hr_employee_fact`
  * ディメンション: `employee_dim`, `department_dim`, `job_dim`, `location_dim`
* **Salesforce CRM**
  * `sf_accounts`（顧客アカウント）
  * `sf_opportunities`（案件）
  * `sf_contacts`（コンタクト）

### モデリングのイメージ

* 各ファクトテーブルは、**キーでディメンションテーブルにぶら下がるスター・スキーマ**になっています。
  * `sales_fact.customer_key → customer_dim.customer_key`
  * `finance_transactions.department_key → department_dim.department_key`
  * `hr_employee_fact.employee_key → employee_dim.employee_key`
* Salesforce テーブルは、
  * `sf_accounts.customer_key → customer_dim.customer_key`
  * `sf_opportunities.sale_id → sales_fact.sale_id`
  などで**基盤テーブルとゆるく連携**できるような設計です。

---

## 各テーブルの説明（テーブルごと）

### 1. プロダクト関連

**product_category_dim**

* **製品カテゴリのディメンションテーブル**です。
* `category_key`: カテゴリの主キー  
* `category_name`: カテゴリ名（例: Electronics, Clothing）  
* `vertical`: ビジネス上のバーティカル（Retail, SaaS など）

**product_dim**

* **製品マスタのディメンションテーブル**です。
* `product_key`: 製品の主キー  
* `product_name`: 製品名  
* `category_key` / `category_name` / `vertical`: `product_category_dim` に対応するカテゴリ情報を冗長保持

---

### 2. ベンダー・顧客・地域・担当者

**vendor_dim**

* **仕入先・サプライヤーのディメンションテーブル**です。
* `vendor_key`: ベンダーID  
* `vendor_name`: ベンダー名  
* `vertical`: ベンダーが属する業種・業界  
* 住所情報（`address`, `city`, `state`, `zip`）も保持

**customer_dim**

* **顧客マスタのディメンションテーブル**です。
* `customer_key`: 顧客ID  
* `customer_name`: 顧客名  
* `industry`, `vertical`: 顧客の業界・バーティカル  
* 住所情報も保持し、Sales / Finance の両方から参照されます。

**region_dim**

* **地域（リージョン）のディメンションテーブル**です。
* `region_key`: 地域ID  
* `region_name`: 地域名（例: East, West, APAC など）

**sales_rep_dim**

* **営業担当者（Sales Rep）のディメンションテーブル**です。
* `sales_rep_key`: 営業担当のID  
* `rep_name`: 氏名  
* `hire_date`: 採用日（勤続年数分析などに利用可能）

---

### 3. ファイナンス（会計・財務）

**account_dim**

* **会計上の勘定科目ディメンション**です。
* `account_key`: 勘定科目ID  
* `account_name`: 勘定科目名（Revenue, Expenses など）  
* `account_type`: 種別（Income / Expense など）

**department_dim**

* **部門マスタのディメンションテーブル**です。
* `department_key`: 部門ID  
* `department_name`: 部門名（Sales, Marketing, HR など）

---

### 4. マーケティング

**campaign_dim**

* **マーケティングキャンペーンのディメンション**です。
* `campaign_key`: キャンペーンID  
* `campaign_name`: キャンペーン名  
* `objective`: 目的（Awareness, Lead Gen, Upsell など）

**channel_dim**

* **マーケティングチャネルのディメンション**です。
* `channel_key`: チャネルID  
* `channel_name`: チャネル名（Email, Social, Web, Events など）

---

### 5. HR（人事）

**employee_dim**

* **従業員マスタのディメンション**です。
* `employee_key`: 従業員ID  
* `employee_name`: 氏名  
* `gender`: 性別コード（M/F など）  
* `hire_date`: 採用日

**job_dim**

* **職位（ジョブロール）のディメンション**です。
* `job_key`: 職位ID  
* `job_title`: 役職名（Engineer, Manager など）  
* `job_level`: レベル（等級）情報

**location_dim**

* **勤務地・拠点のディメンション**です。
* `location_key`: ロケーションID  
* `location_name`: 拠点名（都市＋州など）

---

### 6. ファクトテーブル群

**sales_fact**

* **売上トランザクションのファクトテーブル**です。
* 1 行 = 1 売上トランザクション（`sale_id`）
* 主なカラム:
  * `date`: 取引日
  * `customer_key`, `product_key`, `sales_rep_key`, `region_key`, `vendor_key`: 各ディメンションへの外部キー
  * `amount`: 売上金額
  * `units`: 販売数量
* Sales Semantic View などの売上分析の中心となるテーブルです。

**finance_transactions**

* **財務トランザクションのファクトテーブル**です。
* 1 行 = 1 会計トランザクション（`transaction_id`）
* 主なカラム:
  * `date`: 取引日  
  * `account_key`, `department_key`, `vendor_key`, `product_key`, `customer_key`: 各ディメンションへの外部キー  
  * `amount`: 金額  
  * `approval_status`: 承認ステータス（Approved / Pending / Rejected）  
  * `procurement_method`: 調達方法（RFP / Quotes / Emergency / Contract）  
  * `approver_id`: 承認者（`employee_dim.employee_key` への FK）  
  * `approval_date`, `purchase_order_number`, `contract_reference`: コンプライアンス・トラッキング向けの付帯情報
* Finance Semantic View で、**支出分析・コンプライアンス分析**を行うベースになります。

**marketing_campaign_fact**

* **マーケティングキャンペーン成果のファクトテーブル**です。
* 1 行 = ある日付 × キャンペーン × チャネル × 地域 × 製品 の組み合わせ。
* 主なカラム:
  * `date`
  * `campaign_key`, `product_key`, `channel_key`, `region_key`
  * `spend`: 広告費
  * `leads_generated`: 獲得リード数
  * `impressions`: インプレッション数
* ROI や CPL（Cost per Lead）などのマーケ指標計算に利用されます。

**hr_employee_fact**

* **従業員の状態（給与・離職）の時系列ファクトテーブル**です。
* 1 行 = ある日付における従業員の状態（給与・部署・職位・勤務地など）。
* 主なカラム:
  * `date`
  * `employee_key`, `department_key`, `job_key`, `location_key`
  * `salary`: 給与
  * `attrition_flag`: 離職フラグ（1: その時点までに離職 など）
* 平均給与推移、部門別離職率、勤務年数などの HR 分析に利用されます。

---

### 7. Salesforce CRM テーブル

**sf_accounts**

* **Salesforce のアカウント（顧客）テーブル**です。
* 主なカラム:
  * `account_id`: SF のアカウントID（主キー）
  * `account_name`: アカウント名
  * `customer_key`: `customer_dim.customer_key` とのブリッジ
  * `industry`, `vertical`, `billing_*`: 業界と請求先住所
  * `account_type`, `annual_revenue`, `employees`: アカウント属性
  * `created_date`: レコード作成日

**sf_opportunities**

* **Salesforce の商談・案件テーブル**です。
* 主なカラム:
  * `opportunity_id`: SF の案件ID（主キー）
  * `sale_id`: `sales_fact.sale_id` へのリンク（受注した売上との紐付け）
  * `account_id`: `sf_accounts.account_id` への外部キー
  * `opportunity_name`, `stage_name`, `amount`, `probability`, `close_date`, `lead_source`, `type`, `campaign_id`
* パイプラインや成約率分析、キャンペーン別売上分析のベースになります。

**sf_contacts**

* **Salesforce のコンタクト（人物）テーブル**です。
* 主なカラム:
  * `contact_id`: SF のコンタクトID（主キー）
  * `opportunity_id`: `sf_opportunities.opportunity_id` への外部キー
  * `account_id`: `sf_accounts.account_id` への外部キー
  * `first_name`, `last_name`, `email`, `phone`, `title`, `department`
  * `lead_source`: 流入元
  * `campaign_no`: 対応するマーケキャンペーン番号
* マーケ～Sales～顧客接点までをつなぐ「人物」視点の分析に使えます。

---

このセットをベースに、Sales / Marketing / Finance / HR の **Semantic View** を載せて、  
Cortex Analyst や Intelligence Agent から「部門横断のビジネス質問」に答える、というのがこの VHOL のゴールになっています。

ER図やサンプルクエリ、各テーブルのサンプルデータを作成しましょうか？
