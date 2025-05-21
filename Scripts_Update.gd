#player.gd
## Добавить в переменные
var has_radio: bool = false
var radio: RadioItem = null
var special_items: Array = []

## Добавить методы
func add_radio():
    if has_radio:
        return
    
    has_radio = true
    radio = RadioItem.new()
    add_child(radio)
    hud.show_message("Получено радио! Используйте R для управления")

func add_ammo(ammo_type: String, amount: int):
    for weapon in weapons:
        if weapon["type"] == ammo_type or (ammo_type == "pistol_ammo" and weapon["type"] == "pistol"):
            weapon["spare_ammo"] += amount
            hud.show_message("Получено %d патронов" % amount)
            update_hud()
            return
    
    hud.show_message("Нет оружия для этих патронов")

func add_special_item(item_data: Dictionary):
    special_items.append(item_data)
    hud.show_message("Получен предмет: %s" % item_data["name"])
    
    # Применяем эффекты специальных предметов
    match item_data["name"]:
        "Ночное зрение":
            enable_night_vision()
        "Фальшивые документы":
            increase_faction_reputation(50)

func enable_night_vision():
    # Здесь реализация ночного видения
    pass

func increase_faction_reputation(amount):
    if faction != Faction.NEUTRAL:
        add_reputation(amount)

#HUD.gd
## Добавить переменные
@onready var shop_ui = $ShopUI
@onready var shop_item_list = $ShopUI/ItemList
@onready var shop_title = $ShopUI/Title
@onready var shop_money_label = $ShopUI/MoneyLabel

## Добавить методы
func show_shop(shop_data: Dictionary):
    shop_title.text = shop_data["shop_name"]
    shop_money_label.text = "Деньги: $" + str(shop_data["player_money"])
    
    shop_item_list.clear()
    for item in shop_data["items"]:
        shop_item_list.add_item("%s - $%d" % [item["name"], item["price"]])
    
    shop_ui.visible = true

func hide_shop():
    shop_ui.visible = false

func _on_item_list_item_selected(index):
    # Здесь обработка покупки (нужно связать с ShopArea)
    pass
