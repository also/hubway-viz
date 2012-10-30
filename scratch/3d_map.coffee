WIDTH = 1024
HEIGHT = 768

renderer = new THREE.WebGLRenderer
renderer.setSize WIDTH, HEIGHT
renderer.setClearColorHex 0xdedede

camera = new THREE.PerspectiveCamera 45, WIDTH / HEIGHT, 0.1, 10000
camera.position.x = 1300
camera.position.y = 600
camera.position.z = 1300


scene = new THREE.Scene
camera.lookAt scene.position
scene.add camera

material = new THREE.MeshBasicMaterial wireframe: true, color: 0x666666
plane = new THREE.PlaneGeometry 3200, 2400, 25, 25

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
  requestAnimationFrame render
render()
