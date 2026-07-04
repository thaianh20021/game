class_name BossGolem
extends Enemy
## Floor boss "Golem Thuc Tinh" (GDD boss #1), three phases by HP:
##   P1 (>66%): slow chase + telegraphed close-range smash
##   P2 (>33%): keeps mid distance, throws 3-rock volleys
##   P3:        repeated telegraphed rolling charges
## All attacks are telegraphed (GDD hard rule: every hit is readable).

var phase := 1


func _behave(delta: float) -> void:
	_update_phase()
	var mult := _speed_mult()
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
							target.take_damage(contact_damage)
						_attack_cd = 1.6
				_:
					velocity = to_target.normalized() * speed * 0.8 * mult
					if to_target.length() <= 44.0 and _attack_cd <= 0.0:
						_state = "telegraph"
						_state_timer = 0.6
						_show_telegraph_fx(to_target.normalized(), 52.0, _state_timer)
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
				for i in 3:
					var dir := to_target.normalized().rotated(deg_to_rad(-14.0 + 14.0 * i))
					_shoot(dir, 150.0, maxi(contact_damage - 4, 4), 260.0)
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
	move_and_slide()


func _update_phase() -> void:
	var ratio := float(hp) / float(max_hp)
	var new_phase := 1
	if ratio <= 0.33:
		new_phase = 3
	elif ratio <= 0.66:
		new_phase = 2
	if new_phase != phase:
		phase = new_phase
		_state = "chase"
		_attack_cd = 1.0
		print("Boss phase %d!" % phase)
