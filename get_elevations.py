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

with open(sys.argv[2]) as f:
    f.next()
    print 'id,terminalName,name,installed,locked,temporary,lat,lng,elevation'
    for line in f:
        id,terminalName,name,installed,locked,temporary,lat,lng = line.strip().split(',')
        elevation = t.get(float(lng), float(lat))
        print ','.join([id,terminalName,name,installed,locked,temporary,lat,lng,str(elevation)])
