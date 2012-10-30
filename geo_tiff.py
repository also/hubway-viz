import struct

from osgeo import gdal, osr

class GeoTiff(object):
    def __init__(self, filename):
        self.ds = gdal.Open(filename)
        self.width = self.ds.RasterXSize
        self.height = self.ds.RasterYSize
        self.gt = gt = self.ds.GetGeoTransform()

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

    def get_extents(self):
        return [
            self._get_corner(0.0, 0.0),
            self._get_corner(self.ds.RasterXSize, 0.0),
            self._get_corner(self.ds.RasterXSize, self.ds.RasterYSize),
            self._get_corner(0.0, self.ds.RasterYSize)
        ]

    def get_geo_extents(self):
        return [self.transform.TransformPoint(*p) for p in self.get_extents()]

    def _get_corner(self, x, y):
        geo_x = self.gt[0] + self.gt[1] * x + self.gt[2] * y
        geo_y = self.gt[3] + self.gt[4] * x + self.gt[5] * y
        return (geo_x, geo_y)


    def get(self, lng, lat):
        x, y, z = self.transform_to_ds.TransformPoint(lng, lat)
        x -= self.minx
        y -= self.miny
        y = self.height - y

        band = self.ds.GetRasterBand(1)
        datatype = band.DataType
        values = band.ReadRaster(int(x), int(y), 1, 1, 1, 1, datatype)
        return struct.unpack('f' * 1, values)[0]
