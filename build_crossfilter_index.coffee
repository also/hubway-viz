fs = require 'fs'

{crossfilter} = require './scratch/crossfilter/crossfilter.js'
{hwdv} = require './scratch/data.coffee'


global.d3 = require 'd3'
global.crossfilter = crossfilter

`
function toBuffer(ab) {
    var buffer = new Buffer(ab.byteLength);
    var view = new Uint8Array(ab);
    for (var i = 0; i < buffer.length; ++i) {
        buffer[i] = view[i];
    }
    return buffer;
}
`

hwdv.load_data './output', (data) ->
  console.log data.trips.length
  filters = hwdv.create_filters data
  indexes = {}
  for name, dim of filters.dimension
    console.log name
    index = dim.index()
    console.log index.byteLength
    fs.writeFileSync "output/crossfilter_index/#{name}", toBuffer index.buffer

