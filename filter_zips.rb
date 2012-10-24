require 'json'
require 'set'

require './data'

zips = Set.new

USER_INDEX.keys.each do |u|
  zip = u.split(',')[0]
  zips << zip if !zip.nil? && zip.length == 5
end

#puts zips.length

data = nil
File.open 'output/zips.json' do |f|
  data = JSON.load f
  active_zips = data['features'].find_all do |feature|
    zips.include? feature['properties']['ZCTA5CE10']
  end
  #puts active_zips.length
  data['features'] = active_zips
end

File.open 'output/zips_filtered.json', 'w' do |f|
  JSON.dump data, f
end
