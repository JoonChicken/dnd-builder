extends Node3D

var camera_root
var camera

var velocity := Vector3.ZERO
@export var camera_max_speed := 10.0    # how fast camera translates when pressing WASDEQ
@export var camera_rotate_mult := 0.003    # mouse movement in viewport (pixels) to rotation of camera (radians)
@export var camera_zoom_mult := 1.0

var camera_default_zoom : float  # how far away the camera is from its origin (in meters)

var prev_mouse_pos := Vector2.ZERO


func _ready() -> void:
    camera_root = $CameraRoot
    camera = $CameraRoot/Camera
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
    if Input.is_action_just_pressed("zoom_out"):
        camera_zoom_mult *= 1.1
        camera.position.z = camera_zoom_mult * camera_default_zoom
        
    if Input.is_action_just_pressed("camera_orbit"):
        prev_mouse_pos = get_viewport().get_mouse_position()
    if Input.is_action_pressed("camera_orbit"):
        var curr_mouse_pos = get_viewport().get_mouse_position()
        camera_root.rotation.y -= (curr_mouse_pos.x - prev_mouse_pos.x) * camera_rotate_mult
        camera_root.rotation.x -= clamp((curr_mouse_pos.y - prev_mouse_pos.y) * camera_rotate_mult, -PI/2, PI/2)
        prev_mouse_pos = curr_mouse_pos
        
    if direction != Vector3.ZERO:
        direction = direction.normalized().rotated(Vector3.UP, camera_root.rotation.y)
        velocity += direction
    else:
        velocity *= 0.8
    
    velocity = velocity.limit_length(camera_max_speed)
    camera_root.position += velocity * camera_zoom_mult * delta
