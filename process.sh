rm -rf output
mkdir output

sh ./process-hubway-mess.sh

echo processing lidar
sh ./process-lidar.sh

echo adding elevation data
PYTHONPATH=/usr/local/Cellar/gdal/1.9.2/lib/python2.7/site-packages python get_elevations.py data/lidar.tif data/stations_trips/stations.csv > output/stations.csv

echo generating routing data
mkdir output/routing
./lib/python-env/bin/osm4routing -n output/routing/nodes.csv -e output/routing/edges.csv data/CambridgeMa.osm

echo converting zips to geojson
ogr2ogr -f geoJSON output/zips.json data/tl_2010_25_zcta510/tl_2010_25_zcta510.shp

echo filtering zips
ruby filter_zips.rb

echo converting stations to geojson
ogr2ogr -f geoJSON output/stations_geo.json data/stations_trips/stations.shp/stations.shp
