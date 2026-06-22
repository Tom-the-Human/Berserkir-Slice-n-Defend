extends Node2D

@onready var music_player = $MusicPlayer
@export var music: OvaniSong

@onready var ui_manager = $UIManager
@onready var hud = %HUD
@onready var main_menu =  %MainMenu
@onready var pause_screen = %PauseScreen
@onready var game_over_screen = %GameOverScreen
@onready var upgrade_store = %UpgradeStore
@onready var glory_wallet_label = %GloryWalletLabel
@onready var stats_label = %StatsLabel # shown at game over (probably rename)

@onready var screen_blood = $UIManager/ScreenBlood
@onready var damage_flash = $UIManager/DamageFlash
@onready var camera = $Camera2D
var current_shake_strength := 0.0

var player_health := Global.max_health

var run_glory := 0
var run_kills := 0

var run_start_time := 0
var run_time_str := ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SwipeTrail.swipe_completed.connect(_process_swipe)
	$SpawnDirector.enemy_spawned.connect(_on_enemy_spawned)
	get_tree().paused = true
	
	
	# fade in to 0.0 (normal) over a few secs on load
	if music:
		music_player.QueueSong(music)
	music_player.Intensity = 0.0
	music_player.Volume = -40.0
	music_player.FadeVolume(0.0, 3.0)
	
	hud.hide()
	pause_screen.hide()
	game_over_screen.hide()
	upgrade_store.hide()
	main_menu.show()

func _process(delta: float) -> void:
	if current_shake_strength > 0:
		# random offset camera by current strength
		camera.offset = Vector2(
			randf_range(-current_shake_strength, current_shake_strength),
			randf_range(-current_shake_strength, current_shake_strength)
		)
		# rapidly degrade back to 0,0
		current_shake_strength = lerpf(current_shake_strength, 0.0, 15.0 * delta)


func start_new_run() -> void:
	run_glory = 0
	run_kills = 0
	run_start_time = Time.get_ticks_msec()
	player_health = Global.max_health
	
	music_player.Intensity = 0.25 # intensity 2 = 0.5
	music_player.FadeIntensity(1.0, 90.0)
	
	
	main_menu.hide()
	game_over_screen.hide()
	hud.show()
	
	get_tree().paused = false
	$SpawnDirector/PacingTimer.start()
	$SpawnDirector/SpawnTimer.start()

func _on_enemy_spawned(new_enemy: Enemy) -> void:
	# connect enemy attack signal
	new_enemy.attacked_player.connect(_on_player_damaged)
	
	# listen for stat signals
	new_enemy.killed.connect(_on_enemy_killed)
	new_enemy.part_broken.connect(_on_part_broken)

func _process_swipe(swipe_points: PackedVector2Array) -> void:
	$AttackSFX.play()
	var enemies = get_tree().get_nodes_in_group("enemies")
	enemies.sort_custom(func(a, b): return a.progress > b.progress)
	
	var swipe_dir := (swipe_points[-1] - swipe_points[0]).normalized()
	
	var current_pierce = Global.pierce
	# stop checking when pierces run out, and apply cuts 
	for enemy in enemies:
		if current_pierce <= 0:
			break
		current_pierce = enemy.apply_cut(swipe_points, current_pierce, swipe_dir)

func _on_player_damaged(damage: int) -> void:
	$TakeDamageSFX.play()
	player_health -= damage
	trigger_player_hit_vfx()
	# debug/placeholder
	print("Hit! Player health now ", player_health)
	
	if player_health <= 0:
		music_player.FadeIntensity(0.1, 3.0)
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

func trigger_player_hit_vfx() -> void:
	var health_ratio: float = float(player_health) / float(Global.max_health)
	# invert so 1.0 means dead, 0.0 means full health
	var missing_health_ratio := 1.0 - health_ratio
	
	# screen shake
	current_shake_strength = 10.0 + (40.0 * missing_health_ratio) # tweak!
	
	# damage flash
	var dynamic_radius := lerpf(0.5, 0.0, missing_health_ratio)
	damage_flash.material.set_shader_parameter("vignette_radius", dynamic_radius)
	damage_flash.show()
	var tween = create_tween()
	# fade out is in secs, make very fast!
	tween.tween_method(
		func(val: float): damage_flash.material.set_shader_parameter("intensity", val),
		1.0, 0.0, 0.3
	)
	tween.tween_callback(damage_flash.hide)

func _on_enemy_killed() -> void:
	run_kills += 1
	Global.total_kills += 1

func _on_part_broken() -> void:
	run_glory += 1
	Global.total_glory += 1

func trigger_screen_splatter() -> void:
	screen_blood.show()
	
	# 0.4 is pretty heavy (is it?)
	screen_blood.material.set_shader_parameter("drip_amount", 1.0)
	var tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_method(
		func(val: float): screen_blood.material.set_shader_parameter("drip_amount", val),
		1.0, 0.0, 2.5
	)
	tween.tween_callback(screen_blood.hide)

func _on_play_button_pressed() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	start_new_run()

func _on_upgrades_button_pressed() -> void:
	main_menu.hide()
	game_over_screen.hide()
	upgrade_store.show()
	refresh_store_ui()

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
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	get_tree().paused = true
	pause_screen.hide()
	game_over_screen.hide()
	hud.hide()
	main_menu.show()

func refresh_store_ui() -> void:
	glory_wallet_label.text = "Available Glory: " + str(Global.current_glory)

func _on_buy_berserk_trance_button_pressed() -> void:
	if Global.attempt_purchase(Global.berserk_trance):
		refresh_store_ui()
		# placeholder (print to screen instead)
		print("Berserk Trance Upgraded! Max HP: ", Global.berserk_trance.value)

func _on_buy_axe_bite_button_pressed() -> void:
	if Global.attempt_purchase(Global.axe_bite):
		refresh_store_ui()
		# placeholder (print to screen instead)
		print("Axe Bite Upgraded! Penetration: ", Global.axe_bite.value)

func _on_buy_brute_force_button_pressed() -> void:
	if Global.attempt_purchase(Global.brute_force):
		refresh_store_ui()
		# placeholder (print to screen instead)
		print("Brute Force Upgraded! Knockback: ", Global.brute_force.value)

func _on_store_back_button_pressed() -> void:
	upgrade_store.hide()
	main_menu.show()
