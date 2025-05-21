# В ready() игрока:
func _ready():
    var shop_ui = $Camera3D/HUD/ShopUI
    shop_ui.get_node("PurchaseButton").pressed.connect(_on_purchase_pressed)
    shop_ui.get_node("CloseButton").pressed.connect(_on_close_pressed)
