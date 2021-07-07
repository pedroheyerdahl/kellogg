--average kpis by regions (economic areas) considering clusters load density and area of intersection between clusters and regions as weights
ALTER TABLE
  `potrtms.kellogg.loads_locations` 
  ADD COLUMN IF NOT EXISTS 
    shipper_eaid INT64,
  ADD COLUMN IF NOT EXISTS 
    shipper_ea STRING,
  ADD COLUMN IF NOT EXISTS 
    consignee_eaid INT64,
  ADD COLUMN IF NOT EXISTS 
    consignee_ea STRING
;
UPDATE
  `potrtms.kellogg.loads_locations`
SET
  shipper_eaid = shipper_ea.code,
  shipper_ea = shipper_ea.name
FROM (
  SELECT
    ll.load_id AS lid,
    ea.code AS code,
    ea.name
  FROM
    `potrtms.regions.economic_areas` ea
  JOIN
    `potrtms.kellogg.loads_locations` ll
  ON
    ST_Within(ll.shipper_geom,
      ea.geom)) AS shipper_ea
WHERE
  load_id = shipper_ea.lid
;
UPDATE
  `potrtms.kellogg.loads_locations`
SET
  consignee_eaid = consignee_ea.code,
  consignee_ea = consignee_ea.name
FROM (
  SELECT
    ll.load_id AS lid,
    ea.code AS code,
    ea.name
  FROM
    `potrtms.regions.economic_areas` ea
  JOIN
    `potrtms.kellogg.loads_locations` ll
  ON
    ST_Within(ll.consignee_geom,
      ea.geom)) AS consignee_ea
WHERE
  load_id = consignee_ea.lid
;
CREATE OR REPLACE TABLE
  `potrtms.kellogg.wave_shipper` AS
WITH
  shipper_weights AS (
  SELECT
    ea.code,
    ea.name,
    c.cid,
    c.loads,
    (ST_Area(ST_Intersection(c.geom,
          ea.geom)) * c.loads) AS weight
  FROM
    `potrtms.regions.economic_areas` AS ea
  INNER JOIN
    `potrtms.kellogg.dbscan_shipper` c
  ON
    ST_Intersects(c.geom,
      ea.geom)),

  shipper_weighted_values AS (
  SELECT
    w.code,
    w.name,
    w.cid,
    weight,
    (k.loads * w.weight) AS w_loads,
    (k.contract_price * w.weight) AS w_contract_price,
    (k.freight_price * w.weight) AS w_freight_price,
    (k.discrepancy_price * w.weight) AS w_discrepancy_price,
    (k.final_price * w.weight) AS w_final_price
  FROM
    shipper_weights w
  JOIN
    `potrtms.kellogg.dbscan_shipper` k
  ON
    k.cid = w.cid)

SELECT
  wv.code,
  wv.name,
  ROUND((SUM(w_loads)/SUM(weight)),0) AS loads,
  ROUND((SUM(w_contract_price)/SUM(weight)),2) AS contract_price,
  ROUND((SUM(w_freight_price)/SUM(weight)),2) AS freight_price,
  ROUND((SUM(w_discrepancy_price)/SUM(weight)),2) AS discrepancy_price,
  ROUND((SUM(w_final_price)/SUM(weight)),2) AS final_price
FROM
  shipper_weighted_values wv
JOIN
  `potrtms.regions.economic_areas` ea
ON
  wv.code = ea.code
GROUP BY
  wv.code,
  wv.name
;
CREATE OR REPLACE TABLE
  `potrtms.kellogg.wave_consignee` AS
WITH
  consignee_weights AS (
  SELECT
    ea.code,
    ea.name,
    c.cid,
    c.loads,
    (ST_Area(ST_Intersection(c.geom,
          ea.geom)) * c.loads) AS weight
  FROM
    `potrtms.regions.economic_areas` AS ea
  INNER JOIN
    `potrtms.kellogg.dbscan_consignee` c
  ON
    ST_Intersects( c.geom,
      ea.geom)),

  consignee_weighted_values AS (
  SELECT
    w.code,
    w.name,
    w.cid,
    weight,
    (k.loads * w.weight) AS w_loads,
    (k.contract_price * w.weight) AS w_contract_price,
    (k.freight_price * w.weight) AS w_freight_price,
    (k.discrepancy_price * w.weight) AS w_discrepancy_price,
    (k.final_price * w.weight) AS w_final_price
  FROM
    consignee_weights w
  JOIN
    `potrtms.kellogg.dbscan_consignee` k
  ON
    k.cid = w.cid)
SELECT
  wv.code,
  wv.name,
  ROUND((SUM(w_loads)/SUM(weight)),0) AS loads,
  ROUND((SUM(w_contract_price)/SUM(weight)),2) AS contract_price,
  ROUND((SUM(w_freight_price)/SUM(weight)),2) AS freight_price,
  ROUND((SUM(w_discrepancy_price)/SUM(weight)),2) AS discrepancy_price,
  ROUND((SUM(w_final_price)/SUM(weight)),2) AS final_price
FROM
  consignee_weighted_values wv
JOIN
  `potrtms.regions.economic_areas` ea
ON
  wv.code = ea.code
GROUP BY
  wv.code,
  wv.name
;
ALTER TABLE
  `potrtms.kellogg.loads_locations` 
  ADD COLUMN IF NOT EXISTS 
    shipper_wav_loads FLOAT64,
  ADD COLUMN IF NOT EXISTS 
    shipper_wav_contract_price FLOAT64,
  ADD COLUMN IF NOT EXISTS 
    shipper_wav_freight_price FLOAT64,
  ADD COLUMN IF NOT EXISTS 
    shipper_wav_discrepancy_price FLOAT64,
  ADD COLUMN IF NOT EXISTS 
    shipper_wav_final_price FLOAT64,
  ADD COLUMN IF NOT EXISTS 
    consignee_wav_loads FLOAT64,
  ADD COLUMN IF NOT EXISTS 
    consignee_wav_contract_price FLOAT64,
  ADD COLUMN IF NOT EXISTS 
    consignee_wav_freight_price FLOAT64,
  ADD COLUMN IF NOT EXISTS 
    consignee_wav_discrepancy_price FLOAT64,
  ADD COLUMN IF NOT EXISTS 
    consignee_wav_final_price FLOAT64
;
UPDATE
  `potrtms.kellogg.loads_locations` ll
SET
  shipper_wav_loads = w.loads,
  shipper_wav_contract_price = w.contract_price,
  shipper_wav_freight_price = w.freight_price,
  shipper_wav_discrepancy_price = w.discrepancy_price,
  shipper_wav_final_price = w.final_price
FROM
  `potrtms.kellogg.wave_shipper` w
WHERE
  ll.shipper_eaid = w.code
;
UPDATE
  `potrtms.kellogg.loads_locations` ll
SET
  consignee_wav_loads = w.loads,
  consignee_wav_contract_price = w.contract_price,
  consignee_wav_freight_price = w.freight_price,
  consignee_wav_discrepancy_price = w.discrepancy_price,
  consignee_wav_final_price = w.final_price
FROM
  `potrtms.kellogg.wave_consignee` w
WHERE
  ll.consignee_eaid = w.code
;