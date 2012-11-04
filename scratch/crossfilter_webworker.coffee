# just trick d3 into working enough to get it's helper functions
self.CSSStyleDeclaration = {prototype: {}}
self.document = {documentElement: {}}
self.window = {}

importScripts 'd3/d3.v2.js', 'crossfilter/crossfilter.js', 'data.js'

data = null

handleMessage = (e) ->
  [type, payload] = e.data
  if type == 'init'
    data = payload
    data.trips = new hwdv.PackedTripRecords data.trips.data, data.trips.date_ranges
    filters = hwdv.create_filters data
    dimensions = {}
    for name, dim of filters.dimension
      dimensions[name] =
        index: dim.index()
        values: dim.sortedValues()
    self.postMessage ['indexes', dimensions]

self.addEventListener 'message', handleMessage, false


