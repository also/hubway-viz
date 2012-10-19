import sys
import struct

from osgeo import gdal, osr

class GeoTiff(object):
    def __init__(self, filename):
        self.ds = gdal.Open(filename)
        self.width = self.ds.RasterXSize
        self.height = self.ds.RasterYSize
        gt = self.ds.GetGeoTransform()

        self.minx = gt[0]
        self.miny = gt[3] + self.width*gt[4] + self.height*gt[5] 
        self.maxx = gt[0] + self.width*gt[1] + self.height*gt[2]
        self.maxy = gt[3] 

        ds_cs = osr.SpatialReference()
        ds_cs.ImportFromWkt(self.ds.GetProjectionRef())

        # create a transform object to convert between coordinate systems
        geog_cs = ds_cs.CloneGeogCS()
        self.transform = osr.CoordinateTransformation(ds_cs, geog_cs)
        self.transform_to_ds = osr.CoordinateTransformation(geog_cs, ds_cs)

    def get(self, lng, lat):
        x, y, z = self.transform_to_ds.TransformPoint(lng, lat)
        x -= self.minx
        y -= self.miny
        y = self.height - y

        band = self.ds.GetRasterBand(1)
        datatype = band.DataType
        values = band.ReadRaster(int(x), int(y), 1, 1, 1, 1, datatype)
        return struct.unpack('f' * 1, values)[0]

t = GeoTiff(sys.argv[1])
station = [42.344763,-71.09788]
#station = [42.386428,-71.096413] # somerville city hall
#station = [42.330825,-71.057007] # andrew station
#station = [42.350851,-71.089886] # beacon st mass ave
#station = [42.341598,-71.123338] # coolidge corner
#x, y, z = transform_to_ds.TransformPoint(latlong[0], latlong[1])

elevation = t.get(station[1], station[0])
print elevation
