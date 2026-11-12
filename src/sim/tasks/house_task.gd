## One piece of household work (GDD §10.4): repair a broken object, or clean a room.
## Built fresh by [TaskBoard] from the house's current state; never stored in data.
class_name HouseTask
extends RefCounted

enum Type { REPAIR, CLEAN }

## Stable identity, e.g. "repair:stove" or "clean:kitchen". Claims use it.
var key: String = ""
var type: Type = Type.REPAIR
var target_id: String = ""
var room_id: String = ""
var priority: int = 0
var work_minutes: int = 0
var on_success: Array[Dictionary] = []
## Position in the data, the last tie-breaker (keeps choices repeatable).
var order: int = 0
