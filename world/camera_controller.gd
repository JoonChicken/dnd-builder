extends Node3D

enum modes {VIEWMODE, EDITMODE, PLAYMODE}
var current_mode := modes.VIEWMODE

var camera_root
var camera
var root_visual

@export var meterstick_material : ShaderMaterial

var velocity := Vector3.ZERO
@export var camera_max_speed := 8.0    # how fast camera translates when pressing WASDEQ
@export var camera_rotate_mult := 0.003    # mouse movement in viewport (pixels) to rotation of camera (radians)
@export var camera_zoom_mult := 1.0
var camera_default_zoom : float  # how far away the camera is from its origin (in meters)
var prev_mouse_pos := Vector2.ZERO

var viewmode_root_rotation_save : Vector3
var viewmode_root_height_save : float
var viewmode_camera_zoom_save : float


func _ready() -> void:
    camera_root = $CameraRoot
    camera = $CameraRoot/OrbitCam
    root_visual = $CameraRoot/root_visual
    camera_default_zoom = camera.position.z


func _process(delta: float) -> void: 
    var direction := Vector3.ZERO
    
    if Input.is_action_pressed("camera_forward"):
        direction.z -= 1
    if Input.is_action_pressed("camera_back"):
        direction.z += 1
    if Input.is_action_pressed("camera_left"):
        direction.x -= 1
    if Input.is_action_pressed("camera_right"):
        direction.x += 1
    if Input.is_action_pressed("camera_up"):
        direction.y += 1
    if Input.is_action_pressed("camera_down"):
        direction.y -= 1
    if Input.is_action_just_pressed("zoom_in"):
        camera_zoom_mult *= 0.9
        camera.position.z = camera_zoom_mult * camera_default_zoom
        root_visual.mesh.radius = 0.01 * camera_zoom_mult
        root_visual.mesh.height = 0.02 * camera_zoom_mult
    if Input.is_action_just_pressed("zoom_out"):
        camera_zoom_mult *= 1.1
        camera.position.z = camera_zoom_mult * camera_default_zoom
        root_visual.mesh.radius = 0.01 * camera_zoom_mult
        root_visual.mesh.height = 0.02 * camera_zoom_mult
        
    if current_mode != modes.EDITMODE:
        if Input.is_action_just_pressed("camera_orbit"):
            prev_mouse_pos = get_viewport().get_mouse_position()
        if Input.is_action_pressed("camera_orbit"):
            var curr_mouse_pos := get_viewport().get_mouse_position()
            camera_root.rotation.y -= (curr_mouse_pos.x - prev_mouse_pos.x) * camera_rotate_mult
            camera_root.rotation.x -= clamp((curr_mouse_pos.y - prev_mouse_pos.y) * camera_rotate_mult, -PI/2, PI/2)
            prev_mouse_pos = curr_mouse_pos
        
    if direction != Vector3.ZERO:
        direction = direction.normalized().rotated(Vector3.UP, camera_root.rotation.y)
        velocity += direction
    else:
        velocity *= 0.8
    
    velocity = velocity.limit_length(camera_max_speed)
    
    if Input.is_action_pressed("snapping"):
        velocity.y = 0.0
        if direction.y != 0.0 && (Input.is_action_just_pressed("camera_up") || Input.is_action_just_pressed("camera_down")):
            if direction.y > 0.0:
                camera_root.position.y = ceil(camera_root.position.y + 0.000001)
            else:
                camera_root.position.y = floor(camera_root.position.y - 0.000001)
    else:
        camera_root.position += velocity * camera_zoom_mult * 0.6 * delta
    
    var root_pos = camera_root.global_position
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_LINES)
    st.set_normal(Vector3.UP)
    st.set_uv(Vector2(0, 0))
    st.set_material(meterstick_material)
    st.add_vertex(Vector3(root_pos.x, 0, root_pos.z))
    st.set_normal(Vector3.DOWN)
    st.set_uv(Vector2(0, root_pos.y))
    st.set_material(meterstick_material)
    st.add_vertex(root_pos)
    var linemesh = st.commit()
    $root_to_plane.mesh = linemesh


func change_viewmode(new_mode: int) -> void:
    if new_mode == modes.EDITMODE:
        root_visual.hide()
        $root_to_plane.hide()
    else:
        root_visual.show()
        $root_to_plane.show()
    if current_mode != modes.EDITMODE && new_mode == modes.EDITMODE:
        viewmode_root_rotation_save = camera_root.rotation
        viewmode_root_height_save = camera_root.position.y
        camera_root.rotation = Vector3(-PI/2, 0.0, 0.0)
        camera_root.position.y = 0.0
        root_visual.hide()
        $root_to_plane.hide()
    elif current_mode == modes.EDITMODE && new_mode != modes.EDITMODE:
        camera_root.rotation = viewmode_root_rotation_save
        camera_root.position.y = viewmode_root_height_save
        root_visual.show()
        $root_to_plane.show()
    current_mode = new_mode
    print("Mode is now ", current_mode)
