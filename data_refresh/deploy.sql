/*
 * Deploy the Synthetic Data Refresh Streamlit app.
 * Run from Snowsight or SnowSQL.
 */

USE DATABASE BNK;
USE SCHEMA PUBLIC;
USE WAREHOUSE BNK_WH;

CREATE STAGE IF NOT EXISTS BNK.PUBLIC.DATA_REFRESH_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Streamlit app files for synthetic data refresh tool';

-- Upload (run from local terminal — set LOCAL_PATH to your checkout location):
-- PUT file://<LOCAL_PATH>/data_refresh/app.py @BNK.PUBLIC.DATA_REFRESH_STAGE OVERWRITE=TRUE AUTO_COMPRESS=FALSE;

CREATE OR REPLACE STREAMLIT BNK.PUBLIC.DATA_REFRESH_APP
    ROOT_LOCATION = '@BNK.PUBLIC.DATA_REFRESH_STAGE'
    MAIN_FILE = 'app.py'
    QUERY_WAREHOUSE = 'BNK_WH'
    TITLE = 'Synthetic Data Manager'
    COMMENT = 'Internal tool to keep synthetic demo data current via date shifting';
