-- Matches census place with location data in 3 steps: 
--1. Census place within given radius (30km/18miles) matches location city name OR
--2. Census place with different name but same position as location data
--3. No matches. Defines original city/lat lon as census place
ALTER TABLE
  `potrtms.kellogg.loads_locations` 
  ADD COLUMN IF NOT EXISTS 
    shipper_census_id INT64,
  ADD COLUMN IF NOT EXISTS 
    shipper_census_city STRING,
  ADD COLUMN IF NOT EXISTS 
    shipper_census_state STRING,
  ADD COLUMN IF NOT EXISTS 
    shipper_census_lat FLOAT64,
  ADD COLUMN IF NOT EXISTS 
    shipper_census_lon FLOAT64,
  ADD COLUMN IF NOT EXISTS 
    shipper_census_geom GEOGRAPHY
;
UPDATE
  `potrtms.kellogg.loads_locations`
SET
  shipper_census_id = cid,
  shipper_census_city = ccity,
  shipper_census_state = cstate,
  shipper_census_lon = lon,
  shipper_census_lat = lat
FROM (
  SELECT
    DISTINCT l.shipper_id AS lid,
    c.id AS cid,
    c.name AS ccity,
    c.state AS cstate,
    c.lon AS lon,
    c.lat AS lat
  FROM
    `potrtms.kellogg.loads_locations` l
  INNER JOIN
    `potrtms.regions.census_places_2020` c
  ON
    ST_DWithin(shipper_geom,
      c.geom,
      30000)
  WHERE
    shipper_city LIKE c.name) foo
WHERE
  shipper_id = foo.lid
  AND shipper_census_id IS NULL
;
UPDATE
  `potrtms.kellogg.loads_locations`
SET
  shipper_census_id = cid,
  shipper_census_city = ccity,
  shipper_census_state = cstate,
  shipper_census_lon = lon,
  shipper_census_lat = lat
FROM (
  SELECT
    DISTINCT l.shipper_id AS lid,
    c.id AS cid,
    c.name AS ccity,
    c.state AS cstate,
    c.lon AS lon,
    c.lat AS lat
  FROM
    `potrtms.kellogg.loads_locations` l
  INNER JOIN
    `potrtms.regions.census_places_2020` c
  ON
    ST_Within(shipper_geom,
      c.geom)) foo
WHERE
  shipper_id = foo.lid
  AND shipper_census_id IS NULL
;
UPDATE
  `potrtms.kellogg.loads_locations`
SET
  shipper_census_geom = ST_Centroid(c.geom)
FROM
  `potrtms.regions.census_places_2020` c
WHERE
  shipper_census_id = c.id
;
UPDATE
  `potrtms.kellogg.loads_locations`
SET
  shipper_census_city = INITCAP(shipper_city),
  shipper_census_state = shipper_state,
  shipper_census_lon = ST_X(shipper_geom),
  shipper_census_lat = ST_Y(shipper_geom),
  shipper_census_geom = shipper_geom
WHERE
  shipper_census_id IS NULL
;
ALTER TABLE
  `potrtms.kellogg.loads_locations` 
  ADD COLUMN IF NOT EXISTS 
    consignee_census_id INT64,
  ADD COLUMN IF NOT EXISTS 
    consignee_census_city STRING,
  ADD COLUMN IF NOT EXISTS 
    consignee_census_state STRING,
  ADD COLUMN IF NOT EXISTS 
    consignee_census_lat FLOAT64,
  ADD COLUMN IF NOT EXISTS 
    consignee_census_lon FLOAT64,
  ADD COLUMN IF NOT EXISTS 
    consignee_census_geom GEOGRAPHY
;
UPDATE
  `potrtms.kellogg.loads_locations`
SET
  consignee_census_id = cid,
  consignee_census_city = ccity,
  consignee_census_state = cstate,
  consignee_census_lon = lon,
  consignee_census_lat = lat
FROM (
  SELECT
    DISTINCT l.consignee_id AS lid,
    c.id AS cid,
    c.name AS ccity,
    c.state AS cstate,
    c.lon AS lon,
    c.lat AS lat
  FROM
    `potrtms.kellogg.loads_locations` l
  INNER JOIN
    `potrtms.regions.census_places_2020` c
  ON
    ST_DWithin(consignee_geom,
      c.geom,
      30000)
  WHERE
    consignee_city LIKE c.name) foo
WHERE
  consignee_id = foo.lid
  AND consignee_census_id IS NULL
;
UPDATE
  `potrtms.kellogg.loads_locations`
SET
  consignee_census_id = cid,
  consignee_census_city = ccity,
  consignee_census_state = cstate,
  consignee_census_lon = lon,
  consignee_census_lat = lat
FROM (
  SELECT
    DISTINCT l.consignee_id AS lid,
    c.id AS cid,
    c.name AS ccity,
    c.state AS cstate,
    c.lon AS lon,
    c.lat AS lat
  FROM
    `potrtms.kellogg.loads_locations` l
  INNER JOIN
    `potrtms.regions.census_places_2020` c
  ON
    ST_Within(consignee_geom,
      c.geom)) foo
WHERE
  consignee_id = foo.lid
  AND consignee_census_id IS NULL
;
UPDATE
  `potrtms.kellogg.loads_locations`
SET
  consignee_census_geom = ST_Centroid(c.geom)
FROM
  `potrtms.regions.census_places_2020` c
WHERE
  consignee_census_id = c.id;
UPDATE
  `potrtms.kellogg.loads_locations`
SET
  consignee_census_city = INITCAP(consignee_city),
  consignee_census_state = consignee_state,
  consignee_census_lon = ST_X(consignee_geom),
  consignee_census_lat = ST_Y(consignee_geom),
  consignee_census_geom = consignee_geom
WHERE
  consignee_census_id IS NULL
;