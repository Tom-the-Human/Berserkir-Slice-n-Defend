class_name Slicer
extends Node

# takes target shape and swipe coords, returns array of resulting sliced shapes
static func slice_polygon_curved(target_poly: PackedVector2Array, swipe_points: PackedVector2Array, thickness: float = 10.0) -> Array[PackedVector2Array]:
	# 1. Expand the swipe path into a thick polygon
	# We use JOIN_ROUND to handle sharp turns in the swipe curve
	var blade_poly := Geometry2D.offset_polyline(swipe_points, thickness / 2.0, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
	
	# 2. Safety check: If the swipe is too short/degenerate, return the original
	if blade_poly.is_empty():
		return [target_poly]

	# 3. Perform the subtraction
	# Note: clip_polygons can return multiple pieces if the cut splits the target into 3+ parts
	var result := Geometry2D.clip_polygons(target_poly, blade_poly[0])
	
	# 4. Filter for valid pieces (must have 3+ vertices to be a polygon)
	var cleaned_result: Array[PackedVector2Array] = []
	for piece in result:
		if piece.size() >= 3:
			cleaned_result.append(piece)
			
	return cleaned_result
