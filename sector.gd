extends Node3D

@export_group("Sector Shape")
@export var base_vertices : Array
@export var floor_height := 0.0
@export var ceil_height := 2.0
@export_group("Sector Appearance")
@export var flip_normals := true
@export var wall_material : Material
@export var floor_material : Material

@onready var mesh_node : MeshInstance3D = $Mesh
var st := SurfaceTool.new()
    

func _ready() -> void:
    regenerate()
    

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
    # start with finding a centerpoint for triangle fan; try the average first (should work well with convex shapes)
    var sum = Vector2.ZERO # find average point of all the vertices
    for i in range(base_vertices.size()):
        sum += Vector2(base_vertices[i].x, base_vertices[i].y)
    var centerpoint : Vector2 = sum / base_vertices.size()
    # check if centerpoint is within the polygon made with the base vertices
    if Geometry2D.is_point_in_polygon(centerpoint, base_vertices):
        print("successfully found midpoint")
    else:
        print("uhhh mesh might be weird")
    
    # generate triangle fan meshes for floor and ceiling
    var vertices_floor := [Vector3(centerpoint.x, floor_height, centerpoint.y)]
    var vertices_ceil := [Vector3(centerpoint.x, ceil_height, centerpoint.y)]
    for i in range(base_vertices.size() + 1):
        var bottom_vertex : Vector2 = base_vertices[i % base_vertices.size()]
        var top_vertex : Vector2 = base_vertices[(base_vertices.size() - i) % base_vertices.size()]
        vertices_floor.append(Vector3(bottom_vertex.x, floor_height, bottom_vertex.y))
        vertices_ceil.append(Vector3(top_vertex.x, ceil_height, top_vertex.y))
    st.add_triangle_fan(vertices_floor)
    st.add_triangle_fan(vertices_ceil)

    # other annoying stuff
    st.index()
    st.generate_normals()
    var mesh = st.commit()
    mesh_node.mesh = mesh
    mesh_node.create_multiple_convex_collisions()


func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
    pass # Replace with function body.
