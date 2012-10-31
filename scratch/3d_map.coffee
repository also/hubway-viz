WIDTH = 1280
HEIGHT = 768

XZ_DIST = 1300
raster_size = [1603, 1210]
MESH_SIZE = raster_size.map (d) -> 2 * d
HALF_MESH_SIZE = MESH_SIZE.map (d) -> d / 2

raster_extents = [[-71.1968322667838, 42.40411270085955, 0.0], [-71.0019543893125, 42.40411270085955, 0.0], [-71.0019543893125, 42.29540555285923, 0.0], [-71.1968322667838, 42.29540555285923, 0.0]]

create_proj = ->
  geo_width = (raster_extents[1][0] - raster_extents[0][0]) / 360
  scale = MESH_SIZE[0] / geo_width

  console.log 'MESH_SIZE', MESH_SIZE
  proj = d3.geo.mercator().translate([0,0]).scale(scale)
  a = proj raster_extents[0]
  b = proj raster_extents[2]

  proj_width = b[0] - a[0]
  PROJ_SIZE = [b[0] - a[0], b[1] - a[1]]
  console.log 'PROJ_SIZE', PROJ_SIZE
  proj.translate [-a[0] - HALF_MESH_SIZE[0], -a[1] - HALF_MESH_SIZE[1]]
  proj

proj = create_proj()

hwdv.load_data '../output/', (data) ->
  console.log data
  create_station_markers data.stations_geo

renderer = new THREE.WebGLRenderer antialias: true
renderer.setSize WIDTH, HEIGHT
renderer.setClearColorHex 0xdedede

camera = new THREE.PerspectiveCamera 45, WIDTH / HEIGHT, 0.1, 10000
camera.position.x = XZ_DIST
camera.position.y = 600
camera.position.z = XZ_DIST

scene = new THREE.Scene
camera.lookAt scene.position
scene.add camera

displacement = THREE.ImageUtils.loadTexture '/output/lidar.png'
colors = THREE.ImageUtils.loadTexture '/output/lidar-colored.png'
station_marker = THREE.ImageUtils.loadTexture '/images/hubway-station-marker.png'

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
          gl_FragColor = texture2D( colors, vUv );
          //gl_FragColor = color;
        }
      '''


  plane = new THREE.PlaneGeometry MESH_SIZE[0], MESH_SIZE[1], 256, 256

  terrain = new THREE.Mesh plane, material

  terrain.rotation.x = -Math.PI / 2
  scene.add terrain

create_station_markers = (stations_geo) ->
  material = new THREE.ParticleBasicMaterial color: 0xFFFFFF, size: 20, map: station_marker, transparent: true, sizeAttenuation: false, depthTest: false
  geometry = new THREE.Geometry
  for s in stations_geo.features
    p = proj s.geometry.coordinates
    console.log p
    v = new THREE.Vector3 p[0], 1, p[1]
    geometry.vertices.push v
  ps = new THREE.ParticleSystem geometry, material
  ps.sortParticles = true
  scene.add ps

particle_buffer = create_particles = ->
  material = new THREE.ParticleBasicMaterial color: 0xFFFFFF, size: 8
  geometry = new THREE.Geometry
  for i in [0..10000]
    v = new THREE.Vector3 Math.random() * 5000 - 2500, 100, Math.random() * 5000 - 2500
    geometry.vertices.push v
  ps = new THREE.ParticleSystem geometry, material
  #scene.add ps
  new globe.ParticleBuffer particleCount: 5000, size: 5

create_terrain()
create_particles()

$('#map').append renderer.domElement

render = ->
  t = Date.now() * 0.0002
  camera.position.x = (Math.cos( t ) *  XZ_DIST);
  camera.position.z = (Math.sin( t ) *  XZ_DIST) ;
  camera.lookAt( scene.position )
  renderer.render scene, camera
  #uniforms.displacementScale.value = (Math.cos( t ) * 700)
  requestAnimationFrame render
render()
