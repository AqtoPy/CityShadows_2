extends TextureRect
class_name InventorySlot

@onready var count_label = $CountLabel
@export var slot_index = 0

func update_slot(item):
    if item:
        texture = load(item["icon"])
        count_label.visible = item.get("stackable", false)
        count_label.text = str(item["quantity"])
    else:
        texture = null
        count_label.visible = false
