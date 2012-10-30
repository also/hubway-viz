echo merging images
PYTHONPATH=/usr/local/Cellar/gdal/1.9.2/lib/python2.7/site-packages /usr/local/bin/gdal_merge.py data/lidar/*.tif -o data/lidar.tif

echo reprojecting
gdalwarp -s_srs EPSG:26986 -t_srs EPSG:3785 -r bilinear data/lidar.tif data/lidar-3785.tif

echo coloring
gdaldem color-relief data/lidar-3785.tif ramp.txt data/lidar-colored-3785.tif

echo generating hillshade
gdaldem hillshade -co compress=lzw data/lidar-3785.tif data/lidar-hillshade-3785.tif

echo generating slope
gdaldem slope data/lidar-3785.tif data/lidar-slope-3785.tif

echo generating png
gdal_translate -b 1 -of PNG -outsize 1600 1200 -scale 0 100 data/lidar-3785.tif output/lidar.png

gdal_translate -of PNG -outsize 1600 1200 data/lidar-colored-3785.tif output/lidar-colored.png
