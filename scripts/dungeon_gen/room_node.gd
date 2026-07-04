class_name RoomNode
extends RefCounted
## One room in the floor graph (see docs/gdd/10-dungeon-gen.md).

enum RoomType {
	ENTRANCE,
	COMBAT,
	ELITE,
	SHOP,
	SHRINE,
	TREASURE,
	EVENT,
	SECRET,
	MINIBOSS,
	HEAL,
	BOSS,
}

var id: int = -1
var type: RoomType = RoomType.COMBAT
var depth: int = 0
var on_critical_path: bool = false
var neighbors: Array[int] = []
var template_id: String = ""


func type_name() -> String:
	return RoomType.keys()[type]
