extends RigidBody3D
class_name SodaItem

@export var item_data = {
    "id": "soda_can",
    "name": "Газировка",
    "type": "consumable",
    "stackable": true,
    "icon": "res://items/soda_icon.png",
    "health_restore": 20,
    "description": "Восстанавливает 20 здоровья"
}

func _ready():
    $PickupArea.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body.is_in_group("player"):
        if body.inventory.add_item(item_data):
            queue_free()
            body.show_message("+1 Газировка", 1.5)

func use_item(player):
    player.heal(item_data["health_restore"])
    player.show_message("Восстановлено +20 HP", 2.0)
    return true
