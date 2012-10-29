`function toArrayBuffer(buffer) {
    var ab = new ArrayBuffer(buffer.length);
    var view = new Uint8Array(ab);
    for (var i = 0; i < buffer.length; ++i) {
        view[i] = buffer[i];
    }
    return ab;
}`

class PackedTripRecords
  constructor: (array_buffer, @date_ranges) ->
    @data = new Int32Array array_buffer
    @length = @data.length / 2

  get: (index) ->
    a = @data[index * 2]
    b = @data[index * 2 + 1]
    user_index = a & 0xfff
    a >>>= 12
    bike_index = a & 0x3ff
    a >>>= 10
    end_station = a & 0x7f
    a >>>= 7
    start_station = (a | (b << 3)) & 0x7f
    b >>>= 4
    duration = b & 0x1fff
    b >>>= 13
    start_date_error = b << 17 >> 17

    if index >= @date_ranges[1].i
      coeffs = @date_ranges[1].coeffs
    else
      coeffs = @date_ranges[0].coeffs
    estimated_start_date = ~~ (coeffs[2] * index*index + coeffs[1] * index + coeffs[0])
    start_ts = estimated_start_date - start_date_error
    start_date = new Date start_ts * 60000
    {index, start_date, duration, start_station, end_station, bike_index, user_index}

parse_users = (str) ->
  for line in str.split '\n'
    [zip_code, year, gender] = line.split ','
    zip_code = null if zip_code == ''
    year = if year == '' then null else parseInt(year, 10)
    gender = null if gender == ''
    registered = !!(gender or year or zip_code)
    {zip_code, year, gender, registered}

load_data = (path, callback) ->
  fs = null
  if module?
    fs = require 'fs'
    read_text_sync = (filename) -> fs.readFileSync "#{path}/#{filename}", 'utf8'
    read_bin_async = (filename, callback) -> fs.readFile "#{path}/#{filename}", (err, data) ->
      callback toArrayBuffer data
  else
    read_text_sync = (filename) ->
      xhr = new XMLHttpRequest
      xhr.open 'GET', "#{path}/#{filename}", false
      xhr.send()
      xhr.response
    read_bin_async = (filename, callback) ->
      xhr = new XMLHttpRequest
      xhr.open 'GET', "#{path}/#{filename}", true
      xhr.responseType = 'arraybuffer'
      xhr.onload = ->
        callback xhr.response
      xhr.send()

  date_ranges = JSON.parse read_text_sync 'date_ranges.json'
  users = parse_users read_text_sync 'users.txt'
  zips_geo = JSON.parse read_text_sync 'zips_filtered.json'

  read_bin_async '/output/trips_packed', (d) ->
    trips = new hwdv.PackedTripRecords(d, date_ranges)
    callback {trips, users, zips_geo}

hwdv = @hwdv = {
  PackedTripRecords,
  load_data,
  parse_users
}
