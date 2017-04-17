require 'json'

File.open 'output/stations.csv' do |f|
  stations = {}
  f.each.drop(1).each do |l|
    id,terminalName,name,installed,locked,temporary,lat,lng,elevation = l.strip.split ','
    stations[id] = {
      :name => name,
      :pos => [lng.to_f,lat.to_f],
      :elevation => elevation.to_f
    }
  end
  puts stations.to_json
end
