extends Node2D
class_name SliceablePart

# signal to parent node that shield/armor is gone
signal destroyed

@export var part_color := Color.DARK_RED

@onready var polygon_node: Polygon2D = $Polygon2D
var is_broken := false

func apply_cut(swipe_points: PackedVector2Array, swipe_dir: Vector2, z_offset: int = 0) -> Variant:
	if is_broken:
		return null

	var local_points := PackedVector2Array()
	for pt in swipe_points:
		local_points.append(to_local(pt))

	var sliced_pieces := Slicer.slice_polygon_curved(polygon_node.polygon, local_points)

	if sliced_pieces.size() > 0:
		is_broken = true # Prevent double-cutting in the same frame (reconsider?)

		var largest_rb: RigidBody2D = null
		var max_area := -1.0

		for piece_points in sliced_pieces:
			# directional impulse from the cut, plus a little scatter
			var impulse := (swipe_dir * 500.0) + Vector2(randf_range(-100, 100), randf_range(-50, -150))
			var torque: float = sign(swipe_dir.x) * randf_range(1000.0, 3000.0)
			var rb = create_falling_rigidbody(piece_points, impulse, torque, z_offset)
			var area = get_polygon_area(piece_points)
			if area > max_area:
				max_area = area
				largest_rb = rb

		destroyed.emit()
		queue_free()
		return largest_rb

	return null

## Drops the part as a single falling piece without slicing it - used when the
## part is still intact but its host (e.g. the Body) has been destroyed.
## Randomly picks between being knocked off hard (biased by the killing swipe)
## or just coming loose and dropping, for some variety.
func detach_and_fall(swipe_dir: Vector2 = Vector2.ZERO, z_offset: int = 0) -> RigidBody2D:
	if is_broken:
		return null
	is_broken = true

	var impulse: Vector2
	var torque: float
	if randf() < 0.5:
		# knocked off along with the killing blow - a harder, wilder shove
		impulse = (swipe_dir * 700.0) + Vector2(randf_range(-200.0, 200.0), randf_range(-150.0, -300.0))
		torque = randf_range(-4000.0, 4000.0)
	else:
		# simply comes loose and drops away
		impulse = Vector2(randf_range(-60.0, 60.0), randf_range(-40.0, 0.0))
		torque = randf_range(-500.0, 500.0)

	var rb := create_falling_rigidbody(polygon_node.polygon, impulse, torque, z_offset)
	queue_free()
	return rb

## Attaches this part's shape directly onto an existing falling RigidBody2D
## (e.g. the Body's piece) instead of spawning its own. Since it becomes part
## of the same physics body, it moves with it exactly - no drift.
func attach_to(host_rb: RigidBody2D) -> void:
	if is_broken:
		return
	is_broken = true

	var host_local_points := PackedVector2Array()
	for pt in polygon_node.polygon:
		var world_pt: Vector2 = global_position + (pt * global_scale)
		host_local_points.append(world_pt - host_rb.global_position)

	var poly := Polygon2D.new()
	var col := CollisionPolygon2D.new()
	poly.polygon = host_local_points
	poly.color = part_color
	col.polygon = host_local_points
	host_rb.add_child(poly)
	host_rb.add_child(col)

	queue_free()

func create_falling_rigidbody(points: PackedVector2Array, impulse: Vector2, torque: float, z_offset: int = 0) -> RigidBody2D:
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
	rb.z_index = get_parent().z_index + z_offset

	# purely decorative debris - skip collision detection/resolution between pieces
	# (gravity, impulses and torque still apply; only collision checks are disabled)
	rb.collision_layer = 0
	rb.collision_mask = 0

	# free once fully offscreen so the player never sees it disappear
	var notifier := VisibleOnScreenNotifier2D.new()
	notifier.rect = _get_bounding_rect(scaled_points)
	rb.add_child(notifier)
	notifier.screen_exited.connect(rb.queue_free)

	# safety net in case the piece never leaves the screen (e.g. rests on a pile).
	# Parented to rb so it's destroyed alongside it instead of outliving it as a
	# dangling SceneTreeTimer callback (which would reference a freed object).
	var lifetime_timer := Timer.new()
	lifetime_timer.wait_time = 10.0
	lifetime_timer.one_shot = true
	lifetime_timer.autostart = true
	rb.add_child(lifetime_timer)
	lifetime_timer.timeout.connect(rb.queue_free)

	rb.apply_central_impulse(impulse)
	rb.apply_torque_impulse(torque)

	# Send it to the Main scene so it doesn't keep charging forward with the surviving Enemy
	get_tree().current_scene.add_child(rb)
	
	
	return rb
	
func _get_bounding_rect(points: PackedVector2Array) -> Rect2:
	var rect := Rect2(points[0], Vector2.ZERO)
	for pt in points:
		rect = rect.expand(pt)
	return rect

func get_polygon_area(poly: PackedVector2Array) -> float:
	var area := 0.0
	var n := poly.size()
	for i in range(n):
		var j := (i + 1) % n
		area += (poly[i].x * poly[j].y) - (poly[j].x * poly[i].y)
	return abs(area) / 2.0
