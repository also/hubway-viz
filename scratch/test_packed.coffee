hwdv.load_data ({trips}) ->
  start_time = new Date
  for i in [0...trips.length]
    record = trips.get i
  end_time = new Date
  console.log "done #{trips.length} in #{end_time - start_time}"
