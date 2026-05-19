extends Area2D

@export var item_id: String = "health_potion"
@export var item_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var pickup_label: Label = $PickupLabel

var player_inside := false


func _ready():
	pickup_label.hide()

	if item_texture != null:
		sprite.texture = item_texture


func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		pick_up()


func pick_up():
	GameManager.add_item(item_id)
	queue_free()
	GameManager.set_objective("Vidd el a " + item_id + " itemet a Varázsló Tanárnak.")


func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true
		pickup_label.show()


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		pickup_label.hide()
