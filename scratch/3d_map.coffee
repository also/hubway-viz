WIDTH = 1280
HEIGHT = 768

XZ_DIST = 1300
Y_DIST = 800
raster_size = [1603, 1210]
MESH_SIZE = raster_size.map (d) -> 2 * d
HALF_MESH_SIZE = MESH_SIZE.map (d) -> d / 2

raster_extents = [[-71.1968322667838, 42.40411270085955, 0.0], [-71.0019543893125, 42.40411270085955, 0.0], [-71.0019543893125, 42.29540555285923, 0.0], [-71.1968322667838, 42.29540555285923, 0.0]]

class ParticleBuffer
  constructor: (@particles) ->
    @firstParticleIndex = 0
    @newParticleIndex = 0

  allocate: (items, callback) ->
    for item in items
      particle = @particles[@newParticleIndex]
      callback item, particle
      # TODO check if newParticleIndex == firstParticleIndex
      @newParticleIndex = (@newParticleIndex + 1) % @particles.length

  update: (t, callback) ->
    # hide the old particles
    particleIndex = @firstParticleIndex
    loop
      if particleIndex == @newParticleIndex
        break
      nextParticleIndex = (particleIndex + 1) % @particles.length
      particle = @particles[particleIndex]
      if particle.removeT <= t
        particle.hide()
        if particle.endT <= t
          @firstParticleIndex = nextParticleIndex
      else
        callback? particle
      particleIndex = nextParticleIndex

create_proj = ->
  geo_width = (raster_extents[1][0] - raster_extents[0][0]) / 360
  scale = MESH_SIZE[0] / geo_width

  #console.log 'MESH_SIZE', MESH_SIZE
  proj = d3.geo.mercator().translate([0,0]).scale(scale)
  a = proj raster_extents[0]
  b = proj raster_extents[2]

  proj_width = b[0] - a[0]
  PROJ_SIZE = [b[0] - a[0], b[1] - a[1]]
  #console.log 'PROJ_SIZE', PROJ_SIZE
  proj.translate [-a[0] - HALF_MESH_SIZE[0], -a[1] - HALF_MESH_SIZE[1]]
  proj

proj = create_proj()
data = null
first_trip_time = null
hwdv.load_data '../output/', (d) ->
  data = d
  stations = []
  for s in data.stations_geo.features
    stations[Math.floor s.properties.ID] = name: s.properties.NAME, coordinates: s.geometry.coordinates
  data.stations = stations
  create_station_markers data.stations_geo
  first_trip_time = data.trips.get(0).start_date.getTime()
  animate()

renderer = new THREE.WebGLRenderer antialias: true
renderer.setSize WIDTH, HEIGHT
renderer.setClearColorHex 0xdedede

camera = new THREE.PerspectiveCamera 45, WIDTH / HEIGHT, 0.1, 10000
camera.position.x = XZ_DIST
camera.position.y = Y_DIST
camera.position.z = XZ_DIST

scene = new THREE.Scene
camera.lookAt scene.position
scene.add camera

displacement = THREE.ImageUtils.loadTexture '../output/lidar.png'
colors = THREE.ImageUtils.loadTexture '../output/lidar-colored.png'
station_marker = THREE.ImageUtils.loadTexture '../images/hubway-station-marker.png'

create_terrain = ->
  attributes = {}
  uniforms = {
    displacement: { type: "t", value: displacement }
    colors: { type: "t", value: colors }
    displacementScale: { type: "f", value: 125 }
  }

  material =
    new THREE.ShaderMaterial
      wireframe: false,
      attributes: attributes,
      uniforms: uniforms,
      vertexShader:   '''
        uniform sampler2D displacement;
        uniform sampler2D colors;
        uniform float displacementScale;

        varying vec4 color;
        varying vec2 vUv;

        void main() {
          vUv = uv;
          color = texture2D( colors, uv );
          float d = texture2D( displacement, uv ).x;
          gl_Position = projectionMatrix *
                        modelViewMatrix *
                        vec4(position.xy, d * displacementScale, 1.0);
        }
      ''',
      fragmentShader: '''
        varying vec4 color;
        varying vec2 vUv;
        uniform sampler2D displacement;
        uniform sampler2D colors;
        void main() {
          gl_FragColor = vec4(0.4, 0.4, 0.4, 1);
          gl_FragColor = texture2D(colors, vUv);
          if (gl_FragColor.g == 0.0) {
            gl_FragColor = vec4(0.8, 0.8, 0.8, 1.0);
          }
          //gl_FragColor = color;
        }
      '''


  plane = new THREE.PlaneGeometry MESH_SIZE[0], MESH_SIZE[1], 256, 256

  terrain = new THREE.Mesh plane, material

  terrain.rotation.x = -Math.PI / 2
  scene.add terrain

create_station_markers = (stations_geo) ->
  material = new THREE.ParticleBasicMaterial color: 0xFFFFFF, size: 15, map: station_marker, transparent: true, sizeAttenuation: false, depthTest: false
  geometry = new THREE.Geometry
  for s in stations_geo.features
    p = proj s.geometry.coordinates
    v = new THREE.Vector3 p[0], 1, p[1]
    geometry.vertices.push v
  ps = new THREE.ParticleSystem geometry, material
  ps.sortParticles = true
  scene.add ps

create_particles = ->
  uniforms = {
    displacement: { type: "t", value: displacement }
    displacementScale: { type: "f", value: 125 }
  }

  material = new THREE.ShaderMaterial
      uniforms: uniforms
      transparent: true
      vertexShader: """
        uniform sampler2D displacement;
        uniform float displacementScale;

        void main() {
          gl_PointSize = 5.0;
          vec2 texturePos = vec2((position.x + #{HALF_MESH_SIZE[0].toFixed(1)}) / #{MESH_SIZE[0].toFixed(1)}, (#{HALF_MESH_SIZE[1].toFixed(1)} - position.z) / #{MESH_SIZE[1].toFixed(1)});
          float d = texture2D(displacement, texturePos).x;
          gl_Position = projectionMatrix *
                        modelViewMatrix *
                        vec4(position.x, d * displacementScale + 10.0, position.z, 1.0);
        }
      """
      fragmentShader: '''
        void main() {
          gl_FragColor = vec4(0, 1, 0, 1);
        }
      '''
  geometry = new THREE.Geometry
  particles = []
  for i in [0...10000]
    v = new THREE.Vector3 0, -100, 0
    #v = new THREE.Vector3 Math.random() * MESH_SIZE[0] - HALF_MESH_SIZE[0], 10, Math.random() * MESH_SIZE[1] - HALF_MESH_SIZE[1]
    p = do (v) ->
      setPosition: ([x,y]) ->
        v.set x, 10, y
        geometry.verticesNeedUpdate = true
      hide: ->
        v.set 0, -100, 0
        geometry.verticesNeedUpdate = true
    particles.push p
    geometry.vertices.push v
  ps = new THREE.ParticleSystem geometry, material
  scene.add ps
  new ParticleBuffer particles

create_terrain()
particle_buffer = create_particles()

$('#map').append renderer.domElement

startTime = Date.now()

animate = ->
  window.requestAnimationFrame (t) ->
    nextFrame t - startTime
    animate()

nextFrame = (t) ->
  camera.position.x = Math.cos(t * 0.0002) * XZ_DIST
  camera.position.z = Math.sin(t * 0.0002) * XZ_DIST
  camera.lookAt scene.position
  update_particles t
  renderer.render scene, camera

i = 0
update_particles = (t) ->
  trip = data.trips.get i
  start_time = trip.start_date.getTime()
  start_offset = start_time - first_trip_time
  if start_offset / 1000 / 60 > t
    return
  i++
  #console.log station
  particle_buffer.allocate [trip], (trip, particle) ->
    start_station = data.stations[trip.start_station]
    end_station = data.stations[trip.end_station]
    particle.start_station = start_station
    particle.end_station = end_station
    particle.start = proj start_station.coordinates
    particle.end = proj end_station.coordinates
    particle.setPosition particle.start
    particle.startT = t
    particle.removeT = t + Math.min(trip.duration * 1000, 60000)
    particle.endT = t + 60000
  particle_buffer.update t, (particle) ->
    p = (t - particle.startT) / (particle.endT - particle.startT)
    pos = [
      particle.start[0] + p * (particle.end[0] - particle.start[0]),
      particle.start[1] + p * (particle.end[1] - particle.start[1])
    ]
    particle.setPosition pos

