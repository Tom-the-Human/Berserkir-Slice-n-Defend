extends Node2D

signal enemy_spawned(enemy_node: Enemy)

@export var peasant: PackedScene
@export var spearman: PackedScene
@export var housecarl: PackedScene

var spawn_center_x := 540.0

var run_time_seconds := 0.0

@onready var pacing_timer := $PacingTimer
@onready var spawn_timer := $SpawnTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pacing_timer.timeout.connect(_on_pacing_update)
	spawn_timer.timeout.connect(_spawn_enemy)
	
	spawn_timer.start(2.0)

func _on_pacing_update() -> void:
	run_time_seconds += 1.0
	
	# start at base difficulty (tweak as needed)
	var base_spawn_delay = max(0.5, 2.0 - (run_time_seconds / 60.0))
	
	# intensity ebb & flow
	var wave_cycle = sin(run_time_seconds / 5.0) # cycle every 30 sec(?)
	
	# modulate spawn delay by up to +/- .4 sec based on wave cycle
	var current_spawn_delay = base_spawn_delay + (wave_cycle * 0.4)
	current_spawn_delay = max(0.2, current_spawn_delay)
	
	# update spawn timer
	spawn_timer.wait_time = current_spawn_delay

func _spawn_enemy() -> void:
	var enemy_to_spawn: PackedScene
	var roll := randf() # 0.0 to 1.0
	
	###########
	# TODO: this should probably be refactored to a dict or something
	# change spawn chances over time
	if run_time_seconds < 10.0:
		enemy_to_spawn = peasant
	elif run_time_seconds < 30.0:
		if roll < 0.75:
			enemy_to_spawn = peasant
		else:
			enemy_to_spawn = spearman
	elif run_time_seconds < 60.0:
		if roll < 0.5:
			enemy_to_spawn = peasant
		else:
			enemy_to_spawn = spearman
	elif run_time_seconds < 90.0:
		if roll < 0.3:
			enemy_to_spawn = peasant
		elif roll < 0.9:
			enemy_to_spawn = spearman
		else:
			enemy_to_spawn = housecarl
	elif run_time_seconds < 120.0:
		if roll < 0.1:
			enemy_to_spawn = peasant
		elif roll < 0.7:
			enemy_to_spawn = spearman
		else:
			enemy_to_spawn = housecarl
	elif run_time_seconds < 150.0:
		if roll < 0.05:
			enemy_to_spawn = peasant
		elif roll < 0.5:
			enemy_to_spawn = spearman
		else:
			enemy_to_spawn = housecarl
	elif run_time_seconds < 180.0:
		if roll < 0.25:
			enemy_to_spawn = spearman
		else:
			enemy_to_spawn = housecarl
	#########
	
	# instantiate and add enemy to scene
	if enemy_to_spawn:
		var new_enemy = enemy_to_spawn.instantiate()
		get_parent().add_child(new_enemy)
		
		enemy_spawned.emit(new_enemy)
