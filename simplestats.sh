echo Trips: `wc -l < output/trips_sorted.csv`
echo Users: `wc -l < output/users.txt`
echo Bikes: `wc -l < output/bikes`
echo Station Pairs: `wc -l < output/station_pairs.csv`

echo First Date: `head -1 output/trips_sorted.csv | cut -d , -f 4`
echo Last Dat: `tail -1 output/trips_sorted.csv | cut -d , -f 4`
