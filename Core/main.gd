extends Node2D

var player_health := 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SpawnDirector.enemy_spawned.connect(_on_enemy_spawned)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_enemy_spawned(new_enemy: Enemy) -> void:
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
		$SpawnDirector/SpawnTimer.stop()
