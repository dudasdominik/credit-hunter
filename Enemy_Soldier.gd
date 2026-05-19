extends CharacterBody2D

enum State {
	ROAM,
	CHASE,
	RETURN
}

@export var speed: float = 80.0
@export var chase_range: float = 130.0
@export var lose_range: float = 220.0
@export var stop_distance: float = 28.0
@export var roam_size: Vector2 = Vector2(160, 80)
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0
@export var max_health: int = 100
@export var health: int = 100
@export var drop_item_scene: PackedScene
@export var drop_item_id: String = "health_potion"
@export var drop_item_texture: Texture2D

@export var max_armor: int = 50
@export var armor: int = 50

@onready var health_back: ColorRect = $EnemyStatusBar/HealthBack
@onready var health_fill: ColorRect = $EnemyStatusBar/HealthBack/HealthFill
@onready var health_label: Label = $EnemyStatusBar/HealthBack/HealthLabel

@onready var armor_back: ColorRect = $EnemyStatusBar/ArmorBack
@onready var armor_fill: ColorRect = $EnemyStatusBar/ArmorBack/ArmorFill
@onready var armor_label: Label = $EnemyStatusBar/ArmorBack/ArmorLabel

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var player: Node2D = get_tree().get_first_node_in_group("player")

@onready var enemy_sprite: Sprite2D = $Sprite2D

var state: State = State.ROAM
var roam_center: Vector2
var roam_target: Vector2
var player_inside_room := false
var player_in_attack_area := false
var can_attack := true
var enemy_original_color: Color


func _ready():
	enemy_original_color = enemy_sprite.modulate
	roam_center = global_position
	pick_new_roam_target()
	setup_enemy_bars()
	update_enemy_bars()
	


func setup_enemy_bars():
	health_back.color = Color(0.05, 0.05, 0.05, 0.9)
	health_fill.color = Color.RED

	armor_back.color = Color(0.05, 0.05, 0.05, 0.9)
	armor_fill.color = Color.BLUE


func update_enemy_bars():
	var health_percent := 0.0
	var armor_percent := 0.0

	if max_health > 0:
		health_percent = float(health) / float(max_health)

	if max_armor > 0:
		armor_percent = float(armor) / float(max_armor)

	health_fill.size.x = health_back.size.x * health_percent
	armor_fill.size.x = armor_back.size.x * armor_percent

	health_label.text = "HP: %d/%d" % [health, max_health]
	armor_label.text = "AR: %d/%d" % [armor, max_armor]



func _process(delta):
	if player_in_attack_area and can_attack:
		attack_player()
		

func attack_player():
	can_attack = false
	GameManager.damage(attack_damage)
	print("Enemy sebzett: ", attack_damage)

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func _physics_process(delta):
	if player == null:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	
	if not player_inside_room:
		if state == State.CHASE:
			state = State.RETURN
	else:
		
		if distance_to_player <= chase_range:
			state = State.CHASE
		elif distance_to_player >= lose_range and state == State.CHASE:
			state = State.RETURN

	match state:
		State.ROAM:
			roam()
		State.CHASE:
			chase_player()
		State.RETURN:
			return_to_roam_area()

	move_with_navigation()


func pick_new_roam_target():
	var half_size = roam_size / 2.0

	var random_x = randf_range(roam_center.x - half_size.x, roam_center.x + half_size.x)
	var random_y = randf_range(roam_center.y - half_size.y, roam_center.y + half_size.y)

	roam_target = Vector2(random_x, random_y)
	agent.target_position = roam_target


func roam():
	if global_position.distance_to(roam_target) < 10.0:
		pick_new_roam_target()


func chase_player():
	if player == null:
		return

	
	if not player_inside_room:
		state = State.RETURN
		return

	agent.target_position = player.global_position


func return_to_roam_area():
	agent.target_position = roam_center

	if global_position.distance_to(roam_center) < 10.0:
		state = State.ROAM
		pick_new_roam_target()


func move_with_navigation():
	if state == State.CHASE and player != null:
		var distance_to_player = global_position.distance_to(player.global_position)

		if distance_to_player <= stop_distance:
			velocity = Vector2.ZERO
			return

	if agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return

	var next_position = agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)

	velocity = direction * speed
	move_and_slide()


func on_player_entered_room():
	player_inside_room = true
	print("Enemy megkapta: player bent van a szobában")


func on_player_exited_room():
	player_inside_room = false
	state = State.RETURN
	print("Enemy megkapta: player kiment a szobából")
	


func _on_attack_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_attack_area = true


func _on_attack_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_attack_area = false
		

func take_damage(amount: int):
	var remaining_damage = amount

	if armor > 0:
		var armor_damage = min(armor, remaining_damage)
		armor -= armor_damage
		remaining_damage -= armor_damage

	if remaining_damage > 0:
		health -= remaining_damage

	armor = clamp(armor, 0, max_armor)
	health = clamp(health, 0, max_health)

	update_enemy_bars()

	print("Enemy sebződött: ", amount, " | HP: ", health, " Armor: ", armor)

	if health <= 0:
		await enemy_hit_flash()
		die()
	else:
		enemy_hit_flash()


func die():
	print("Enemy meghalt")

	var drop_position = global_position

	if drop_item_scene != null:
		var item = drop_item_scene.instantiate()

		item.item_id = drop_item_id
		item.item_texture = drop_item_texture

		get_parent().add_child(item)
		item.global_position = drop_position

		print("Item ledobva ide: ", drop_position)
	else:
		print("Nincs beállítva drop_item_scene!")

	queue_free()


func enemy_hit_flash():
	enemy_sprite.modulate = Color(1, 0.25, 0.25)

	await get_tree().create_timer(0.08).timeout

	if is_instance_valid(enemy_sprite):
		enemy_sprite.modulate = enemy_original_color

func set_room_navigation_layers(layers: int):
	agent.navigation_layers = layers
