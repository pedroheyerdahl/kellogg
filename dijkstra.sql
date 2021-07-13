CREATE TABLE distances AS
SELECT nodes.id,
,       ROUND(SUM(pgr.cost)::numeric,2) AS "agg_km"
FROM    (
  SELECT lanes.id,
         lanes."shipper_vid",
         lanes."consignee_vid",
         ST_Collect(shipper_geom, consignee_geom)::TEXT AS bbox
  FROM   lanes
) AS nodes,
LATERAL PGR_Dijkstra(
  '
  SELECT id::INT,
         source,
         target,
         km AS cost
  FROM   nam_2po_4pgr
  WHERE  geom_way && ST_Expand(''' || nodes.bbox || '''::GEOMETRY, 0.1)
  ',
  nodes."shipper_vid",
  nodes."consignee_vid",
  FALSE
) AS pgr
GROUP BY
        nodes.id
;