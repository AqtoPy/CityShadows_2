func show_shop(data):
    $ShopUI.visible = true
    $ShopUI/ItemList.clear()
    
    for item in data["items"]:
        var text = "%s - $%d" % [item["name"], item["price"]]
        $ShopUI/ItemList.add_item(text)
    
    update_money_display(data["player_money"])

func update_money_display(amount):
    $ShopUI/MoneyLabel.text = "Деньги: $" + str(amount)
