-- TPC-E schema for GridGain 9.
-- Adapted from tpce-mysql scripts/mysql/1_create_table.sql.
--
-- Key differences from MySQL:
--   - Explicit PRIMARY KEY on every table (GridGain requirement)
--   - Zone assignments with STORAGE PROFILES
--   - COLOCATE BY for related tables
--   - No AUTO_INCREMENT, ENUM, MEDIUMBLOB, CHECK constraints, or TINYINT(1)
--   - MEDIUMINT -> INT, TINYINT -> SMALLINT, BIGINT(N) -> BIGINT
--   - MEDIUMBLOB -> VARCHAR(10000) for ni_item (news body text)
--   - DATE stays as DATE, DATETIME -> TIMESTAMP
--   - All CHAR(N) -> VARCHAR(N) for safer handling

-- -----------------------------------------------------------------------
-- Zones
-- -----------------------------------------------------------------------
CREATE ZONE IF NOT EXISTS tpce_zone (PARTITIONS 64, REPLICAS 3) STORAGE PROFILES ['default'];
CREATE ZONE IF NOT EXISTS tpce_fixed_zone (PARTITIONS 1, REPLICAS 3) STORAGE PROFILES ['default'];

-- -----------------------------------------------------------------------
-- Reference / fixed-size tables (single partition zone)
-- -----------------------------------------------------------------------

CREATE TABLE status_type (
  st_id    VARCHAR(4)  NOT NULL,
  st_name  VARCHAR(10) NOT NULL,
  PRIMARY KEY (st_id)
) ZONE tpce_fixed_zone;

CREATE TABLE trade_type (
  tt_id      VARCHAR(3)  NOT NULL,
  tt_name    VARCHAR(12) NOT NULL,
  tt_is_sell SMALLINT    NOT NULL,
  tt_is_mrkt SMALLINT    NOT NULL,
  PRIMARY KEY (tt_id)
) ZONE tpce_fixed_zone;

CREATE TABLE zip_code (
  zc_code VARCHAR(12) NOT NULL,
  zc_town VARCHAR(80) NOT NULL,
  zc_div  VARCHAR(80) NOT NULL,
  PRIMARY KEY (zc_code)
) ZONE tpce_fixed_zone;

CREATE TABLE address (
  ad_id      BIGINT      NOT NULL,
  ad_line1   VARCHAR(80),
  ad_line2   VARCHAR(80),
  ad_zc_code VARCHAR(12) NOT NULL,
  ad_ctry    VARCHAR(80),
  PRIMARY KEY (ad_id)
) ZONE tpce_fixed_zone;

CREATE TABLE sector (
  sc_id   VARCHAR(2)  NOT NULL,
  sc_name VARCHAR(30) NOT NULL,
  PRIMARY KEY (sc_id)
) ZONE tpce_fixed_zone;

CREATE TABLE industry (
  in_id    VARCHAR(2)  NOT NULL,
  in_name  VARCHAR(50) NOT NULL,
  in_sc_id VARCHAR(2)  NOT NULL,
  PRIMARY KEY (in_id)
) ZONE tpce_fixed_zone;

CREATE TABLE exchange (
  ex_id       VARCHAR(6)   NOT NULL,
  ex_name     VARCHAR(100) NOT NULL,
  ex_num_symb INT          NOT NULL,
  ex_open     SMALLINT     NOT NULL,
  ex_close    SMALLINT     NOT NULL,
  ex_desc     VARCHAR(150),
  ex_ad_id    BIGINT       NOT NULL,
  PRIMARY KEY (ex_id)
) ZONE tpce_fixed_zone;

CREATE TABLE charge (
  ch_tt_id  VARCHAR(3)    NOT NULL,
  ch_c_tier SMALLINT      NOT NULL,
  ch_chrg   DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (ch_tt_id, ch_c_tier)
) ZONE tpce_fixed_zone;

CREATE TABLE commission_rate (
  cr_c_tier  SMALLINT      NOT NULL,
  cr_tt_id   VARCHAR(3)    NOT NULL,
  cr_ex_id   VARCHAR(6)    NOT NULL,
  cr_from_qty INT           NOT NULL,
  cr_to_qty   INT           NOT NULL,
  cr_rate     DECIMAL(5,2)  NOT NULL,
  PRIMARY KEY (cr_c_tier, cr_tt_id, cr_ex_id, cr_from_qty)
) ZONE tpce_fixed_zone;

CREATE TABLE taxrate (
  tx_id   VARCHAR(4)   NOT NULL,
  tx_name VARCHAR(50)  NOT NULL,
  tx_rate DECIMAL(6,5) NOT NULL,
  PRIMARY KEY (tx_id)
) ZONE tpce_fixed_zone;

-- -----------------------------------------------------------------------
-- Company / Market tables (partitioned zone)
-- -----------------------------------------------------------------------

CREATE TABLE company (
  co_id        BIGINT       NOT NULL,
  co_st_id     VARCHAR(4)   NOT NULL,
  co_name      VARCHAR(60)  NOT NULL,
  co_in_id     VARCHAR(2)   NOT NULL,
  co_sp_rate   VARCHAR(4)   NOT NULL,
  co_ceo       VARCHAR(46)  NOT NULL,
  co_ad_id     BIGINT       NOT NULL,
  co_desc      VARCHAR(150) NOT NULL,
  co_open_date DATE         NOT NULL,
  PRIMARY KEY (co_id)
) ZONE tpce_zone;

CREATE TABLE company_competitor (
  cp_co_id      BIGINT     NOT NULL,
  cp_comp_co_id BIGINT     NOT NULL,
  cp_in_id      VARCHAR(2) NOT NULL,
  PRIMARY KEY (cp_co_id, cp_comp_co_id, cp_in_id)
) ZONE tpce_zone;

CREATE TABLE security (
  s_symb           VARCHAR(15)   NOT NULL,
  s_issue          VARCHAR(6)    NOT NULL,
  s_st_id          VARCHAR(4)    NOT NULL,
  s_name           VARCHAR(70)   NOT NULL,
  s_ex_id          VARCHAR(6)    NOT NULL,
  s_co_id          BIGINT        NOT NULL,
  s_num_out        BIGINT        NOT NULL,
  s_start_date     DATE          NOT NULL,
  s_exch_date      DATE          NOT NULL,
  s_pe             DECIMAL(10,2) NOT NULL,
  s_52wk_high      DECIMAL(8,2)  NOT NULL,
  s_52wk_high_date DATE          NOT NULL,
  s_52wk_low       DECIMAL(8,2)  NOT NULL,
  s_52wk_low_date  DATE          NOT NULL,
  s_dividend       DECIMAL(10,2) NOT NULL,
  s_yield          DECIMAL(5,2)  NOT NULL,
  PRIMARY KEY (s_symb)
) ZONE tpce_zone;

CREATE TABLE daily_market (
  dm_date   DATE          NOT NULL,
  dm_s_symb VARCHAR(15)   NOT NULL,
  dm_close  DECIMAL(8,2)  NOT NULL,
  dm_high   DECIMAL(8,2)  NOT NULL,
  dm_low    DECIMAL(8,2)  NOT NULL,
  dm_vol    BIGINT        NOT NULL,
  PRIMARY KEY (dm_s_symb, dm_date)
) ZONE tpce_zone;

CREATE TABLE financial (
  fi_co_id          BIGINT         NOT NULL,
  fi_year           SMALLINT       NOT NULL,
  fi_qtr            SMALLINT       NOT NULL,
  fi_qtr_start_date DATE           NOT NULL,
  fi_revenue        DECIMAL(15,2)  NOT NULL,
  fi_net_earn       DECIMAL(15,2)  NOT NULL,
  fi_basic_eps      DECIMAL(10,2)  NOT NULL,
  fi_dilut_eps      DECIMAL(10,2)  NOT NULL,
  fi_margin         DECIMAL(10,2)  NOT NULL,
  fi_inventory      DECIMAL(15,2)  NOT NULL,
  fi_assets         DECIMAL(15,2)  NOT NULL,
  fi_liability      DECIMAL(15,2)  NOT NULL,
  fi_out_basic      BIGINT         NOT NULL,
  fi_out_dilut      BIGINT         NOT NULL,
  PRIMARY KEY (fi_co_id, fi_year, fi_qtr)
) ZONE tpce_zone;

CREATE TABLE last_trade (
  lt_s_symb     VARCHAR(15)  NOT NULL,
  lt_dts        TIMESTAMP    NOT NULL,
  lt_price      DECIMAL(8,2) NOT NULL,
  lt_open_price DECIMAL(8,2) NOT NULL,
  lt_vol        BIGINT       NOT NULL,
  PRIMARY KEY (lt_s_symb)
) ZONE tpce_zone;

CREATE TABLE news_item (
  ni_id       BIGINT        NOT NULL,
  ni_headline VARCHAR(80)   NOT NULL,
  ni_summary  VARCHAR(255)  NOT NULL,
  ni_item     VARCHAR(10000) NOT NULL,
  ni_dts      TIMESTAMP     NOT NULL,
  ni_source   VARCHAR(30)   NOT NULL,
  ni_author   VARCHAR(30),
  PRIMARY KEY (ni_id)
) ZONE tpce_zone;

CREATE TABLE news_xref (
  nx_ni_id BIGINT NOT NULL,
  nx_co_id BIGINT NOT NULL,
  PRIMARY KEY (nx_co_id, nx_ni_id)
) ZONE tpce_zone;

-- -----------------------------------------------------------------------
-- Customer tables (partitioned zone)
-- -----------------------------------------------------------------------

CREATE TABLE customer (
  c_id      BIGINT      NOT NULL,
  c_tax_id  VARCHAR(20) NOT NULL,
  c_st_id   VARCHAR(4)  NOT NULL,
  c_l_name  VARCHAR(25) NOT NULL,
  c_f_name  VARCHAR(20) NOT NULL,
  c_m_name  VARCHAR(1),
  c_gndr    VARCHAR(1),
  c_tier    SMALLINT    NOT NULL,
  c_dob     DATE        NOT NULL,
  c_ad_id   BIGINT      NOT NULL,
  c_ctry_1  VARCHAR(3),
  c_area_1  VARCHAR(3),
  c_local_1 VARCHAR(10),
  c_ext_1   VARCHAR(5),
  c_ctry_2  VARCHAR(3),
  c_area_2  VARCHAR(3),
  c_local_2 VARCHAR(10),
  c_ext_2   VARCHAR(5),
  c_ctry_3  VARCHAR(3),
  c_area_3  VARCHAR(3),
  c_local_3 VARCHAR(10),
  c_ext_3   VARCHAR(5),
  c_email_1 VARCHAR(50),
  c_email_2 VARCHAR(50),
  PRIMARY KEY (c_id)
) ZONE tpce_zone;

CREATE TABLE customer_account (
  ca_id     BIGINT        NOT NULL,
  ca_b_id   BIGINT        NOT NULL,
  ca_c_id   BIGINT        NOT NULL,
  ca_name   VARCHAR(50),
  ca_tax_st SMALLINT      NOT NULL,
  ca_bal    DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (ca_id)
) ZONE tpce_zone;

CREATE TABLE customer_taxrate (
  cx_tx_id VARCHAR(4) NOT NULL,
  cx_c_id  BIGINT     NOT NULL,
  PRIMARY KEY (cx_c_id, cx_tx_id)
) ZONE tpce_zone;

CREATE TABLE account_permission (
  ap_ca_id  BIGINT      NOT NULL,
  ap_acl    VARCHAR(4)  NOT NULL,
  ap_tax_id VARCHAR(20) NOT NULL,
  ap_l_name VARCHAR(25) NOT NULL,
  ap_f_name VARCHAR(20) NOT NULL,
  PRIMARY KEY (ap_ca_id, ap_tax_id)
) ZONE tpce_zone;

CREATE TABLE watch_list (
  wl_id   BIGINT NOT NULL,
  wl_c_id BIGINT NOT NULL,
  PRIMARY KEY (wl_id)
) ZONE tpce_zone;

CREATE TABLE watch_item (
  wi_wl_id  BIGINT      NOT NULL,
  wi_s_symb VARCHAR(15) NOT NULL,
  PRIMARY KEY (wi_wl_id, wi_s_symb)
) ZONE tpce_zone;

-- -----------------------------------------------------------------------
-- Broker table
-- -----------------------------------------------------------------------

CREATE TABLE broker (
  b_id          BIGINT        NOT NULL,
  b_st_id       VARCHAR(4)    NOT NULL,
  b_name        VARCHAR(49)   NOT NULL,
  b_num_trades  INT           NOT NULL,
  b_comm_total  DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (b_id)
) ZONE tpce_zone;

-- -----------------------------------------------------------------------
-- Trade tables (partitioned zone)
-- -----------------------------------------------------------------------

CREATE TABLE trade (
  t_id          BIGINT        NOT NULL,
  t_dts         TIMESTAMP     NOT NULL,
  t_st_id       VARCHAR(4)    NOT NULL,
  t_tt_id       VARCHAR(3)    NOT NULL,
  t_is_cash     SMALLINT      NOT NULL,
  t_s_symb      VARCHAR(15)   NOT NULL,
  t_qty         INT           NOT NULL,
  t_bid_price   DECIMAL(8,2)  NOT NULL,
  t_ca_id       BIGINT        NOT NULL,
  t_exec_name   VARCHAR(49)   NOT NULL,
  t_trade_price DECIMAL(8,2),
  t_chrg        DECIMAL(10,2) NOT NULL,
  t_comm        DECIMAL(10,2) NOT NULL,
  t_tax         DECIMAL(10,2) NOT NULL,
  t_lifo        SMALLINT      NOT NULL,
  PRIMARY KEY (t_id)
) ZONE tpce_zone;

CREATE TABLE trade_history (
  th_t_id  BIGINT    NOT NULL,
  th_dts   TIMESTAMP NOT NULL,
  th_st_id VARCHAR(4) NOT NULL,
  PRIMARY KEY (th_t_id, th_st_id)
) ZONE tpce_zone;

CREATE TABLE trade_request (
  tr_t_id      BIGINT       NOT NULL,
  tr_tt_id     VARCHAR(3)   NOT NULL,
  tr_s_symb    VARCHAR(15)  NOT NULL,
  tr_qty       INT          NOT NULL,
  tr_bid_price DECIMAL(8,2) NOT NULL,
  tr_b_id      BIGINT       NOT NULL,
  PRIMARY KEY (tr_t_id)
) ZONE tpce_zone;

CREATE TABLE settlement (
  se_t_id         BIGINT        NOT NULL,
  se_cash_type    VARCHAR(40)   NOT NULL,
  se_cash_due_date DATE          NOT NULL,
  se_amt          DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (se_t_id)
) ZONE tpce_zone;

CREATE TABLE cash_transaction (
  ct_t_id BIGINT        NOT NULL,
  ct_dts  TIMESTAMP     NOT NULL,
  ct_amt  DECIMAL(10,2) NOT NULL,
  ct_name VARCHAR(100),
  PRIMARY KEY (ct_t_id)
) ZONE tpce_zone;

CREATE TABLE holding (
  h_t_id   BIGINT       NOT NULL,
  h_ca_id  BIGINT       NOT NULL,
  h_s_symb VARCHAR(15)  NOT NULL,
  h_dts    TIMESTAMP    NOT NULL,
  h_price  DECIMAL(8,2) NOT NULL,
  h_qty    INT          NOT NULL,
  PRIMARY KEY (h_t_id)
) ZONE tpce_zone;

CREATE TABLE holding_history (
  hh_h_t_id    BIGINT NOT NULL,
  hh_t_id      BIGINT NOT NULL,
  hh_before_qty INT    NOT NULL,
  hh_after_qty  INT    NOT NULL,
  PRIMARY KEY (hh_t_id, hh_h_t_id)
) ZONE tpce_zone;

CREATE TABLE holding_summary (
  hs_ca_id  BIGINT      NOT NULL,
  hs_s_symb VARCHAR(15) NOT NULL,
  hs_qty    INT         NOT NULL,
  PRIMARY KEY (hs_ca_id, hs_s_symb)
) ZONE tpce_zone;

-- -----------------------------------------------------------------------
-- Indexes (GridGain secondary indexes)
-- -----------------------------------------------------------------------

CREATE INDEX i_c_tax_id ON customer (c_tax_id);
CREATE INDEX i_co_name ON company (co_name);
CREATE INDEX i_th_t_id_dts ON trade_history (th_t_id, th_dts);
CREATE INDEX i_in_name ON industry (in_name);
CREATE INDEX i_sc_name ON sector (sc_name);
CREATE INDEX i_t_ca_id_dts ON trade (t_ca_id, t_dts);
CREATE INDEX i_t_s_symb_dts ON trade (t_s_symb, t_dts);
CREATE INDEX i_h_ca_id_s_symb_dts ON holding (h_ca_id, h_s_symb, h_dts);
