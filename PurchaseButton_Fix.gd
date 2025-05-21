func _on_purchase_button_pressed():
    var shop_ui = player_ref.get_node("Camera3D/HUD/ShopUI")
    var item_list = shop_ui.get_node("VBoxContainer/ItemList")
    var selected = item_list.get_selected_items()
    
    if selected.is_empty():
        shop_ui.show_message("Выберите предмет сначала!", 1.5)
        return
    
    var item = get_available_items()[selected[0]]
    
    if player_ref.money < item["price"]:
        shop_ui.show_message("Недостаточно денег!", 1.5)
        # Анимация кнопки
        var btn = shop_ui.get_node("VBoxContainer/PurchaseButton")
        btn.modulate = Color.RED
        await get_tree().create_timer(0.3).timeout
        btn.modulate = Color.WHITE
        return
    
    # Успешная покупка
    try_purchase(item["type"], item)
    shop_ui.show_message("Куплено: " + item["name"], 2.0)
    shop_ui.update_money_display(player_ref.money)  # Новый метод для обновления
