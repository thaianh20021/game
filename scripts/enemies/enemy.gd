class_name Enemy
extends CharacterBody2D
## Enemy with kind-based AI behaviors and elemental statuses/combos
## (GDD sections 7 and 11). Kind is set by the spawner from enemy data:
##   melee_charger: telegraph 0.5s then locked dash
##   ranged/caster: keep distance, fire projectiles
##   exploder: chase, fuse on contact range, blast
##   flyer: sine-wave chase
##   others: straight chase (tanker is slow via SPEED_BY_KIND)

signal died(enemy: Enemy)
signal element_combo_triggered(info: Dictionary)

const DOT_INTERVAL := 0.5
const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")
const PROJECTILE_PROFILES := {
	"mycelium_archer": {
		"attack": "spore_shot",
		"status": "poisoned",
		"duration": 2.0,
		"color": Color(0.54, 1.0, 0.38),
	},
	"spore_oracle": {
		"attack": "spore_bolt",
		"status": "poisoned",
		"duration": 2.4,
		"color": Color(0.48, 1.0, 0.38),
	},
	"slag_thrower": {
		"attack": "slag_shot",
		"status": "burning",
		"duration": 2.0,
		"color": Color(1.0, 0.38, 0.16),
	},
	"ember_acolyte": {
		"attack": "ember_bolt",
		"status": "burning",
		"duration": 2.2,
		"color": Color(1.0, 0.48, 0.22),
	},
	"glyph_archer": {
		"attack": "archive_bolt",
		"status": "chilled",
		"duration": 1.5,
		"color": Color(0.58, 0.88, 1.0),
	},
	"mirror_acolyte": {
		"attack": "mirror_hex",
		"status": "chilled",
		"duration": 1.7,
		"color": Color(0.72, 0.78, 1.0),
	},
}
const TELEGRAPH_PROFILES := {
	"coal_imp": {"attack": "hot_charge", "label": "HOT CHARGE", "color": Color(1.0, 0.38, 0.16, 0.65)},
	"index_lancer": {"attack": "lance_charge", "label": "LANCE", "color": Color(0.58, 0.86, 1.0, 0.62)},
	"puffcap_bomber": {"attack": "spore_bloom", "label": "SPORE", "color": Color(0.52, 1.0, 0.38, 0.62)},
	"blast_keg": {"attack": "forge_blast", "label": "BLAST", "color": Color(1.0, 0.34, 0.14, 0.68)},
	"glass_bomber": {"attack": "glass_burst", "label": "GLASS", "color": Color(0.62, 0.9, 1.0, 0.66)},
}

@export var speed := 55.0
@export var max_hp := 20
@export var contact_damage := 5
@export var sight_range := 150.0
@export var contact_range := 12.0

var kind := "melee"
var hp: int
var target: Node2D
var base_tint := Color.WHITE  # elite tint, set by the spawner
var weak_elements: Array[String] = []
var resist_elements: Array[String] = []

var _statuses := {}  # status name -> seconds left
var _hit_cd := 0.0
var _attack_cd := 0.0
var _dot_tick := 0.0
var _time := 0.0
var _elite_teleport_cd := 1.2
var _state := "chase"
var _state_timer := 0.0
var _dash_dir := Vector2.ZERO
var _projectile_windup_dir := Vector2.RIGHT
var _contact_telegraph_target_id := 0
var _contact_telegraph_started_at := -999.0
var _hp_bar: Node2D
var _hp_fill: ColorRect
var _last_hit_effectiveness := "normal"
var _affinity_feedback_pending := false
var _last_hit_critical := false
var _last_hit_element := ""
var _last_hit_damage_amount := 0
var _sprite_action_left := 0.0
var _sprite_action := ""
var _dying := false
@onready var _sprite: AnimatedSprite2D = get_node_or_null("Sprite")
@onready var _body: Polygon2D = get_node_or_null("Body")


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	modulate = base_tint


func _physics_process(delta: float) -> void:
	_time += delta
	_sprite_action_left = maxf(_sprite_action_left - delta, 0.0)
	if _dying:
		velocity = Vector2.ZERO
		return
	_hit_cd = maxf(_hit_cd - delta, 0.0)
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if not _tick_statuses(delta):  # frozen or stunned
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if target == null or not is_instance_valid(target):
		return
	if not _tick_family_trait(delta):
		return
	_tick_elite_modifier(delta)
	_behave(delta)
	_update_sprite_anim()
	if kind != "exploder":
		_try_contact_damage()


func configure_visual(idle_name: String, run_name: String = "") -> void:
	if _sprite == null:
		_sprite = get_node_or_null("Sprite")
	if _body == null:
		_body = get_node_or_null("Body")
	if _sprite == null or idle_name == "":
		return
	var anims := {"idle": idle_name}
	anims["run"] = run_name if run_name != "" else idle_name
	for optional in ["attack", "hurt", "death"]:
		var optional_name := _related_sprite_name(idle_name, optional)
		if optional_name != "":
			anims[optional] = optional_name
	var sprite_frames := SpriteDB.build_sprite_frames(anims)
	if sprite_frames == null:
		return
	_sprite.sprite_frames = sprite_frames
	_sprite.visible = true
	_sprite.scale = SpriteDB.visual_scale(idle_name, maxf(_collision_half_height() * 2.0, 24.0))
	SpriteDB.apply_sprite_metadata(_sprite, idle_name)
	_sprite.set_meta("run_sprite_name", run_name if run_name != "" else idle_name)
	for optional in ["attack", "hurt", "death"]:
		if anims.has(optional):
			_sprite.set_meta("%s_sprite_name" % optional, str(anims[optional]))
	_align_sprite_to_collision()
	_sprite.play("idle")
	if _body != null:
		_body.visible = false

func configure_element_affinity(weak: Array, resist: Array) -> void:
	weak_elements.clear()
	resist_elements.clear()
	for element in weak:
		weak_elements.append(str(element))
	for element in resist:
		resist_elements.append(str(element))
	set_meta("weak", ",".join(weak_elements))
	set_meta("resist", ",".join(resist_elements))


func _update_sprite_anim() -> void:
	if _sprite == null or not _sprite.visible or _sprite.sprite_frames == null:
		return
	if _sprite_action_left > 0.0 and _sprite.sprite_frames.has_animation(_sprite_action):
		return
	var anim := "run" if velocity.length_squared() > 1.0 else "idle"
	if _sprite.animation != anim:
		_sprite.play(anim)
	var face_dir := velocity
	if face_dir.length_squared() <= 1.0 and target != null and is_instance_valid(target):
		face_dir = target.global_position - global_position
	if absf(face_dir.x) > 0.01:
		_sprite.flip_h = face_dir.x < 0.0


func play_sprite_action(anim: String, duration: float = 0.18) -> bool:
	if _sprite == null or _sprite.sprite_frames == null or not _sprite.sprite_frames.has_animation(anim):
		return false
	_sprite_action = anim
	_sprite_action_left = maxf(duration, 0.0)
	_sprite.play(anim)
	set_meta("last_sprite_action_anim", anim)
	set_meta("last_sprite_action_seconds", _sprite_action_left)
	return true


func _related_sprite_name(idle_name: String, action: String) -> String:
	var prefix := idle_name
	if prefix.ends_with("_idle"):
		prefix = prefix.trim_suffix("_idle")
	elif prefix.ends_with("_walk"):
		prefix = prefix.trim_suffix("_walk")
	var candidate := "%s_%s" % [prefix, action]
	return candidate if SpriteDB.has_sprite(candidate) else ""


func _align_sprite_to_collision() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var frame_height := _sprite_frame_height()
	if frame_height <= 0.0:
		return
	var scale_y := maxf(absf(_sprite.scale.y), 0.001)
	_sprite.offset = Vector2(0.0, _collision_half_height() / scale_y - frame_height * 0.5)


func _sprite_frame_height() -> float:
	var max_height := 0.0
	for anim_name in _sprite.sprite_frames.get_animation_names():
		for i in _sprite.sprite_frames.get_frame_count(anim_name):
			var frame := _sprite.sprite_frames.get_frame_texture(anim_name, i)
			if frame != null:
				max_height = maxf(max_height, frame.get_size().y)
	return max_height


func _collision_half_height() -> float:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return 0.0
	var rect := collision.shape as RectangleShape2D
	return rect.size.y * 0.5 if rect != null else 0.0


func _behave(delta: float) -> void:
	match kind:
		"melee_charger":
			_charger_behavior(delta)
		"ranged", "caster":
			_ranged_behavior(delta)
		"exploder":
			_exploder_behavior(delta)
		"flyer":
			_flyer_behavior(delta)
		_:
			_chase_behavior(delta)

func _tick_elite_modifier(delta: float) -> void:
	if str(get_meta("elite_modifier", "")) != "teleporting":
		return
	_elite_teleport_cd -= delta
	if _elite_teleport_cd > 0.0:
		return
	var to_target := target.global_position - global_position
	if to_target.length() < 110.0:
		_elite_teleport_cd = 0.45
		return
	var away_dir := (global_position - target.global_position).normalized()
	if away_dir.length_squared() <= 0.0:
		away_dir = Vector2.RIGHT
	var old_position := global_position
	global_position = target.global_position + away_dir * 56.0
	_elite_teleport_cd = 2.4
	set_meta("elite_teleports", int(get_meta("elite_teleports", 0)) + 1)
	_spawn_attack_telegraph_at(old_position, away_dir, 18.0, 0.12, "blink", "BLINK",
		Color(0.78, 0.42, 1.0, 0.55)).set_meta("elite_modifier", "teleporting")
	_spawn_attack_telegraph_at(global_position, -away_dir, 18.0, 0.16, "blink", "BLINK",
		Color(0.78, 0.42, 1.0, 0.75)).set_meta("elite_modifier", "teleporting")

func _tick_family_trait(_delta: float) -> bool:
	match str(get_meta("enemy_id", "")):
		"stalactite_wisp":
			return _tick_stalactite_wisp()
	return true

func _tick_stalactite_wisp() -> bool:
	if not bool(get_meta("ambush_hidden", false)):
		return true
	velocity = Vector2.ZERO
	if target == null or not is_instance_valid(target):
		return false
	if global_position.distance_to(target.global_position) > 28.0:
		return false
	set_meta("ambush_hidden", false)
	set_meta("ambush_dropped", true)
	visible = true
	_show_telegraph_fx((target.global_position - global_position).normalized(), 34.0, 0.12,
		"ambush", "AMBUSH")
	if target.has_method("take_damage") and global_position.distance_to(target.global_position) <= 34.0:
		if target is Player:
			target.take_damage(contact_damage, global_position, _enemy_damage_source_label())
		else:
			target.take_damage(contact_damage)
	_hit_cd = 0.8
	return true


func _chase_behavior(_delta: float) -> void:
	var to_target := target.global_position - global_position
	if to_target.length() <= sight_range:
		velocity = to_target.normalized() * speed * _speed_mult()
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _charger_behavior(delta: float) -> void:
	var to_target := target.global_position - global_position
	match _state:
		"telegraph":
			velocity = Vector2.ZERO
			_state_timer -= delta
			_blink(Color(1.6, 1.6, 1.6))
			if _state_timer <= 0.0:
				_state = "dash"
				_state_timer = 0.4
				_dash_dir = to_target.normalized()  # direction locks here
				modulate = _current_tint()
		"dash":
			velocity = _dash_dir * speed * 3.2 * _speed_mult()
			_state_timer -= delta
			if _state_timer <= 0.0:
				_state = "cooldown"
				_state_timer = 0.7
		"cooldown":
			velocity = Vector2.ZERO
			_state_timer -= delta
			if _state_timer <= 0.0:
				_state = "chase"
		_:
			if to_target.length() > sight_range:
				velocity = Vector2.ZERO
			elif to_target.length() <= 70.0:
				_state = "telegraph"
				_state_timer = 0.5
				velocity = Vector2.ZERO
				play_sprite_action("attack", _state_timer)
				var profile := _telegraph_profile("charge", "CHARGE")
				_show_telegraph_fx(
					to_target.normalized(),
					28.0,
					_state_timer,
					str(profile["attack"]),
					str(profile["label"]),
					profile["color"]
				)
			else:
				velocity = to_target.normalized() * speed * _speed_mult()
	move_and_slide()


func _ranged_behavior(delta: float) -> void:
	var to_target := target.global_position - global_position
	var dist := to_target.length()
	if _state == "projectile_telegraph":
		velocity = Vector2.ZERO
		move_and_slide()
		_state_timer -= delta
		_blink(Color(1.55, 0.95, 0.55))
		if _state_timer <= 0.0:
			_state = "chase"
			modulate = _current_tint()
			_attack_cd = 1.8
			_fire_ranged_attack(_projectile_windup_dir)
		return
	if dist > sight_range * 1.4:
		velocity = Vector2.ZERO
	elif dist < 60.0:
		velocity = -to_target.normalized() * speed * _speed_mult()
	elif dist > 140.0:
		velocity = to_target.normalized() * speed * _speed_mult()
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	if dist <= 180.0 and _attack_cd <= 0.0:
		_begin_projectile_windup(to_target.normalized())

func _begin_projectile_windup(dir: Vector2) -> void:
	_state = "projectile_telegraph"
	_state_timer = CombatFxScript.MIN_ATTACK_TELEGRAPH_SECONDS
	_projectile_windup_dir = dir if dir.length_squared() > 0.0 else Vector2.RIGHT
	play_sprite_action("attack", _state_timer)
	var attack := _default_projectile_attack_id()
	var readability := _projectile_readability_payload(attack)
	set_meta("projectile_telegraph_seconds", CombatFxScript.MIN_ATTACK_TELEGRAPH_SECONDS)
	set_meta("projectile_telegraph_started_at", _time)
	set_meta("projectile_telegraph_attack", attack)
	set_meta("projectile_telegraph_label", str(readability.get("attack_label", _attack_label(attack))))
	_show_telegraph_fx(
		_projectile_windup_dir,
		42.0,
		CombatFxScript.MIN_ATTACK_TELEGRAPH_SECONDS,
		attack,
		str(readability.get("attack_label", _attack_label(attack))),
		readability.get("color", Color(1.0, 0.45, 0.35, 0.6))
	)

func _fire_ranged_attack(dir: Vector2) -> void:
	if _try_family_ranged_attack(dir):
		return
	_shoot(dir, 150.0, contact_damage, 220.0)

func _try_family_ranged_attack(dir: Vector2) -> bool:
	match str(get_meta("enemy_id", "")):
		"quartz_shaman":
			_quartz_shaman_volley(dir)
			_buff_nearby_golems()
			return true
	return false

func _quartz_shaman_volley(dir: Vector2) -> void:
	var aim := dir if dir.length_squared() > 0.0 else Vector2.RIGHT
	for angle in [-16.0, 0.0, 16.0]:
		_shoot(aim.rotated(deg_to_rad(angle)), 145.0, maxi(contact_damage - 1, 1), 240.0,
			"crystal_volley")

func _buff_nearby_golems() -> void:
	var parent := get_parent()
	if parent == null:
		return
	for child in parent.get_children():
		var golem := child as Enemy
		if golem == null or golem == self:
			continue
		if str(golem.get_meta("enemy_id", "")) != "rubble_golem":
			continue
		if bool(golem.get_meta("quartz_shaman_buffed", false)):
			continue
		if global_position.distance_to(golem.global_position) > 120.0:
			continue
		golem.set_meta("quartz_shaman_buffed", true)
		golem.speed *= 1.18
		golem.contact_damage += maxi(1, ceili(float(golem.contact_damage) * 0.2))
		golem.base_tint *= Color(0.8, 1.05, 1.25)
		golem.modulate = golem._current_tint()


func _exploder_behavior(delta: float) -> void:
	var to_target := target.global_position - global_position
	match _state:
		"fuse":
			velocity = Vector2.ZERO
			_state_timer -= delta
			_blink(Color(2.0, 0.5, 0.5))
			if _state_timer <= 0.0:
				_explode()
		_:
			if to_target.length() <= 26.0:
				_state = "fuse"
				_state_timer = 0.8
				velocity = Vector2.ZERO
				play_sprite_action("attack", _state_timer)
				var profile := _telegraph_profile("explode", "EXPLODE")
				_show_telegraph_fx(
					to_target.normalized(),
					44.0,
					_state_timer,
					str(profile["attack"]),
					str(profile["label"]),
					profile["color"]
				)
			elif to_target.length() <= sight_range:
				velocity = to_target.normalized() * speed * _speed_mult()
			else:
				velocity = Vector2.ZERO
	move_and_slide()


func _flyer_behavior(_delta: float) -> void:
	var to_target := target.global_position - global_position
	if to_target.length() <= sight_range:
		var dir := to_target.normalized()
		var perp := dir.orthogonal() * sin(_time * 6.0) * 0.6
		velocity = (dir + perp).normalized() * speed * _speed_mult()
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _explode() -> void:
	if target != null and is_instance_valid(target) \
			and global_position.distance_to(target.global_position) <= 44.0 \
			and target.has_method("take_damage"):
		if target is Player:
			target.take_damage(contact_damage, global_position, _enemy_damage_source_label())
		else:
			target.take_damage(contact_damage)
	_die()


func _try_contact_damage() -> void:
	if target == null or not is_instance_valid(target):
		_clear_contact_telegraph()
		return
	var to_target := target.global_position - global_position
	if _hit_cd > 0.0 or to_target.length() > contact_range or not target.has_method("take_damage"):
		if to_target.length() > contact_range:
			_clear_contact_telegraph()
		return
	var target_id := target.get_instance_id()
	if _contact_telegraph_target_id != target_id:
		_arm_contact_telegraph(target_id, to_target)
		return
	if _time - _contact_telegraph_started_at < CombatFxScript.MIN_ATTACK_TELEGRAPH_SECONDS:
		return
	_apply_contact_damage()

func _arm_contact_telegraph(target_id: int, to_target: Vector2) -> void:
	_contact_telegraph_target_id = target_id
	_contact_telegraph_started_at = _time
	set_meta("contact_telegraph_seconds", CombatFxScript.MIN_ATTACK_TELEGRAPH_SECONDS)
	set_meta("contact_telegraph_started_at", _contact_telegraph_started_at)
	var dir := to_target.normalized() if to_target.length_squared() > 0.0 else Vector2.RIGHT
	_show_telegraph_fx(dir, maxf(contact_range + 10.0, 22.0),
		CombatFxScript.MIN_ATTACK_TELEGRAPH_SECONDS, "contact", "HIT")

func _apply_contact_damage() -> void:
	play_sprite_action("attack", 0.16)
	if target is Player:
		target.take_damage(contact_damage, global_position, _enemy_damage_source_label())
		if target.has_method("on_melee_attacked"):
			target.call("on_melee_attacked", self, contact_damage)
	else:
		target.take_damage(contact_damage)
	_try_elite_contact_status()
	_try_family_contact_status()
	_try_room_affix_contact_status()
	_try_vampiric_contact_heal()
	_hit_cd = 0.6
	_clear_contact_telegraph()

func _clear_contact_telegraph() -> void:
	_contact_telegraph_target_id = 0
	_contact_telegraph_started_at = -999.0

func _enemy_damage_source_label() -> String:
	var id := str(get_meta("enemy_id", "")).strip_edges()
	if id != "":
		return "Enemy: %s" % id.replace("_", " ").capitalize()
	var clean_kind := kind.strip_edges()
	if clean_kind != "":
		return "Enemy: %s" % clean_kind.replace("_", " ").capitalize()
	return "Enemy"

func _try_elite_contact_status() -> void:
	match str(get_meta("elite_modifier", "")):
		"burning":
			_apply_target_status("burning", 2.4)
		"frozen":
			_apply_target_status("chilled", 1.2)

func _try_family_contact_status() -> void:
	match str(get_meta("enemy_id", "")):
		"cave_slime":
			_apply_target_status("poisoned", 2.4)

func _try_room_affix_contact_status() -> void:
	if str(get_meta("room_affix", "")) == "cursed_mist":
		_apply_target_status("cursed", 2.5)

func _apply_target_status(status_name: String, duration: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("add_status"):
		target.call("add_status", status_name, duration)
	else:
		target.set_meta("status_" + status_name + "_left", duration)

func _try_vampiric_contact_heal() -> void:
	if str(get_meta("elite_modifier", "")) != "vampiric":
		return
	if hp <= 0 or hp >= max_hp:
		return
	var heal := maxi(1, ceili(float(contact_damage) * 0.75))
	hp = mini(max_hp, hp + heal)
	_update_hp_bar()
	_spawn_heal_number(heal)


func _shoot(
		dir: Vector2,
		speed_px: float,
		damage: int,
		range_px: float,
		attack_id: String = "",
) -> void:
	var projectile := EnemyProjectile.new()
	projectile.setup(dir, speed_px, damage, range_px)
	var payload := _projectile_status_payload()
	if not payload.is_empty():
		projectile.setup_status(str(payload.get("status", "")), float(payload.get("duration", 0.0)))
	var attack := attack_id if attack_id != "" else _default_projectile_attack_id()
	var readability := _projectile_readability_payload(attack)
	if not readability.is_empty():
		projectile.setup_readability(
			str(readability.get("variant", "")),
			readability.get("color", Color(1.0, 0.45, 0.35)),
			"enemy")
	_tag_projectile_readability(projectile, attack, readability)
	_projectile_parent().add_child(projectile)
	projectile.global_position = global_position + dir * 8.0

func _projectile_status_payload() -> Dictionary:
	var profile: Dictionary = PROJECTILE_PROFILES.get(str(get_meta("enemy_id", "")), {})
	if not profile.is_empty():
		return {
			"status": str(profile.get("status", "")),
			"duration": float(profile.get("duration", 0.0)),
		}
	match str(get_meta("enemy_id", "")):
		"web_spider":
			return {"status": "chilled", "duration": 1.5}
	return {}

func _projectile_readability_payload(attack_id: String = "") -> Dictionary:
	var variant_id := str(get_meta("enemy_id", ""))
	if variant_id == "":
		variant_id = kind
	return {
		"variant": variant_id,
		"attack": attack_id,
		"attack_label": _attack_label(attack_id),
		"color": _enemy_projectile_color(attack_id),
	}

func _default_projectile_attack_id() -> String:
	var enemy_id := str(get_meta("enemy_id", ""))
	var profile: Dictionary = PROJECTILE_PROFILES.get(enemy_id, {})
	if not profile.is_empty():
		return str(profile.get("attack", "projectile"))
	match enemy_id:
		"web_spider":
			return "web_shot"
		"quartz_shaman":
			return "crystal_volley"
	match kind:
		"caster":
			return "caster_bolt"
		"ranged":
			return "ranged_shot"
	return "projectile"

func _tag_projectile_readability(
		projectile: EnemyProjectile,
		attack_id: String,
		readability: Dictionary,
) -> void:
	projectile.set_meta("enemy_attack", attack_id)
	projectile.set_meta("enemy_attack_label", str(readability.get("attack_label", "")))
	projectile.set_meta("enemy_kind", kind)
	projectile.set_meta("enemy_id", str(get_meta("enemy_id", "")))

func _enemy_projectile_color(attack_id: String) -> Color:
	var profile := _projectile_profile_for_attack(attack_id)
	if not profile.is_empty():
		return profile.get("color", Color(1.0, 0.45, 0.35))
	match attack_id:
		"web_shot":
			return Color(0.66, 0.9, 1.0)
		"crystal_volley":
			return Color(0.72, 0.88, 1.0)
		"caster_bolt":
			return Color(0.78, 0.58, 1.0)
		"ranged_shot":
			return Color(1.0, 0.68, 0.36)
	return Color(1.0, 0.45, 0.35)

func _attack_label(attack_id: String) -> String:
	match attack_id:
		"spore_shot", "spore_bolt":
			return "SPORE"
		"slag_shot":
			return "SLAG"
		"ember_bolt":
			return "EMBER"
		"archive_bolt":
			return "ARCHIVE"
		"mirror_hex":
			return "MIRROR"
		"hot_charge":
			return "HOT CHARGE"
		"lance_charge":
			return "LANCE"
		"spore_bloom":
			return "SPORE"
		"forge_blast":
			return "BLAST"
		"glass_burst":
			return "GLASS"
		"web_shot":
			return "WEB"
		"crystal_volley":
			return "VOLLEY"
		"caster_bolt":
			return "CAST"
		"ranged_shot":
			return "SHOT"
		"charge":
			return "CHARGE"
		"explode":
			return "EXPLODE"
		"ambush":
			return "AMBUSH"
		"blink":
			return "BLINK"
		"poison_bloom":
			return "POISON"
		"forge_charge":
			return "CHARGE"
	return attack_id.replace("_", " ").to_upper()

func _projectile_profile_for_attack(attack_id: String) -> Dictionary:
	for profile in PROJECTILE_PROFILES.values():
		if str(profile.get("attack", "")) == attack_id:
			return profile
	return {}

func _telegraph_profile(default_attack: String, default_label: String) -> Dictionary:
	var profile: Dictionary = TELEGRAPH_PROFILES.get(str(get_meta("enemy_id", "")), {})
	if profile.is_empty():
		return {
			"attack": default_attack,
			"label": default_label,
			"color": Color(1.0, 0.24, 0.18, 0.6),
		}
	return profile


# --- Damage + elemental statuses -------------------------------------------

## Damage plus element application in one call (used by player weapons/skills).
func hit(amount: int, element: String = "") -> void:
	take_damage(_affinity_damage(amount, element))
	if element != "" and hp > 0:
		apply_element(element)

func hit_from(amount: int, element: String, hit_origin: Vector2) -> void:
	take_damage(_family_directional_damage(_affinity_damage(amount, element), hit_origin))
	if element != "" and hp > 0:
		apply_element(element)

func _family_directional_damage(amount: int, hit_origin: Vector2) -> int:
	if str(get_meta("enemy_id", "")) != "cave_crab":
		return amount
	var front_dir := Vector2.RIGHT
	if target != null and is_instance_valid(target):
		front_dir = (target.global_position - global_position).normalized()
	elif velocity.length_squared() > 1.0:
		front_dir = velocity.normalized()
	var hit_dir := (hit_origin - global_position).normalized()
	if front_dir.length_squared() <= 0.0 or hit_dir.length_squared() <= 0.0:
		return amount
	if front_dir.dot(hit_dir) < 0.35:
		return amount
	var reduced := maxi(1, ceili(float(amount) * 0.45))
	set_meta("front_shell_blocked",
		int(get_meta("front_shell_blocked", 0)) + maxi(amount - reduced, 0))
	return reduced

func _affinity_damage(amount: int, element: String) -> int:
	_last_hit_effectiveness = "normal"
	_last_hit_element = element
	set_meta("last_hit_effectiveness", _last_hit_effectiveness)
	set_meta("last_hit_element", _last_hit_element)
	if element == "":
		_affinity_feedback_pending = true
		return amount
	var value := float(amount)
	_affinity_feedback_pending = true
	if weak_elements.has(element):
		value *= 1.5
		_last_hit_effectiveness = "weak"
	if resist_elements.has(element):
		value *= 0.65
		_last_hit_effectiveness = "resist"
	set_meta("last_hit_effectiveness", _last_hit_effectiveness)
	set_meta("last_hit_element", _last_hit_element)
	return maxi(1, int(round(value)))


func take_damage(amount: int) -> void:
	if not _affinity_feedback_pending:
		_last_hit_effectiveness = "normal"
		_last_hit_element = ""
	if not has_meta("last_hit_effectiveness") or not _affinity_feedback_pending:
		set_meta("last_hit_effectiveness", _last_hit_effectiveness)
		set_meta("last_hit_element", _last_hit_element)
	_last_hit_critical = bool(get_meta("incoming_critical", false))
	set_meta("last_hit_critical", _last_hit_critical)
	set_meta("incoming_critical", false)
	if _statuses.has("vulnerable"):  # Plasma combo
		amount = ceili(amount * 1.25)
	amount = _apply_elite_incoming_damage(amount)
	hp -= amount
	_show_hit_feedback(amount)
	modulate = Color(1.0, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(self, "modulate", _current_tint(), 0.15)
	if hp <= 0:
		play_sprite_action("death", 0.35)
		_die()
	else:
		play_sprite_action("hurt", 0.18)
		_try_berserk_enrage()
		_try_family_enrage()

func _apply_elite_incoming_damage(amount: int) -> int:
	if str(get_meta("elite_modifier", "")) != "shielded":
		return amount
	var reduced := maxi(1, ceili(float(amount) * 0.5))
	set_meta("shielded_absorbed",
		int(get_meta("shielded_absorbed", 0)) + maxi(amount - reduced, 0))
	return reduced

func _try_berserk_enrage() -> void:
	if str(get_meta("elite_modifier", "")) != "berserk":
		return
	if bool(get_meta("elite_enraged", false)):
		return
	if hp > int(ceil(float(max_hp) * 0.5)):
		return
	set_meta("elite_enraged", true)
	speed *= 1.3
	contact_damage += maxi(1, ceili(float(contact_damage) * 0.25))
	base_tint *= Color(1.35, 0.55, 0.45)
	modulate = _current_tint()
	show_elite_enrage_warning()
	CombatFxScript.spawn_skill_cast(_fx_parent(), global_position, "berserk")

func _try_family_enrage() -> void:
	var id := str(get_meta("enemy_id", ""))
	if not ["beast_herder", "spore_matriarch", "forge_captain", "archive_curator"].has(id):
		return
	if bool(get_meta("family_enraged", false)):
		return
	if hp > int(ceil(float(max_hp) * 0.5)):
		return
	set_meta("family_enraged", true)
	match id:
		"spore_matriarch":
			_enrage_spore_matriarch()
		"forge_captain":
			_enrage_forge_captain()
		"archive_curator":
			_enrage_archive_curator()
		_:
			_enrage_beast_herder()

func _enrage_beast_herder() -> void:
	speed *= 1.25
	contact_damage += maxi(1, ceili(float(contact_damage) * 0.25))
	base_tint *= Color(1.25, 0.72, 0.45)
	modulate = _current_tint()
	_buff_beast_herder_minions()
	show_family_warning(family_warning_text(true))
	CombatFxScript.spawn_skill_cast(_fx_parent(), global_position, "beast_herder")

func _enrage_spore_matriarch() -> void:
	set_meta("spore_matriarch_bloomed", true)
	speed *= 1.12
	contact_damage += maxi(1, ceili(float(contact_damage) * 0.18))
	base_tint *= Color(0.72, 1.25, 0.72)
	modulate = _current_tint()
	if target != null and is_instance_valid(target) \
			and global_position.distance_to(target.global_position) <= 72.0:
		_apply_target_status("poisoned", 2.8)
	_show_telegraph_fx(Vector2.RIGHT, 52.0, 0.22, "poison_bloom", "POISON",
		Color(0.48, 1.0, 0.38, 0.62))
	show_family_warning(family_warning_text(true))
	CombatFxScript.spawn_skill_cast(_fx_parent(), global_position, "sacrifice")

func _enrage_forge_captain() -> void:
	set_meta("forge_captain_commanded", true)
	speed *= 1.2
	contact_damage += maxi(1, ceili(float(contact_damage) * 0.25))
	base_tint *= Color(1.35, 0.78, 0.45)
	modulate = _current_tint()
	_buff_forge_captain_guards()
	var dir := Vector2.RIGHT
	if target != null and is_instance_valid(target):
		dir = (target.global_position - global_position).normalized()
	_show_telegraph_fx(dir, 48.0, 0.28, "forge_charge", "CHARGE",
		Color(1.0, 0.42, 0.2, 0.62))
	show_family_warning(family_warning_text(true))
	CombatFxScript.spawn_skill_cast(_fx_parent(), global_position, "battle_roar")

func _enrage_archive_curator() -> void:
	set_meta("archive_curator_lattice", true)
	speed *= 1.14
	contact_damage += maxi(1, ceili(float(contact_damage) * 0.2))
	base_tint *= Color(0.72, 0.92, 1.3)
	modulate = _current_tint()
	if target != null and is_instance_valid(target) \
			and global_position.distance_to(target.global_position) <= 80.0:
		_apply_target_status("chilled", 1.8)
	var dir := Vector2.RIGHT
	if target != null and is_instance_valid(target):
		dir = (target.global_position - global_position).normalized()
	_show_telegraph_fx(dir, 56.0, 0.26, "archive_lattice", "LATTICE",
		Color(0.55, 0.88, 1.0, 0.62))
	show_family_warning(family_warning_text(true))
	CombatFxScript.spawn_skill_cast(_fx_parent(), global_position, "null_ring")

func family_pattern() -> String:
	match str(get_meta("enemy_id", "")):
		"beast_herder":
			return "summon_enrage"
		"spore_matriarch":
			return "summon_poison_enrage"
		"forge_captain":
			return "buff_charge"
		"archive_curator":
			return "summon_chill_lattice"
	return "standard"

func family_warning_text(enrage: bool = false) -> String:
	match str(get_meta("enemy_id", "")):
		"beast_herder":
			return "ENRAGE + BUFF" if enrage else "SUMMON PACK"
		"spore_matriarch":
			return "POISON BLOOM" if enrage else "SPORE SWARM"
		"forge_captain":
			return "CHARGE + BUFF" if enrage else "GUARDS UP"
		"archive_curator":
			return "CHILL LATTICE" if enrage else "ARCHIVE CONSTRUCTS"
	return ""

func show_family_warning(text: String = "") -> void:
	var warning_text := text if text != "" else family_warning_text(false)
	if warning_text == "":
		return
	var label := find_child("FamilyWarning", true, false) as Label
	if label == null:
		label = Label.new()
		label.name = "FamilyWarning"
		label.position = Vector2(-42, -36)
		label.z_index = 20
		label.add_theme_font_size_override("font_size", 9)
		add_child(label)
	label.text = warning_text
	label.modulate = Color(1.0, 0.82, 0.34)
	if is_inside_tree():
		var tween := create_tween()
		tween.tween_property(label, "position", Vector2(-42, -42), 0.16)
		tween.parallel().tween_property(label, "modulate:a", 0.55, 0.45).set_delay(0.16)

func show_elite_modifier_label(modifier: String = "") -> void:
	var id := modifier if modifier != "" else str(get_meta("elite_modifier", ""))
	if id == "":
		return
	var text := "Elite: %s" % id.replace("_", " ").capitalize()
	set_meta("elite_modifier_label", text)
	var label := find_child("EliteModifierLabel", true, false) as Label
	if label == null:
		label = Label.new()
		label.name = "EliteModifierLabel"
		label.position = Vector2(-34, -28)
		label.z_index = 19
		label.add_theme_font_size_override("font_size", 8)
		add_child(label)
	label.text = text
	label.modulate = Color(1.0, 0.86, 0.36, 0.88)

func show_elite_enrage_warning(text: String = "ENRAGE: SPEED + DAMAGE") -> void:
	set_meta("elite_enrage_warning", text)
	var label := find_child("EliteEnrageWarning", true, false) as Label
	if label == null:
		label = Label.new()
		label.name = "EliteEnrageWarning"
		label.position = Vector2(-44, -42)
		label.z_index = 21
		label.add_theme_font_size_override("font_size", 9)
		add_child(label)
	label.text = text
	label.modulate = Color(1.0, 0.42, 0.26, 0.95)
	if is_inside_tree():
		var tween := create_tween()
		tween.tween_property(label, "position", Vector2(-44, -48), 0.16)
		tween.parallel().tween_property(label, "modulate:a", 0.7, 0.45).set_delay(0.16)

func _buff_beast_herder_minions() -> void:
	_buff_family_minions("beast_herder", "beast_herder_buffed",
		Color(1.2, 0.9, 0.55), 1.25, 0.3)

func _buff_forge_captain_guards() -> void:
	_buff_family_minions("forge_captain", "forge_captain_buffed",
		Color(1.22, 0.78, 0.48), 1.22, 0.25)

func _buff_family_minions(
		source: String,
		flag: String,
		tint: Color,
		speed_mult: float,
		damage_mult: float,
) -> void:
	var parent := get_parent()
	if parent == null:
		return
	for child in parent.get_children():
		var minion := child as Enemy
		if minion == null or minion == self:
			continue
		if str(minion.get_meta("family_minion", "")) != source:
			continue
		if bool(minion.get_meta(flag, false)):
			continue
		if global_position.distance_to(minion.global_position) > 140.0:
			continue
		minion.set_meta(flag, true)
		minion.speed *= speed_mult
		minion.contact_damage += maxi(1, ceili(float(minion.contact_damage) * damage_mult))
		minion.base_tint *= tint
		minion.modulate = minion._current_tint()


## Applies an element. If a DIFFERENT element status is already present,
## it is consumed and the matching combo triggers instead.
func apply_element(element: String) -> void:
	for existing in _statuses.keys():
		if existing != element and ElementSystem.is_element(existing):
			_statuses.erase(existing)
			ElementSystem.trigger_combo(self, existing, element)
			modulate = _current_tint()
			_refresh_status_badges()
			return
	_statuses[element] = ElementSystem.status_duration(element)
	if element == "lightning":  # shock: short stun, longer combo window
		add_status("stun", 0.3)
	modulate = _current_tint()
	_spawn_status_feedback(element)
	_refresh_status_badges()


func add_status(status_name: String, duration: float) -> void:
	_statuses[status_name] = maxf(duration, float(_statuses.get(status_name, 0.0)))
	modulate = _current_tint()
	_spawn_status_feedback(status_name)
	_refresh_status_badges()

func has_status(status_name: String) -> bool:
	return _statuses.has(status_name)

## Ticks status timers and DoTs. Returns false while the enemy cannot act.
func _tick_statuses(delta: float) -> bool:
	var expired: Array = []
	for status_name in _statuses.keys():
		_statuses[status_name] -= delta
		if _statuses[status_name] <= 0.0:
			expired.append(status_name)
	for status_name in expired:
		_statuses.erase(status_name)
		_spawn_status_feedback(str(status_name), " ended")
	if not expired.is_empty():
		modulate = _current_tint()
	_refresh_status_badges()

	_dot_tick += delta
	if _dot_tick >= DOT_INTERVAL:
		_dot_tick -= DOT_INTERVAL
		var dot := 0
		if _statuses.has("fire"):
			dot += 2  # burn: ~4 dmg/s
		if _statuses.has("poison"):
			dot += maxi(1, int(max_hp * 0.01))  # ~2% maxHP/s
		if dot > 0:
			_dot_damage(dot)
	return not (_statuses.has("frozen") or _statuses.has("stun") or _statuses.has("rooted"))


func _dot_damage(amount: int) -> void:
	_last_hit_effectiveness = "normal"
	_last_hit_critical = false
	_last_hit_element = "dot"
	set_meta("last_hit_effectiveness", _last_hit_effectiveness)
	set_meta("last_hit_critical", _last_hit_critical)
	set_meta("last_hit_element", _last_hit_element)
	hp -= amount
	_show_hit_feedback(amount)
	if hp <= 0:
		_die()


func _show_hit_feedback(amount: int) -> void:
	_last_hit_damage_amount = amount
	_update_hp_bar()
	_spawn_damage_number(amount)
	_spawn_hit_spark(amount)
	_play_hit_sfx(amount)


func _update_hp_bar() -> void:
	if _hp_bar == null or not is_instance_valid(_hp_bar):
		_hp_bar = Node2D.new()
		_hp_bar.name = "HpBar"
		_hp_bar.position = Vector2(-10, -18)
		add_child(_hp_bar)
		var bg := ColorRect.new()
		bg.name = "Background"
		bg.position = Vector2.ZERO
		bg.size = Vector2(20, 3)
		bg.color = Color(0.02, 0.02, 0.02, 0.8)
		_hp_bar.add_child(bg)
		_hp_fill = ColorRect.new()
		_hp_fill.name = "Fill"
		_hp_fill.position = Vector2(1, 1)
		_hp_fill.size = Vector2(18, 1)
		_hp_fill.color = Color(0.9, 0.18, 0.14)
		_hp_bar.add_child(_hp_fill)
	if _hp_fill != null:
		var ratio := clampf(float(maxi(hp, 0)) / maxf(float(max_hp), 1.0), 0.0, 1.0)
		_hp_fill.size.x = 18.0 * ratio


func _spawn_damage_number(amount: int) -> void:
	var old := get_node_or_null("DamageNumber")
	if old != null:
		remove_child(old)
		old.queue_free()
	var label := Label.new()
	label.name = "DamageNumber"
	var prefix := "CRIT " if _last_hit_critical else ""
	var damage_kind := "critical" if _last_hit_critical else _last_hit_effectiveness
	match _last_hit_effectiveness:
		"weak":
			label.text = "%sWEAK %d" % [prefix, amount]
			label.modulate = Color(1.0, 0.64, 0.24)
			label.scale = Vector2(1.08, 1.08)
		"resist":
			label.text = "%sRESIST %d" % [prefix, amount]
			label.modulate = Color(0.62, 0.78, 1.0)
			label.scale = Vector2(0.9, 0.9)
		_:
			label.text = "%s%d" % [prefix, amount]
			label.modulate = Color(1.0, 0.82, 0.28)
			label.scale = Vector2.ONE
	if _last_hit_critical:
		label.scale = Vector2(1.18, 1.18)
	label.set_meta("damage_amount", amount)
	label.set_meta("damage_kind", damage_kind)
	label.set_meta("effectiveness", _last_hit_effectiveness)
	label.set_meta("critical", _last_hit_critical)
	label.set_meta("element", _last_hit_element)
	_affinity_feedback_pending = false
	label.position = Vector2(-8, -30)
	label.add_theme_font_size_override("font_size", 8)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -10), 0.35)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(label.queue_free)

func _spawn_hit_spark(amount: int) -> void:
	var hit_kind := "critical" if _last_hit_critical else _last_hit_effectiveness
	if not ["critical", "normal", "resist", "weak"].has(hit_kind):
		hit_kind = "normal"
	CombatFxScript.spawn_hit_spark(self, global_position, hit_kind, _last_hit_element, amount)

func _play_hit_sfx(amount: int) -> void:
	var hit_kind := "critical" if _last_hit_critical else _last_hit_effectiveness
	if not ["critical", "normal", "resist", "weak"].has(hit_kind):
		hit_kind = "normal"
	var cue: Dictionary = AudioCueDBScript.enemy_hit_cue(hit_kind, _last_hit_element, amount)
	var sfx := get_node_or_null("EnemyHitSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "EnemyHitSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("enemy_hit_sound_id", str(cue.get("id", "enemy_hit_normal")))
	sfx.set_meta("enemy_hit_kind", str(cue.get("hit_kind", hit_kind)))
	sfx.set_meta("enemy_hit_element", str(cue.get("element", _last_hit_element)))
	sfx.set_meta("enemy_hit_amount", int(cue.get("damage_amount", amount)))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "enemy_hit")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "enemy_hit")))
	sfx.set_meta("enemy_hit_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_enemy_sfx_playback(sfx)

func _request_enemy_sfx_playback(sfx: AudioStreamPlayer) -> void:
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _spawn_heal_number(amount: int) -> void:
	var old := get_node_or_null("HealNumber")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "HealNumber"
	label.text = "+" + str(amount)
	label.position = Vector2(-8, -36)
	label.add_theme_font_size_override("font_size", 8)
	label.modulate = Color(0.45, 1.0, 0.62)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -9), 0.35)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(label.queue_free)

func _refresh_status_badges() -> void:
	var statuses: Array[String] = []
	for status_name in _statuses.keys():
		statuses.append(str(status_name))
	statuses.sort()
	var stack := get_node_or_null("EnemyStatusStack") as Node2D
	if statuses.is_empty():
		if stack != null:
			stack.set_meta("status_count", 0)
			stack.set_meta("active_statuses", "")
			stack.queue_free()
		return
	if stack == null:
		stack = Node2D.new()
		stack.name = "EnemyStatusStack"
		stack.position = Vector2(-18, -30)
		stack.z_index = 18
		add_child(stack)
	for child in stack.get_children():
		stack.remove_child(child)
		child.queue_free()
	stack.set_meta("status_count", statuses.size())
	stack.set_meta("active_statuses", ",".join(statuses))
	for i in statuses.size():
		var status_name := statuses[i]
		var badge := Label.new()
		badge.name = "StatusBadge%d" % i
		badge.text = "%s %.1f" % [_readable_status_name(status_name), float(_statuses.get(status_name, 0.0))]
		badge.position = Vector2(0.0, -9.0 * i)
		badge.z_index = 18
		badge.add_theme_font_size_override("font_size", 7)
		badge.modulate = _status_feedback_color(status_name)
		badge.set_meta("status_id", status_name)
		badge.set_meta("status_seconds_left", float(_statuses.get(status_name, 0.0)))
		badge.set_meta("status_color_role", status_name)
		stack.add_child(badge)

func _spawn_status_feedback(status_name: String, suffix: String = "") -> void:
	var old := get_node_or_null("EnemyStatusFeedback")
	if old != null:
		remove_child(old)
		old.queue_free()
	var label := Label.new()
	label.name = "EnemyStatusFeedback"
	label.text = _readable_status_name(status_name) + suffix
	label.position = Vector2(-14, -40)
	label.add_theme_font_size_override("font_size", 8)
	label.modulate = _status_feedback_color(status_name)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -9), 0.35)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(label.queue_free)

func show_combo_feedback(info: Dictionary) -> void:
	if info.is_empty():
		return
	var combo_id := str(info.get("id", ""))
	var combo_name := str(info.get("name", combo_id))
	var combo_effect := str(info.get("effect", ""))
	var combo_elements := _combo_elements_text(info)
	set_meta("last_combo_id", combo_id)
	set_meta("last_combo_name", combo_name)
	set_meta("last_combo_elements", combo_elements)
	set_meta("last_combo_effect", combo_effect)
	element_combo_triggered.emit(info.duplicate(true))
	var old := get_node_or_null("EnemyComboFeedback")
	if old != null:
		remove_child(old)
		old.queue_free()
	var label := Label.new()
	label.name = "EnemyComboFeedback"
	label.text = combo_name if combo_effect == "" else "%s | %s" % [combo_name, combo_effect]
	label.position = Vector2(-28, -52)
	label.z_index = 22
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", _combo_feedback_color(combo_id))
	label.set_meta("combo_id", combo_id)
	label.set_meta("combo_name", combo_name)
	label.set_meta("combo_elements", combo_elements)
	label.set_meta("combo_effect", combo_effect)
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -12), 0.48)
	tween.tween_property(label, "modulate:a", 0.0, 0.48)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))
	_play_combo_sfx(info)

func _play_combo_sfx(info: Dictionary) -> void:
	var old := get_node_or_null("EnemyComboSfx")
	if old != null:
		old.queue_free()
	var combo_id := str(info.get("id", ""))
	var combo_name := str(info.get("name", combo_id))
	var cue: Dictionary = AudioCueDBScript.element_combo_cue(combo_id)
	var sfx := AudioStreamPlayer.new()
	sfx.name = "EnemyComboSfx"
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("combo_id", combo_id)
	sfx.set_meta("combo_name", combo_name)
	sfx.set_meta("combo_sound_id", str(cue.get("id", "element_combo_generic")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "element_combo")))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("combo_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("playback_requested", true)
	add_child(sfx)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _combo_elements_text(info: Dictionary) -> String:
	var parts: Array[String] = []
	for element in info.get("elements", []):
		parts.append(str(element))
	return "+".join(parts)

func _combo_feedback_color(combo_id: String) -> Color:
	match combo_id:
		"thermal_shock":
			return Color(0.78, 0.95, 1.0)
		"plasma":
			return Color(1.0, 0.58, 1.0)
		"burning_smog":
			return Color(0.82, 1.0, 0.42)
		"deep_freeze":
			return Color(0.52, 0.88, 1.0)
		"frostbane":
			return Color(0.62, 1.0, 0.58)
		"toxic_current":
			return Color(0.78, 1.0, 0.32)
	return Color(1.0, 0.9, 0.55)

func _readable_status_name(status_name: String) -> String:
	return status_name.replace("_", " ").capitalize()

func _status_feedback_color(status_name: String) -> Color:
	match status_name:
		"fire", "burning":
			return Color(1.0, 0.46, 0.22)
		"ice", "frozen", "chilled":
			return Color(0.55, 0.86, 1.0)
		"poison", "poisoned":
			return Color(0.54, 1.0, 0.38)
		"lightning", "stun":
			return Color(1.0, 0.92, 0.35)
		"rooted":
			return Color(0.6, 0.9, 0.5)
		"vulnerable", "cursed":
			return Color(1.0, 0.58, 1.0)
		_:
			return Color(1.0, 0.9, 0.64)


func _die() -> void:
	if _dying:
		return
	_dying = true
	_hit_pause(0.04, 0.9)
	_show_death_feedback()
	_play_death_sfx()
	died.emit(self)
	remove_from_group("enemies")
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		collision.set_deferred("disabled", true)
	if _sprite != null and _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation("death"):
		set_meta("death_animation_hold_active", true)
		set_meta("death_animation_hold_seconds", 0.28)
		await get_tree().create_timer(0.28, true, false, true).timeout
	queue_free()

func _hit_pause(seconds: float, scale_value: float) -> void:
	set_meta("hit_pause_feedback", true)
	if not is_inside_tree():
		return
	Engine.time_scale = minf(Engine.time_scale, scale_value)
	get_tree().create_timer(seconds, true, false, true).timeout.connect(func() -> void:
		Engine.time_scale = 1.0)

func _show_death_feedback() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var old := parent.get_node_or_null("EnemyDeathFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "EnemyDeathFeedback"
	label.text = "Down"
	label.global_position = global_position + Vector2(-14, -22)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.32))
	parent.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -12), 0.42)
	tween.tween_property(label, "modulate:a", 0.0, 0.42)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _play_death_sfx() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var hit_kind := "critical" if _last_hit_critical else _last_hit_effectiveness
	if not ["critical", "normal", "resist", "weak"].has(hit_kind):
		hit_kind = "normal"
	var cue: Dictionary = AudioCueDBScript.enemy_death_cue(
		hit_kind,
		_last_hit_element,
		_last_hit_damage_amount,
		str(get_meta("enemy_id", "")))
	var sfx := parent.get_node_or_null("EnemyDeathSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "EnemyDeathSfx"
		parent.add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("enemy_death_sound_id", str(cue.get("id", "enemy_death")))
	sfx.set_meta("enemy_death_hit_kind", str(cue.get("hit_kind", hit_kind)))
	sfx.set_meta("enemy_death_element", str(cue.get("element", _last_hit_element)))
	sfx.set_meta("enemy_death_damage_amount", int(cue.get("damage_amount", _last_hit_damage_amount)))
	sfx.set_meta("enemy_id", str(cue.get("enemy_id", "")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_family", str(cue.get("family", "enemy_death")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "enemy_death")))
	sfx.set_meta("enemy_death_sound_frequency", float(cue.get("frequency", 0.0)))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	_request_enemy_sfx_playback(sfx)

func _speed_mult() -> float:
	if _statuses.has("frostbane"):
		return 0.4
	if _statuses.has("ice"):
		return 0.6
	return 1.0


func _current_tint() -> Color:
	if _statuses.has("frozen"):
		return base_tint * Color(0.5, 0.8, 1.4)
	if _statuses.has("fire"):
		return base_tint * Color(1.4, 0.8, 0.5)
	if _statuses.has("poison"):
		return base_tint * Color(0.6, 1.3, 0.6)
	if _statuses.has("ice"):
		return base_tint * Color(0.7, 0.9, 1.3)
	if _statuses.has("lightning"):
		return base_tint * Color(1.3, 1.3, 0.6)
	if _statuses.has("vulnerable"):
		return base_tint * Color(1.2, 0.7, 1.2)
	return base_tint


func _blink(color: Color) -> void:
	modulate = color if fmod(_time, 0.2) < 0.1 else _current_tint()


func _show_telegraph_fx(
		dir: Vector2,
		radius: float,
		duration: float,
		attack_id: String = "",
		label_text: String = "",
		color: Color = Color(1.0, 0.24, 0.18, 0.6),
) -> void:
	_spawn_attack_telegraph_at(global_position, dir, radius, duration, attack_id, label_text, color)

func _spawn_attack_telegraph_at(
		origin: Vector2,
		dir: Vector2,
		radius: float,
		duration: float,
		attack_id: String,
		label_text: String = "",
		color: Color = Color(1.0, 0.24, 0.18, 0.6),
) -> Node2D:
	var safe_dir := dir if dir.length_squared() > 0.0 else Vector2.RIGHT
	var fx := CombatFxScript.spawn_telegraph(_fx_parent(), origin, safe_dir, radius, duration, color)
	_tag_attack_fx(fx, attack_id, label_text, radius, color)
	return fx

func _tag_attack_fx(
		fx: Node2D,
		attack_id: String,
		label_text: String,
		radius: float,
		color: Color,
) -> void:
	if attack_id != "":
		fx.set_meta("enemy_attack", attack_id)
		fx.set_meta("enemy_attack_label", _attack_label(attack_id))
	fx.set_meta("enemy_kind", kind)
	var id := str(get_meta("enemy_id", ""))
	if id != "":
		fx.set_meta("enemy_id", id)
	var text := label_text if label_text != "" else _attack_label(attack_id)
	if text == "":
		return
	var label := fx.get_node_or_null("AttackCueLabel") as Label
	if label == null:
		label = Label.new()
		label.name = "AttackCueLabel"
		label.z_index = 30
		label.add_theme_font_size_override("font_size", 8)
		fx.add_child(label)
	label.text = text
	label.position = Vector2(-maxf(18.0, float(text.length()) * 3.0), -radius - 12.0)
	label.modulate = Color(color.r, color.g, color.b, 0.95)

func _projectile_parent() -> Node:
	var tree := get_tree()
	if tree == null:
		return self
	if tree.current_scene != null:
		return tree.current_scene
	if get_parent() != null:
		return get_parent()
	return tree.root


func _fx_parent() -> Node:
	if get_parent() != null:
		return get_parent()
	var tree := get_tree()
	if tree == null:
		return self
	return tree.current_scene if tree.current_scene != null else tree.root
