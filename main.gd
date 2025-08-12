extends Node3D

@export_group("World")
@export var vertex_preview : MeshInstance3D
@export_group("Control")
@export var topmenu : Panel
@export var sidemenu : Panel
@export var inspector : Panel
@export_subgroup("Bottom Bar")
@export var bottombar : Panel
@export var current_mode_label : Label
@export var current_tool_label : Label

enum modes {VIEWMODE, EDITMODE, PLAYMODE}
var current_mode := modes.VIEWMODE

enum tools {SELECT, NEW_SECTOR}
var current_tool := tools.SELECT

var sectors : Array
var selected_sector : Area3D

var snap : bool
var mouse_global_coords : Vector3
 

func _ready() -> void:
    selected_sector = null
    snap = false
    vertex_preview.hide()
    sidemenu.hide()
    current_tool_label.hide()


func _process(_delta: float) -> void:    
    if Input.is_action_just_pressed("change_viewmode"):
        change_viewmode()
    if current_mode == modes.EDITMODE and current_tool == tools.NEW_SECTOR:
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
    if current_mode == modes.EDITMODE and current_tool == tools.NEW_SECTOR:
        if event is InputEventMouseButton:
            if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
                var test_mesh := MeshInstance3D.new()
                test_mesh.mesh = BoxMesh.new()
                test_mesh.scale = Vector3(0.1, 0.1, 0.1)
                test_mesh.set_name("test")
                test_mesh.position = mouse_global_coords
                add_child(test_mesh)


func change_viewmode() -> void:
    @warning_ignore("int_as_enum_without_cast")
    current_mode = (current_mode + 1) % 2
    $World/CameraController.change_viewmode(current_mode)
    $World/GroundPlane.change_viewmode(current_mode)
    if current_mode == modes.VIEWMODE:
        sidemenu.hide()
        current_tool_label.hide()
        current_mode_label.text = "VIEW MODE"
    elif current_mode == modes.EDITMODE:
        sidemenu.show()
        current_tool_label.show()
        current_mode_label.text = "EDIT MODE"
    else: # modes.PLAYMODE
        sidemenu.hide()
        current_tool_label.hide()
        current_mode_label.text = "PLAY MODE"


func _change_tool_to_select() -> void:
    current_tool = tools.SELECT
    vertex_preview.hide()
    current_tool_label.text = "SELECTION TOOL"


func _change_tool_to_new_sector() -> void:
    current_tool = tools.NEW_SECTOR
    vertex_preview.show()
    current_tool_label.text = "SECTOR TOOL"
