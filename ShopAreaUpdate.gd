extends Area3D

# ... (предыдущий код из ShopArea.gd остается без изменений до этого места)

func _ready():
    # Добавляем кнопку закрытия программно
    add_close_button()
    
    # Подключаем сигналы кнопок
    if player_ref and player_ref.get_node("Camera3D/HUD/ShopUI/PurchaseButton"):
        var purchase_btn = player_ref.get_node("Camera3D/HUD/ShopUI/PurchaseButton")
        purchase_btn.pressed.connect(_on_purchase_button_pressed)
        
        var close_btn = player_ref.get_node("Camera3D/HUD/ShopUI/CloseButton")
        close_btn.pressed.connect(_on_close_button_pressed)

func add_close_button():
    if player_ref:
        var shop_ui = player_ref.get_node("Camera3D/HUD/ShopUI")
        if shop_ui and not shop_ui.has_node("CloseButton"):
            var close_btn = Button.new()
            close_btn.name = "CloseButton"
            close_btn.text = "Закрыть"
            close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
            close_btn.pressed.connect(_on_close_button_pressed)
            shop_ui.get_node("VBoxContainer").add_child(close_btn)

func _on_purchase_button_pressed():
    if not player_ref:
        return
    
    var shop_ui = player_ref.get_node("Camera3D/HUD/ShopUI")
    var selected_idx = shop_ui.get_node("VBoxContainer/ItemList").get_selected_items()
    
    if selected_idx.is_empty():
        shop_ui.get_node("VBoxContainer").show_message("Выберите предмет!")
        return
    
    var item_idx = selected_idx[0]
    var items = get_available_items()
    
    if item_idx >= items.size():
        return
    
    var item = items[item_idx]
    
    if player_ref.money < item["price"]:
        shop_ui.get_node("VBoxContainer").show_message("Недостаточно денег!")
        return
    
    # Совершаем покупку
    if try_purchase(item["type"], item):
        shop_ui.get_node("VBoxContainer").show_message("Покупка совершена!")
        # Обновляем список денег
        shop_ui.get_node("VBoxContainer/MoneyLabel2").text = "Деньги: $" + str(player_ref.money)
    else:
        shop_ui.get_node("VBoxContainer").show_message("Ошибка покупки!")

func _on_close_button_pressed():
    hide_shop_ui()

# Дополняем существующий метод try_purchase
func try_purchase(item_type: String, item_data: Dictionary) -> bool:
    if not player_ref or not player_in_shop:
        return false
    
    if player_ref.money < item_data["price"]:
        player_ref.get_node("Camera3D/HUD").show_message("Недостаточно денег!")
        return false
    
    # Совершаем покупку
    player_ref.money -= item_data["price"]
    
    match item_type:
        "armor":
            player_ref.add_armor(item_data["amount"])
            player_ref.get_node("Camera3D/HUD").show_message("Куплена броня +" + str(item_data["amount"]))
        "medkit":
            player_ref.heal(item_data["amount"])
            player_ref.get_node("Camera3D/HUD").show_message("Куплена аптечка +" + str(item_data["amount"]) + " HP")
        "radio":
            give_radio_to_player()
            player_ref.get_node("Camera3D/HUD").show_message("Куплено радио!")
        "ammo":
            add_ammo_to_player(item_data["ammo_type"], item_data["amount"])
            player_ref.get_node("Camera3D/HUD").show_message("Куплены патроны: " + item_data["ammo_type"])
        "special":
            give_special_item_to_player(item_data)
            player_ref.get_node("Camera3D/HUD").show_message("Куплен: " + item_data["name"])
        _:
            return false
    
    # Обновляем UI магазина
    show_shop_ui()
    return true
