@icon("./FootIcon.png")
extends Node3D
class_name AutoFootSteps
## This node from the Ovani Auto Footsteps plugin will play footsteps when your player walks.
## 
## Place this around your players feet, and tell it your player's walking running & crouching speed.
## Then, It'll automatically detect what the player is standing on, and play the correct sound.

const AIR_NAME : StringName = StringName("Air")

## The Current Collection of Sound Effects / Materials to play. 
@export
var foot_profile : FootProfile = preload("res://addons/ovani_auto_footsteps/DefaultSounds/BareFootProfile.tres")
## The Current Material Name the player is standing on.
var current_material : StringName = AIR_NAME

static var DetectionModules : Array[FootMatDetectionModule]

func _get_material() -> FootProfileMaterialSpecification:
	if current_material == AIR_NAME:
		return FootProfile._AIR_MAT_SPEC
	if foot_profile._material_lookup.keys().has(current_material):
		return foot_profile._material_lookup[current_material]
	else:
		return FootProfile._AIR_MAT_SPEC

var _character_controller : CharacterBody3D
var _cached_material_materials : Dictionary

## The audio bus to play footsteps to.
@export
var audio_bus : StringName = "Master":
	get:
		if _audio_player == null:
			return audio_bus
		else:
			return _audio_player.bus
	set(value):
		audio_bus = value
		if _audio_player != null:
			_audio_player.bus = value
var _audio_player : AudioStreamPlayer3D
var _audio_player_playback : AudioStreamPlaybackPolyphonic

## Footstep volume, in decibels.
@export_range(-80, 20)
var volume_db : float = 0

## The distance per step in meters.
@export
var footstep_distance : float = 1.6

## Whether to auto play Foot SFX.
## If you'd like to sync up footsteps to an animation or collision,
## Turn this off and use the TriggerFootstep Function.
@export
var autoplay_footsteps : bool = true
var _anim_saved_sfx : Array[AudioStream] = []
var _anim_saved_vol : float = 0

## The speed we'll expect your player to crouch at.
@export
var crouch_speed : float = 1.6 / 2
## The speed we'll expect your player to walk at.
@export
var walk_speed : float = 1.6
## The speed we'll expect your player to run at.
@export
var run_speed : float = 1.6 * 2

## What this node will detect as the floor.
## Usefull for intricate player models/colliders that could
## interfere with the node. Shoutout to @gammagames on Discord
## For the recommendation and Implementation!
@export_flags_3d_physics 
var floor_collision_mask : int = 0xFFFFFFFF

## Allows for Footsteps on Gridmaps, Defaults to on.
@export
var support_gridmaps : bool = true

## If you've got an un-centered GridMap, use this variable to accordingly offset
## where the node checks for grid flooring.
@export
var grid_offset : Vector3

func _ready():
	if len(DetectionModules) == 0:
		for detector in DirAccess.get_files_at("res://addons/ovani_auto_footsteps/DetectionModules/"):
			if not (detector.ends_with(".uid") or detector.ends_with(".remap")): # Thanks to @gammagames in the Ovani Discord for pointing this 4.4+ issue out!
				DetectionModules.append(load("res://addons/ovani_auto_footsteps/DetectionModules/" + detector).new())
	
	var parent : Node = get_parent()
	if not parent is CharacterBody3D:
		push_warning("!WARNING!"
		 		+ "\nAn \"AutoFootSteps\" Node has been put somewhere other than a CharacterBody3D node."
				+ "\nThis AutoFootSteps Node has imploded.")
		queue_free()
	else:
		_character_controller = parent as CharacterBody3D

	var new_audio_player : AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	new_audio_player.bus = audio_bus
	_audio_player = new_audio_player
	add_child(new_audio_player)
	_audio_player.stream = AudioStreamPolyphonic.new()
	_audio_player.play()
	_audio_player_playback = _audio_player.get_stream_playback()


	var timer : Timer = Timer.new()
	timer.name = "Timer8th"
	timer.autostart = true
	timer.wait_time = .125
	timer.timeout.connect(self._process_eighth)
	add_child(timer)


var _last_floor_state : bool

var _last_positions : Array[Vector3]
var _last_eighth_pos : Vector3
var _cur_distance_travelled : float

const _xz : Vector3 = Vector3(1, 0, 1)

func _xy_vel_to_speed(vec : Vector3) -> float:
	return (vec*_xz).abs().length() / 2

func _xz_points_to_speed(p1 : Vector3, p2 : Vector3, time : float) -> float:
	return (p1 * _xz).distance_to(p2 * _xz) / time

func _process(_delta):
	if len(_last_positions) != 6:
		return
	var cur_material : FootProfileMaterialSpecification = null

	# Jump/land needs a higher update rate!
	if _last_floor_state and !_character_controller.is_on_floor() and _character_controller.velocity.y > 0:
		_refresh_foot_material(10)
		if cur_material == null:
			cur_material = _get_material()
		if cur_material != null:
			_play_random_ordered_sfx_from_arr(cur_material.jumps, cur_material.volume_multiplier)
	elif !_last_floor_state and _character_controller.is_on_floor() and _last_positions[0].y > position.y:
		_refresh_foot_material(10)
		if cur_material == null:
			cur_material = _get_material()
		if cur_material != null:
			_play_random_ordered_sfx_from_arr(cur_material.landings, cur_material.volume_multiplier)
	_last_floor_state = _character_controller.is_on_floor()


func _process_eighth():
	_refresh_foot_material()

	_cur_distance_travelled += _last_eighth_pos.distance_to(global_position * _xz)
	_last_eighth_pos = global_position * _xz

	var cur_material : FootProfileMaterialSpecification = null
	# normal footstep logic
	if _cur_distance_travelled > footstep_distance:
		_cur_distance_travelled = 0

		if cur_material == null:
			cur_material = _get_material()
			if cur_material == null:
				return
		var steps_sfx_array : Array[AudioStream]

		var current_speed : float = _character_controller.get_real_velocity().length()
		if current_speed < lerp(crouch_speed, walk_speed, .5):
			steps_sfx_array = cur_material.soft_steps
		elif current_speed > lerp(run_speed, walk_speed, .5):
			steps_sfx_array = cur_material.hard_steps
		else:
			steps_sfx_array = cur_material.med_steps
		
		if (cur_material != null):
			if autoplay_footsteps:
				_play_random_ordered_sfx_from_arr(steps_sfx_array, cur_material.volume_multiplier)
			else:
				_anim_saved_sfx = steps_sfx_array
				_anim_saved_vol = cur_material.volume_multiplier
			
	# jump/fall/skid/slip logic
	_last_positions.push_front(global_position)
	if len(_last_positions) > 6:
		_last_positions.remove_at(len(_last_positions) - 1)
		
	if len(_last_positions) == 6:
		# scuff
		if _character_controller.is_on_floor():
			if _xy_vel_to_speed(_character_controller.get_real_velocity()) < crouch_speed:
				var speed_over_time : float = _xz_points_to_speed(_last_positions[0], _last_positions[4], .5)
				if speed_over_time > lerp(walk_speed, run_speed, .5):
					if cur_material == null:
						cur_material = _get_material()
					if cur_material != null:
						_play_random_ordered_sfx_from_arr(cur_material.scuffs, cur_material.volume_multiplier)

 
var _rng : RandomNumberGenerator = RandomNumberGenerator.new()
var _sfx_count : int
func _play_random_ordered_sfx_from_arr(sfx : Array[AudioStream], volume_multiplier : float):
	if sfx == null or len(sfx) == 0:
		return
	_sfx_count = _sfx_count + 1
	var played_sound = sfx[_sfx_count % len(sfx)]
	_audio_player_playback.play_stream(played_sound, 0, volume_db * volume_multiplier, _rng.randf_range(.9, 1.1))
	if _sfx_count % len(sfx) == len(sfx) - 1:
		sfx.shuffle()
		if sfx[0] == played_sound:
			sfx[0] = sfx[len(sfx) - 1]
			sfx[len(sfx) - 1] = played_sound

## Manually Triggers a footstep, often used with autoplay_footsteps=false
## and an Animation/Collider setup.
func TriggerFootstep():
	_play_random_ordered_sfx_from_arr(_anim_saved_sfx, _anim_saved_vol)

## Finds what Foot Material / SFX should play for a Visual Material.
## Uses Cache; Doesn't add to Cache.
func get_mat_fmat(mat : Material) -> FootProfileMaterialSpecification:
	# do if cached
	if mat in _cached_material_materials:
		return foot_profile._material_lookup[_cached_material_materials[mat]]
	
	# check if resource name is recognized, or path (non-builtin)
	if mat.resource_name != "":
		var mat_fmat = foot_profile._string_to_material(mat.resource_name)
		if mat_fmat.name != AIR_NAME:
			return mat_fmat;
	if mat.resource_path.ends_with(".tres") or mat.resource_path.ends_with(".res"):
		var mat_fmat = foot_profile._string_to_material(mat.resource_path)
		if mat_fmat.name != AIR_NAME:
			return mat_fmat;
	
	
	# couldn't find fmat from name/path; check textures.
	var target_textures : Array[Texture] = []
	# 1st check if this is the most common material: BaseMaterial3D
	var mat_3D : BaseMaterial3D = mat as BaseMaterial3D
	if mat_3D != null:
		target_textures.append(mat_3D.albedo_texture)
	else:
		# 2nd check if this is a custom shader
		var mat_custom : ShaderMaterial = mat as ShaderMaterial
		if mat_custom == null:
			return FootProfile._AIR_MAT_SPEC # We can't do much about UI or Sprite materials; give up.
		else:
			# process custom Shader Mat.
			# how absolutely repulsive! we will need to index through each and every property
			# to find where the user has put their texture fields.
			for property in mat_custom.get_property_list():
				if property["type"] == TYPE_OBJECT:
					var found_texture : Texture = mat_custom.get(property["name"]) as Texture
					if found_texture != null:
						target_textures.append(found_texture)
	
	for texture in target_textures:
		if texture.resource_name != "":
			return foot_profile._string_to_material(texture.resource_name)
		return foot_profile._string_to_material(texture.resource_path)
	
	return FootProfile._AIR_MAT_SPEC

func _refresh_foot_material(ray_distance : float = .5):
	var raycast_response : Dictionary = get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(
			global_position, 
			to_global(Vector3(0, -ray_distance, 0)),
			floor_collision_mask # Again, Credit to @gammagames for the reccomendation
		)                        # and example implementation.
	)
	if "collider" not in raycast_response:
		current_material = AIR_NAME
		return
	
	for module in DetectionModules:
		current_material = module.TryFigureMaterial(raycast_response, self)
		if current_material != AIR_NAME:
			return
