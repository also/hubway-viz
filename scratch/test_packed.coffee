hwdv.load_data (records) ->
  start_time = new Date
  for i in [0...records.length]
    record = records.get i
  end_time = new Date
  console.log "done #{records.length} in #{end_time - start_time}"
