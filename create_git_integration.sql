use role accountadmin;

//Publicなレポジトリとの連携用
CREATE OR REPLACE API INTEGRATION git_integration_for_public_repo
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/')
  ENABLED = TRUE;
