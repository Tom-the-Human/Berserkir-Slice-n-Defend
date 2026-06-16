extends Node2D

@export var enemy_scene: PackedScene

var player_health := 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_enemy_spawn_timer_timeout() -> void:
	if enemy_scene == null:
		# debug
		print("Error: Enemy scene is not assigned in the Inspector!")
		return
	
	var new_enemy = enemy_scene.instantiate()
	add_child(new_enemy)
	
	# send SwipeTrail coords to enemy
	$SwipeTrail.swipe_completed.connect(new_enemy.apply_cut)
	
	# connect enemy attack signal
	new_enemy.attacked_player.connect(_on_player_damaged)

func _on_player_damaged(damage: int) -> void:
	player_health -= damage
	# debug/placeholder
	print("Hit! Player health now ", player_health)
	
	if player_health <= 0:
		# placeholder
		print("Berserker has fallen!\nGAME OVER")
		# implement proper game over later, just end spawning for now
		$EnemySpawnTimer.stop()
