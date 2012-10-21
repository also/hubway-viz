xhr = new XMLHttpRequest
xhr.open 'GET', '/output/date_ranges.json', false
xhr.send()
date_ranges = JSON.parse xhr.response

xhr = new XMLHttpRequest
xhr.open 'GET', '/output/trips_packed', true
xhr.responseType = 'arraybuffer'

xhr.onload = (e) ->
  if @status == 200
    d = e.target.response
    records = new hwdv.PackedTripRecords(d, date_ranges)
    start_time = new Date
    n = 0
    sum = 0
    for i in [0...records.length]
      n++
      record = records.get i
      sum += record.start_date
      sum %= 1000000
      #console.log start_date_error, duration, start_station, end_station, bike_index, user_index
    end_time = new Date
    console.log "done #{records.length} #{sum} in #{end_time - start_time}"

xhr.send()
