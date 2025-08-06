extends Node3D

enum modes {VIEWMODE, EDITMODE, PLAYMODE}
var current_mode := modes.VIEWMODE

var snap : bool
var mouse_global_coords
var vertex_preview
 

func _ready() -> void:
    snap = false
    vertex_preview = $World/VertexPreview
    vertex_preview.hide()


func change_viewmode() -> void:
    current_mode = (current_mode + 1) % 2
    $World/CameraController.change_viewmode(current_mode)
    $World/GroundPlane.change_viewmode(current_mode)
    
    if current_mode == modes.EDITMODE:
        vertex_preview.show()
    else:
        vertex_preview.hide()


func _process(delta: float) -> void:    
    if Input.is_action_just_pressed("change_viewmode"):
        change_viewmode()
    if current_mode == modes.EDITMODE:
        if Input.is_action_just_pressed("snapping"):
            snap = true
        elif Input.is_action_just_released("snapping"):
            snap = false
        mouse_global_coords = $World/CameraController.get_mouse_pos()
        if mouse_global_coords != null:
            if snap:
                mouse_global_coords = mouse_global_coords.round()
        vertex_preview.position = mouse_global_coords
            

func _unhandled_input(event: InputEvent) -> void:
    if current_mode == modes.EDITMODE:
        if event is InputEventMouseButton:
            if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
                var test_mesh := MeshInstance3D.new()
                test_mesh.mesh = BoxMesh.new()
                test_mesh.scale = Vector3(0.1, 0.1, 0.1)
                test_mesh.set_name("test")
                test_mesh.position = mouse_global_coords
                add_child(test_mesh)
