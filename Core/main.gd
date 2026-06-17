extends Node2D

# FIXME: this needs to be split into a max health and current health
# max health will be upgradable, so needs to be dynamic
var player_health := 100 

var total_glory := 0   # all runs
var current_glory := 0 # wallet
var total_kills := 0   # all runs

var run_glory := 0     # this run
var run_kills := 0     # this run

var run_start_time := 0
var run_time_str := ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SpawnDirector.enemy_spawned.connect(_on_enemy_spawned)
	start_new_run()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func start_new_run() -> void:
	run_glory = 0
	run_kills = 0
	run_start_time = Time.get_ticks_msec()
	player_health = 100 # FIXME
	# DEBUG
	print("Run started")

func _on_enemy_spawned(new_enemy: Enemy) -> void:
	# send SwipeTrail coords to enemy
	$SwipeTrail.swipe_completed.connect(new_enemy.apply_cut)
	
	# connect enemy attack signal
	new_enemy.attacked_player.connect(_on_player_damaged)
	
	# listen for stat signals
	new_enemy.killed.connect(_on_enemy_killed)
	new_enemy.part_broken.connect(_on_part_broken)

func _on_player_damaged(damage: int) -> void:
	player_health -= damage
	# debug/placeholder
	print("Hit! Player health now ", player_health)
	
	if player_health <= 0:
		# get run time
		var run_end_time := Time.get_ticks_msec()
		var elapsed_msec := run_end_time - run_start_time
		var total_seconds := elapsed_msec / 1000
		var minutes := total_seconds / 60
		var seconds := total_seconds % 60
		run_time_str = "%d:%02d" % [minutes, seconds]
		
		# placeholder
		print("Berserker has fallen!\nGAME OVER")
		print("Run Summary -> Kills: ", run_kills, " | Glory: ", run_glory, " | Time: ", run_time_str)
		# implement proper game over later, just end spawning for now
		# will return player to menu
		$SpawnDirector/SpawnTimer.stop()

func _on_enemy_killed() -> void:
	total_kills += 1
	# debug
	print(total_kills)

func _on_part_broken() -> void:
	total_glory += 1
	print(total_glory)
