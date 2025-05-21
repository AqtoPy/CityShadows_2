extends Area3D

class_name ShopArea

@export_category("Настройки магазина")
@export var shop_name: String = "Магазин"
@export var price_multiplier: float = 1.0  # Множитель цен

@export_group("Товары")
@export var sell_armor: bool = true
@export var armor_price: int = 200
@export var armor_amount: int = 25

@export var sell_medkits: bool = true
@export var medkit_price: int = 150
@export var medkit_heal_amount: int = 30

@export var sell_radios: bool = true
@export var radio_price: int = 350

@export var sell_ammo: bool = true
@export var ammo_prices: Dictionary = {
    "pistol": 50,
    "assault_rifle": 80,
    "shotgun": 70
}

@export var sell_special_items: bool = false
@export var special_items: Array[Dictionary] = [
    {"name": "Ночное зрение", "price": 600, "icon": "night_vision"},
    {"name": "Глушитель", "price": 450, "icon": "silencer"},
    {"name": "Фальшивые документы", "price": 300, "icon": "fake_id"}
]

var player_in_shop: bool = false
var player_ref: Node = null

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    
    # Применяем множитель цен
    apply_price_multiplier()

func apply_price_multiplier():
    armor_price = int(armor_price * price_multiplier)
    medkit_price = int(medkit_price * price_multiplier)
    radio_price = int(radio_price * price_multiplier)
    
    for ammo_type in ammo_prices:
        ammo_prices[ammo_type] = int(ammo_prices[ammo_type] * price_multiplier)
    
    for item in special_items:
        item["price"] = int(item["price"] * price_multiplier)

func _on_body_entered(body):
    if body.is_in_group("player"):
        player_in_shop = true
        player_ref = body
        show_shop_ui()

func _on_body_exited(body):
    if body.is_in_group("player"):
        player_in_shop = false
        player_ref = null
        hide_shop_ui()

func show_shop_ui():
    if not player_ref:
        return
    
    var shop_data = {
        "shop_name": shop_name,
        "items": get_available_items(),
        "player_money": player_ref.money
    }
    
    # Отправляем данные в UI
    var ui = player_ref.get_node("Camera3D/HUD")
    if ui.has_method("show_shop"):
        ui.show_shop(shop_data)

func hide_shop_ui():
    if player_ref:
        var ui = player_ref.get_node("Camera3D/HUD")
        if ui.has_method("hide_shop"):
            ui.hide_shop()

func get_available_items() -> Array:
    var items = []
    
    if sell_armor:
        items.append({
            "type": "armor",
            "name": "Бронепластина (+%d)" % armor_amount,
            "price": armor_price,
            "icon": "armor",
            "amount": armor_amount
        })
    
    if sell_medkits:
        items.append({
            "type": "medkit",
            "name": "Аптечка (+%d HP)" % medkit_heal_amount,
            "price": medkit_price,
            "icon": "medkit",
            "amount": medkit_heal_amount
        })
    
    if sell_radios:
        items.append({
            "type": "radio",
            "name": "Портативное радио",
            "price": radio_price,
            "icon": "radio",
            "stations": 3
        })
    
    if sell_ammo:
        for ammo_type in ammo_prices:
            items.append({
                "type": "ammo",
                "name": "Патроны (%s)" % ammo_type,
                "price": ammo_prices[ammo_type],
                "icon": "ammo_" + ammo_type,
                "ammo_type": ammo_type,
                "amount": get_ammo_amount(ammo_type)
            })
    
    if sell_special_items:
        for item in special_items:
            var special_item = item.duplicate()
            special_item["type"] = "special"
            items.append(special_item)
    
    return items

func get_ammo_amount(ammo_type: String) -> int:
    match ammo_type:
        "pistol": return 24
        "assault_rifle": return 60
        "shotgun": return 16
        _: return 30

func try_purchase(item_type: String, item_data: Dictionary) -> bool:
    if not player_ref or not player_in_shop:
        return false
    
    if player_ref.money < item_data["price"]:
        # Воспроизвести звук "недостаточно денег"
        return false
    
    # Совершаем покупку
    player_ref.money -= item_data["price"]
    
    match item_type:
        "armor":
            player_ref.add_armor(item_data["amount"])
        "medkit":
            player_ref.heal(item_data["amount"])
        "radio":
            give_radio_to_player()
        "ammo":
            add_ammo_to_player(item_data["ammo_type"], item_data["amount"])
        "special":
            give_special_item_to_player(item_data)
    
    # Обновляем UI магазина
    show_shop_ui()
    return true

func give_radio_to_player():
    if player_ref.has_method("add_radio"):
        player_ref.add_radio()
    else:
        print("У игрока нет метода для получения радио!")

func add_ammo_to_player(ammo_type: String, amount: int):
    if player_ref.has_method("add_ammo"):
        player_ref.add_ammo(ammo_type, amount)
    else:
        print("У игрока нет метода для получения патронов!")

func give_special_item_to_player(item_data: Dictionary):
    if player_ref.has_method("add_special_item"):
        player_ref.add_special_item(item_data)
    else:
        print("У игрока нет метода для получения спецпредметов!")
