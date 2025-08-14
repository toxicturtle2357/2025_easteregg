extends Node

const COOLDOWN_S: float = 0.25
const DEBUG_PM: bool = false

var pairs: Dictionary = {}          # pair_id -> {1: portal, 2: portal}
var cooldown_until: Dictionary = {} # instance_id(int) -> allowed_at(ms)

func registerPortal(p: Node) -> void:
	var t: int = p.portal_type
	if t != 1 and t != 2:
		t = 1
		p.portal_type = 1
	var d: Dictionary = pairs.get(p.pair_id, {})
	d[t] = p
	pairs[p.pair_id] = d
	if DEBUG_PM: print("[PM] register pair=", p.pair_id, " type=", t, " map=", pairs.get(p.pair_id))

func unregisterPortal(p: Node) -> void:
	if not pairs.has(p.pair_id):
		return
	pairs[p.pair_id].erase(p.portal_type)
	if pairs[p.pair_id].is_empty():
		pairs.erase(p.pair_id)
	if DEBUG_PM: print("[PM] unregister pair=", p.pair_id, " type=", p.portal_type)

func getOtherPortal(p: Node) -> Node2D:
	if not pairs.has(p.pair_id):
		return null
	var other_type: int = 2 if p.portal_type == 1 else 1
	return pairs[p.pair_id].get(other_type, null) as Node2D

func checkTeleportAllowed(body: Node) -> bool:
	var id := body.get_instance_id()
	return Time.get_ticks_msec() >= int(cooldown_until.get(id, 0))

func markTeleport(body: Node) -> void:
	var id := body.get_instance_id()
	cooldown_until[id] = Time.get_ticks_msec() + int(COOLDOWN_S * 1000.0)
