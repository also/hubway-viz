WIDTH = 1280
HEIGHT = 768

raster_size = [1603, 1210]
MESH_SIZE = raster_size.map (d) -> 1 * d

raster_extents = [[-71.1968322667838, 42.40411270085955, 0.0], [-71.0019543893125, 42.40411270085955, 0.0], [-71.0019543893125, 42.29540555285923, 0.0], [-71.1968322667838, 42.29540555285923, 0.0]]

geo_width = (raster_extents[1][0] - raster_extents[0][0]) / 360
scale = MESH_SIZE[0] / geo_width

console.log 'MESH_SIZE', MESH_SIZE
proj = d3.geo.mercator().translate([0,0]).scale(scale)
a = proj raster_extents[0]
b = proj raster_extents[2]

proj_width = b[0] - a[0]
console.log 'PROJ_SIZE', [b[0] - a[0], b[1] - a[1]]
proj.translate [-a[0], -a[1]]
console.log proj(raster_extents[2])

renderer = new THREE.WebGLRenderer antialias: true
renderer.setSize WIDTH, HEIGHT
renderer.setClearColorHex 0xdedede

camera = new THREE.PerspectiveCamera 45, WIDTH / HEIGHT, 0.1, 10000
camera.position.x = 1300
camera.position.y = 300
camera.position.z = 1300


scene = new THREE.Scene
camera.lookAt scene.position
scene.add camera

displacement = THREE.ImageUtils.loadTexture '/output/lidar.png', null, null
colors = THREE.ImageUtils.loadTexture '/output/lidar-colored.png', null, null

attributes = {}
uniforms = {
  displacement: { type: "t", value: displacement }
  colors: { type: "t", value: colors }
  displacementScale: { type: "f", value: 75 }
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

terrain.position.set 0, -125, 0
terrain.rotation.x = -Math.PI / 2
scene.add terrain

$('#map').append renderer.domElement

render = ->
  t = Date.now() * 0.0002
  camera.position.x = (Math.cos( t ) *  400);
  camera.position.z = (Math.sin( t ) *  400) ;
  camera.lookAt( scene.position )
  renderer.render scene, camera
  #uniforms.displacementScale.value = (Math.cos( t ) * 700)
  requestAnimationFrame render
render()
