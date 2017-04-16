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

load_crossfilter_indexes = (path, callback) ->
  names = ['date', 'start_hour', 'start_day_of_week', 'duration', 'gender', 'age', 'registration', 'zip']
  indexes_to_read = 0
  indexes = {}

  read_index = (name) ->
    indexes_to_read++
    xhr = new XMLHttpRequest
    xhr.open 'GET', "#{path}/crossfilter_index/#{name}", true
    xhr.responseType = 'arraybuffer'
    xhr.onload = ->
      indexes[name] = new Int32Array xhr.response
      indexes_to_read--
      callback indexes if indexes_to_read == 0
    xhr.send()

  read_index name for name in names

load_data = (path, callback) ->
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
  stations_geo = JSON.parse read_text_sync 'stations_geo.json'

  read_bin_async 'trips_packed', (d) ->
    trips = new hwdv.PackedTripRecords(d, date_ranges)
    callback {trips, users, zips_geo, stations_geo}

create_filters = (data, index) ->
  index ?= {}
  records = for i in [0...data.trips.length]
    data.trips.get i
  trips = crossfilter records
  all = trips.groupAll()
  date = trips.dimension ((d) -> d3.time.day(d.start_date)), index.date
  dates = date.group()
  start_hour = trips.dimension ((d) -> d.start_date.getHours() + d.start_date.getMinutes() / 60), index.start_hour
  start_hours = start_hour.group Math.floor
  start_day_of_week = trips.dimension ((d) -> (d.start_date.getDay() + 1) % 7), index.start_day_of_week
  start_day_of_weeks = start_day_of_week.group()
  duration = trips.dimension ((d) -> d.duration), index.duration
  durations = duration.group()
  gender = trips.dimension ((d) -> (data.users[d.user_index].gender ? "Unknown")[0]), index.gender
  genders = gender.group()
  age = trips.dimension ((d) -> 2012 - (data.users[d.user_index].year ? 2012)), index.age
  ages = age.group()
  registration = trips.dimension ((d) -> data.users[d.user_index].registered), index.registration
  registrations = registration.group()
  zip = trips.dimension ((d) -> data.users[d.user_index].zip_code ? ''), index.zip
  zips = zip.group()
  {
    trips,
    all,
    dimension: {date, start_hour, start_day_of_week, duration, gender, age, registration, zip},
    group: {dates, start_hours, start_day_of_weeks, durations, genders, ages, registrations, zips}
  }

hwdv = @hwdv = {
  PackedTripRecords,
  load_data,
  load_crossfilter_indexes,
  parse_users,
  create_filters
}
