class_name DayNight
extends Node
## Slowly changes an outdoor map's light with the time of day (Session.day_hour):
## sun/moon colour, strength and angle, ambient light, sky and fog, and lamps at night.
## The look of each hour lives in data/world/daynight.json; at midday the map looks
## exactly as it was designed.

## How often the light is updated (it changes slowly, no need every frame).
const STEP: float = 0.2

var environment: Environment
var sun: DirectionalLight3D

var _base_sky: Color
var _base_sun: Color
var _base_sun_energy: float
var _base_amb: Color
var _base_amb_energy: float
var _base_fog: Color
var _timer: float = 0.0


func setup(env: Environment, light: DirectionalLight3D) -> void:
	environment = env
	sun = light
	_base_sky = env.background_color
	_base_amb = env.ambient_light_color
	_base_amb_energy = env.ambient_light_energy
	_base_fog = env.fog_light_color
	_base_sun = light.light_color
	_base_sun_energy = light.light_energy


func _ready() -> void:
	apply(Session.day_hour)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = STEP
		apply(Session.day_hour)


func apply(hour: float) -> void:
	var k: Dictionary = sample(hour)
	sun.light_color = _base_sun.lerp(k["sun_color"], k["sun_mix"])
	sun.light_energy = _base_sun_energy * float(k["sun"])
	sun.rotation_degrees = Vector3(-float(k["elev"]), float(k["yaw"]), 0.0)
	environment.ambient_light_color = _base_amb.lerp(k["amb_color"], k["amb_mix"])
	environment.ambient_light_energy = _base_amb_energy * float(k["amb"])
	environment.background_color = _base_sky.lerp(k["sky"], k["sky_mix"])
	if environment.fog_enabled:
		environment.fog_light_color = _base_fog.lerp(k["sky"], float(k["sky_mix"]) * 0.8)
	var night: float = float(k["night"])
	for n: Node in get_tree().get_nodes_in_group("night_lights"):
		var omni := n as OmniLight3D
		omni.light_energy = float(omni.get_meta("base_energy", 1.0)) * (0.35 + night * 1.15)


## The light settings at `hour` (0-24), blended smoothly between the two nearest keys.
static func sample(hour: float) -> Dictionary:
	var keys: Array = Data.daynight.get("keys", [])
	if keys.is_empty():
		return {"sun": 1.0, "sun_color": Color.WHITE, "sun_mix": 0.0, "amb": 1.0, "amb_color": Color.WHITE,
			"amb_mix": 0.0, "sky": Color.WHITE, "sky_mix": 0.0, "elev": 55.0, "yaw": -35.0, "night": 0.0}
	var h: float = fposmod(hour, 24.0)
	var a: Dictionary = keys[0]
	var b: Dictionary = keys[keys.size() - 1]
	for i: int in range(keys.size() - 1):
		if h >= float(keys[i]["h"]) and h <= float(keys[i + 1]["h"]):
			a = keys[i]
			b = keys[i + 1]
			break
	var span: float = maxf(float(b["h"]) - float(a["h"]), 0.001)
	var t: float = smoothstep(0.0, 1.0, (h - float(a["h"])) / span)
	var out: Dictionary = {}
	for key: String in ["sun", "sun_mix", "amb", "amb_mix", "sky_mix", "elev", "night"]:
		out[key] = lerpf(float(a.get(key, 0.0)), float(b.get(key, 0.0)), t)
	out["yaw"] = lerp_angle(deg_to_rad(float(a.get("yaw", 0.0))), deg_to_rad(float(b.get("yaw", 0.0))), t) * 180.0 / PI
	for key: String in ["sun_color", "amb_color", "sky"]:
		out[key] = Color(str(a.get(key, "#ffffff"))).lerp(Color(str(b.get(key, "#ffffff"))), t)
	return out


## 0 at midday, 1 deep at night (for the clock and anything else that cares).
static func darkness(hour: float) -> float:
	return float(sample(hour)["night"])
