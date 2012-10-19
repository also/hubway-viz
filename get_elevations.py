import sys
import struct

from osgeo import gdal, osr

ds = gdal.Open(sys.argv[1])
width = ds.RasterXSize
height = ds.RasterYSize
gt = ds.GetGeoTransform()

minx = gt[0]
miny = gt[3] + width*gt[4] + height*gt[5] 
maxx = gt[0] + width*gt[1] + height*gt[2]
maxy = gt[3] 

ds_cs = osr.SpatialReference()
ds_cs.ImportFromWkt(ds.GetProjectionRef())

# create a transform object to convert between coordinate systems
geog_cs = ds_cs.CloneGeogCS()
transform = osr.CoordinateTransformation(ds_cs, geog_cs)
transform_to_ds = osr.CoordinateTransformation(geog_cs, ds_cs)

width = ds.RasterXSize
height = ds.RasterYSize

gt = ds.GetGeoTransform()
minx = gt[0]
miny = gt[3] + width*gt[4] + height*gt[5]
maxx = gt[0] + width*gt[1] + height*gt[2]
maxy = gt[3]


station = [42.344763,-71.09788]
#station = [42.386428,-71.096413] # somerville city hall
#station = [42.330825,-71.057007] # andrew station
#station = [42.350851,-71.089886] # beacon st mass ave
#station = [42.341598,-71.123338] # coolidge corner
x, y, z = transform_to_ds.TransformPoint(station[1], station[0])
#x, y, z = transform_to_ds.TransformPoint(latlong[0], latlong[1])

x -= minx
y -= miny
y = height - y

band = ds.GetRasterBand(1)
datatype = band.DataType 
values = band.ReadRaster(int(x), int(y), 1, 1, 1, 1, datatype)
elevation = struct.unpack('f' * 1, values)[0]
print elevation
