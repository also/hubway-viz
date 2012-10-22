rm -rf output
mkdir output

head -1 data/stations_trips/trips.csv > output/fields.csv

TRIPS=output/trips_sorted.csv

echo sorting trips
tail -n +2 data/stations_trips/trips.csv | sort -t , -k4 > ${TRIPS}

echo extracting users
cut -d , -f 10,11,12 ${TRIPS} | tr -d '"' | sort | uniq > output/users.txt

echo extracting station pairs
cut -d , -f 5,7 ${TRIPS} | sort | uniq > output/station_pairs.csv

echo extracting bikes
cut -d , -f 8 ${TRIPS} | sort | uniq > output/bikes.txt

echo extracting bike moves
ruby extract_moves.rb output/trips_sorted.csv > output/moves.csv

echo processing lidar
sh ./process-lidar.sh

echo adding elevation data
PYTHONPATH=/usr/local/Cellar/gdal/1.9.2/lib/python2.7/site-packages python get_elevations.py data/lidar.tif data/stations_trips/stations.csv > output/stations.csv

echo generating routing data
mkdir output/routing
./lib/python-env/bin/osm4routing -n output/routing/nodes.csv -e output/routing/edges.csv data/CambridgeMa.osm

echo computing date ranges
ruby compute_ranges.rb > output/date_ranges.json
