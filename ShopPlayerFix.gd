# В Player.gd:

func interact_with_shop():
    var shop = get_nearest_shop()
    if shop:
        shop.show_shop_ui(self)  # Передаем ссылку на игрока

# В ShopArea.gd:

func show_shop_ui(player):
    player_ref = player
    var shop_data = {
        "shop_name": shop_name,
        "items": get_available_items(),
        "player_money": player.money
    }
    player.get_node("Camera3D/HUD").show_shop(shop_data)
