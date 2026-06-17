extends Node2D
class_name Sliceable_Part

# signal to parent node that shield/armor is gone
signal destroyed

@export var part_color := Color.DARK_RED

@onready var polygon_node: Polygon2D = $Polygon2D
var is_broken := false

func apply_cut(swipe_points: PackedVector2Array) -> bool:
	if is_broken:
		return false
		
	var local_points := PackedVector2Array()
	for pt in swipe_points:
		local_points.append(to_local(pt))
	
	var sliced_pieces := Slicer.slice_polygon_curved(polygon_node.polygon, local_points)
	
	if sliced_pieces.size() > 1:
		is_broken = true # Prevent double-cutting in the same frame (reconsider?)
		for piece_points in sliced_pieces:
			create_falling_rigidbody(piece_points)
		
		destroyed.emit()
		queue_free()
		return true
	
	return false

func create_falling_rigidbody(points: PackedVector2Array) -> void:
	var scaled_points := PackedVector2Array()
	for pt in points:
		# global_scale so it inherits the 3D perspective scale from the Enemy
		scaled_points.append(pt * global_scale)
		
	var rb := RigidBody2D.new()
	var poly := Polygon2D.new()
	var col := CollisionPolygon2D.new()
	
	poly.polygon = scaled_points
	poly.color = part_color
	col.polygon = scaled_points

	######################
	# not sure if I want this, test and maybe remove
	var edge_glow := Line2D.new()
	edge_glow.points = scaled_points
	edge_glow.closed = true
	edge_glow.width = 1.5 * global_scale.x 
	edge_glow.default_color = Color(2.0, 0.2, 0.2) 
	rb.add_child(edge_glow)
	######################
	
	rb.add_child(poly)
	rb.add_child(col)
	rb.global_position = global_position
	
	# Grab the z_index from the parent Enemy so it layers correctly
	rb.z_index = get_parent().z_index + 1
	
	rb.apply_central_impulse(Vector2(randf_range(-100, 100), randf_range(-50, -150)))
	
	# Send it to the Main scene so it doesn't keep charging forward with the surviving Enemy
	get_tree().current_scene.add_child(rb)
