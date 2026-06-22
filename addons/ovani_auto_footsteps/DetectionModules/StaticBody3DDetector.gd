extends FootMatDetectionModule

func _init() -> void:
	var engine_version = Engine.get_version_info()
	# face_index was not added until 4.2
	trimesh_supported = (engine_version["minor"] >= 2 or engine_version["major"] > 4)

var trimesh_supported : bool
var _cached_collider_fmaterials : Dictionary

func TryFigureMaterial(raycast_response : Dictionary, foot_node : AutoFootSteps) -> StringName:
	
	var hit_collider : Node = raycast_response["collider"]
	var isShape : bool = false
	if hit_collider is StaticBody3D: # if we hit a single shape shift focus to that shape
		hit_collider = hit_collider.shape_owner_get_owner(hit_collider.shape_find_owner(raycast_response["shape"]))
		isShape = true
	
	#figure/process if this collider is tagged
	for col_child in hit_collider.get_children():
		if col_child is FootMaterialTag:
			return col_child.foot_material_override
	
	#figure/process if this collider's fmaterial is known already / cached
	if hit_collider in _cached_collider_fmaterials:
		return _cached_collider_fmaterials[hit_collider]
	elif isShape and (raycast_response["shape"] in _cached_collider_fmaterials):
		return _cached_collider_fmaterials[raycast_response["shape"]]
	
	
	# check if fmat can be extrapolated from collider name
	var col_name_fmat : FootProfileMaterialSpecification = foot_node.foot_profile._string_to_material(hit_collider.name)
	
	# if it's a shape also check the name of the StaticBody parent
	if isShape and col_name_fmat.name == foot_node.AIR_NAME:
		col_name_fmat = foot_node.foot_profile._string_to_material(raycast_response["collider"].name)
		if col_name_fmat.name != foot_node.AIR_NAME:
			_cached_collider_fmaterials[raycast_response["collider"]] = col_name_fmat
			return col_name_fmat.name
	if col_name_fmat.name != foot_node.AIR_NAME:
		return col_name_fmat.name
	else:
		# shoot, looks like collider names don't resolve.
		
		# lets try to find the "base" this collider comes from
		var col_base : Node = hit_collider.get_parent()
		
# start Shape Scenario (advanced finding of col_base Renderer)
		if isShape: # shapes are contained by a staticbody;
			# see if staticbody parent is mesh
			if raycast_response["collider"].get_parent() is GeometryInstance3D:
				col_base = col_base.get_parent()
			else: # not contained by a mesh; lets see if the next sibling is one
				var col_idx = hit_collider.get_index()
				if (col_idx + 1) != col_base.get_child_count():
					if col_base.get_child(col_idx + 1) is GeometryInstance3D:
						col_base = col_base.get_child(col_idx + 1)
				# if next sibling wasn't an option
				if !(col_base is GeometryInstance3D):
					if (col_idx - 1) >= 0:
						if col_base.get_child(col_idx - 1) is GeometryInstance3D:
							col_base = col_base.get_child(col_idx - 1)
#   end Shape Scenario
		
		# check base name (works especially if no Renderer was found)
		var figured_material = foot_node.foot_profile._string_to_material(col_base.name)
		
		# check if the base is a mesh - then check the material names in order.
		if figured_material.name == foot_node.AIR_NAME or col_base is GeometryInstance3D:
			var col_parent_Geo3D : GeometryInstance3D = col_base as GeometryInstance3D
			if col_parent_Geo3D == null: # look for mesh in children?
				for chil in hit_collider.get_children():
					if chil is GeometryInstance3D:
						col_parent_Geo3D = chil
						break
			if col_parent_Geo3D != null:
				# gather related materials in array
				var target_materials : Array[Material] = [col_parent_Geo3D.material_override]
				
				# If we've hit an Individual shape, or a ConcavePolygon, or a ConvexPolygon
				# (as in if we've hit a collider that conforms to a mesh)
				# Figure out the specific face we hit and its material.
#               start TriMesh Scenario (Collects Material from ArrayMesh hit_face)
				if trimesh_supported and isShape and col_parent_Geo3D is MeshInstance3D and col_parent_Geo3D.mesh is ArrayMesh and (hit_collider.shape is ConcavePolygonShape3D or hit_collider.shape is ConvexPolygonShape3D):
					# Basically Mesh MultiMaterial support
					var trimesh_mesh : MeshInstance3D = col_parent_Geo3D
					var trimesh_arraymesh : ArrayMesh = trimesh_mesh.mesh
					# get each surface, then check if the face at "face_index"
					# was hit by the raycast.
					var hit_face : int = -1
					if hit_collider.shape is ConcavePolygonShape3D:
						hit_face = raycast_response["face_index"] * 3
						
					for surfIdx in trimesh_arraymesh.get_surface_count():
						var surf_arrays = trimesh_arraymesh.surface_get_arrays(surfIdx)
						var vert_array = trimesh_mesh.get_global_transform() * (surf_arrays[Mesh.ARRAY_VERTEX])
						var vert_array_len = len(vert_array)
						var face_array = surf_arrays[Mesh.ARRAY_INDEX]
						var face_array_len = len(face_array)
						
						var targ_faces = []
						if hit_face > -1:
							targ_faces = [hit_face]
							if face_array_len <= (hit_face + 2):
								hit_face -= face_array_len
								continue;
						else:
							if ProjectSettings["physics/3d/physics_engine"]:
								targ_faces = range(0, face_array_len - 2)
							else:
								targ_faces = range(0, 3, face_array_len)
						
						var onHit : bool = false
						for face in targ_faces:
							var intersection = Geometry3D.segment_intersects_triangle(
								foot_node.global_position, 
								raycast_response["position"] + (raycast_response["position"] - foot_node.global_position),
								vert_array[face_array[(face) + 2]],
								vert_array[face_array[(face) + 1]],
								vert_array[face_array[(face) + 0]]
							)
							if intersection != null: # we hit it!
								target_materials.append(trimesh_mesh.get_surface_override_material(surfIdx))
								target_materials.append(trimesh_arraymesh.surface_get_material(surfIdx))
								onHit = true
								break
							else:
								continue
						if (onHit):
							break;
#           end TriMesh Scenario
				else:
					# not Trimesh or not supported; Just collect mats from overrides & meshes.
					var col_parent_mesh3D : MeshInstance3D = col_parent_Geo3D as MeshInstance3D
					if col_parent_mesh3D != null:
						for mat_num in col_parent_mesh3D.get_surface_override_material_count():
							target_materials.append(col_parent_mesh3D.get_surface_override_material(mat_num))
						var col_parent_mesh3D_prim : PrimitiveMesh = col_parent_mesh3D.mesh as PrimitiveMesh
						if col_parent_mesh3D_prim != null:
							target_materials.append(col_parent_mesh3D_prim.material)
						else:
							var col_parent_mesh3D_Array : ArrayMesh = col_parent_mesh3D.mesh as ArrayMesh
							if col_parent_mesh3D_Array != null:
								for si in col_parent_mesh3D_Array.get_surface_count():
									target_materials.append(col_parent_mesh3D_Array.surface_get_material(si))
				
				# for each collected mat, figure fmat
				for mat in target_materials:
					if mat == null:
						continue
					figured_material = foot_node.get_mat_fmat(mat);
					if figured_material.name != foot_node.AIR_NAME:
						foot_node._cached_material_materials[mat] = figured_material.name
						return figured_material.name
				# not a single mat was resolved to an fmat.
				return foot_node.AIR_NAME
			else: # couldn't find fmat from any source.
				return foot_node.AIR_NAME
		else:
			# figured material from col_base;
			return figured_material.name
