container = undefined
stats = undefined
camera = undefined
controls = undefined
scene = undefined
projector = undefined
renderer = undefined
plane = undefined
INTERSECTED = undefined
SELECTED = undefined

objects = []
mouse = new THREE.Vector2()
offset = new THREE.Vector3()

lineGeometry = undefined
lineCache = undefined

init = ->

  container = document.createElement('div');
  document.body.appendChild(container);

  camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 1, 100000);
  camera.position.z = 1000;

  controls = new THREE.TrackballControls(camera);
  controls.rotateSpeed = 1.0;
  controls.zoomSpeed = 1.2;
  controls.panSpeed = 0.8;
  controls.noZoom = false;
  controls.noPan = false;
  controls.staticMoving = true;
  controls.dynamicDampingFactor = 0.3;

  scene = new THREE.Scene();

  scene.add(new THREE.AmbientLight(0x505050));

  light = new THREE.SpotLight(0xffffff, 1.5);
  light.position.set(0, 500, 2000);
  light.castShadow = true;

  light.shadowCameraNear = 200;
  light.shadowCameraFar = camera.far;
  light.shadowCameraFov = 50;

  light.shadowBias = -0.00022;
  light.shadowDarkness = 0.5;

  light.shadowMapWidth = 2048;
  light.shadowMapHeight = 2048;

  scene.add(light);

  boxGeometry = new THREE.BoxGeometry(40, 40, 40);
  lineGeometry = new THREE.Geometry()

  for i in [1..5]
    rate = (i + 4) / 8
    object = new THREE.Mesh(boxGeometry, new THREE.MeshLambertMaterial({
      color: (0xff0000 * rate) + (0x00ff00 * rate) + (0x0000ff * rate)
    }));

    object.material.ambient = object.material.color;

    object.position.x = (i - 3) * 200
    object.position.y = 0
    object.position.z = 0

    object.castShadow = true;
    object.receiveShadow = true;

    scene.add(object);

    objects.push(object);

  plane = new THREE.Mesh(new THREE.PlaneGeometry(2000, 2000, 8, 8), new THREE.MeshBasicMaterial({
    color: 0x000000,
    opacity: 0.25,
    transparent: true,
    wireframe: true
  }));
  plane.visible = false;
  scene.add(plane);

  projector = new THREE.Projector();

  renderer = new THREE.WebGLRenderer({
    antialias: true
  });
  renderer.setClearColor(0xf0f0f0);
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.sortObjects = false;

  renderer.shadowMapEnabled = true;
  renderer.shadowMapType = THREE.PCFShadowMap;

  container.appendChild(renderer.domElement);

  renderer.domElement.addEventListener('mousemove', onDocumentMouseMove, false);
  renderer.domElement.addEventListener('mousedown', onDocumentMouseDown, false);
  renderer.domElement.addEventListener('mouseup', onDocumentMouseUp, false);


  window.addEventListener('resize', onWindowResize, false);

onWindowResize = ->

  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);

onDocumentMouseMove = (event) ->
  event.preventDefault();

  mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
  mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

  vector = new THREE.Vector3(mouse.x, mouse.y, 0.5);
  projector.unprojectVector(vector, camera);

  raycaster = new THREE.Raycaster(camera.position, vector.sub(camera.position).normalize());

  if SELECTED
    intersects = raycaster.intersectObject(plane);
    SELECTED.position.copy(intersects[0].point.sub(offset));

    myList = []
    for cube, index in objects
      p = cube.position
      myList.push x: p.x, y: p.y, z: p.z

    {bend} = require './bend'
    {three, four} = require "./three_quarter"

    result = data = myList.map four
    [1..6].forEach ->
      result = bend result, data

    lineGeometry.vertices = []
    result.forEach (a) ->
      lineGeometry.vertices.push (new THREE.Vector3 a.x, a.y, a.z)
    lineGeometry.verticesNeedUpdate = yes

    material = new THREE.LineBasicMaterial color: 0x0000ff
    line = new THREE.Line lineGeometry, material

    scene.remove lineCache if lineCache?
    scene.add line
    lineCache = line

    return;

  intersects = raycaster.intersectObjects(objects);

  if intersects.length > 0

    if INTERSECTED != intersects[0].object

      if INTERSECTED
        INTERSECTED.material.color.setHex(INTERSECTED.currentHex);

      INTERSECTED = intersects[0].object;
      INTERSECTED.currentHex = INTERSECTED.material.color.getHex();

      plane.position.copy(INTERSECTED.position);
      plane.lookAt(camera.position);

    container.style.cursor = 'pointer'

  else

    if INTERSECTED
      INTERSECTED.material.color.setHex(INTERSECTED.currentHex);

    INTERSECTED = null;

    container.style.cursor = 'auto';

onDocumentMouseDown = (event) ->

  event.preventDefault();

  vector = new THREE.Vector3(mouse.x, mouse.y, 0.5);
  projector.unprojectVector(vector, camera);

  raycaster = new THREE.Raycaster(camera.position, vector.sub(camera.position).normalize());

  intersects = raycaster.intersectObjects(objects);

  if intersects.length > 0

    controls.enabled = false;

    SELECTED = intersects[0].object;

    intersects = raycaster.intersectObject(plane);
    offset.copy(intersects[0].point).sub(plane.position);

    container.style.cursor = 'move';


onDocumentMouseUp = (event) ->

  event.preventDefault();

  controls.enabled = true;

  if INTERSECTED

    plane.position.copy(INTERSECTED.position);

    SELECTED = null;

  container.style.cursor = 'auto';

animate = ->
  setTimeout ->
    requestAnimationFrame(animate);
    render()
  , 20
    
render = ->
  controls.update();
  renderer.render(scene, camera);

init();
animate();
