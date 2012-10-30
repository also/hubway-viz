WIDTH = 1024
HEIGHT = 768

renderer = new THREE.WebGLRenderer antialias: true
renderer.setSize WIDTH, HEIGHT
renderer.setClearColorHex 0xdedede

camera = new THREE.PerspectiveCamera 45, WIDTH / HEIGHT, 0.1, 10000
camera.position.x = 1300
camera.position.y = 600
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
  displacementScale: { type: "f", value: 200 }
}

material =
  new THREE.ShaderMaterial
    wireframe: false,
    attributes: attributes,
    uniforms: uniforms,
    vertexShader:   '''
      uniform sampler2D displacement;
      uniform float displacementScale;

      varying vec4 color;
      varying vec2 vUv;

      void main() {
        vUv = uv;
        color = texture2D( displacement, uv );
        vec3 dv = color.xyz;
        gl_Position = projectionMatrix *
                      modelViewMatrix *
                      vec4(position.xy, dv.x * displacementScale, 1.0);
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
      }
    '''


plane = new THREE.PlaneGeometry 3200, 2400, 256, 256

terrain = new THREE.Mesh plane, material

terrain.position.set 0, -125, 0
terrain.rotation.x = -Math.PI / 2
scene.add terrain

$('#map').append renderer.domElement

render = ->
  t = Date.now() * 0.0008
  camera.position.x = (Math.cos( t ) *  1300);
  camera.position.z = (Math.sin( t ) *  1300) ;
  camera.lookAt( scene.position )
  renderer.render scene, camera
  uniforms.displacementScale.value = (Math.cos( t ) * 700)
  requestAnimationFrame render
render()
