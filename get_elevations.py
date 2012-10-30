import sys
from geo_tiff import GeoTiff

t = GeoTiff(sys.argv[1])

with open(sys.argv[2]) as f:
    f.next()
    print 'id,terminalName,name,installed,locked,temporary,lat,lng,elevation'
    for line in f:
        id,terminalName,name,installed,locked,temporary,lat,lng = line.strip().split(',')
        elevation = t.get(float(lng), float(lat))
        print ','.join([id,terminalName,name,installed,locked,temporary,lat,lng,str(elevation)])
