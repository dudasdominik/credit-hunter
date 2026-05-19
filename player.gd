extends CharacterBody2D

@export var speed: float = 160.0
@export var attack_cooldown: float = 0.4

@onready var attack_area: Area2D = $AttackArea
@onready var player_sprite: Sprite2D = $Sprite2D

var enemies_in_range: Array[Node] = []
var can_attack := true
var player_original_color: Color

func _ready() -> void:
	player_original_color = player_sprite.modulate
	GameManager.player_damaged.connect(player_hit_flash)

func attack():
	if not can_attack:
		return

	can_attack = false
	print("Player támadott")
	print("Enemyk range-ben: ", enemies_in_range.size())
	print("Player damage: ", GameManager.player_damage)

	for enemy in enemies_in_range:
		print("Talált enemy/object: ", enemy.name)

		if enemy != null and enemy.has_method("take_damage"):
			print("Sebzem ezt: ", enemy.name)
			enemy.take_damage(GameManager.player_damage)
		else:
			print("Ezen nincs take_damage: ", enemy.name)

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true




func _physics_process(delta):
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * speed
	move_and_slide()

func _input(event):
	if event.is_action_pressed("test_damage"):
		GameManager.damage(10)
	if event.is_action_pressed("attack"):
		attack()


func _on_attack_area_body_entered(body):
	if body.has_method("take_damage"):
		if not enemies_in_range.has(body):
			enemies_in_range.append(body)


func _on_attack_area_body_exited(body):
	if enemies_in_range.has(body):
		enemies_in_range.erase(body)

func player_hit_flash(_amount: int):
	player_sprite.modulate = Color(1, 0.25, 0.25)

	await get_tree().create_timer(0.08).timeout

	if is_instance_valid(player_sprite):
		player_sprite.modulate = player_original_color
