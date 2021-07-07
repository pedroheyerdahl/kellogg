 --Define density based spatial clusters over shipper and consignee data. Mininimum points per cluster = 1. Maximum distance between clusters points: 75/100km (45/60 miles)
  CREATE TEMPORARY TABLE voronoi_shipper AS (
  WITH
    shipper_clusters AS (
    SELECT
      load_id,
      shipper_geom,
      ST_CLUSTERDBSCAN(shipper_geom,
        1e5,
        1) OVER () AS cluster_num
    FROM
      `potrtms.kellogg.loads_locations`
    WHERE
      shipper_geom IS NOT NULL ),

    shipper_centroids AS(
    SELECT
      cluster_num,
      ARRAY_AGG(load_id) AS rowids,
      ST_Centroid(ST_UNION_AGG(shipper_geom)) AS cgeom
    FROM
      shipper_clusters
    GROUP BY
      cluster_num ),
    shipper_array_centroids AS (
    SELECT
      ARRAY (
      SELECT
        cgeom
      FROM
        shipper_centroids) AS ageom ),

    shipper_voronoi_array AS (
    SELECT
      bqcarto.processing.ST_VORONOIPOLYGONS(ageom,
        NULL) AS nested_voronoi
    FROM
      shipper_array_centroids ),
    shipper_voronoi_polygons AS (
    SELECT
      ST_INTERSECTION(aoi.geom,
        unnested_voronoi) AS vor_geom
    FROM
      shipper_voronoi_array,
      UNNEST(nested_voronoi) AS unnested_voronoi,
      `potrtms.regions.aoi` AS aoi )

  SELECT
    cluster_num,
    rowids,
    ST_AREA(vor_geom) AS area,
    vor_geom
  FROM
    shipper_voronoi_polygons
  JOIN
    shipper_centroids
  ON
    ST_Contains(vor_geom,
      cgeom) )
;

ALTER TABLE
  `potrtms.kellogg.loads_locations` 
ADD COLUMN IF NOT EXISTS 
  shipper_cid INT64
;

UPDATE
  `potrtms.kellogg.loads_locations`
SET
  shipper_cid = cluster_num
FROM
  voronoi_shipper
WHERE
  ST_Contains(vor_geom,
    shipper_geom)
;

DROP TABLE IF EXISTS
  `potrtms.kellogg.dbscan_shipper`
;
CREATE TABLE IF NOT EXISTS
  `potrtms.kellogg.dbscan_shipper` AS (
  SELECT
    shipper_cid AS cid,
    COUNT(load_id) AS loads,
    ROUND(AVG(contract_price),2) AS contract_price,
    ROUND(AVG(freight_price),2) AS freight_price,
    ROUND(AVG(discrepancy_price),2) AS discrepancy_price,
    ROUND(AVG(final_price),2) AS final_price
  FROM
    `potrtms.kellogg.loads_locations`
  JOIN
    voronoi_shipper
  ON
    shipper_cid = cluster_num
  GROUP BY
    shipper_cid )
;
ALTER TABLE
  `potrtms.kellogg.dbscan_shipper` 
ADD COLUMN IF NOT EXISTS 
  geom GEOGRAPHY
;
UPDATE
  `potrtms.kellogg.dbscan_shipper`
SET
  geom = vor_geom
FROM
  voronoi_shipper
WHERE
  cid = cluster_num
; 
CREATE TEMPORARY TABLE voronoi_consignee AS (
  WITH
    consignee_clusters AS (
    SELECT
      load_id,
      consignee_geom,
      ST_CLUSTERDBSCAN(consignee_geom,
        75000,
        1) OVER () AS cluster_num
    FROM
      `potrtms.kellogg.loads_locations`
    WHERE
      consignee_geom IS NOT NULL ),

    consignee_centroids AS(
    SELECT
      cluster_num,
      ARRAY_AGG(load_id) AS rowids,
      ST_Centroid(ST_UNION_AGG(consignee_geom)) AS cgeom
    FROM
      consignee_clusters
    GROUP BY
      cluster_num ),

    consignee_array_centroids AS (
    SELECT
      ARRAY (
      SELECT
        cgeom
      FROM
        consignee_centroids) AS ageom ),

    consignee_voronoi_array AS (
    SELECT
      bqcarto.processing.ST_VORONOIPOLYGONS(ageom,
        NULL) AS nested_voronoi
    FROM
      consignee_array_centroids ),

    consignee_voronoi_polygons AS (
    SELECT
      ST_INTERSECTION(aoi.geom,
        unnested_voronoi) AS vor_geom
    FROM
      consignee_voronoi_array,
      UNNEST(nested_voronoi) AS unnested_voronoi,
      `potrtms.regions.aoi` AS aoi )

  SELECT
    cluster_num,
    rowids,
    ST_AREA(vor_geom) AS area,
    vor_geom
  FROM
    consignee_voronoi_polygons
  JOIN
    consignee_centroids
  ON
    ST_Contains(vor_geom,
      cgeom) )
;

ALTER TABLE
  `potrtms.kellogg.loads_locations` 
ADD COLUMN IF NOT EXISTS consignee_cid INT64
;
UPDATE
  `potrtms.kellogg.loads_locations`
SET
  consignee_cid = cluster_num
FROM
  voronoi_consignee
WHERE
  ST_Contains(vor_geom,
    consignee_geom)
;
DROP TABLE IF EXISTS
  `potrtms.kellogg.dbscan_consignee`
;

CREATE TABLE IF NOT EXISTS
  `potrtms.kellogg.dbscan_consignee` AS (
  SELECT
    consignee_cid AS cid,
    COUNT(load_id) AS loads,
    ROUND(AVG(contract_price),2) AS contract_price,
    ROUND(AVG(freight_price),2) AS freight_price,
    ROUND(AVG(discrepancy_price),2) AS discrepancy_price,
    ROUND(AVG(final_price),2) AS final_price
  FROM
    `potrtms.kellogg.loads_locations`
  JOIN
    voronoi_consignee
  ON
    consignee_cid = cluster_num
  GROUP BY
    consignee_cid )
;

ALTER TABLE
  `potrtms.kellogg.dbscan_consignee` 
  ADD COLUMN IF NOT EXISTS 
  geom GEOGRAPHY;
  
UPDATE
  `potrtms.kellogg.dbscan_consignee`
SET
  geom = vor_geom
FROM
  voronoi_consignee
WHERE
  cid = cluster_num
;