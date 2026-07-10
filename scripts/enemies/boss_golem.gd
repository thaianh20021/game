class_name BossGolem
extends Enemy
## Floor boss "Golem Thuc Tinh" (GDD boss #1), three phases by HP:
##   P1 (>66%): slow chase + telegraphed close-range smash
##   P2 (>33%): keeps mid distance, throws 3-rock volleys
##   P3:        repeated telegraphed rolling charges
## All attacks are telegraphed (GDD hard rule: every hit is readable).

signal boss_phase_changed(status: Dictionary)
signal boss_attack_cued(status: Dictionary)

var phase := 1
var enraged := false
var variant_id := "cave_golem"

const FloatingGunScript := preload("res://scripts/enemies/floating_gun.gd")
const TrapScript := preload("res://scripts/rooms/trap.gd")
const MAX_BOSS_TRAPS := 12
const RECENT_ATTACK_HISTORY_LIMIT := 4
const BOSS_TRAP_RADIUS := 42.0
const BOSS_TRAP_TARGET_SAFE_RADIUS := 28.0
const BOSS_TRAP_MIN_SPACING := 20.0

var _floating_guns: Array[Node2D] = []
var _phase2_traps_spawned := false
var _bullet_hell_cd := 1.2
var _enrage_trap_cd := 1.6
var _pattern_step_index := 0
var _attack_sequence_index := 0
var _recent_attack_events: Array[Dictionary] = []
var _spawn_ticks_msec := 0

func _ready() -> void:
	_spawn_ticks_msec = Time.get_ticks_msec()
	super()

func configure_variant(p_variant_id: String) -> void:
	variant_id = p_variant_id if p_variant_id != "" else "cave_golem"
	set_meta("boss_variant", variant_id)
	match variant_id:
		"spore_golem":
			base_tint = Color(0.65, 1.0, 0.72)
			speed *= 1.04
		"forge_golem":
			base_tint = Color(1.0, 0.68, 0.45)
			contact_damage += 2
			speed *= 1.08
		"archive_golem":
			base_tint = Color(0.58, 0.84, 1.0)
			contact_damage += 1
			speed *= 1.12
		"void_golem":
			base_tint = Color(0.72, 0.58, 1.0)
			contact_damage += 2
			speed *= 1.1
		_:
			base_tint = Color.WHITE
	modulate = _current_tint()

func apply_tuning_patch(patch: Dictionary) -> void:
	if not bool(patch.get("enabled", false)):
		return
	var patch_variant := str(patch.get("boss_variant", ""))
	if patch_variant != "" and patch_variant != variant_id:
		return
	var multiplier := clampf(float(patch.get("hp_multiplier", 1.0)), 0.5, 2.0)
	if multiplier <= 0.0 or is_equal_approx(multiplier, 1.0):
		return
	var old_max := maxi(max_hp, 1)
	max_hp = maxi(1, ceili(float(max_hp) * multiplier))
	hp = max_hp if hp <= 0 or hp >= old_max else mini(max_hp, maxi(1, ceili(float(hp) * multiplier)))
	set_meta("tuning_patch_source", str(patch.get("source", "")))
	set_meta("tuning_hp_multiplier", multiplier)
	set_meta("tuning_patch_id", str(patch.get("id", "")))


func _behave(delta: float) -> void:
	_update_phase()
	if enraged:
		_enrage_trap_cd = maxf(_enrage_trap_cd - delta, 0.0)
		if _enrage_trap_cd <= 0.0:
			summon_phase_traps(2)
			_enrage_trap_cd = 1.8
	_bullet_hell_cd = maxf(_bullet_hell_cd - delta, 0.0)
	if phase == 3 and _bullet_hell_cd <= 0.0:
		spawn_bullet_hell(12 if enraged else 8)
		_bullet_hell_cd = 1.0 if enraged else 1.35
	var mult := _speed_mult() * (1.25 if enraged else 1.0)
	var to_target := target.global_position - global_position
	match phase:
		1:
			match _state:
				"telegraph":
					velocity = Vector2.ZERO
					_state_timer -= delta
					_blink(Color(1.6, 1.3, 1.3))
					if _state_timer <= 0.0:
						_state = "chase"
						modulate = _current_tint()
						if to_target.length() <= 52.0:
							if target is Player:
								target.take_damage(contact_damage, global_position, _boss_damage_source("smash"))
							else:
								target.take_damage(contact_damage)
						_attack_cd = 1.6
				_:
					velocity = to_target.normalized() * speed * 0.8 * mult
					if to_target.length() <= 44.0 and _attack_cd <= 0.0:
						_state = "telegraph"
						_state_timer = 0.6
						_show_telegraph_fx(to_target.normalized(), 52.0, _state_timer)
						_emit_boss_attack_cue("smash", {
							"warning": "Close smash incoming",
							"next_attack_seconds": _state_timer,
						})
		2:
			var dist := to_target.length()
			if dist < 90.0:
				velocity = -to_target.normalized() * speed * mult
			elif dist > 160.0:
				velocity = to_target.normalized() * speed * mult
			else:
				velocity = Vector2.ZERO
			if _attack_cd <= 0.0:
				_attack_cd = 2.0
				_emit_boss_attack_cue("rock_volley", {
					"projectile_count": 3,
					"warning": "Three-rock volley",
				})
				for i in 3:
					var dir := to_target.normalized().rotated(deg_to_rad(-14.0 + 14.0 * i))
					_shoot(dir, 150.0, maxi(contact_damage - 4, 4), 260.0, "rock_volley")
		3:
			match _state:
				"telegraph":
					velocity = Vector2.ZERO
					_state_timer -= delta
					_blink(Color(1.7, 1.0, 1.0))
					if _state_timer <= 0.0:
						_state = "dash"
						_state_timer = 0.6
						_dash_dir = to_target.normalized()
						modulate = _current_tint()
				"dash":
					velocity = _dash_dir * speed * 3.5 * mult
					_state_timer -= delta
					if _state_timer <= 0.0:
						_state = "chase"
						_attack_cd = 0.9
				_:
					velocity = to_target.normalized() * speed * mult
					if _attack_cd <= 0.0:
						_state = "telegraph"
						_state_timer = 0.5
						_show_telegraph_fx(to_target.normalized(), 56.0, _state_timer)
						_emit_boss_attack_cue("rolling_charge", {
							"warning": "Rolling charge line",
							"next_attack_seconds": _state_timer,
						})
	move_and_slide()


func _update_phase() -> void:
	var ratio := float(hp) / float(max_hp)
	var new_phase := 1
	if ratio <= 0.33:
		new_phase = 3
	elif ratio <= 0.66:
		new_phase = 2
	var was_enraged := enraged
	enraged = ratio <= 0.30
	if new_phase != phase:
		phase = new_phase
		_state = "chase"
		_attack_cd = 1.0
		_pattern_step_index = 0
		if phase == 2:
			spawn_floating_guns(2)
			summon_phase_traps(4)
		elif phase == 3:
			spawn_floating_guns(4 if enraged else 3)
			_bullet_hell_cd = 0.25
		_pattern_step_index = 0
		_show_phase_warning(phase_warning_text())
		var status := boss_status()
		_play_boss_phase_sfx(status)
		boss_phase_changed.emit(status)
		print("Boss phase %d!" % phase)
	if enraged and not was_enraged:
		spawn_floating_guns(4)
		summon_phase_traps(4)
		_enrage_trap_cd = 1.6
		_attack_cd = minf(_attack_cd, 0.35)
		_pattern_step_index = 0
		_show_phase_warning(phase_warning_text())
		var enrage_status := boss_status()
		_play_boss_phase_sfx(enrage_status)
		boss_phase_changed.emit(enrage_status)


func phase_pattern() -> String:
	var base := ""
	match phase:
		1:
			base = "smash"
		2:
			base = "volley_traps"
		3:
			base = "enrage_bullet_hell" if enraged else "dash_bullet_hell"
		_:
			base = "unknown"
	var prefix := _variant_prefix()
	return base if prefix == "" else "%s_%s" % [prefix, base]

func phase_warning_text() -> String:
	match phase:
		1:
			return "SMASH"
		2:
			return "VOLLEY + TRAPS"
		3:
			return "ENRAGE + BULLET HELL" if enraged else "DASH + BULLET HELL"
		_:
			return "UNKNOWN"

func boss_status() -> Dictionary:
	var status := {
		"name": _display_name(),
		"hp": maxi(hp, 0),
		"max_hp": max_hp,
		"elapsed_seconds": _elapsed_seconds(),
		"phase": phase,
		"phase_text": phase_warning_text(),
		"pattern": phase_pattern(),
		"pattern_label": pattern_label(),
		"pattern_steps": pattern_steps(),
		"pattern_step_index": pattern_step_index(),
		"current_pattern_step": current_pattern_step(),
		"next_pattern_step": next_pattern_step(),
		"pattern_timeline": pattern_timeline(),
		"counter_hint": counter_hint(),
		"dodge_cue": dodge_cue(),
		"punish_window_seconds": punish_window_seconds(),
		"safe_window_hint": safe_window_hint(),
		"enraged": enraged,
		"enrage_warning": enrage_warning_text(),
		"enrage_intensity": enrage_intensity(),
		"active_trap_count": _active_boss_trap_count(),
		"floating_gun_count": _active_floating_gun_count(),
		"enrage_bullet_count": _planned_bullet_hell_count(),
		"arena_pressure_summary": arena_pressure_summary(),
		"variant": variant_id,
		"variant_pressure": variant_pressure_text(),
		"variant_counter_hint": variant_counter_hint(),
		"variant_status": variant_status_name(),
		"next_attack": next_attack_cue(),
		"next_attack_id": next_attack_id(),
		"next_variant_attack": next_variant_attack(),
		"next_attack_label": next_attack_label(),
		"next_attack_warning": next_attack_warning(),
		"next_attack_seconds": next_attack_seconds(),
	}
	var attack_history := _attack_history_status()
	for key in attack_history.keys():
		status[key] = attack_history[key]
	return status

func _elapsed_seconds() -> float:
	if _spawn_ticks_msec <= 0:
		_spawn_ticks_msec = Time.get_ticks_msec()
	return maxf(float(Time.get_ticks_msec() - _spawn_ticks_msec) / 1000.0, 0.0)

func pattern_label() -> String:
	var text := ""
	match phase:
		1:
			text = "Smash"
		2:
			text = "Rock Volley + Trap Wave"
		3:
			text = "Bullet Hell + Trap Wave" if enraged else "Dash + Bullet Hell"
		_:
			text = "Unknown"
	var variant_prefix := _readable_variant_prefix()
	return "Pattern: %s%s" % [variant_prefix, text]

func pattern_steps() -> Array[String]:
	match phase:
		1:
			return ["Close gap", "Smash telegraph", "Impact"]
		2:
			return ["Rock volley", "Trap wave", "Reposition"]
		3:
			return ["Bullet hell", "Trap wave", "Rolling charge"] if enraged \
				else ["Rolling charge", "Bullet hell", "Reposition"]
	return ["Read telegraph", "Dodge", "Punish"]

func pattern_step_index() -> int:
	var steps: Array = pattern_steps()
	if steps.is_empty():
		return 0
	return clampi(_pattern_step_index, 0, steps.size() - 1)

func current_pattern_step() -> String:
	var steps: Array = pattern_steps()
	if steps.is_empty():
		return ""
	return str(steps[pattern_step_index()])

func next_pattern_step() -> String:
	var steps: Array = pattern_steps()
	if steps.is_empty():
		return ""
	return str(steps[(pattern_step_index() + 1) % steps.size()])

func pattern_timeline() -> String:
	var steps: Array = pattern_steps()
	if steps.is_empty():
		return ""
	return "Now: %s | Next: %s | Step %d/%d" % [
		current_pattern_step(),
		next_pattern_step(),
		pattern_step_index() + 1,
		steps.size(),
	]

func advance_pattern_step() -> void:
	var steps: Array = pattern_steps()
	if steps.is_empty():
		_pattern_step_index = 0
		return
	_pattern_step_index = (_pattern_step_index + 1) % steps.size()

func counter_hint() -> String:
	match phase:
		1:
			return "Back off during red smash telegraph"
		2:
			return "Strafe the volley, then step out of trap tiles"
		3:
			return "Keep moving between bullet lanes and sidestep charge lines" if enraged \
		else "Sidestep charge lines, then rotate through bullet gaps"
	return "Watch telegraphs before attacking"

func dodge_cue() -> String:
	match phase:
		1:
			return "Step back before smash"
		2:
			return "Strafe sideways, then leave trap tiles"
		3:
			return "Rotate through bullet gaps" if enraged else "Sidestep charge, then rotate gaps"
	return "Dodge the telegraph"

func punish_window_seconds() -> float:
	match phase:
		1:
			return 0.8
		2:
			return 0.7
		3:
			return 0.45 if enraged else 0.6
	return 0.5

func safe_window_hint() -> String:
	match phase:
		1:
			return "Punish after smash impact"
		2:
			return "Punish after volley, before trap wave closes"
		3:
			return "Punish briefly after charge whiffs" if enraged \
				else "Punish after charge line ends"
	return "Punish after the telegraph resolves"

func enrage_warning_text() -> String:
	if not enraged:
		return ""
	return "ENRAGED: Bullet hell + traps"

func enrage_intensity() -> String:
	if enraged:
		return "high"
	if phase == 3:
		return "medium"
	return "low"

func arena_pressure_summary() -> String:
	return "Bullets %d | Traps %d/%d | Guns %d" % [
		_planned_bullet_hell_count(),
		_active_boss_trap_count(),
		MAX_BOSS_TRAPS,
		_active_floating_gun_count(),
	]

func _planned_bullet_hell_count() -> int:
	if phase != 3:
		return 0
	return maxi(12 if enraged else 8, _default_bullet_hell_count())

func next_attack_cue() -> String:
	return "Next: %s %.1fs" % [next_attack_label(), next_attack_seconds()]

func next_attack_id() -> String:
	match phase:
		1:
			return "smash"
		2:
			return "rock_volley"
		3:
			return "bullet_hell"
	return "attack"

func next_attack_label() -> String:
	var variant_attack := next_variant_attack()
	return _variant_attack_label(variant_attack) if variant_attack != "" else boss_attack_label(next_attack_id())

func next_attack_warning() -> String:
	var variant_attack := next_variant_attack()
	return _variant_attack_warning(variant_attack) if variant_attack != "" else boss_attack_warning(next_attack_id())

func next_variant_attack() -> String:
	return _variant_attack_id(next_attack_id())

func next_attack_seconds() -> float:
	match phase:
		1:
			return maxf(_state_timer if _state == "telegraph" else _attack_cd, 0.0)
		2:
			return maxf(_attack_cd, 0.0)
		3:
			return maxf(_bullet_hell_cd, 0.0)
	return 0.0

func _display_name() -> String:
	match variant_id:
		"spore_golem":
			return "Spore Golem"
		"forge_golem":
			return "Forge Golem"
		"archive_golem":
			return "Archive Golem"
	return "Golem Thuc Tinh"

func _show_phase_warning(text: String) -> void:
	var label := find_child("BossPhaseWarning", true, false) as Label
	if label == null:
		label = Label.new()
		label.name = "BossPhaseWarning"
		label.position = Vector2(-58, -48)
		label.z_index = 20
		label.add_theme_font_size_override("font_size", 10)
		add_child(label)
	var status := boss_status()
	var elapsed := float(status.get("elapsed_seconds", -1.0))
	label.text = "%s%s" % [
		text,
		" @%.1fs" % elapsed if elapsed >= 0.0 else "",
	]
	label.modulate = Color(1.0, 0.72, 0.34)
	label.set_meta("boss_phase", int(status.get("phase", 0)))
	label.set_meta("boss_phase_text", str(status.get("phase_text", "")))
	label.set_meta("boss_phase_elapsed_seconds", elapsed)
	label.set_meta("boss_enraged", bool(status.get("enraged", false)))
	label.set_meta("boss_pattern", str(status.get("pattern", "")))
	label.set_meta("boss_pattern_label", str(status.get("pattern_label", "")))
	label.set_meta("boss_counter_hint", str(status.get("counter_hint", "")))
	label.set_meta("boss_dodge_cue", str(status.get("dodge_cue", "")))
	label.set_meta("boss_safe_window_hint", str(status.get("safe_window_hint", "")))
	if is_inside_tree():
		var tween := create_tween()
		tween.tween_property(label, "position", Vector2(-58, -56), 0.18)
		tween.parallel().tween_property(label, "modulate:a", 0.35, 0.55).set_delay(0.18)

func spawn_bullet_hell(count: int = 8) -> void:
	var shots := maxi(maxi(count, _default_bullet_hell_count()), 1)
	var readable_delay := CombatFxScript.MIN_ATTACK_TELEGRAPH_SECONDS
	_show_telegraph_fx(Vector2.RIGHT, 72.0 if enraged else 60.0, readable_delay)
	_emit_boss_attack_cue("bullet_hell", {
		"projectile_count": shots,
		"warning": "Dodge radial bullets",
		"next_attack_seconds": readable_delay,
	})
	if not is_inside_tree():
		_fire_bullet_hell(shots)
		return
	var timer := Timer.new()
	timer.name = "BossBulletHellDelay"
	timer.one_shot = true
	timer.wait_time = readable_delay
	timer.timeout.connect(_on_bullet_hell_delay_timeout.bind(timer, shots))
	add_child(timer)
	timer.start()

func _on_bullet_hell_delay_timeout(timer: Timer, shots: int) -> void:
	if is_instance_valid(timer):
		timer.queue_free()
	_fire_bullet_hell(shots)

func _fire_bullet_hell(shots: int) -> void:
	for i in shots:
		var angle := TAU * float(i) / float(shots)
		var dir := Vector2.RIGHT.rotated(angle)
		_shoot(dir, 135.0 if enraged else 120.0, maxi(contact_damage - 2, 4), 260.0, "bullet_hell")

func summon_phase_traps(count: int = 4) -> void:
	if phase == 2 and _phase2_traps_spawned:
		return
	if phase == 2:
		_phase2_traps_spawned = true
	var kinds := _variant_trap_kinds()
	var variant_attack := _variant_attack_id("trap_wave")
	var variant_attack_label := _variant_attack_label(variant_attack)
	var spawned := 0
	var angle_bias := _trap_wave_angle_bias(count)
	var radius := _trap_wave_radius(count)
	for i in count:
		if _active_boss_trap_count() >= MAX_BOSS_TRAPS:
			break
		var trap := TrapScript.new()
		trap.configure(kinds[i % kinds.size()], maxi(contact_damage - 3, 4), 0.8, 0.22)
		trap.add_to_group("room_traps")
		trap.set_meta("boss_trap", true)
		trap.set_meta("boss_trap_warning", true)
		trap.set_meta("boss_pattern", phase_pattern())
		trap.set_meta("boss_pattern_label", pattern_label())
		trap.set_meta("boss_attack", "trap_wave")
		trap.set_meta("boss_target_safe_radius", BOSS_TRAP_TARGET_SAFE_RADIUS)
		trap.set_meta("boss_min_spacing", BOSS_TRAP_MIN_SPACING)
		if variant_attack != "":
			trap.set_meta("boss_variant_attack", variant_attack)
			trap.set_meta("boss_variant_attack_label", variant_attack_label)
		var offset := Vector2(radius, 0).rotated(
			TAU * (float(i) + angle_bias) / float(maxi(count, 1)))
		trap.top_level = true
		trap.z_index = 1
		_add_trap_warning(trap, kinds[i % kinds.size()])
		add_child(trap)
		trap.global_position = global_position + offset
		spawned += 1
	if spawned > 0:
		_emit_boss_attack_cue("trap_wave", {
			"hazard_count": spawned,
			"warning": "Trap wave spreading",
		})

func _trap_wave_angle_bias(count: int) -> float:
	if target == null or count <= 1:
		return 0.0
	var radius := _trap_wave_radius(count)
	var best_bias := 0.0
	var best_distance := -1.0
	for step in 8:
		var bias := float(step) / 8.0
		var closest := INF
		for i in count:
			var offset := Vector2(radius, 0).rotated(
				TAU * (float(i) + bias) / float(count))
			closest = minf(closest, (global_position + offset).distance_to(target.global_position))
		if closest > best_distance:
			best_distance = closest
			best_bias = bias
	return best_bias

func _trap_wave_radius(count: int) -> float:
	if count <= 1:
		return BOSS_TRAP_RADIUS
	var spacing_radius := BOSS_TRAP_MIN_SPACING / (2.0 * sin(PI / float(count)))
	return maxf(BOSS_TRAP_RADIUS, spacing_radius)

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
	var readability := _projectile_readability_payload(attack_id)
	if not readability.is_empty():
		projectile.setup_readability(
			str(readability.get("variant", "")),
			readability.get("color", Color(1.0, 0.45, 0.35)))
	projectile.set_meta("boss_pattern", phase_pattern())
	projectile.set_meta("boss_pattern_label", pattern_label())
	if attack_id != "":
		projectile.set_meta("boss_attack", attack_id)
		projectile.set_meta("boss_attack_label", boss_attack_label(attack_id))
	var variant_attack := _variant_attack_id(attack_id)
	if variant_attack != "":
		projectile.set_meta("boss_variant_attack", variant_attack)
		projectile.set_meta("boss_variant_attack_label", _variant_attack_label(variant_attack))
	var tree := get_tree()
	var parent := tree.current_scene if tree != null and tree.current_scene != null else get_parent()
	if parent == null and tree != null:
		parent = tree.root
	parent.add_child(projectile)
	projectile.global_position = global_position + dir * 8.0

func _emit_boss_attack_cue(attack_id: String, extra: Dictionary = {}) -> void:
	_sync_pattern_step_for_attack(attack_id)
	var status := boss_status()
	status["attack"] = attack_id
	status["attack_label"] = boss_attack_label(attack_id)
	status["warning"] = str(extra.get("warning", boss_attack_warning(attack_id)))
	var variant_attack := _variant_attack_id(attack_id)
	if variant_attack != "":
		status["variant_attack"] = variant_attack
		status["variant_attack_label"] = _variant_attack_label(variant_attack)
		status["variant_warning"] = _variant_attack_warning(variant_attack)
	status["variant_pressure"] = variant_pressure_text()
	status["variant_counter_hint"] = variant_counter_hint()
	status["variant_status"] = variant_status_name()
	for key in extra.keys():
		status[key] = extra[key]
	_record_boss_attack(status)
	_show_attack_warning(status)
	_play_boss_attack_sfx(status)
	boss_attack_cued.emit(status)

func _record_boss_attack(status: Dictionary) -> void:
	var previous_attack := _last_recorded_attack_id()
	var previous_label := _last_recorded_attack_label()
	_attack_sequence_index += 1
	status["attack_sequence_index"] = _attack_sequence_index
	status["previous_attack"] = previous_attack
	status["previous_attack_label"] = previous_label
	_recent_attack_events.append(_attack_history_entry(status))
	while _recent_attack_events.size() > RECENT_ATTACK_HISTORY_LIMIT:
		_recent_attack_events.remove_at(0)
	var history_status := _attack_history_status()
	for key in history_status.keys():
		status[key] = history_status[key]
	status["previous_attack"] = previous_attack
	status["previous_attack_label"] = previous_label

func _attack_history_entry(status: Dictionary) -> Dictionary:
	var label := str(status.get("variant_attack_label", status.get("attack_label", "")))
	var warning := str(status.get("variant_warning", status.get("warning", "")))
	return {
		"sequence_index": int(status.get("attack_sequence_index", _attack_sequence_index)),
		"attack": str(status.get("attack", "")),
		"attack_label": label,
		"count": int(status.get("projectile_count", status.get("hazard_count", 0))),
		"warning": warning,
		"phase": phase,
		"pattern": str(status.get("pattern", "")),
		"pattern_label": str(status.get("pattern_label", "")),
		"current_pattern_step": str(status.get("current_pattern_step", "")),
	}

func _attack_history_status() -> Dictionary:
	var last: Dictionary = _recent_attack_events.back() if not _recent_attack_events.is_empty() else {}
	var previous: Dictionary = _recent_attack_events[_recent_attack_events.size() - 2] \
		if _recent_attack_events.size() >= 2 else {}
	return {
		"attack_sequence_count": _attack_sequence_index,
		"last_attack": str(last.get("attack", "")),
		"last_attack_label": str(last.get("attack_label", "")),
		"previous_attack": str(previous.get("attack", "")),
		"previous_attack_label": str(previous.get("attack_label", "")),
		"recent_attacks": _recent_attack_events.duplicate(true),
		"recent_attack_summary": recent_attack_summary(),
	}

func recent_attack_summary() -> String:
	var parts: Array[String] = []
	for event in _recent_attack_events:
		var label := str(event.get("attack_label", "Attack"))
		var count := int(event.get("count", 0))
		parts.append("%s%s" % [label, " x%d" % count if count > 0 else ""])
	return " -> ".join(parts)

func _last_recorded_attack_id() -> String:
	if _recent_attack_events.is_empty():
		return ""
	return str(_recent_attack_events.back().get("attack", ""))

func _last_recorded_attack_label() -> String:
	if _recent_attack_events.is_empty():
		return ""
	return str(_recent_attack_events.back().get("attack_label", ""))

func boss_attack_label(attack_id: String) -> String:
	match attack_id:
		"smash":
			return "Smash"
		"rock_volley":
			return "Rock Volley"
		"rolling_charge":
			return "Rolling Charge"
		"bullet_hell":
			return "Bullet Hell"
		"trap_wave":
			return "Trap Wave"
	return attack_id.replace("_", " ").capitalize()

func _boss_damage_source(attack_id: String) -> String:
	var label := boss_attack_label(attack_id).strip_edges()
	return "Boss: %s" % (label if label != "" else "Hit")

func boss_attack_warning(attack_id: String) -> String:
	match attack_id:
		"smash":
			return "Back off before impact"
		"rock_volley":
			return "Strafe the volley"
		"rolling_charge":
			return "Sidestep the line"
		"bullet_hell":
			return "Dodge radial bullets"
		"trap_wave":
			return "Watch the floor"
	return "Boss attack"

func _show_attack_warning(status: Dictionary) -> void:
	var label := find_child("BossAttackWarning", true, false) as Label
	if label == null:
		label = Label.new()
		label.name = "BossAttackWarning"
		label.position = Vector2(-54, -62)
		label.z_index = 21
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
		add_child(label)
	for key in [
		"attack",
		"attack_label",
		"variant_attack",
		"variant_attack_label",
		"projectile_count",
		"hazard_count",
		"warning",
		"variant_warning",
		"variant_pressure",
		"variant_counter_hint",
		"variant_status",
		"next_attack_seconds",
		"counter_hint",
		"dodge_cue",
		"punish_window_seconds",
		"safe_window_hint",
		"pattern_step_index",
		"current_pattern_step",
		"next_pattern_step",
		"pattern_timeline",
		"attack_sequence_index",
		"previous_attack",
		"recent_attack_summary",
		"elapsed_seconds",
		"boss_attack_elapsed_seconds",
	]:
		if label.has_meta(key):
			label.remove_meta(key)
	for key in status.keys():
		if [
			"attack",
			"attack_label",
			"variant_attack",
			"variant_attack_label",
			"projectile_count",
			"hazard_count",
			"warning",
			"variant_warning",
			"variant_pressure",
			"variant_counter_hint",
			"variant_status",
			"next_attack_seconds",
			"counter_hint",
			"dodge_cue",
			"punish_window_seconds",
			"safe_window_hint",
			"pattern_step_index",
			"current_pattern_step",
			"next_pattern_step",
			"pattern_timeline",
			"attack_sequence_index",
			"previous_attack",
			"recent_attack_summary",
			"elapsed_seconds",
		].has(str(key)):
			label.set_meta(str(key), status[key])
	var elapsed := float(status.get("elapsed_seconds", -1.0))
	label.set_meta("boss_attack_elapsed_seconds", elapsed)
	var text_parts: Array[String] = [
		str(status.get("variant_attack_label", status.get("attack_label", "Attack"))),
	]
	var count := int(status.get("projectile_count", status.get("hazard_count", 0)))
	if count > 0:
		text_parts.append("x%d" % count)
	var warning := str(status.get("variant_warning", status.get("warning", "")))
	if warning != "":
		text_parts.append(warning)
	var counter := str(status.get("variant_counter_hint", ""))
	if counter != "":
		text_parts.append(counter)
	if status.has("next_attack_seconds"):
		text_parts.append("%.1fs" % float(status.get("next_attack_seconds", 0.0)))
	if elapsed >= 0.0:
		text_parts.append("@%.1fs" % elapsed)
	var punish_window := float(status.get("punish_window_seconds", 0.0))
	if punish_window > 0.0:
		text_parts.append("Punish %.1fs" % punish_window)
	var timeline := str(status.get("pattern_timeline", ""))
	if timeline != "":
		text_parts.append(timeline)
	label.text = " | ".join(text_parts)
	label.add_theme_color_override("font_color", _variant_cue_color())
	if is_inside_tree():
		label.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_property(label, "modulate:a", 0.35, 0.45)

func _play_boss_phase_sfx(status: Dictionary) -> void:
	var cue: Dictionary = AudioCueDBScript.boss_phase_cue(status)
	var sfx := get_node_or_null("BossPhaseSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "BossPhaseSfx"
		add_child(sfx)
	else:
		sfx.stop()
	var pattern_steps: Array = status.get("pattern_steps", [])
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("boss_phase_sound_id", str(cue.get("id", "boss_phase_shift")))
	sfx.set_meta("boss_phase", int(status.get("phase", 0)))
	sfx.set_meta("boss_phase_text", str(status.get("phase_text", "")))
	sfx.set_meta("boss_enraged", bool(status.get("enraged", false)))
	sfx.set_meta("boss_pattern", str(status.get("pattern", "")))
	sfx.set_meta("boss_pattern_label", str(status.get("pattern_label", "")))
	sfx.set_meta("boss_pattern_steps", " -> ".join(pattern_steps))
	sfx.set_meta("boss_pattern_step_index", int(status.get("pattern_step_index", -1)))
	sfx.set_meta("boss_current_pattern_step", str(status.get("current_pattern_step", "")))
	sfx.set_meta("boss_next_pattern_step", str(status.get("next_pattern_step", "")))
	sfx.set_meta("boss_pattern_timeline", str(status.get("pattern_timeline", "")))
	sfx.set_meta("boss_counter_hint", str(status.get("counter_hint", "")))
	sfx.set_meta("boss_dodge_cue", str(status.get("dodge_cue", "")))
	sfx.set_meta("boss_punish_window_seconds", float(status.get("punish_window_seconds", 0.0)))
	sfx.set_meta("boss_safe_window_hint", str(status.get("safe_window_hint", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "boss_phase")))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _play_boss_attack_sfx(status: Dictionary) -> void:
	var cue: Dictionary = AudioCueDBScript.boss_attack_cue(status)
	var sfx := get_node_or_null("BossAttackSfx") as AudioStreamPlayer
	if sfx == null:
		sfx = AudioStreamPlayer.new()
		sfx.name = "BossAttackSfx"
		add_child(sfx)
	else:
		sfx.stop()
	sfx.stream = AudioCueDBScript.placeholder_stream(cue)
	sfx.set_meta("boss_attack_sound_id", str(cue.get("id", "boss_generic_attack")))
	sfx.set_meta("boss_attack", str(status.get("attack", "")))
	sfx.set_meta("boss_attack_label", str(status.get("attack_label", "")))
	sfx.set_meta("boss_attack_count", int(status.get(
		"projectile_count", status.get("hazard_count", 0))))
	sfx.set_meta("boss_attack_warning", str(status.get(
		"variant_warning", status.get("warning", ""))))
	sfx.set_meta("boss_variant_attack", str(status.get("variant_attack", "")))
	sfx.set_meta("boss_variant_attack_label", str(status.get("variant_attack_label", "")))
	sfx.set_meta("boss_pattern", str(status.get("pattern", "")))
	sfx.set_meta("boss_attack_sequence_index", int(status.get("attack_sequence_index", 0)))
	sfx.set_meta("boss_previous_attack", str(status.get("previous_attack", "")))
	sfx.set_meta("boss_recent_attack_summary", str(status.get("recent_attack_summary", "")))
	sfx.set_meta("boss_counter_hint", str(status.get("counter_hint", "")))
	sfx.set_meta("boss_dodge_cue", str(status.get("dodge_cue", "")))
	sfx.set_meta("boss_punish_window_seconds", float(status.get("punish_window_seconds", 0.0)))
	sfx.set_meta("boss_safe_window_hint", str(status.get("safe_window_hint", "")))
	sfx.set_meta("audio_cue_source", str(cue.get("source", "AudioCueDB")))
	sfx.set_meta("audio_cue_kind", str(cue.get("kind", "boss_attack")))
	sfx.set_meta("placeholder_audio_stream", true)
	sfx.set_meta("playback_requested", true)
	if DisplayServer.get_name() == "headless":
		sfx.set_meta("headless_playback_skipped", true)
		return
	sfx.set_meta("headless_playback_skipped", false)
	sfx.play()

func _add_trap_warning(trap: Node2D, trap_kind: String) -> void:
	var label := Label.new()
	label.name = "BossTrapWarning"
	label.text = _trap_warning_text(trap_kind)
	label.position = Vector2(-14, -22)
	label.z_index = 8
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", _trap_warning_color(trap_kind))
	trap.add_child(label)

func _trap_warning_text(trap_kind: String) -> String:
	match trap_kind:
		"fire":
			return "FIRE"
		"saw":
			return "SAW"
		"arrow":
			return "ARROW"
	return "TRAP"

func _trap_warning_color(trap_kind: String) -> Color:
	match trap_kind:
		"fire":
			return Color(1.0, 0.42, 0.22)
		"saw":
			return Color(0.9, 0.9, 0.82)
		"arrow":
			return Color(1.0, 0.86, 0.36)
	return Color(1.0, 0.35, 0.28)

func _active_boss_trap_count() -> int:
	var count := 0
	for child in get_children():
		if child.is_in_group("room_traps") and child.has_meta("boss_trap"):
			count += 1
	return count

func _active_floating_gun_count() -> int:
	_floating_guns = _floating_guns.filter(func(gun: Node2D) -> bool:
		return is_instance_valid(gun))
	return _floating_guns.size()

func _projectile_status_payload() -> Dictionary:
	match variant_id:
		"spore_golem":
			return {"status": "poisoned", "duration": 2.2}
		"forge_golem":
			return {"status": "burning", "duration": 2.0}
		"archive_golem":
			return {"status": "chilled", "duration": 1.6}
		"void_golem":
			return {"status": "cursed", "duration": 2.0}
	return {}

func variant_status_name() -> String:
	var payload := _projectile_status_payload()
	return str(payload.get("status", ""))

func variant_pressure_text() -> String:
	match variant_id:
		"spore_golem":
			return "Poison pressure: lingering bloom lanes"
		"forge_golem":
			return "Burn pressure: hot rings and hazard waves"
		"archive_golem":
			return "Chill pressure: crystal lanes slow rotations"
		"void_golem":
			return "Curse pressure: collapsing lanes punish late dodges"
	return "Physical pressure: readable smash and volley patterns"

func variant_counter_hint() -> String:
	match variant_id:
		"spore_golem":
			return "Keep moving through gaps; avoid standing in poison lanes"
		"forge_golem":
			return "Step out of hot zones before punishing"
		"archive_golem":
			return "Rotate early through crystal lanes before chill stacks"
		"void_golem":
			return "Cross the centerline early; punish after curse lanes collapse"
	return "Read the telegraph, dodge, then punish"

func _projectile_readability_payload(_attack_id: String = "") -> Dictionary:
	return {
		"variant": variant_id,
		"color": _projectile_readability_color(),
	}

func _projectile_readability_color() -> Color:
	match variant_id:
		"spore_golem":
			return Color(0.48, 1.0, 0.58)
		"forge_golem":
			return Color(1.0, 0.42, 0.22)
		"archive_golem":
			return Color(0.55, 0.88, 1.0)
		"void_golem":
			return Color(0.72, 0.52, 1.0)
	return Color(0.82, 0.72, 1.0) if enraged else Color(1.0, 0.58, 0.36)

func _sync_pattern_step_for_attack(attack_id: String) -> void:
	var steps: Array = pattern_steps()
	if steps.is_empty():
		_pattern_step_index = 0
		return
	var wanted := ""
	match attack_id:
		"smash":
			wanted = "Smash"
		"rock_volley":
			wanted = "Rock"
		"trap_wave":
			wanted = "Trap"
		"rolling_charge":
			wanted = "Rolling"
		"bullet_hell":
			wanted = "Bullet"
	if wanted == "":
		return
	for i in steps.size():
		if str(steps[i]).contains(wanted):
			_pattern_step_index = i
			return

func _variant_prefix() -> String:
	match variant_id:
		"spore_golem":
			return "spore"
		"forge_golem":
			return "forge"
		"archive_golem":
			return "archive"
		"void_golem":
			return "void"
	return ""

func _readable_variant_prefix() -> String:
	match variant_id:
		"spore_golem":
			return "Spore "
		"forge_golem":
			return "Forge "
		"archive_golem":
			return "Archive "
		"void_golem":
			return "Void "
	return ""

func _variant_attack_id(base_attack_id: String) -> String:
	match variant_id:
		"spore_golem":
			match base_attack_id:
				"bullet_hell":
					return "spore_bloom"
				"trap_wave":
					return "spore_root_wave"
				"rock_volley":
					return "spore_volley"
				"rolling_charge":
					return "spore_charge"
				"smash":
					return "spore_smash"
		"forge_golem":
			match base_attack_id:
				"bullet_hell":
					return "forge_overheat"
				"trap_wave":
					return "forge_hazard_wave"
				"rock_volley":
					return "forge_shrapnel"
				"rolling_charge":
					return "forge_charge"
				"smash":
					return "forge_slam"
		"archive_golem":
			match base_attack_id:
				"bullet_hell":
					return "archive_prism"
				"trap_wave":
					return "archive_lattice"
				"rock_volley":
					return "archive_shards"
				"rolling_charge":
					return "archive_charge"
				"smash":
					return "archive_slam"
		"void_golem":
			match base_attack_id:
				"bullet_hell":
					return "void_collapse"
				"trap_wave":
					return "void_rift_wave"
				"rock_volley":
					return "void_shards"
				"rolling_charge":
					return "void_charge"
				"smash":
					return "void_slam"
	return ""

func _variant_attack_label(variant_attack: String) -> String:
	match variant_attack:
		"spore_bloom":
			return "Spore Bloom"
		"spore_root_wave":
			return "Spore Root Wave"
		"spore_volley":
			return "Spore Volley"
		"spore_charge":
			return "Spore Charge"
		"spore_smash":
			return "Spore Smash"
		"forge_overheat":
			return "Forge Overheat"
		"forge_hazard_wave":
			return "Forge Hazard Wave"
		"forge_shrapnel":
			return "Forge Shrapnel"
		"forge_charge":
			return "Forge Charge"
		"forge_slam":
			return "Forge Slam"
		"archive_prism":
			return "Archive Prism"
		"archive_lattice":
			return "Archive Lattice"
		"archive_shards":
			return "Archive Shards"
		"archive_charge":
			return "Archive Charge"
		"archive_slam":
			return "Archive Slam"
		"void_collapse":
			return "Void Collapse"
		"void_rift_wave":
			return "Void Rift Wave"
		"void_shards":
			return "Void Shards"
		"void_charge":
			return "Void Charge"
		"void_slam":
			return "Void Slam"
	return ""

func _variant_attack_warning(variant_attack: String) -> String:
	match variant_attack:
		"spore_bloom":
			return "Poison bloom: keep moving through gaps"
		"spore_root_wave":
			return "Poison roots spreading underfoot"
		"spore_volley":
			return "Poison rocks fan outward"
		"spore_charge":
			return "Poison charge line"
		"spore_smash":
			return "Poison smash burst"
		"forge_overheat":
			return "Burn overheat: dodge the hot ring"
		"forge_hazard_wave":
			return "Burning forge hazards spreading"
		"forge_shrapnel":
			return "Burning shrapnel volley"
		"forge_charge":
			return "Burning charge line"
		"forge_slam":
			return "Burning forge slam"
		"archive_prism":
			return "Chill prism: rotate through crystal lanes"
		"archive_lattice":
			return "Chill lattice spreading underfoot"
		"archive_shards":
			return "Chill shards fan outward"
		"archive_charge":
			return "Chill charge line"
		"archive_slam":
			return "Chill archive slam"
		"void_collapse":
			return "Curse collapse: cross the centerline before lanes close"
		"void_rift_wave":
			return "Cursed rifts spreading underfoot"
		"void_shards":
			return "Cursed shards fan outward"
		"void_charge":
			return "Cursed charge line"
		"void_slam":
			return "Cursed void slam"
	return ""

func _variant_cue_color() -> Color:
	match variant_id:
		"spore_golem":
			return Color(0.56, 1.0, 0.62)
		"forge_golem":
			return Color(1.0, 0.48, 0.24)
		"archive_golem":
			return Color(0.58, 0.9, 1.0)
		"void_golem":
			return Color(0.76, 0.55, 1.0)
	return Color(1.0, 0.86, 0.42)

func _default_bullet_hell_count() -> int:
	match variant_id:
		"spore_golem":
			return 10
		"forge_golem":
			return 12
		"archive_golem":
			return 14
		"void_golem":
			return 14
	return 8

func _variant_trap_kinds() -> Array[String]:
	match variant_id:
		"spore_golem":
			return ["spike", "arrow", "spike", "saw"]
		"forge_golem":
			return ["fire", "saw", "fire", "arrow"]
		"archive_golem":
			return ["arrow", "saw", "spike", "arrow"]
		"void_golem":
			return ["saw", "arrow", "spike", "saw"]
	return ["spike", "fire", "saw", "arrow"]

func spawn_floating_guns(count: int) -> void:
	_floating_guns = _floating_guns.filter(func(gun: Node2D) -> bool:
		return is_instance_valid(gun))
	if _floating_guns.size() >= count:
		return
	var start := _floating_guns.size()
	for i in range(start, count):
		var gun := FloatingGunScript.new()
		gun.configure(self, target, i, count)
		add_child(gun)
		_floating_guns.append(gun)
