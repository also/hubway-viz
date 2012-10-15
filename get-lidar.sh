mkdir -p data/lidar
cd data/lidar

237894
lidar_files="233898 233902 237898 237902 241898 241902 241894 237894 233894 229902"
for file in $lidar_files
do
  echo getting $file
  curl -O http://wsgw.mass.gov/data/gispub/lidar/2002_Boston_area/dem_tif/bare$file.tif.bz2
done

echo decompressing
bunzip2 *.bz2
cd
