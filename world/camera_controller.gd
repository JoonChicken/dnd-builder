extends Node3D

enum modes {VIEWMODE, EDITMODE, PLAYMODE}
var current_mode := modes.VIEWMODE

var camera_root
var camera
var root_visual

@export var meterstick_material : ShaderMaterial

@export var camera_target_pos := Vector3.ZERO
var target_y_save : float # for up down snapping movement
var snap_vertically := false
@export var camera_drag := 10.0
var camera_max_speed := 4.0    # how fast camera translates when pressing WASDEQ
var camera_rotate_mult := 0.003    # mouse movement in viewport (pixels) to rotation of camera (radians)
var camera_zoom_mult := 1.0
var camera_default_zoom_perspective : float  # how far away the camera is from its origin (in meters)
var camera_default_zoom_orthogonal : float
var prev_mouse_pos := Vector2.ZERO
var prev_global_mouse_pos := Vector3.ZERO

var viewmode_root_rotation_save : Vector3
var viewmode_root_height_save : float

@onready var stencil_viewport : SubViewport = $CameraRoot/SubViewport
@onready var stencil_cam : Camera3D = $CameraRoot/SubViewport/StencilCam


func _ready() -> void:
    camera_root = $CameraRoot
    camera = $CameraRoot/OrbitCam
    root_visual = $CameraRoot/RootVisual
    camera_default_zoom_perspective = camera.position.z
    camera_default_zoom_orthogonal = 5.0


func _process(delta: float) -> void:
    # setup fake stencil buffer for selection outline
    var viewport := get_viewport()
    var current_camera := viewport.get_camera_3d()
    if stencil_viewport.size != viewport.size:
        stencil_viewport.size = viewport.size
    if current_camera:
        stencil_cam.fov = current_camera.fov
        stencil_cam.size = current_camera.size
        stencil_cam.projection = current_camera.projection
        stencil_cam.global_transform = current_camera.global_transform
    
    # get movement from WASDQE
    var direction := Vector3.ZERO
    var target_speed = camera_max_speed * (3 if Input.is_action_pressed("shift") else 1)
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
        
    if direction != Vector3.ZERO:
        direction = direction.normalized().rotated(Vector3.UP, camera_root.rotation.y)
        camera_target_pos += direction * camera_zoom_mult * target_speed * delta;
    
    if Input.is_action_just_pressed("snapping"):
        target_y_save = camera_target_pos.y
    if Input.is_action_pressed("snapping"):
        if direction.y != 0.0 && (Input.is_action_just_pressed("camera_up") || Input.is_action_just_pressed("camera_down")):
            var target_pos_modifier := 0.0
            if snap_vertically:
                target_pos_modifier += 0.49
            if direction.y > 0.0:
                target_y_save = ceil(camera_root.position.y + target_pos_modifier + 0.001)
            else:
                target_y_save = floor(camera_root.position.y - target_pos_modifier - 0.001)
            snap_vertically = true
        camera_target_pos.y = target_y_save
    if snap_vertically:
        if abs(camera_root.position.y - target_y_save) < 0.0001:
            snap_vertically = false
            
    # zooming - if in edit mode, then zoom toward mouse cursor
    var zoomed := false
    if Input.is_action_just_pressed("zoom_in"):
        zoomed = true
        prev_global_mouse_pos = get_mouse_pos()
        camera_zoom_mult *= 0.8
        if current_mode == modes.EDITMODE:
            camera.size *= 0.8 # orthogonal stuff
        camera.position.z = camera_zoom_mult * camera_default_zoom_perspective
        root_visual.mesh.radius = 0.01 * camera_zoom_mult
        root_visual.mesh.height = 0.02 * camera_zoom_mult
    if Input.is_action_just_pressed("zoom_out"):
        zoomed = true
        prev_global_mouse_pos = get_mouse_pos()
        camera_zoom_mult *= 1.25
        if current_mode == modes.EDITMODE:
            camera.size *= 1.25
        camera.position.z = camera_zoom_mult * camera_default_zoom_perspective
        root_visual.mesh.radius = 0.01 * camera_zoom_mult
        root_visual.mesh.height = 0.02 * camera_zoom_mult      
        
    # get rotation of camera from mouse pos
    # OR if in edit mode, translate the camera
    if Input.is_action_just_pressed("camera_orbit"):
        if current_mode == modes.EDITMODE:
            prev_global_mouse_pos = get_mouse_pos()
        else:
            prev_mouse_pos = get_viewport().get_mouse_position()
    if Input.is_action_pressed("camera_orbit"):
        if current_mode == modes.EDITMODE:
            camera_target_pos += prev_global_mouse_pos - get_mouse_pos()
            camera_root.position = camera_target_pos
        else:
            var curr_mouse_pos := get_viewport().get_mouse_position()
            camera_root.rotation.y -= (curr_mouse_pos.x - prev_mouse_pos.x) * camera_rotate_mult
            camera_root.rotation.x -= clamp((curr_mouse_pos.y - prev_mouse_pos.y) * camera_rotate_mult, -PI/2, PI/2)
            prev_mouse_pos = curr_mouse_pos  
    
    if current_mode == modes.EDITMODE and zoomed:
        camera_target_pos += prev_global_mouse_pos - get_mouse_pos()
        camera_root.position = camera_target_pos
    
    $target_visual.position = camera_target_pos # DEBUG
    
    var velocity_actual = (camera_target_pos - camera_root.position) * camera_drag
    camera_root.position += velocity_actual * delta
    
    # make meterstick to represent distance of camera above the ground plane
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
    $Meterstick.mesh = linemesh
            

func change_viewmode(new_mode: int) -> void:
    if new_mode == modes.EDITMODE:
        camera.projection = 1 # orthogonal projection
        camera.size = camera_default_zoom_orthogonal
        root_visual.hide()
        $Meterstick.hide()
    else:
        camera.projection = 0 # perspective projection
        root_visual.show()
        $Meterstick.show()
    if current_mode != modes.EDITMODE && new_mode == modes.EDITMODE:
        viewmode_root_rotation_save = camera_root.rotation
        viewmode_root_height_save = camera_root.position.y
        camera_root.rotation = Vector3(-PI/2, 0.0, 0.0)
        camera.size = camera_default_zoom_orthogonal * camera_zoom_mult
        root_visual.hide()
        $Meterstick.hide()
    elif current_mode == modes.EDITMODE && new_mode != modes.EDITMODE:
        camera_root.rotation = viewmode_root_rotation_save
        camera_root.position.y = viewmode_root_height_save
        root_visual.show()
        $Meterstick.show()
    @warning_ignore("int_as_enum_without_cast")
    current_mode = new_mode
    
    
func get_mouse_pos():
    # Thanks Okan Ozdemir!
    # https://forum.godotengine.org/t/how-to-get-3d-position-of-the-mouse-cursor/28741/2
    var position2D : Vector2 = get_viewport().get_mouse_position()
    var dropPlane := Plane.PLANE_XZ
    var position3D = dropPlane.intersects_ray(camera.project_ray_origin(position2D),camera.project_ray_normal(position2D))
    return position3D
