  /*
  z.miles,
  ((z.customer_price+z.fuel_surcharge) - z.carrier_price) AS profit,
  ((z.customer_price+z.fuel_surcharge)/z.miles) AS customer_rate,
  (z.carrier_price/z.miles) AS carrier_rate,
  (((z.customer_price+z.fuel_surcharge) - z.carrier_price)/z.miles) AS profit_rate,
  (((z.customer_price+z.fuel_surcharge) - z.carrier_price)/z.customer_price) AS margin_pct,
  */
CREATE TEMPORARY TABLE repeated_zips AS (
  SELECT
    l.consignee_id AS lid,
    COUNT(DISTINCT consignee_zip) zips,
  FROM
    `potrtms.kellogg.zip_to_zip` l
  GROUP BY
    1
  HAVING
    zips > 1 
);

CREATE OR REPLACE TABLE
  `potrtms.kellogg.loads_locations`
AS SELECT
  z.load_id,
  a.shipper_wh AS shipper_id,
  z.consignee_id AS consignee_id,
  z.carrier AS carrier_id,
  z.shipped_date,
  z.has_stops_over,
  z.contract_price,
  z.freight_price,
  z.discrepancy_amount,
  z.final_price,
  shipper.city AS shipper_city,
  shipper.state_code AS shipper_state,
  shipper.internal_point_geom AS shipper_geom,
  consignee.city AS consignee_city,
  consignee.state_code AS consignee_state,
  consignee.internal_point_geom AS consignee_geom
FROM
  `potrtms.kellogg.zip_to_zip` z
JOIN
  `potrtms.kellogg.accessorials` a
ON
  z.load_id = a.load_id
JOIN
  `bigquery-public-data.geo_us_boundaries.zip_codes` AS shipper
ON
  shipper.zip_code = CAST(shipper_zip AS STRING)
JOIN
  `bigquery-public-data.geo_us_boundaries.zip_codes` AS consignee
ON
  consignee.zip_code = CAST(consignee_zip AS STRING)
WHERE
  consignee.state_code != 'HI'
  AND consignee.state_code != 'GU'
  AND z.consignee_id NOT IN (
  SELECT
    lid
  FROM
    repeated_zips)
;