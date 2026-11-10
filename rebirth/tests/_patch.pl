use strict;
sub must { my ($ok, $n) = @_; die "fail $n" unless $ok; }
sub slurp { my $f = shift; local $/; open(my $h, "<", $f) or die $f; my $s = <$h>; close $h; return $s; }
sub spit { my ($f, $s) = @_; open(my $h, ">", $f) or die $f; print $h $s; close $h; }
$_ = slurp("src/game.gd");
must(s|const More = preload\("res://src/more.gd"\)|const More = preload("res://src/more.gd")\nconst Touch = preload("res://src/touch.gd")|, "a");
must(s|var allies = \[\]\n|var allies = []\nvar tin = Touch.fresh()\n|, "b");
must(s|\tInput.mouse_mode = Input.MOUSE_MODE_HIDDEN\n|\tInput.mouse_mode = Input.MOUSE_MODE_HIDDEN\n\ttin.on = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")\n|, "c");
must(s|func _input\(ev: InputEvent\) -> void:\n|func _input(ev: InputEvent) -> void:\n\tif ev is InputEventScreenTouch or ev is InputEventScreenDrag:\n\t\tTouch.handle(self, ev)\n\t\treturn\n\tif tin.on and ev is InputEventMouseButton:\n\t\treturn\n|, "d");
must(s|func mouse\(\) -> Vector2:\n\tif sim.has\("mouse"\):\n\t\treturn sim\["mouse"\]\n|func mouse() -> Vector2:\n\tif sim.has("mouse"):\n\t\treturn sim["mouse"]\n\tif tin.on:\n\t\tif state == "play" and not p.is_empty():\n\t\t\treturn pcenter() - cam_tl + p.aim * 80.0\n\t\treturn tin.tap\n|, "e");
must(s|func firing\(\) -> bool:\n|func firing() -> bool:\n\tif tin.on:\n\t\treturn tin.fire\n|, "f");
must(s|\tif mv.length\(\) > 0.0:\n\t\tmv = mv.normalized\(\)\n\tvar mw = mouse\(\) \+ cam_tl\n\tvar aim = mw - pcenter\(\)\n\tif aim.length\(\) > 1.0:\n\t\tp.aim = aim.normalized\(\)\n|\tif mv.length() > 0.0:\n\t\tmv = mv.normalized()\n\tif tin.on:\n\t\tif tin.mv != Vector2.ZERO:\n\t\t\tmv = tin.mv\n\t\tvar td = Touch.aim_dir(self)\n\t\tif td != Vector2.ZERO:\n\t\t\tp.aim = td\n\tvar mw = mouse() + cam_tl\n\tvar aim = mw - pcenter()\n\tif aim.length() > 1.0 and not tin.on:\n\t\tp.aim = aim.normalized()\n|, "g");
must(s|\tif jpk\(KEY_ESCAPE\) or \(jpk\(KEY_E\) and state_t > 0.2\):\n\t\tset_state\("play"\)\n\t\treturn\n|\tif jpk(KEY_ESCAPE) or (jpk(KEY_E) and state_t > 0.2) or (tin.on and jpk("m1") and Rect2(364, 28, 28, 18).has_point(mouse())):\n\t\tset_state("play")\n\t\treturn\n|, "h");
must(s|\t\t"pause":\n\t\t\tif jpk\(KEY_ESCAPE\):\n\t\t\t\tset_state\("play"\)\n\t\t\telif jpk\(KEY_Q\):|\t\t"pause":\n\t\t\tvar tq = tin.on and jpk("m1") and state_t > 0.2\n\t\t\tif jpk(KEY_ESCAPE) or (tq and not Rect2(250, 226, 110, 20).has_point(mouse())):\n\t\t\t\tset_state("play")\n\t\t\telif jpk(KEY_Q) or tq:|, "i");
spit("src/game.gd", $_);
$_ = slurp("src/hud.gd");
must(s|const Meta = preload\("res://src/meta.gd"\)\n|const Meta = preload("res://src/meta.gd")\nconst Touch = preload("res://src/touch.gd")\n|, "j");
must(s|\tvar m = g.mouse\(\).round\(\)\n\tvar cc = Color\("f6f2e6"\)|\tif g.tin.on:\n\t\tTouch.draw(g, ci)\n\t\tif g.state == "menu":\n\t\t\tPx.text(ci, Vector2(374, 37), "X", Color("ff6a6a"))\n\t\treturn\n\tvar m = g.mouse().round()\n\tvar cc = Color("f6f2e6")|, "k");
must(s|\tvar wr = Rect2\(360, 231, 117, 36\)|\tvar wx = 182.0 if g.tin.on else 360.0\n\tvar wr = Rect2(wx, 231, 117, 36)|, "l");
must(s|var orr = Rect2\(430, 211, 47, 18\)|var orr = Rect2(wx + 70, 211, 47, 18)|, "m");
must(s|Vector2\(338, 216\), 1.0\)\n\t\tPx.text\(ci, Vector2\(348, 218\), "\+", DIM\)\n\t\tbig\(ci, Art.T\["ic_" \+ all\[1\]\], Vector2\(355, 216\), 1.0\)\n\t\tPx.text\(ci, Vector2\(367, 218\), info\[0\], info\[1\]\)|Vector2(wx - 22, 216), 1.0)\n\t\tPx.text(ci, Vector2(wx - 12, 218), "+", DIM)\n\t\tbig(ci, Art.T["ic_" + all[1]], Vector2(wx - 5, 216), 1.0)\n\t\tPx.text(ci, Vector2(wx + 7, 218), info[0], info[1])|, "n");
must(s|Px.ctext\(ci, Vector2\(240, 236\), "ESC RESUME      Q " \+ \("QUIT TO TITLE" if g.in_lobby else "ABANDON RUN"\), GOLD\)|if g.tin.on:\n\t\tpanel(ci, Rect2(120, 226, 110, 20), Color(0.1, 0.2, 0.1, 0.95), Color("a6e84e"))\n\t\tPx.ctext(ci, Vector2(175, 233), "RESUME", Color("a6e84e"))\n\t\tpanel(ci, Rect2(250, 226, 110, 20), Color(0.2, 0.08, 0.08, 0.95), Color("ff6a6a"))\n\t\tPx.ctext(ci, Vector2(305, 233), "QUIT TO TITLE" if g.in_lobby else "ABANDON RUN", Color("ff6a6a"))\n\telse:\n\t\tPx.ctext(ci, Vector2(240, 236), "ESC RESUME      Q " + ("QUIT TO TITLE" if g.in_lobby else "ABANDON RUN"), GOLD)|, "o");
spit("src/hud.gd", $_);
print "ok\n";
