extends CharacterBody3D

@export var camera_target_velocity := 5    # how fast camera translates when pressing WASDEQ
@export var camera_y_rotate_mult := 0.005   # mouse movement in viewport (pixels) to rotation of camera (radians)
@export var camera_x_rotate_mult := 0.005

var prev_mouse_pos := Vector2.ZERO

func _process(delta: float) -> void:
    var direction := Vector3.ZERO
    
    if Input.is_action_just_pressed("camera_orbit"):
       prev_mouse_pos = get_viewport().get_mouse_position() 
    if Input.is_action_pressed("camera_orbit"):
        var curr_mouse_pos = get_viewport().get_mouse_position()
        basis.rotated(Vector3.UP, (curr_mouse_pos.x - prev_mouse_pos.x) * camera_y_rotate_mult)
        basis.rotated(Vector3.RIGHT, clamp((curr_mouse_pos.y - prev_mouse_pos.y) * camera_x_rotate_mult, -PI/2, PI/2))
        prev_mouse_pos = curr_mouse_pos
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
        direction = direction.normalized()
        velocity = camera_target_velocity * direction
    else:
        velocity /= 1.2
    
    move_and_slide()
