extends Area3D

var player_ref: Node = null

func _on_body_entered(body):
    if body.is_in_group("player"):
        player_ref = body
        show_shop_ui()

func show_shop_ui():
    if !player_ref: return
    
    var shop_data = {
        "items": get_available_items(),
        "player_money": player_ref.money
    }
    
    var hud = player_ref.get_node("Camera3D/HUD")
    hud.show_shop(shop_data)
    
    # Явное подключение сигналов
    var purchase_btn = hud.get_node("ShopUI/PurchaseButton")
    if !purchase_btn.is_connected("pressed", _on_purchase_pressed):
        purchase_btn.pressed.connect(_on_purchase_pressed.bind())

func _on_purchase_pressed():
    if !player_ref: return
    
    var hud = player_ref.get_node("Camera3D/HUD")
    var item_list = hud.get_node("ShopUI/ItemList")
    var selected = item_list.get_selected_items()
    
    if selected.is_empty():
        hud.show_message("Выберите предмет!")
        return
    
    var item = get_available_items()[selected[0]]
    
    if player_ref.money < item["price"]:
        hud.show_message("Недостаточно денег!")
        return
    
    # Совершаем покупку
    player_ref.money -= item["price"]
    apply_purchase(item)
    
    # Обновляем интерфейс
    hud.update_money_display(player_ref.money)
    hud.show_message("Куплено: " + item["name"])

func apply_purchase(item):
    match item["type"]:
        "armor":
            player_ref.add_armor(item["amount"])
        "medkit":
            player_ref.heal(item["amount"])
        # ... другие типы предметов
