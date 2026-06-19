extends Node2D

@onready var ui_manager = $UIManager
@onready var hud = %HUD
@onready var main_menu =  %MainMenu
@onready var pause_screen = %PauseScreen
@onready var game_over_screen = %GameOverScreen

@onready var stats_label = %StatsLabel # shown at

# FIXME: this needs to be split into a max health and current health
# max health will be upgradable, so needs to be dynamic (Global?)
var player_health := 100 

# FIXME: these vars need to be Global
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
	get_tree().paused = true
	
	hud.hide()
	pause_screen.hide()
	game_over_screen.hide()
	main_menu.show()


func start_new_run() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	# DEBUG
	print("Run started")
	run_glory = 0
	run_kills = 0
	run_start_time = Time.get_ticks_msec()
	player_health = 100 # FIXME
	
	main_menu.hide()
	game_over_screen.hide()
	hud.show()
	
	get_tree().paused = false
	$SpawnDirector/PacingTimer.start()
	$SpawnDirector/SpawnTimer.start()
	

func _on_enemy_spawned(new_enemy: Enemy) -> void:
	# send SwipeTrail coords to enemy
	$SwipeTrail.swipe_completed.connect(new_enemy.apply_cut)
	
	# connect enemy attack signal
	new_enemy.attacked_player.connect(_on_player_damaged)
	
	# listen for stat signals
	new_enemy.killed.connect(_on_enemy_killed)
	new_enemy.part_broken.connect(_on_part_broken)

func _on_player_damaged(damage: int) -> void:
	if player_health <= 0:
		# get run time
		var run_end_time := Time.get_ticks_msec()
		var elapsed_msec := run_end_time - run_start_time
		var total_seconds := elapsed_msec / 1000
		var minutes := total_seconds / 60
		var seconds := total_seconds % 60
		run_time_str = "%d:%02d" % [minutes, seconds]
		
		get_tree().paused = true
		$SpawnDirector/PacingTimer.stop()
		$SpawnDirector/SpawnTimer.stop()
		stats_label.text = "Kills: %d | Glory: %d | Time: %s" % [run_kills, run_glory, run_time_str]
		
		hud.hide()
		game_over_screen.show()
	
	
	player_health -= damage
	# debug/placeholder
	print("Hit! Player health now ", player_health)

func _on_enemy_killed() -> void:
	run_kills += 1
	total_kills +1

func _on_part_broken() -> void:
	run_glory += 1
	total_glory += 1


func _on_play_button_pressed() -> void:
	start_new_run()

func _on_upgrades_button_pressed() -> void:
	pass # Replace with function body.
	# TODO: Design and then hook up Upgrade Store

func _on_settings_button_pressed() -> void:
	pass # Replace with function body.
	# TODO: Design and then hook up Settings Screen

func _on_pause_button_pressed() -> void:
	get_tree().paused = true
	pause_screen.show()

func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	pause_screen.hide()

func _on_menu_button_pressed() -> void:
	get_tree().paused = true
	pause_screen.hide()
	game_over_screen.hide()
	hud.hide()
	main_menu.show()
