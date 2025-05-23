var inventory = preload("res://scripts/InventorySystem.gd").new()

func heal(amount):
    health = clamp(health + amount, 0, max_health)
    $HUD.update_health(health)

func _ready():
    add_child(inventory)

func toggle_inventory():
    $Inventory.visible = !$Inventory.visible
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if $Inventory.visible else Input.MOUSE_MODE_CAPTURED
