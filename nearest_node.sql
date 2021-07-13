CREATE OR REPLACE FUNCTION GetNearestNode(x integer, col VARCHAR(40))
RETURNS integer
LANGUAGE plpgsql
AS
$$
DECLARE
  node integer;
  
BEGIN
  EXECUTE format('
  SELECT topo.source
  FROM nam_2po_4pgr as topo, lanes
  WHERE lanes.id = $1
  AND ST_DWithin(geom_way, lanes.%I,0.1)
  ORDER BY topo.geom_way <-> lanes.%I
  LIMIT 1', col,col)
  USING x
  INTO node;
  
  RETURN node;
END;
$$;

ALTER TABLE lanes
ADD COLUMN IF NOT EXISTS shipper_vid integer,
ADD COLUMN IF NOT EXISTS consignee_vid integer
;

UPDATE lanes
SET shipper_vid = GetNearestNode(id, 'shipper_geom'),
consignee_vid = GetNearestNode(id, 'consignee_geom')
;

SELECT * FROM lanes

--WHERE id = 1
-- shipper_vid: 10964228 consignee_vid: 11137701