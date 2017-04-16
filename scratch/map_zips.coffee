center = [-71.058543, 42.367021]
xy = d3.geo.mercator().scale(899000)
offset = xy(center)
xy.translate([-offset[0] + 960, -offset[1] + 500])
path = d3.geo.path().projection(xy)
console.log xy([-71.058543, 42.367021])

vis = d3.select("#viz")
  .append("svg:svg")
  .attr("width", 900)
  .attr("height", 900)

d3.json "/output/zips_filtered.json", (json) ->
  vis.append("svg:g")
    .attr("class", "tracts")
  .selectAll("path")
    .data(json.features)
  .enter().append("svg:path")
    .attr("d", path)
    .attr("fill-opacity", 0.5)
    .attr("fill", (d) -> if d.properties["STATEFP10"] == "20" then "#B5D9B9" else "#85C3C0")
    .attr("stroke", "#222")
    console.log 'did it'

