# Где-то в конце скрипта Player.gd добавьте:

func _on_purchase_pressed():
    if $Camera3D/HUD/ShopUI.visible:  # Проверяем, открыт ли магазин
        var shop_area = get_nearest_shop()  # Нужно реализовать этот метод
        if shop_area:
            shop_area._on_purchase_button_pressed()  # Вызываем метод магазина

func _on_close_pressed():
    $Camera3D/HUD/ShopUI.visible = false

# Добавьте этот метод для поиска ближайшего магазина
func get_nearest_shop():
    var shops = get_tree().get_nodes_in_group("shop")
    var nearest = null
    var min_dist = INF
    
    for shop in shops:
        var dist = global_position.distance_to(shop.global_position)
        if dist < min_dist and dist < shop.interaction_distance:
            min_dist = dist
            nearest = shop
    
    return nearest
