CREATE TEMP FUNCTION
  ClearCurrency(x STRING)
  RETURNS FLOAT64 AS (
    CASE
      WHEN x LIKE '%$ -%' THEN NULL
    ELSE
    CAST(REGEXP_REPLACE(x,r'[^0-9.]+','') AS FLOAT64)
  END
);

CREATE TEMPORARY TABLE dup_data AS 
SELECT
  UPPER(Shipping_Warehouse) AS shipper_wh,
  Assigned_Customer_Warehouse AS assigned_cust_wh,
  Base_T_L_H_Nbr AS base_tlh,
  SO____T_R_ AS soid_trid,
  Customer AS consignee_id,
  custname AS consignee_name,
  shipdate AS shipped_date,
  Zip AS zip,
  Has_Stops_Over AS has_stops_over,
  ClearCurrency(_Contract__Freight_) AS contract_price,
  ClearCurrency(_Freight_Amount_) AS freight_price,
  ClearCurrency(_Discrepancy_Amount_) AS discrepancy_amount,
  ClearCurrency(_Grand_Total_) AS final_price,
  Posted AS was_posted,
  Customer_PO_Number AS cust_po,
  UPPER(Carrier) AS carrier,
  CAST(REPLACE(Shipment_,'-SH','' ) AS INT64) AS load_id,
  State AS state
FROM
  `potrtms.kellogg.raw_data` 
;
CREATE OR REPLACE TABLE
  `potrtms.kellogg.data` AS
WITH
  repeated AS (
  SELECT
    load_id AS repeated_load_id,
    COUNT(*) AS count
  FROM
    dup_data
  GROUP BY
    load_id
  HAVING
    count > 1 )
SELECT
  * EXCEPT (repeated_load_id,
    count)
FROM
  dup_data
LEFT JOIN
  repeated
ON
  repeated_load_id = load_id
WHERE
  repeated_load_id IS NULL
  AND final_price IS NOT NULL 
; 
CREATE TEMPORARY TABLE dup_accessorials AS
SELECT
  UPPER(Shipping_Warehouse) AS shipper_wh,
  Assigned_Customer_Warehouse AS assigned_cust_wh,
  Base_T_L_H_Nbr AS base_tlh,
  SO____T_R_ AS soid_trid,
  Customer AS consignee_id,
  custname AS consignee_name,
  shipdate AS shipped_date,
  Zip AS zip,
  Has_Stops_Over AS has_stops_over,
  ClearCurrency(_Contract__Freight_) AS contract_price,
  ClearCurrency(_Freight_Amount_) AS freight_price,
  ClearCurrency(_Discrepancy_Amount_) AS discrepancy_amount,
  ClearCurrency(_Grand_Total_) AS final_price,
  Posted AS was_posted,
  Customer_PO_Number AS cust_po,
  UPPER(Carrier) AS carrier,
  CAST(REPLACE(Shipment_,'-SH','' ) AS INT64) AS load_id,
  State AS state
FROM
  `potrtms.kellogg.raw_accessorials` 
;
CREATE OR REPLACE TABLE
  `potrtms.kellogg.accessorials` AS
WITH
  repeated AS (
  SELECT
    load_id AS repeated_load_id,
    COUNT(*) AS count
  FROM
    dup_accessorials
  GROUP BY
    load_id
  HAVING
    count > 1 )
SELECT
  * EXCEPT (repeated_load_id,
    count)
FROM
  dup_accessorials
LEFT JOIN
  repeated
ON
  repeated_load_id = load_id
WHERE
  repeated_load_id IS NULL
  AND final_price IS NOT NULL 
; 
CREATE TEMPORARY TABLE dup_zip_to_zip AS
SELECT
  Customer AS consignee_id,
  custname AS consignee_name,
  shipdate AS shipped_date,
  Ship_Zip AS shipper_zip,
  Deliver_Zip AS consignee_zip,
  Has_Stops_Over AS has_stops_over,
  ClearCurrency(_Contract__Freight_) AS contract_price,
  ClearCurrency(_Freight_Amount_) AS freight_price,
  ClearCurrency(_Discrepancy_Amount_) AS discrepancy_amount,
  ClearCurrency(_Grand_Total_) AS final_price,
  Posted AS was_posted,
  Customer_PO_Number AS cust_po,
  UPPER(Carrier) AS carrier,
  CAST(REPLACE(Shipment_,'-SH','' ) AS INT64) AS load_id,
  State AS state
FROM
  `potrtms.kellogg.raw_zip_to_zip` 
;
CREATE OR REPLACE TABLE
  `potrtms.kellogg.zip_to_zip` AS
WITH
  repeated AS (
  SELECT
    load_id AS repeated_load_id,
    COUNT(*) AS count
  FROM
    dup_zip_to_zip
  GROUP BY
    load_id
  HAVING
    count > 1 )
SELECT
  * EXCEPT (repeated_load_id,
    count)
FROM
  dup_zip_to_zip
LEFT JOIN
  repeated
ON
  repeated_load_id = load_id
WHERE
  repeated_load_id IS NULL
  AND final_price IS NOT NULL 
; 

WITH
  summary_data AS (
  SELECT
    COUNT(*) row_count,
    --COUNT(DISTINCT shipper_wh) dstc_shipper_wh,
    --SUM(CASE WHEN shipper_wh IS NULL THEN 1 END) null_shipper_wh,
    --COUNT(DISTINCT assigned_cust_wh) dstc_assigned_cust_wh,
    --SUM(CASE WHEN assigned_cust_wh IS NULL THEN 1 END) null_assigned_cust_wh,
    --COUNT(DISTINCT base_tlh) dstc_base_tlh,
    --SUM(CASE WHEN base_tlh IS NULL THEN 1 END) null_base_tlh,
    --MIN(base_tlh) min_base_tlh,
    --MAX(base_tlh) max_base_tlh,
    --AVG(base_tlh) avg_base_tlh,
    --COUNT(DISTINCT soid_trid) dstc_soid_trid,
    --SUM(CASE WHEN soid_trid IS NULL THEN 1 END) null_soid_trid,
    COUNT(DISTINCT consignee_id) dstc_consignee_id,
    SUM(CASE WHEN consignee_id IS NULL THEN 1 END) null_consignee_id,
    MIN(consignee_id) min_consignee_id,
    MAX(consignee_id) max_consignee_id,
    COUNT(DISTINCT consignee_name) dstc_consignee_name,
    SUM(CASE WHEN consignee_name IS NULL THEN 1 END) null_consignee_name,
    SUM(CASE WHEN shipped_date IS NULL THEN 1 END) null_shipped_date,
    MIN(shipped_date) min_shipped_date,
    MAX(shipped_date) max_shipped_date,
    --COUNT(DISTINCT zip) dstc_zip,
    --SUM(CASE WHEN zip IS NULL THEN 1 END) null_zip,
    COUNT(DISTINCT has_stops_over) dstc_has_stops_over,
    SUM(CASE WHEN has_stops_over IS NULL THEN 1 END) null_has_stops_over,
    COUNT(DISTINCT contract_price) dstc_contract_price,
    SUM(CASE WHEN contract_price IS NULL THEN 1 END) null_contract_price,
    MIN(contract_price) min_contract_price,
    MAX(contract_price) max_contract_price,
    AVG(contract_price) avg_contract_price,
    COUNT(DISTINCT freight_price) dstc_freight_price,
    SUM(CASE WHEN freight_price IS NULL THEN 1 END) null_freight_price,
    MIN(freight_price) min_freight_price,
    MAX(freight_price) max_freight_price,
    AVG(freight_price) avg_freight_price,
    COUNT(DISTINCT discrepancy_amount) dstc_discrepancy_amount,
    SUM(CASE WHEN discrepancy_amount IS NULL THEN 1 END) null_discrepancy_amount,
    MIN(discrepancy_amount) min_discrepancy_amount,
    MAX(discrepancy_amount) max_discrepancy_amount,
    AVG(discrepancy_amount) avg_discrepancy_amount,
    COUNT(DISTINCT final_price) dstc_final_price,
    SUM(CASE WHEN final_price IS NULL THEN 1 END) null_final_price,
    MIN(final_price) min_final_price,
    MAX(final_price) max_final_price,
    AVG(final_price) avg_final_price,
    COUNT(DISTINCT was_posted) dstc_was_posted,
    SUM(CASE WHEN was_posted IS NULL THEN 1 END) null_was_posted,
    COUNT(DISTINCT cust_po) dstc_cust_po,
    SUM(CASE WHEN cust_po IS NULL THEN 1 END) null_cust_po,
    COUNT(DISTINCT carrier) dstc_carrier,
    SUM(CASE WHEN carrier IS NULL THEN 1 END) null_carrier,
    COUNT(DISTINCT load_id) dstc_load_id,
    SUM(CASE WHEN load_id IS NULL THEN 1 END) null_load_id,
    COUNT(DISTINCT state) dstc_state,
    SUM(CASE WHEN state IS NULL THEN 1 END) null_state,
  FROM
    `potrtms.kellogg.data` 
),
  summary_accessorials AS (
  SELECT
    COUNT(*) row_count,
    --COUNT(DISTINCT shipper_wh) dstc_shipper_wh,
    --SUM(CASE WHEN shipper_wh IS NULL THEN 1 END) null_shipper_wh,
    --COUNT(DISTINCT assigned_cust_wh) dstc_assigned_cust_wh,
    --SUM(CASE WHEN assigned_cust_wh IS NULL THEN 1 END) null_assigned_cust_wh,
    --COUNT(DISTINCT base_tlh) dstc_base_tlh,
    --SUM(CASE WHEN base_tlh IS NULL THEN 1 END) null_base_tlh,
    --MIN(base_tlh) min_base_tlh,
    --MAX(base_tlh) max_base_tlh,
    --AVG(base_tlh) avg_base_tlh,
    --COUNT(DISTINCT soid_trid) dstc_soid_trid,
    --SUM(CASE WHEN soid_trid IS NULL THEN 1 END) null_soid_trid,
    COUNT(DISTINCT consignee_id) dstc_consignee_id,
    SUM(CASE WHEN consignee_id IS NULL THEN 1 END) null_consignee_id,
    MIN(consignee_id) min_consignee_id,
    MAX(consignee_id) max_consignee_id,
    COUNT(DISTINCT consignee_name) dstc_consignee_name,
    SUM(CASE WHEN consignee_name IS NULL THEN 1 END) null_consignee_name,
    SUM(CASE WHEN shipped_date IS NULL THEN 1 END) null_shipped_date,
    MIN(shipped_date) min_shipped_date,
    MAX(shipped_date) max_shipped_date,
    --COUNT(DISTINCT zip) dstc_zip,
    --SUM(CASE WHEN zip IS NULL THEN 1 END) null_zip,
    COUNT(DISTINCT has_stops_over) dstc_has_stops_over,
    SUM(CASE WHEN has_stops_over IS NULL THEN 1 END) null_has_stops_over,
    COUNT(DISTINCT contract_price) dstc_contract_price,
    SUM(CASE WHEN contract_price IS NULL THEN 1 END) null_contract_price,
    MIN(contract_price) min_contract_price,
    MAX(contract_price) max_contract_price,
    AVG(contract_price) avg_contract_price,
    COUNT(DISTINCT freight_price) dstc_freight_price,
    SUM(CASE WHEN freight_price IS NULL THEN 1 END) null_freight_price,
    MIN(freight_price) min_freight_price,
    MAX(freight_price) max_freight_price,
    AVG(freight_price) avg_freight_price,
    COUNT(DISTINCT discrepancy_amount) dstc_discrepancy_amount,
    SUM(CASE WHEN discrepancy_amount IS NULL THEN 1 END) null_discrepancy_amount,
    MIN(discrepancy_amount) min_discrepancy_amount,
    MAX(discrepancy_amount) max_discrepancy_amount,
    AVG(discrepancy_amount) avg_discrepancy_amount,
    COUNT(DISTINCT final_price) dstc_final_price,
    SUM(CASE WHEN final_price IS NULL THEN 1 END) null_final_price,
    MIN(final_price) min_final_price,
    MAX(final_price) max_final_price,
    AVG(final_price) avg_final_price,
    COUNT(DISTINCT was_posted) dstc_was_posted,
    SUM(CASE WHEN was_posted IS NULL THEN 1 END) null_was_posted,
    COUNT(DISTINCT cust_po) dstc_cust_po,
    SUM(CASE WHEN cust_po IS NULL THEN 1 END) null_cust_po,
    COUNT(DISTINCT carrier) dstc_carrier,
    SUM(CASE WHEN carrier IS NULL THEN 1 END) null_carrier,
    COUNT(DISTINCT load_id) dstc_load_id,
    SUM(CASE WHEN load_id IS NULL THEN 1 END) null_load_id,
    COUNT(DISTINCT state) dstc_state,
    SUM(CASE WHEN state IS NULL THEN 1 END) null_state,
  FROM
    `potrtms.kellogg.accessorials` ),
  summary_zip AS (
  SELECT
    COUNT(*) row_count,
    --COUNT(DISTINCT shipper_wh) dstc_shipper_wh,
    --SUM(CASE WHEN shipper_wh IS NULL THEN 1 END) null_shipper_wh,
    --COUNT(DISTINCT assigned_cust_wh) dstc_assigned_cust_wh,
    --SUM(CASE WHEN assigned_cust_wh IS NULL THEN 1 END) null_assigned_cust_wh,
    --COUNT(DISTINCT base_tlh) dstc_base_tlh,
    --SUM(CASE WHEN base_tlh IS NULL THEN 1 END) null_base_tlh,
    --MIN(base_tlh) min_base_tlh,
    --MAX(base_tlh) max_base_tlh,
    --AVG(base_tlh) avg_base_tlh,
    --COUNT(DISTINCT soid_trid) dstc_soid_trid,
    --SUM(CASE WHEN soid_trid IS NULL THEN 1 END) null_soid_trid,
    COUNT(DISTINCT consignee_id) dstc_consignee_id,
    SUM(CASE WHEN consignee_id IS NULL THEN 1 END) null_consignee_id,
    MIN(consignee_id) min_consignee_id,
    MAX(consignee_id) max_consignee_id,
    COUNT(DISTINCT consignee_name) dstc_consignee_name,
    SUM(CASE WHEN consignee_name IS NULL THEN 1 END) null_consignee_name,
    SUM(CASE WHEN shipped_date IS NULL THEN 1 END) null_shipped_date,
    MIN(shipped_date) min_shipped_date,
    MAX(shipped_date) max_shipped_date,
    --COUNT(DISTINCT zip) dstc_zip,
    --SUM(CASE WHEN zip IS NULL THEN 1 END) null_zip,
    COUNT(DISTINCT has_stops_over) dstc_has_stops_over,
    SUM(CASE WHEN has_stops_over IS NULL THEN 1 END) null_has_stops_over,
    COUNT(DISTINCT contract_price) dstc_contract_price,
    SUM(CASE WHEN contract_price IS NULL THEN 1 END) null_contract_price,
    MIN(contract_price) min_contract_price,
    MAX(contract_price) max_contract_price,
    AVG(contract_price) avg_contract_price,
    COUNT(DISTINCT freight_price) dstc_freight_price,
    SUM(CASE WHEN freight_price IS NULL THEN 1 END) null_freight_price,
    MIN(freight_price) min_freight_price,
    MAX(freight_price) max_freight_price,
    AVG(freight_price) avg_freight_price,
    COUNT(DISTINCT discrepancy_amount) dstc_discrepancy_amount,
    SUM(CASE WHEN discrepancy_amount IS NULL THEN 1 END) null_discrepancy_amount,
    MIN(discrepancy_amount) min_discrepancy_amount,
    MAX(discrepancy_amount) max_discrepancy_amount,
    AVG(discrepancy_amount) avg_discrepancy_amount,
    COUNT(DISTINCT final_price) dstc_final_price,
    SUM(CASE WHEN final_price IS NULL THEN 1 END) null_final_price,
    MIN(final_price) min_final_price,
    MAX(final_price) max_final_price,
    AVG(final_price) avg_final_price,
    COUNT(DISTINCT was_posted) dstc_was_posted,
    SUM(CASE WHEN was_posted IS NULL THEN 1 END) null_was_posted,
    COUNT(DISTINCT cust_po) dstc_cust_po,
    SUM(CASE WHEN cust_po IS NULL THEN 1 END) null_cust_po,
    COUNT(DISTINCT carrier) dstc_carrier,
    SUM(CASE WHEN carrier IS NULL THEN 1 END) null_carrier,
    COUNT(DISTINCT load_id) dstc_load_id,
    SUM(CASE WHEN load_id IS NULL THEN 1 END) null_load_id,
    COUNT(DISTINCT state) dstc_state,
    SUM(CASE WHEN state IS NULL THEN 1 END) null_state,
  FROM
    `potrtms.kellogg.zip_to_zip` )
SELECT
  *
FROM
  summary_accessorials
UNION ALL
SELECT
  *
FROM
  summary_data
UNION ALL
SELECT
  *
FROM summary_zip
;