import sys
import json

from geo_tiff import GeoTiff

t = GeoTiff(sys.argv[1])
print json.dumps(t.get_geo_extents())
