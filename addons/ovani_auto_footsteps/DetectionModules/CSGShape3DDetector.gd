extends FootMatDetectionModule

func _init() -> void:
	var engine_version = Engine.get_version_info()
	# face_index was not added until 4.2
	supported = (engine_version["minor"] >= 2 or engine_version["major"] > 4)

var supported : bool

func TryFigureMaterial(raycast_response : Dictionary, foot_node : AutoFootSteps) -> StringName:
	if !supported:
		return foot_node.AIR_NAME

	if !(raycast_response["collider"] is CSGShape3D): # ensure we are, infact, on a CSGShape3D
		return foot_node.AIR_NAME
	else:
		var hit_CSG : CSGShape3D = raycast_response["collider"]
		var hit_mesh : ArrayMesh = hit_CSG.get_meshes()[1];
		
		# Check each face, internally
		var surface_start = 0;
		var face_id = raycast_response["face_index"]*3;
		for surface_num in len(hit_mesh._surfaces):
			var surface = hit_mesh._surfaces[surface_num];
			if (face_id > surface_start && face_id < surface_start + surface.vertex_count):
				if surface.has("material"):
					return foot_node.get_mat_fmat(surface.material).name;
				else:
					return foot_node.AIR_NAME
			else:
				surface_start = surface_start + surface.vertex_count;
		return foot_node.AIR_NAME
