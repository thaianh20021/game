class_name Weapon
extends Node2D
## Equipped weapon behavior driven by data/weapons.json stats.
## Stat conversion (1-10 scale -> gameplay values):
##   base damage = dmg * 3, then scaled by the player's class damage_mult
##   and crit roll (x1.5)
##   cooldown = 1.2 - speed * 0.09 (floor 0.15s)
##   melee reach = 14 + range * 6 px; projectile range = range * 24 px
## Hits apply weapon innate element first, else the player's equipped element.
## Weapons with mana_cost spend player resource before firing.

const MELEE_GROUPS := ["sword_1h", "axe", "dagger", "hammer", "spear", "shield"]
const MAGIC_GROUPS := ["staff", "orb", "tome"]
const PROJECTILE_SPEED := 220.0
const ACTIVE_RELOAD_WINDOW_RATIO := 0.35
const ACTIVE_RELOAD_DAMAGE_MULT := 1.1
const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")
const AudioCueDBScript := preload("res://scripts/audio/audio_cue_db.gd")

var data: Dictionary = {}

var _cd_left := 0.0
var _last_roll_critical := false
var _melee_hit_count := 0
var _ranged_attack_count := 0
var _attack_speed_bonus := 0.0
var _charged_projectile_pierce_bonus := 0
var _charged_damage_mult := 1.0
var _charged_cleave_width_mult := 1.0
var _last_stationary_bonus_active := false


func equip(id: String) -> void:
	data = WeaponDB.get_weapon(id)
	assert(not data.is_empty(), "Weapon.equip: unknown weapon id " + id)


func display_name() -> String:
	return str(data.get("name", "?"))


func base_damage() -> int:
	return int(data.get("dmg", 1)) * 3


func cooldown() -> float:
	var value := maxf(1.2 - float(data.get("speed", 5)) * 0.09, 0.15)
	var player := _player()
	if player != null and player.has_method("weapon_cooldown_multiplier"):
		value *= float(player.call("weapon_cooldown_multiplier"))
	if _attack_speed_bonus > 0.0:
		value /= 1.0 + _attack_speed_bonus
	return value

func cooldown_left() -> float:
	return _cd_left


func is_melee() -> bool:
	return MELEE_GROUPS.has(str(data.get("group", "")))


func melee_reach() -> float:
	return 14.0 + float(data.get("range", 2)) * 6.0


func projectile_range() -> float:
	return float(data.get("range", 6)) * 24.0


func resource_cost() -> float:
	return float(data.get("mana_cost", 0.0))


func homing_strength() -> float:
	return float(data.get("homing", 0.0))


func chain_count() -> int:
	return maxi(int(data.get("chain_count", 0)), 0)


func chain_radius() -> float:
	return float(data.get("chain_radius", 0.0))


func chain_damage_mult() -> float:
	return maxf(float(data.get("chain_damage_mult", 0.0)), 0.0)


func split_count() -> int:
	return maxi(int(data.get("split_count", 0)), 0)


func split_angle_deg() -> float:
	return float(data.get("split_angle_deg", 0.0))


func split_damage_mult() -> float:
	return maxf(float(data.get("split_damage_mult", 0.0)), 0.0)


func fire_patch_damage() -> int:
	return maxi(int(data.get("fire_patch_damage", 0)), 0)


func fire_patch_radius() -> float:
	return float(data.get("fire_patch_radius", 0.0))


func fire_patch_duration() -> float:
	return float(data.get("fire_patch_duration", 0.0))


func fire_patch_tick() -> float:
	return float(data.get("fire_patch_tick", 0.0))


func prop_damage_mult() -> float:
	return maxf(float(data.get("prop_damage_mult", 1.0)), 0.0)


func backstab_damage_mult() -> float:
	return maxf(float(data.get("backstab_damage_mult", 1.0)), 1.0)


func combo_knockback_every() -> int:
	return maxi(int(data.get("combo_knockback_every", 0)), 0)


func knockback_distance() -> float:
	return maxf(float(data.get("knockback_distance", 0.0)), 0.0)


func line_pierce_range() -> float:
	return maxf(float(data.get("line_pierce_range", 0.0)), 0.0)


func line_pierce_width() -> float:
	return maxf(float(data.get("line_pierce_width", 0.0)), 0.0)


func stun_chance() -> float:
	return clampf(float(data.get("stun_chance", 0.0)), 0.0, 1.0)


func stun_duration() -> float:
	return maxf(float(data.get("stun_duration", 0.0)), 0.0)


func attack_speed_ramp_per_hit() -> float:
	return maxf(float(data.get("attack_speed_ramp_per_hit", 0.0)), 0.0)


func attack_speed_ramp_max() -> float:
	return maxf(float(data.get("attack_speed_ramp_max", 0.0)), 0.0)


func magazine_size() -> int:
	return maxi(int(data.get("magazine_size", 0)), 0)


func last_round_damage_mult() -> float:
	return maxf(float(data.get("last_round_damage_mult", 1.0)), 1.0)

func active_reload_window_status() -> Dictionary:
	var total := cooldown()
	var window := total * ACTIVE_RELOAD_WINDOW_RATIO
	var enabled := magazine_size() > 0 and not is_melee()
	return {
		"enabled": enabled,
		"in_window": enabled and _cd_left > 0.0 and _cd_left <= window,
		"cooldown_left": _cd_left,
		"cooldown_total": total,
		"window_seconds": window,
		"damage_mult": ACTIVE_RELOAD_DAMAGE_MULT,
	}

func try_active_reload() -> bool:
	var player := _player()
	if player == null or str(player.class_id) != "gunner":
		set_meta("active_reload_failed_reason", "class")
		return false
	var status := active_reload_window_status()
	if not bool(status.get("enabled", false)):
		set_meta("active_reload_failed_reason", "weapon")
		return false
	if not bool(status.get("in_window", false)):
		set_meta("active_reload_failed_reason", "timing")
		return false
	_cd_left = 0.0
	_ranged_attack_count = 0
	set_meta("active_reload_rounds_left", magazine_size())
	set_meta("active_reload_damage_mult", ACTIVE_RELOAD_DAMAGE_MULT)
	set_meta("active_reload_successes", int(get_meta("active_reload_successes", 0)) + 1)
	set_meta("active_reload_failed_reason", "")
	player.set_meta("active_reload_ready", true)
	player.set_meta("active_reload_weapon", str(data.get("id", "")))
	player.set_meta("active_reload_rounds_left", magazine_size())
	_show_active_reload_feedback(player)
	return true

func charge_time_full() -> float:
	return maxf(float(data.get("full_charge_time", 0.0)), 0.0)

func full_charge_pierce_bonus() -> int:
	return maxi(int(data.get("full_charge_pierce_bonus", 0)), 0)

func uses_charge_attack() -> bool:
	return charge_time_full() > 0.0

func stationary_damage_mult() -> float:
	return maxf(float(data.get("stationary_damage_mult", 1.0)), 1.0)

func stationary_speed_threshold() -> float:
	return maxf(float(data.get("stationary_speed_threshold", 1.0)), 0.0)

func front_block_damage_mult() -> float:
	return clampf(float(data.get("front_block_damage_mult", 1.0)), 0.0, 1.0)

func front_block_dot_min() -> float:
	return clampf(float(data.get("front_block_dot_min", 0.0)), -1.0, 1.0)


func shadow_wave_every() -> int:
	return maxi(int(data.get("shadow_wave_every", 0)), 0)


func shadow_wave_damage_mult() -> float:
	return maxf(float(data.get("shadow_wave_damage_mult", 0.0)), 0.0)


func shadow_wave_range() -> float:
	return maxf(float(data.get("shadow_wave_range", 0.0)), 0.0)


func shadow_wave_pierce() -> int:
	return maxi(int(data.get("shadow_wave_pierce", 0)), 0)


func socket_capacity() -> int:
	return maxi(int(data.get("sockets", 0)), 0)

func projectile_count() -> int:
	var base_count := 1
	match str(data.get("group", "")):
		"bow", "crossbow":
			base_count = 3
		"orb":
			base_count = 2
	var player := _player()
	if player != null:
		base_count += player.projectile_bonus
	return maxi(base_count, 1)


func projectile_pierce_count() -> int:
	var group := str(data.get("group", ""))
	var player := _player()
	var pierce := _charged_projectile_pierce_bonus
	if player != null and int(player.get_meta("special_rounds_left", 0)) > 0:
		pierce += 1
	if player != null and player.has_method("has_passive") \
			and bool(player.call("has_passive", "piercer")) \
			and ["bow", "crossbow"].has(group):
		pierce += 1
	return pierce


func burst_count() -> int:
	var group := str(data.get("group", ""))
	if group == "pistol":
		return 2
	if not is_melee() and float(data.get("speed", 0)) >= 8.0:
		return 2
	return 1


func _process(delta: float) -> void:
	_cd_left = maxf(_cd_left - delta, 0.0)


func try_attack(origin: Vector2, aim: Vector2) -> bool:
	if data.is_empty():
		return false
	if _cd_left > 0.0:
		_notify_attack_blocked("cooldown", {
			"cooldown_left": _cd_left,
			"cooldown_total": cooldown(),
		})
		return false
	if not _can_pay_resource():
		_notify_attack_blocked("resource", _resource_block_detail())
		return false
	_pay_resource()
	_cd_left = cooldown()
	_play_weapon_attack_sfx()
	var player := _player()
	if player != null and player.has_method("play_sprite_action"):
		player.call("play_sprite_action", "attack", 0.18)
	if is_melee():
		CombatFxScript.spawn_slash(_fx_parent(), origin + aim * melee_reach() * 0.45, aim)
		_melee_hit(origin, aim)
	else:
		CombatFxScript.spawn_muzzle_flash(_fx_parent(), origin + aim * 10.0, aim)
		_fire_projectile_pattern(origin, aim)
	return true

func try_charged_attack(origin: Vector2, aim: Vector2, charge_seconds: float) -> bool:
	var full_time := charge_time_full()
	if full_time <= 0.0:
		return try_attack(origin, aim)
	var ratio := clampf(charge_seconds / full_time, 0.0, 1.0)
	_charged_projectile_pierce_bonus = full_charge_pierce_bonus() if ratio >= 1.0 else 0
	_apply_charged_player_passives(ratio)
	set_meta("last_charge_ratio", ratio)
	set_meta("last_full_charge", ratio >= 1.0)
	var fired := try_attack(origin, aim)
	if fired and ratio >= 1.0:
		CombatFxScript.spawn_weapon_charge(_fx_parent(), origin, ratio)
	_reset_charged_attack_modifiers()
	return fired

func _apply_charged_player_passives(ratio: float) -> void:
	_charged_damage_mult = 1.0
	_charged_cleave_width_mult = 1.0
	var player := _player()
	if player == null:
		return
	if player.has_method("charged_attack_damage_multiplier"):
		_charged_damage_mult = maxf(float(player.call("charged_attack_damage_multiplier", ratio)), 1.0)
	if player.has_method("charged_attack_cleave_width_multiplier"):
		_charged_cleave_width_mult = maxf(float(player.call("charged_attack_cleave_width_multiplier", ratio)), 1.0)
	if _charged_damage_mult > 1.0:
		set_meta("heavy_windup_damage_mult", _charged_damage_mult)
	if _charged_cleave_width_mult > 1.0:
		set_meta("heavy_windup_cleave_width_mult", _charged_cleave_width_mult)

func _reset_charged_attack_modifiers() -> void:
	_charged_projectile_pierce_bonus = 0
	_charged_damage_mult = 1.0
	_charged_cleave_width_mult = 1.0

func front_block_damage(
		amount: int,
		source_position: Vector2,
		owner_position: Vector2,
		facing_dir: Vector2,
) -> int:
	var mult := front_block_damage_mult()
	if mult >= 1.0 or amount <= 0:
		return amount
	if absf(source_position.x) > 9.0e19 or absf(source_position.y) > 9.0e19:
		return amount
	var to_source := source_position - owner_position
	if to_source.length_squared() <= 0.0:
		return amount
	var facing := facing_dir.normalized() if facing_dir.length_squared() > 0.0 else Vector2.RIGHT
	if facing.dot(to_source.normalized()) < front_block_dot_min():
		return amount
	var reduced := maxi(1, int(round(float(amount) * mult)))
	set_meta("front_blocks", int(get_meta("front_blocks", 0)) + 1)
	set_meta("front_blocked_damage", int(get_meta("front_blocked_damage", 0)) + amount - reduced)
	CombatFxScript.spawn_block_spark(_fx_parent(), owner_position + facing * 12.0, facing)
	return reduced


func _player() -> Player:
	return get_parent() as Player


func _can_pay_resource() -> bool:
	var cost := resource_cost()
	if cost <= 0.0:
		return true
	var player := _player()
	return player == null or player.resource >= cost


func _pay_resource() -> void:
	var cost := resource_cost()
	if cost <= 0.0:
		return
	var player := _player()
	if player == null:
		return
	player.resource = maxf(player.resource - cost, 0.0)
	player.resource_changed.emit(player.resource, player.max_resource)

func _resource_block_detail() -> Dictionary:
	var player := _player()
	return {
		"cost": resource_cost(),
		"resource": player.resource if player != null else 0.0,
		"max_resource": player.max_resource if player != null else 0.0,
		"resource_type": player.resource_type if player != null else "resource",
	}

func _show_active_reload_feedback(player: Player) -> void:
	var old := player.get_node_or_null("ActiveReloadFeedback")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "ActiveReloadFeedback"
	label.text = "ACTIVE RELOAD +10% MAG"
	label.position = Vector2(-32, -50)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.28))
	label.set_meta("active_reload_damage_mult", ACTIVE_RELOAD_DAMAGE_MULT)
	label.set_meta("active_reload_rounds", magazine_size())
	label.set_meta("active_reload_weapon_id", str(data.get("id", "")))
	label.set_meta("active_reload_weapon_name", display_name())
	player.add_child(label)
	if not player.is_inside_tree():
		return
	var tween := label.create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -10), 0.35)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(label.queue_free)

func _notify_attack_blocked(reason: String, detail: Dictionary) -> void:
	var player := _player()
	if player == null or not player.has_method("notify_weapon_attack_blocked"):
		return
	var payload := detail.duplicate(true)
	payload["weapon_name"] = display_name()
	payload["weapon_group"] = str(data.get("group", ""))
	player.call("notify_weapon_attack_blocked", data, reason, payload)


func _play_weapon_attack_sfx() -> void:
	var old := get_node_or_null("WeaponAttackSfx")
	if old != null:
		_release_weapon_attack_sfx(old)
	var cue: Dictionary = AudioCueDBScript.weapon_attack_cue(data)
	var sfx := AudioStreamPlayer.new()
	sfx.name = "WeaponAttackSfx"
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("weapon_id", str(data.get("id", "")))
	sfx.set_meta("weapon_group", str(cue.get("group", data.get("group", ""))))
	sfx.set_meta("weapon_sound_id", str(cue.get("id", "ranged_attack")))
	sfx.set_meta("audio_cue_label", str(cue.get("label", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "weapon_attack")))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("weapon_sound_frequency", float(cue.get("frequency", 500.0)))
	sfx.set_meta("playback_requested", true)
	add_child(sfx)
	if DisplayServer.get_name() != "headless":
		sfx.play()
	call_deferred("_release_weapon_attack_sfx", sfx)

func _release_weapon_attack_sfx(node: Node, should_queue_free: bool = true) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is AudioStreamPlayer:
		var sfx := node as AudioStreamPlayer
		sfx.stop()
		sfx.stream = null
	if should_queue_free:
		node.queue_free()

func _fx_parent() -> Node:
	var tree := get_tree()
	if tree == null:
		return self
	return tree.current_scene if tree.current_scene != null else tree.root


func _roll_damage() -> int:
	var dmg := float(base_damage())
	_last_roll_critical = false
	_last_stationary_bonus_active = false
	var player := _player()
	if player != null:
		dmg *= player.damage_mult
		dmg *= player.element_damage_multiplier(_element())
		if _stationary_bonus_active(player):
			_last_stationary_bonus_active = true
			dmg *= stationary_damage_mult()
			set_meta("stationary_bonus_shots", int(get_meta("stationary_bonus_shots", 0)) + 1)
		if player.has_method("weapon_damage_multiplier"):
			dmg *= float(player.call("weapon_damage_multiplier"))
		dmg *= _charged_damage_mult
		if player.has_method("consume_weapon_damage_bonus"):
			player.call("consume_weapon_damage_bonus")
		var guaranteed_crit := player.has_method("consume_guaranteed_crit") \
			and bool(player.call("consume_guaranteed_crit"))
		if guaranteed_crit or randf() < player.crit_chance:
			_last_roll_critical = true
			dmg *= 1.5
	return int(round(dmg))

func _stationary_bonus_active(player: Player) -> bool:
	if stationary_damage_mult() <= 1.0:
		return false
	return player.velocity.length_squared() <= stationary_speed_threshold() * stationary_speed_threshold()


func _element() -> String:
	var innate := str(data.get("element", ""))
	if innate != "":
		return innate
	var player := _player()
	return player.equipped_element if player != null else ""


func _melee_hit(origin: Vector2, aim: Vector2) -> void:
	var reach := melee_reach()
	var landed := false
	var enemies: Array[Enemy] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and _melee_can_hit(enemy.global_position, origin, aim, reach):
			enemies.append(enemy)
	var props: Array[Node2D] = []
	for prop in get_tree().get_nodes_in_group("breakable_props"):
		if prop is Node2D and prop.has_method("hit") \
				and _melee_can_hit(prop.global_position, origin, aim, reach):
			props.append(prop)

	if not enemies.is_empty() or not props.is_empty():
		landed = true
		_melee_hit_count += 1
		_apply_attack_speed_ramp()
	var knockback_ready := _combo_knockback_ready()

	for enemy in enemies:
		var damage := _roll_damage()
		damage = _apply_enemy_melee_effects(enemy, damage, origin)
		enemy.set_meta("incoming_critical", _last_roll_critical)
		if enemy.has_method("hit_from"):
			enemy.hit_from(damage, _element(), origin)
		else:
			enemy.hit(damage, _element())
		_apply_enemy_post_hit_effects(enemy)
		if knockback_ready:
			_apply_knockback(enemy, aim)
	for prop in props:
		prop.hit(_prop_damage())
	if landed:
		_try_shadow_wave(origin, aim)
	var player := _player()
	if landed and player != null:
		player.on_hit_landed()

func _melee_can_hit(pos: Vector2, origin: Vector2, aim: Vector2, reach: float) -> bool:
	var dir := aim.normalized() if aim.length_squared() > 0.0 else Vector2.RIGHT
	if line_pierce_range() > 0.0:
		var rel := pos - origin
		var along := rel.dot(dir)
		if along >= 0.0 and along <= line_pierce_range():
			var lateral := absf(rel.cross(dir))
			if lateral <= maxf(line_pierce_width() * _charged_cleave_width_mult, 6.0):
				return true
	var hit_center := origin + dir * reach * 0.6
	return pos.distance_to(hit_center) <= reach * _charged_cleave_width_mult

func _apply_enemy_melee_effects(enemy: Enemy, damage: int, origin: Vector2) -> int:
	var value := damage
	var backstabbed := _is_backstab(enemy, origin)
	if backstab_damage_mult() > 1.0 and backstabbed:
		value = maxi(1, int(round(float(value) * backstab_damage_mult())))
		enemy.set_meta("backstab_hits", int(enemy.get_meta("backstab_hits", 0)) + 1)
	var player := _player()
	if player != null and player.has_method("target_damage_multiplier"):
		var target_mult := float(player.call("target_damage_multiplier", enemy))
		if target_mult > 1.0:
			value = maxi(1, int(round(float(value) * target_mult)))
			enemy.set_meta("target_damage_mult", target_mult)
	if backstabbed and player != null and player.has_method("back_attack_damage_multiplier"):
		var weakpoint_mult := float(player.call("back_attack_damage_multiplier"))
		if weakpoint_mult > 1.0:
			value = maxi(1, int(round(float(value) * weakpoint_mult)))
			enemy.set_meta("weakpoint_hits", int(enemy.get_meta("weakpoint_hits", 0)) + 1)
			enemy.set_meta("weakpoint_damage_mult", weakpoint_mult)
	return value


func _apply_enemy_post_hit_effects(enemy: Enemy) -> void:
	if stun_chance() > 0.0 and stun_duration() > 0.0 and randf() <= stun_chance():
		enemy.add_status("stun", stun_duration())
		enemy.set_meta("weapon_stun_hits", int(enemy.get_meta("weapon_stun_hits", 0)) + 1)

func _is_backstab(enemy: Enemy, origin: Vector2) -> bool:
	var front_dir := Vector2.RIGHT
	if enemy.target != null and is_instance_valid(enemy.target):
		front_dir = (enemy.target.global_position - enemy.global_position).normalized()
	elif enemy.velocity.length_squared() > 1.0:
		front_dir = enemy.velocity.normalized()
	var hit_dir := (origin - enemy.global_position).normalized()
	if front_dir.length_squared() <= 0.0 or hit_dir.length_squared() <= 0.0:
		return false
	return front_dir.dot(hit_dir) < -0.35

func _prop_damage() -> int:
	return maxi(1, int(round(float(_roll_damage()) * prop_damage_mult())))

func _combo_knockback_ready() -> bool:
	var every := combo_knockback_every()
	return every > 0 and _melee_hit_count % every == 0 and knockback_distance() > 0.0

func _apply_knockback(enemy: Enemy, aim: Vector2) -> void:
	var dir := aim.normalized() if aim.length_squared() > 0.0 else Vector2.RIGHT
	enemy.global_position += dir * knockback_distance()
	enemy.set_meta("weapon_knockback_hits", int(enemy.get_meta("weapon_knockback_hits", 0)) + 1)


func _apply_attack_speed_ramp() -> void:
	var step := attack_speed_ramp_per_hit()
	var cap := attack_speed_ramp_max()
	if step <= 0.0 or cap <= 0.0:
		return
	_attack_speed_bonus = minf(_attack_speed_bonus + step, cap)
	set_meta("attack_speed_bonus", _attack_speed_bonus)


func _try_shadow_wave(origin: Vector2, aim: Vector2) -> void:
	var every := shadow_wave_every()
	if every <= 0 or shadow_wave_damage_mult() <= 0.0 or shadow_wave_range() <= 0.0:
		return
	if _melee_hit_count % every != 0:
		return
	var dir := aim.normalized() if aim.length_squared() > 0.0 else Vector2.RIGHT
	var projectile := Projectile.new()
	projectile.name = "ShadowWaveProjectile"
	projectile.setup(dir, PROJECTILE_SPEED * 0.85, _shadow_wave_damage(), shadow_wave_range(),
		Color(0.55, 0.32, 0.85), _element(), _player(), shadow_wave_pierce(), false)
	var parent := _fx_parent()
	parent.add_child(projectile)
	projectile.global_position = origin + dir * melee_reach()
	set_meta("shadow_wave_count", int(get_meta("shadow_wave_count", 0)) + 1)


func _shadow_wave_damage() -> int:
	var dmg := float(base_damage()) * shadow_wave_damage_mult()
	var player := _player()
	if player != null:
		dmg *= player.damage_mult
		dmg *= player.element_damage_multiplier(_element())
	return maxi(1, int(round(dmg)))


func _fire_projectile_pattern(origin: Vector2, aim: Vector2) -> void:
	var dirs := _aim_variants(aim)
	var bursts := burst_count()
	var volley_count := maxi(dirs.size() * bursts, 1)
	var rolled_damage := _roll_damage()
	if _active_reload_rounds_left() > 0:
		rolled_damage = maxi(1, int(round(float(rolled_damage) * ACTIVE_RELOAD_DAMAGE_MULT)))
		set_meta("active_reload_empowered_shots",
			int(get_meta("active_reload_empowered_shots", 0)) + 1)
	if _last_round_bonus_ready():
		rolled_damage = maxi(1, int(round(float(rolled_damage) * last_round_damage_mult())))
		set_meta("last_round_bonus_shots", int(get_meta("last_round_bonus_shots", 0)) + 1)
	var damage := maxi(1, int(round(float(rolled_damage) / sqrt(float(volley_count)))))
	var critical := _last_roll_critical
	if _last_stationary_bonus_active:
		CombatFxScript.spawn_stationary_focus(_fx_parent(), origin)
	for burst in bursts:
		for dir in dirs:
			_fire_projectile(origin + aim.normalized() * float(burst) * 3.0, dir, damage, critical)
	_charged_projectile_pierce_bonus = 0
	_charged_damage_mult = 1.0
	_charged_cleave_width_mult = 1.0
	var player := _player()
	if player != null and int(player.get_meta("special_rounds_left", 0)) > 0:
		_update_special_rounds_after_attack(player, int(player.get_meta("special_rounds_left", 0)) - 1)
	_consume_active_reload_round()


func _update_special_rounds_after_attack(player: Player, rounds_left: int) -> void:
	var label := player.get_node_or_null("SpecialRoundsFeedback") as Label
	if rounds_left <= 0:
		player.set_meta("special_rounds_left", 0)
		if player.has_meta("special_rounds_element"):
			player.remove_meta("special_rounds_element")
		if label != null:
			label.queue_free()
		return
	player.set_meta("special_rounds_left", rounds_left)
	if label != null:
		label.text = "ROUNDS %d" % rounds_left

func _active_reload_rounds_left() -> int:
	return maxi(int(get_meta("active_reload_rounds_left", 0)), 0)

func _consume_active_reload_round() -> void:
	var left := _active_reload_rounds_left()
	if left <= 0:
		return
	left -= 1
	set_meta("active_reload_rounds_left", left)
	var player := _player()
	if player != null:
		player.set_meta("active_reload_rounds_left", left)
	if left <= 0:
		set_meta("active_reload_damage_mult", 1.0)
		if player != null:
			player.set_meta("active_reload_ready", false)

func _last_round_bonus_ready() -> bool:
	var mag := magazine_size()
	if mag <= 0 or last_round_damage_mult() <= 1.0:
		return false
	_ranged_attack_count += 1
	return _ranged_attack_count % mag == 0


func _aim_variants(aim: Vector2) -> Array[Vector2]:
	var base := aim.normalized() if aim.length_squared() > 0.0 else Vector2.RIGHT
	var count := projectile_count()
	if count <= 1:
		return [base]
	var spread := deg_to_rad(10.0)
	var dirs: Array[Vector2] = []
	for i in count:
		var offset := float(i) - (float(count) - 1.0) * 0.5
		dirs.append(base.rotated(spread * offset))
	return dirs


func _fire_projectile(origin: Vector2, aim: Vector2, damage: int = -1, critical: bool = false) -> void:
	var projectile := Projectile.new()
	var color := Color(0.5, 0.8, 1.0) if MAGIC_GROUPS.has(str(data.get("group", ""))) \
		else Color(1.0, 0.9, 0.55)
	projectile.setup(aim, PROJECTILE_SPEED, damage if damage > 0 else _roll_damage(), projectile_range(),
		color, _element(), _player(), projectile_pierce_count(), critical or _last_roll_critical,
		homing_strength())
	if chain_count() > 0:
		projectile.configure_chain(chain_count(), chain_radius(), chain_damage_mult())
	if split_count() > 0:
		projectile.configure_split(split_count(), split_angle_deg(), split_damage_mult())
	if fire_patch_damage() > 0:
		projectile.configure_fire_patch(
			fire_patch_damage(), fire_patch_radius(), fire_patch_duration(), fire_patch_tick())
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin + aim * 10.0
