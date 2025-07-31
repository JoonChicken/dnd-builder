extends Node3D

enum modes {VIEWMODE, EDITMODE, PLAYMODE}
var current_mode := modes.VIEWMODE

func change_viewmode() -> void:
    current_mode = (current_mode + 1) % 3
    $CameraController.change_viewmode(current_mode)
    $GroundPlane.change_viewmode(current_mode)


func _process(delta: float) -> void:
    if Input.is_action_just_pressed("change_viewmode"):
        change_viewmode()
