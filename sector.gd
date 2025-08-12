extends Node3D

@export var origin := Vector3.ZERO
@export_group("Sector Shape")
@export var base_vertices : Array
@export var floor_height := 0.0
@export var ceil_height := 2.0
@export_group("Sector Components")
@export var mesh_node : MeshInstance3D
@export var collider_node : CollisionShape3D
@export_group("Sector Appearance")
@export var hide_sector_from_players := false
@export var wall_material : Material
@export var floor_material : Material

var st := SurfaceTool.new()
    

func _ready() -> void:
    regenerate()
    

func generate_origin() -> void:
    # start with finding a centerpoint for triangle fan; try the average of vertices and midpoints
    # (should work well enough with convex-ish shapes)
    var sum = Vector2.ZERO # find average point of all the vertices
    for i in range(base_vertices.size()):
        sum += base_vertices[i]
        var midpoint : Vector2 = base_vertices[i] + (base_vertices[(i + 1) % base_vertices.size()] - base_vertices[i]) / 2
        sum += midpoint
    var avg : Vector2 = sum / (base_vertices.size() * 2.0)
    origin = Vector3(avg.x, (floor_height + ceil_height) / 2, avg.y)


func regenerate() -> void:
    # first clear any collision shapes from last generation
    var children := mesh_node.get_children()
    for child in children:
        child.queue_free()
        
    # fix wrong side being culled
    # if vertices are arranged clockwise, then it's all good, but if not, the face has to be flippped by
    # going backward through the array of vertices
    # first get midpoint of line between first two vertices; direction vector will be important later
    var edge : Vector2 = base_vertices[1] - base_vertices[0] # MAKE SURE base_vertices.size() > 2
    var midpoint : Vector2 = base_vertices[0] + edge / 2
    var edge_offset : Vector2 = edge.normalized() * 0.01
    var is_right_inner : bool = Geometry2D.is_point_in_polygon(midpoint + edge_offset.rotated(PI/2), base_vertices)
    var is_left_inner : bool = Geometry2D.is_point_in_polygon(midpoint + edge_offset.rotated(-PI/2), base_vertices)
    if is_right_inner and not is_left_inner:
        print("yay")
    elif is_left_inner and not is_right_inner:
        base_vertices.reverse()
    else:
        print("Something's wrong with your points. Please make it look less bad.")
    
    # SurfaceTool setup
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_smooth_group(-1) # no smooth shading

    # generate walls
    var next_tri_end : Vector3
    for i in range(base_vertices.size() + 1):
        var vertex : Vector2 = base_vertices[i % base_vertices.size()]
        # think about tris as going from right to left (clockwise in mesh)
        if i != 0:
            var duplicate_corner := Vector3(vertex.x, ceil_height, vertex.y) # top left of quad
            st.add_vertex(duplicate_corner) # finish off last tri
            st.add_vertex(duplicate_corner) # start new tri
            st.add_vertex(Vector3(vertex.x, floor_height, vertex.y)) # bottom left of quad
            st.add_vertex(next_tri_end)
        if i != base_vertices.size():
            next_tri_end = Vector3(vertex.x, floor_height, vertex.y) # bottom right of quad
            st.add_vertex(next_tri_end)
            st.add_vertex(Vector3(vertex.x, ceil_height, vertex.y)) # top right of quad

    # generate floor and ceiling
    # first find origin of shape
    generate_origin()
    var centerpoint := Vector2(origin.x, origin.z)
    # check if centerpoint is within the polygon made with the base vertices
    if not Geometry2D.is_point_in_polygon(centerpoint, base_vertices):
        print("MESH WARNING: Midpoint not generated correctly. Try to split up convex shapes into concave components.")
    
    # generate triangle fan meshes for floor and ceiling
    var vertices_floor := [Vector3(centerpoint.x, floor_height, centerpoint.y)]
    var vertices_ceil := [Vector3(centerpoint.x, ceil_height, centerpoint.y)]
    for i in range(base_vertices.size() + 1):
        var bottom_vertex : Vector2 = base_vertices[i % base_vertices.size()]
        var top_vertex : Vector2 = base_vertices[(base_vertices.size() - i) % base_vertices.size()]
        vertices_floor.append(Vector3(bottom_vertex.x, floor_height, bottom_vertex.y))
        vertices_ceil.append(Vector3(top_vertex.x, ceil_height, top_vertex.y))
    st.add_triangle_fan(vertices_floor)
    st.add_triangle_fan(vertices_ceil) # handle uvs here somehow

    # other annoying stuff
    st.index()
    st.generate_normals()
    var mesh = st.commit()
    mesh_node.mesh = mesh
    collider_node.shape = mesh.create_trimesh_shape()


func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
            print("clicked!!")
            mesh_node.set_layer_mask_value(6, not mesh_node.get_layer_mask_value(6))
