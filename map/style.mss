@water: #a5bfdd;
@park: #c9dfaf;
@land: #efebe2;
@hubway-green: #49a942;

Map {
  background-color: @water;
}

#land {
  polygon-fill: @land;
  //comp-op: dst-atop;
}

#elevation-hillshade {
  raster-opacity: 1;
  raster-scaling: bilinear;
}

#buildings {
  polygon-fill: #ddd;
}

#natural[type='water'] {
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

#waterways {
  line-width: 2;
  line-color: @water;
}

#roads {
  ::stroke {
    line-color: white;
    line-width: 4;
  }
  line-color: #999;
  line-width: 0.5;
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