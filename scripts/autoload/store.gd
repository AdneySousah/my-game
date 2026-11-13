extends Node
## Real-money shop (GDD 6.6), autoloaded as `Store`. Every purchase goes through here,
## with one backend per platform:
##  - Google Play (Android, when the Godot Google Play Billing plugin is installed: Phase 7);
##  - test store (test builds on PC): simulates the purchase, no money involved;
##  - none (PC release builds): the special shop is hidden.
## Products and what they give come from data/shop/store.json. Main hands the rewards to
## the hero (signal `granted`) and saves right away; only then is the purchase consumed.

## A purchase was paid and must be given to the player now.
signal granted(product: Dictionary)
## A purchase did not go through (cancelled, error, pending payment): key of data/i18n.
signal failed(product_id: String, msg: String)
## Prices or availability changed (e.g. Google Play answered).
signal changed

const PLAY_CLASS: String = "BillingClient"
## Values of BillingClient.BillingResponseCode.OK / USER_CANCELED and PurchaseState.PURCHASED.
const PLAY_OK: int = 0
const PLAY_CANCELED: int = 1
const PLAY_PURCHASED: int = 1

## "play", "test" or "" (no shop).
var mode: String = ""
var products: Array[Dictionary] = []
## Product id -> price text from Google Play ("R$ 4,90").
var _play_prices: Dictionary = {}
var _play: Object = null
## Paid purchases found while nobody could receive them (e.g. on the title screen):
## [{"product": {...}, "token": "..."}]. The game claims them when it starts.
var _waiting: Array[Dictionary] = []


func _ready() -> void:
	var cfg: Dictionary = Data.store
	for p: Variant in cfg.get("products", []):
		products.append(p as Dictionary)
	if OS.has_feature("android") and _start_play():
		mode = "play"
	elif OS.is_debug_build():
		mode = "test"


func available() -> bool:
	return mode != ""


## The welcome offer ("first_purchase_only") is only for heroes who never bought anything.
func first_purchase_open() -> bool:
	return not Session.has_flag("store_bought") and Session.store_tokens.is_empty()


func product(id: String) -> Dictionary:
	for p: Dictionary in products:
		if str(p.get("id", "")) == id:
			return p
	return {}


## Price to show: Google Play's own text when known, else the price in data.
func price_text(id: String) -> String:
	if _play_prices.has(id):
		return str(_play_prices[id])
	var brl: float = float(product(id).get("price_brl", 0.0))
	return "R$ %s" % ("%.2f" % brl).replace(".", ",")


## Hands out purchases that arrived before the game could receive them (Main calls this).
func claim_waiting() -> void:
	var list: Array[Dictionary] = _waiting.duplicate()
	_waiting.clear()
	for w: Dictionary in list:
		var token: String = str(w["token"])
		if _given(token):
			continue
		_mark_given(token)
		granted.emit(w["product"])
		if _play:
			_play.call("consume_purchase", token)


## Starts a purchase. The answer comes later as `granted` or `failed`.
func buy(id: String) -> void:
	var p: Dictionary = product(id)
	if p.is_empty() or mode == "":
		failed.emit(id, "STORE_UNAVAILABLE")
		return
	match mode:
		"test":
			# Test store: answers like a real purchase would, a moment later.
			await get_tree().create_timer(0.3, true, false, true).timeout
			granted.emit(p)
		"play":
			var res: Variant = _play.call("purchase", id)
			if res is Dictionary and int((res as Dictionary).get("response_code", PLAY_OK)) != PLAY_OK:
				failed.emit(id, "STORE_ERROR")


# --- Google Play (Phase 7) -----------------------------------------------------------

## Creates the plugin's BillingClient if the plugin is installed. False otherwise.
func _start_play() -> bool:
	var path: String = ""
	for c: Dictionary in ProjectSettings.get_global_class_list():
		if str(c.get("class", "")) == PLAY_CLASS:
			path = str(c.get("path", ""))
	if path == "":
		return false
	var script: Script = load(path)
	if script == null:
		return false
	_play = script.new()
	if _play is Node:
		add_child(_play as Node)
	_play.connect("connected", _on_play_connected)
	_play.connect("query_product_details_response", _on_play_details)
	_play.connect("query_purchases_response", _on_play_purchases)
	_play.connect("on_purchase_updated", _on_play_purchases)
	_play.connect("disconnected", _on_play_lost)
	_play.connect("connect_error", func(_code: int, _msg: String) -> void: _on_play_lost())
	_play.call("start_connection")
	return true


## Tries to reach Google Play again a little later (no network, Play Store updating...).
func _on_play_lost() -> void:
	await get_tree().create_timer(15.0, true, false, true).timeout
	if _play and int(_play.call("get_connection_state")) != 2:
		_play.call("start_connection")


func _given(token: String) -> bool:
	return Session.store_tokens.has(token)


## Remembered in the save (Main saves right after `granted`), the last 100 only.
func _mark_given(token: String) -> void:
	Session.store_tokens.append(token)
	while Session.store_tokens.size() > 100:
		Session.store_tokens.pop_front()


func _on_play_connected() -> void:
	var ids: PackedStringArray = []
	for p: Dictionary in products:
		ids.append(str(p["id"]))
	_play.call("query_product_details", ids, 0)
	# Purchases paid while the game was closed (or not consumed yet) are handed out now.
	_play.call("query_purchases", 0)


func _on_play_details(res: Dictionary) -> void:
	if int(res.get("response_code", -1)) != PLAY_OK:
		return
	for d: Variant in res.get("product_details", []):
		var det: Dictionary = d
		var offers: Variant = det.get("one_time_purchase_offer_details_list", null)
		if offers is Array and not (offers as Array).is_empty():
			_play_prices[str(det.get("product_id", ""))] = str((offers as Array)[0].get("formatted_price", ""))
	changed.emit()


func _on_play_purchases(res: Dictionary) -> void:
	var code: int = int(res.get("response_code", -1))
	if code == PLAY_CANCELED:
		failed.emit("", "STORE_CANCELED")
		return
	if code != PLAY_OK:
		failed.emit("", "STORE_ERROR")
		return
	for v: Variant in res.get("purchases", []):
		var pur: Dictionary = v
		var token: String = str(pur.get("purchase_token", ""))
		if int(pur.get("purchase_state", 0)) != PLAY_PURCHASED:
			failed.emit("", "STORE_PENDING")
			continue
		if _given(token):
			# Handed out before but not consumed (the game closed in between): consume now.
			_play.call("consume_purchase", token)
			continue
		if granted.get_connections().is_empty():
			for pid: Variant in pur.get("product_ids", []):
				var wp: Dictionary = product(str(pid))
				if not wp.is_empty():
					_waiting.append({"product": wp, "token": token})
			continue
		for pid: Variant in pur.get("product_ids", []):
			var p: Dictionary = product(str(pid))
			if not p.is_empty():
				_mark_given(token)
				granted.emit(p)
		# Main saved the reward before this line runs (signals are synchronous).
		_play.call("consume_purchase", token)
