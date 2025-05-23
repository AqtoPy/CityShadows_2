extends Node
class_name InventorySystem

## Сигналы
signal inventory_updated
signal item_used(item_data)
signal item_added(item_data)
signal item_removed(item_data)

## Настройки
@export var max_slots = 20
@export var max_stack_size = 99

## Данные инвентаря
var items = []
var equipped_items = {}

func _ready():
    initialize_inventory()

func initialize_inventory():
    items.resize(max_slots)
    items.fill(null)

## Добавление предмета в инвентарь
func add_item(item_data: Dictionary):
    # Проверка на валидность предмета
    if not validate_item(item_data):
        push_error("Invalid item data!")
        return false
    
    var remaining = item_data.get("quantity", 1)
    var stackable = item_data.get("stackable", false)
    
    # Попытка объединения стака
    if stackable:
        for i in items.size():
            if items[i] and items[i]["id"] == item_data["id"]:
                var space = max_stack_size - items[i]["quantity"]
                if space > 0:
                    var add_amount = min(remaining, space)
                    items[i]["quantity"] += add_amount
                    remaining -= add_amount
                    if remaining <= 0:
                        inventory_updated.emit()
                        return true
    
    # Добавление в новые слоты
    while remaining > 0:
        var empty_slot = find_first_empty_slot()
        if empty_slot == -1:
            print("Inventory full!")
            return false
        
        var new_item = item_data.duplicate()
        new_item["quantity"] = min(remaining, max_stack_size)
        items[empty_slot] = new_item
        remaining -= new_item["quantity"]
        item_added.emit(new_item)
    
    inventory_updated.emit()
    return true

## Удаление предмета
func remove_item(slot: int, quantity: int = 1):
    if slot < 0 or slot >= items.size():
        return false
    
    if not items[slot]:
        return false
    
    if items[slot]["quantity"] > quantity:
        items[slot]["quantity"] -= quantity
    else:
        items[slot] = null
    
    inventory_updated.emit()
    item_removed.emit(items[slot])
    return true

## Использование предмета
func use_item(slot: int):
    if slot < 0 or slot >= items.size():
        return
    
    var item = items[slot]
    if not item:
        return
    
    match item["type"]:
        "consumable":
            handle_consumable(item)
            remove_item(slot, 1)
        "equipment":
            equip_item(item)
        _:
            print("Cannot use this item type")

## Экипировка предмета
func equip_item(item_data):
    var slot_type = item_data.get("equipment_slot", "general")
    equipped_items[slot_type] = item_data
    apply_item_effects(item_data)

## Поиск предметов по ID
func find_items(item_id: String):
    var found = []
    for item in items:
        if item and item["id"] == item_id:
            found.append(item)
    return found

## Сохранение инвентаря
func save_inventory():
    var save_data = {
        "items": items.duplicate(true),
        "equipped": equipped_items.duplicate(true)
    }
    return save_data

## Загрузка инвентаря
func load_inventory(save_data):
    items = save_data["items"]
    equipped_items = save_data["equipped"]
    inventory_updated.emit()

## Вспомогательные функции
func find_first_empty_slot():
    return items.find(null)

func validate_item(item_data):
    return item_data.has("id") and item_data.has("name") and item_data.has("type")

func get_item(slot):
    return items[slot] if slot >= 0 and slot < items.size() else null

func handle_consumable(item):
    var player = get_parent()
    if player.has_method("heal"):
        player.heal(item["effect_value"])
    item_used.emit(item)

func apply_item_effects(item):
    var player = get_parent()
    if player.has_method("apply_equipment_effects"):
        player.apply_equipment_effects(item)
