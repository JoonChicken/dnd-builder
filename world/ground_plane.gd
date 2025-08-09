extends MeshInstance3D

enum modes {VIEWMODE, EDITMODE, PLAYMODE}
var current_mode := modes.VIEWMODE

func change_viewmode(new_mode: int) -> void:
    if current_mode != modes.PLAYMODE && new_mode == modes.PLAYMODE:
        mesh.material.shader_paramter.opacity = 0.5
    elif current_mode == modes.PLAYMODE && new_mode != modes.PLAYMODE:
        mesh.material.shader_paramter.opacity = 1.0
    current_mode = new_mode
