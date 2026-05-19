extends Node2D

@onready var room_trigger: Area2D = $RoomTrigger
@onready var enemies_container: Node2D = $Enemies
@export_flags_2d_navigation var room_navigation_layers: int = 1

@onready var nav_region: NavigationRegion2D = $NavigationRegion2D




func _ready():
	nav_region.navigation_layers = room_navigation_layers

	for enemy in enemies_container.get_children():
		if enemy.has_method("set_room_navigation_layers"):
			enemy.set_room_navigation_layers(room_navigation_layers)

	room_trigger.body_entered.connect(_on_room_body_entered)
	room_trigger.body_exited.connect(_on_room_body_exited)


func _on_room_body_entered(body):
	if body.is_in_group("player"):
		for enemy in enemies_container.get_children():
			if enemy.has_method("on_player_entered_room"):
				enemy.on_player_entered_room()


func _on_room_body_exited(body):
	if body.is_in_group("player"):
		for enemy in enemies_container.get_children():
			if enemy.has_method("on_player_exited_room"):
				enemy.on_player_exited_room()
