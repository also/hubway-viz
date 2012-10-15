@water: #a5bfdd;
@park: #c9dfaf;
@land: #efebe2;
@hubway-green: #49a942;

Map {
  background-color: @land;
}

#land {
  polygon-fill: @land;
  comp-op: dst-atop;
}

#elevation-hillshade, #lidar {
  raster-opacity: 1;
  raster-scaling: bilinear;
}

#buildings {
  polygon-fill: #ddd;
}

#natural[type='water'],
#natural[type='riverbank'] {
  polygon-fill: @water;
  line-color: @water;
}

#natural[type='park'],
#natural[type='forest']{
  polygon-fill: @park;
}

#natural[type='shoreline'] {
  line-color: red;
  line-width: 10;
}

#roads {
  line-color: #333;
  line-width: 1;
  line-join: round;
  [type='motorway'], [type='motorway_link'] {
    line-width: 3;
  }
}

#stations {
  point-file: url(/Users/ryan/work/hubway-viz/images/hubway-station-marker.svg);
  marker-width: 20;
  point-allow-overlap: true;
}