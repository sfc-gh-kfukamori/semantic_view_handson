-- ============================================
-- Snowflake Intelligenceからセマンティックビューを利用する
-- ============================================


-- ============================================
-- コンテキスト設定
-- ============================================

-- このハンズオン環境の初期セットアップやエージェント作成を行うため、
-- 権限の強い accountadmin ロールに切り替え
USE ROLE accountadmin;

-- 対象となるデータベースとスキーマをコンテキストに設定
USE DATABASE SV_VHOL_DB;
USE SCHEMA VHOL_SCHEMA;

-- agentic_analytics_vhol_role に accountadmin ロールを付与
-- （accountadmin ロールでログインしているユーザも、この専用ロールを使えるようにする）
GRANT ROLE agentic_analytics_vhol_role TO ROLE accountadmin;

-- ============================================
-- AGENTS スキーマとネットワーク関連オブジェクトの作成
-- ============================================

-- エージェント（Snowflake Intelligence Agent）を配置するためのスキーマを作成
CREATE OR REPLACE SCHEMA SV_VHOL_DB.AGENTS;

-- -- Cortex / エージェントが外部にアクセスするためのネットワークルールを作成
-- -- 0.0.0.0:80 / 443 に対する EGRESS（外向き）通信を許可
-- CREATE OR REPLACE NETWORK RULE SV_VHOL_DB.AGENTS.Snowflake_intelligence_WebAccessRule
--   MODE = EGRESS
--   TYPE = HOST_PORT
--   VALUE_LIST = ('0.0.0.0:80', '0.0.0.0:443');

-- -- 上記ネットワークルールを利用する External Access Integration を作成
-- -- エージェントが外部 HTTP(S) へアクセスする際に使用される
-- CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION Snowflake_intelligence_ExternalAccess_Integration
--   ALLOWED_NETWORK_RULES = (SV_VHOL_DB.AGENTS.Snowflake_intelligence_WebAccessRule)
--   ENABLED = true;

-- ============================================
-- 権限付与
-- ============================================

-- デモ用データベース SV_VHOL_DB に対する全権限を付与
GRANT ALL PRIVILEGES ON DATABASE SV_VHOL_DB TO ROLE agentic_analytics_vhol_role;

-- AGENTS スキーマに対する全権限を付与（エージェントオブジェクトの作成・管理用）
GRANT ALL PRIVILEGES ON SCHEMA SV_VHOL_DB.AGENTS TO ROLE agentic_analytics_vhol_role;

-- VHOL_SCHEMA スキーマに対する全権限を付与（セマンティックビューや基盤テーブル用）
GRANT ALL PRIVILEGES ON SCHEMA SV_VHOL_DB.VHOL_SCHEMA TO ROLE agentic_analytics_vhol_role;

-- AGENTS スキーマ内で AGENT オブジェクトを作成できるように権限を付与
GRANT CREATE AGENT ON SCHEMA SV_VHOL_DB.AGENTS TO ROLE agentic_analytics_vhol_role;

-- -- External Access Integration の使用権限を付与
-- GRANT USAGE ON INTEGRATION Snowflake_intelligence_ExternalAccess_Integration
--   TO ROLE agentic_analytics_vhol_role;

-- -- ネットワークルールの使用権限を付与
-- GRANT USAGE ON NETWORK RULE SV_VHOL_DB.AGENTS.Snowflake_intelligence_WebAccessRule
--   TO ROLE agentic_analytics_vhol_role;

-- ============================================
-- 作業ロール・スキーマをエージェント用に切り替え
-- ============================================

-- ここからは実際にエージェントを作成・操作するロールで作業
USE ROLE agentic_analytics_vhol_role;

-- データベースと AGENTS スキーマをコンテキストに設定
USE DATABASE SV_VHOL_DB;
USE SCHEMA AGENTS;

-- ============================================
-- エージェントの作成
-- ============================================

-- -- Agent オブジェクトを作成
-- -- このHands onで作成した3つセマンティックビューをCortex Analystからの呼び出しをツールとして定義します。
-- CREATE OR REPLACE AGENT SV_VHOL_DB.AGENTS.Agentic_Analytics_VHOL_Chatbot
-- -- エージェントの表示名などのプロフィール設定
-- WITH PROFILE='{ "display_name": "セマンティックビューハンズオンラボ チャットbot" }'
--     COMMENT='Sales, Marketing, HR, Finance に関する社内データの質問に回答するエージェントです。'
-- -- ここから JSON 形式でエージェント仕様を定義
-- FROM SPECIFICATION 
-- \[
-- {
--   "models": {
--     "orchestration": ""
--   },
--   "instructions": {
--     "response": "Answer user questions about Sales, Marketing, HR, and Finance using the provided semantic views. When appropriate, ask clarifying questions, generate safe SQL via the tools, and summarize results clearly."
--   },
--   "tools": [
--     {
--       "tool_spec": {
--         "type": "cortex_analyst_text_to_sql",
--         "name": "Query Finance Datamart",
--         "description": "Allows users to query finance data for revenue & expenses."
--       }
--     },
--     {
--       "tool_spec": {
--         "type": "cortex_analyst_text_to_sql",
--         "name": "Query Sales Datamart",
--         "description": "Allows users to query sales data such as products and sales reps."
--       }
--     },
--     {
--       "tool_spec": {
--         "type": "cortex_analyst_text_to_sql",
--         "name": "Query HR Datamart",
--         "description": "Allows users to query HR data; employee_name includes sales rep names."
--       }
--     },
--     {
--       "tool_spec": {
--         "type": "cortex_analyst_text_to_sql",
--         "name": "Query Marketing Datamart",
--         "description": "Allows users to query campaigns, channels, impressions, and spend."
--       }
--     }
--   ],
--   "tool_resources": {
--     "Query Finance Datamart": {
--       "semantic_view": "SV_VHOL_DB.VHOL_SCHEMA.FINANCE_SEMANTIC_VIEW"
--     },
--     "Query HR Datamart": {
--       "semantic_view": "SV_VHOL_DB.VHOL_SCHEMA.HR_SEMANTIC_VIEW"
--     },
--     "Query Marketing Datamart": {
--       "semantic_view": "SV_VHOL_DB.VHOL_SCHEMA.MARKETING_SEMANTIC_VIEW"
--     },
--     "Query Sales Datamart": {
--       "semantic_view": "SV_VHOL_DB.VHOL_SCHEMA.SALES_SEMANTIC_VIEW"
--     }
--   }
-- }
-- \]
-- ;

-- エージェントの作成
CREATE OR REPLACE AGENT SV_VHOL_DB.AGENTS.Agentic_Analytics_VHOL_Chatbot
WITH PROFILE = '{ "display_name": "セマンティックビューハンズオンラボ チャットbot" }'
    COMMENT = 'Sales、Marketing、HR、Finance に関する社内データの質問に回答するエージェントです。'
FROM SPECIFICATION 
$$
{
  "models": {
    "orchestration": ""
  },
  "instructions": {
    "response": "Sales、Marketing、HR、および Finance に関するユーザーからの質問に対して、指定されたセマンティックビューを用いて日本語で回答してください。必要に応じて確認のための質問を行い、ツールを使って安全な SQL を生成し、その結果を分かりやすく要約して伝えてください。"
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Finance Datamart",
        "description": "売上や費用などの財務データを問い合わせるためのツールです。"
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Sales Datamart",
        "description": "製品別・営業担当者別など、売上データを問い合わせるためのツールです。"
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query HR Datamart",
        "description": "従業員情報（employee_name には営業担当者名も含まれます）など、人事データを問い合わせるためのツールです。"
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Marketing Datamart",
        "description": "キャンペーン、チャネル、インプレッション、費用などのマーケティングデータを問い合わせるためのツールです。"
      }
    }
  ],
  "tool_resources": {
    "Query Finance Datamart": {
      "semantic_view": "SV_VHOL_DB.VHOL_SCHEMA.FINANCE_SEMANTIC_VIEW"
    },
    "Query HR Datamart": {
      "semantic_view": "SV_VHOL_DB.VHOL_SCHEMA.HR_SEMANTIC_VIEW"
    },
    "Query Marketing Datamart": {
      "semantic_view": "SV_VHOL_DB.VHOL_SCHEMA.MARKETING_SEMANTIC_VIEW"
    },
    "Query Sales Datamart": {
      "semantic_view": "SV_VHOL_DB.VHOL_SCHEMA.SALES_SEMANTIC_VIEW"
    }
  }
}
$$
;

//作成されたAgentを格納するとともにSample Questionsを入力しよう
-- 直近四半期の部門別の費用と収益を教えてください。
-- 先月の製品別売上トップ10を教えてください。
-- 従業員数合計で上位10件の部門はどこですか？
-- 2025年に最も多くの売上を生み出したマーケティングキャンペーン名はどれですか？チャネル別にマーケティングROIとリード単価も教えてください。
