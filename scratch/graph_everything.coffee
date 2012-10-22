hwdv.load_data (data) ->
  records = for i in [0...data.trips.length]
    data.trips.get i
  console.log records[1029]

  trips = crossfilter records
  console.log 'created filter'
  all = trips.groupAll()
  # A nest operator, for grouping the trip list.
  nestByDate = d3.nest().key (d) -> d3.time.day(d.start_date)

  date = trips.dimension (d) -> d3.time.day(d.start_date)
  dates = date.group()
  start_hour = trips.dimension (d) -> d.start_date.getHours() + d.start_date.getMinutes() / 60
  start_hours = start_hour.group Math.floor
  duration = trips.dimension (d) -> d.duration
  durations = duration.group (d) -> ~~ (d / 5 * 60)
  gender = trips.dimension (d) -> data.users[d.user_index].gender
  genders = gender.group()
  console.log "top durations:", duration.top 10
  console.log "genders: ", genders.all()

  window.start_hour = start_hour
  window.start_hours = start_hours
  window.all = all

  addCharts()

`
function addCharts() {
    var charts = [

  barChart()
      .dimension(start_hour)
      .group(start_hours)
    .x(d3.scale.linear()
      .domain([0, 24])
      .rangeRound([0, 10 * 24])),
/*
  barChart()
      .dimension(delay)
      .group(delays)
    .x(d3.scale.linear()
      .domain([-60, 150])
      .rangeRound([0, 10 * 21])),

  barChart()
      .dimension(distance)
      .group(distances)
    .x(d3.scale.linear()
      .domain([0, 2000])
      .rangeRound([0, 10 * 40])),

  barChart()
      .dimension(date)
      .group(dates)
      .round(d3.time.day.round)
    .x(d3.time.scale()
      .domain([new Date(2001, 0, 1), new Date(2001, 3, 1)])
      .rangeRound([0, 10 * 90]))
      .filter([new Date(2001, 1, 1), new Date(2001, 2, 1)])
*/
];

// Given our array of charts, which we assume are in the same order as the
// .chart elements in the DOM, bind the charts to the DOM and render them.
// We also listen to the chart's brush events to update the display.
var chart = d3.selectAll(".chart")
    .data(charts)
    .each(function(chart) { chart.on("brush", renderAll).on("brushend", renderAll); });

    /*
// Render the initial lists.
var list = d3.selectAll(".list")
    .data([flightList]);
*/

/*
// Render the total.
d3.selectAll("#total")
    .text(formatNumber(flight.size()));
*/
renderAll();

// Renders the specified chart or list.
function render(method) {
  d3.select(this).call(method);
}

// Whenever the brush moves, re-rendering everything.
function renderAll() {
  chart.each(render);
  //list.each(render);
  d3.select("#active").text(formatNumber(all.value()));
}

window.filter = function(filters) {
  filters.forEach(function(d, i) { charts[i].filter(d); });
  renderAll();
};

window.reset = function(i) {
  charts[i].filter(null);
  renderAll();
};
}
`
