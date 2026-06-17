extends Node2D
class_name SliceablePart

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
	
	if sliced_pieces.size() > 0:
		is_broken = true # Prevent double-cutting in the same frame (reconsider?)
		
		var swipe_dir := (swipe_points[swipe_points.size() - 1] - swipe_points[0]).normalized()
		for piece_points in sliced_pieces:
			create_falling_rigidbody(piece_points, swipe_dir)
		
		destroyed.emit()
		queue_free()
		return true
	
	return false

func create_falling_rigidbody(points: PackedVector2Array, swipe_dir: Vector2) -> void:
	var scaled_points := PackedVector2Array()
	for pt in points:
		# global_scale so it inherits the 3D perspective scale from the Enemy
		scaled_points.append(pt * global_scale)
		
	var rb := RigidBody2D.new()
	# attach self-cleanup script
	var cleanup = GDScript.new()
	cleanup.source_code = """
extends RigidBody2D
func _process(_delta) -> void:
	if global_position.y > 2500:
		queue_free()
	"""
	cleanup.reload()
	rb.set_script(cleanup)
	
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
	rb.z_index = get_parent().z_index
	
	# calc directional impulse and apply torque
	var base_force := swipe_dir * 500.0
	var random_variance := Vector2(randf_range(-100, 100), randf_range(-50, -150))
	
	rb.apply_central_impulse(base_force + random_variance)
	rb.apply_torque_impulse(sign(swipe_dir.x) * randf_range(1000.0, 3000.0))
	
	# Send it to the Main scene so it doesn't keep charging forward with the surviving Enemy
	get_tree().current_scene.add_child(rb)
