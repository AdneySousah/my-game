class_name Shop
extends RefCounted
## Gold shops (GDD 6.6): buy from a merchant's list, sell what is in the bag.
## Prices in data/shop/shop.json (buy) and data/items/items.json (sell = "price").
## Actions return {"ok": bool, "msg": key of data/i18n}.

var player: Player


func _init(p: Player = null) -> void:
	player = p


static func goods(merchant: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var m: Dictionary = (Data.shop.get("merchants", {}) as Dictionary).get(merchant, {})
	for g: Variant in m.get("goods", []):
		if not Data.item(str((g as Dictionary).get("id", ""))).is_empty():
			out.append(g as Dictionary)
	return out


static func buy_price(merchant: String, item_id: String) -> int:
	for g: Dictionary in goods(merchant):
		if str(g["id"]) == item_id:
			return int(g.get("buy", 0))
	return 0


## Gold for one unit of a bag slot (gear is worth more with each +level).
static func sell_price(entry: Dictionary) -> int:
	var base: int = int(Data.item(str(entry.get("id", ""))).get("price", 0))
	var plus: int = int(entry.get("plus", 0))
	return roundi(base * (1.0 + float(Data.shop.get("sell_plus_bonus", 0.15)) * plus))


static func can_sell(entry: Dictionary) -> bool:
	return sell_price(entry) > 0 and str(entry.get("id", "")) != Session.STARTER_WEAPON


## How many the hero can afford and carry (0 = none).
func max_buy(merchant: String, item_id: String) -> int:
	var price: int = buy_price(merchant, item_id)
	if price <= 0 or player == null:
		return 0
	var by_gold: int = player.gold / price
	var stack: int = int(Data.item(item_id).get("stack", 1))
	var room: int = Session.inventory.free_slots() * stack
	if not Inventory.is_gear(item_id):
		for s: Dictionary in Session.inventory.slots:
			if s["id"] == item_id:
				room += stack - int(s["count"])
	return clampi(mini(by_gold, room), 0, 99)


func buy(merchant: String, item_id: String, count: int = 1) -> Dictionary:
	var price: int = buy_price(merchant, item_id)
	if price <= 0 or count <= 0:
		return {"ok": false, "msg": "SMITH_CANT"}
	if player.gold < price * count:
		return {"ok": false, "msg": "SMITH_NO_GOLD"}
	if max_buy(merchant, item_id) < count:
		return {"ok": false, "msg": "HUD_BAG_FULL"}
	player.add_gold(-price * count)
	Session.inventory.add(item_id, count)
	Session.routine.on_event("event", "buy")
	return {"ok": true, "msg": "SHOP_BOUGHT"}


## Sells `count` from the bag slot at `index`.
func sell(index: int, count: int = 1) -> Dictionary:
	var slots: Array[Dictionary] = Session.inventory.slots
	if index < 0 or index >= slots.size():
		return {"ok": false, "msg": "SMITH_CANT"}
	var entry: Dictionary = slots[index]
	if not can_sell(entry):
		return {"ok": false, "msg": "SHOP_CANT_SELL"}
	var gold: int = sell_price(entry)
	if entry.has("uid"):
		Session.inventory.take_uid(int(entry["uid"]))
		player.add_gold(gold)
		return {"ok": true, "msg": "SHOP_SOLD"}
	var n: int = mini(count, int(entry["count"]))
	Session.inventory.remove(str(entry["id"]), n)
	player.add_gold(gold * n)
	return {"ok": true, "msg": "SHOP_SOLD"}
