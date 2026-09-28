extends Node2D
# Game-owned movement, hit detection and state. Model responses only request an intent.
const FIELD := Rect2(24, 80, 592, 248)
const GATE := Rect2(432, 176, 16, 64)
const PLATE_N := Vector2(320, 136)
const PLATE_S := Vector2(320, 280)
const CORE := Vector2(560, 208)
const EXIT := Vector2(72, 208)
const MODES := ["follow", "hold", "cover", "plate"]
var player := Vector2(88, 208)
var ally := Vector2(120, 228)
var ally_target := ally
var mode := "follow"
var hp := 100.0
var elapsed := 0.0
var cooldown := 0.0
var ally_cooldown := 0.0
var hurt_cooldown := 0.0
var gate_charge := 0.0
var gate_open := false
var carrying := false
var extraction := 0.0
var phase := "playing"
var epoch := 0
var bullets: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var walls: Array[Rect2] = []
var nav := AStarGrid2D.new()
var font: Font
var sprites: Dictionary = {}
var message := "NOVA ready. Two plates. One way out."
var request_status := "OFFLINE / explicit orders"
var request_busy := false
var bridge_url := ""
var http: HTTPRequest
var input_line: LineEdit
var order_buttons: Array[Button] = []
var demo := false
var self_test := false
var aim := Vector2.RIGHT
var last_success := "none"
var wins := 0
var run_id := ""
var touch_vector := Vector2.ZERO
var touch_firing := false
var nav_clock := 0.0
var ally_path: PackedVector2Array = []
var enemy_paths: Array = []

func _ready() -> void:
	font = ThemeDB.fallback_font
	demo = "--demo" in OS.get_cmdline_user_args()
	self_test = "--self-test" in OS.get_cmdline_user_args()
	bridge_url = OS.get_environment("ECHO_AGENT_URL").trim_suffix("/")
	if not bridge_url.is_empty():
		request_status = "OpenGameAgent / connect on Enter"
	if demo:
		request_status = "CAPTURE / offline gameplay rehearsal"
	make_sprites()
	make_ui()
	load_memory()
	reset_game()
	if self_test:
		call_deferred("run_tests")

func reset_game() -> void:
	epoch += 1
	run_id = str(Time.get_unix_time_from_system()) + "-" + str(epoch)
	player = Vector2(88, 208)
	ally = Vector2(120, 228)
	ally_target = ally
	mode = "follow"
	hp = 100.0
	elapsed = 0.0
	cooldown = 0.0
	ally_cooldown = 0.0
	hurt_cooldown = 0.0
	gate_charge = 0.0
	extraction = 0.0
	gate_open = false
	carrying = false
	phase = "playing"
	bullets.clear()
	sparks.clear()
	enemies.clear()
	for pos in [Vector2(216, 112), Vector2(240, 294), Vector2(384, 204), Vector2(506, 132), Vector2(556, 292)]:
		enemies.append({"pos": pos, "hp": 3, "cool": 0.0})
	walls = [Rect2(176, 144, 32, 48), Rect2(176, 240, 32, 48), Rect2(352, 176, 32, 32), Rect2(432, 80, 16, 96), Rect2(432, 240, 16, 88), Rect2(512, 160, 16, 16), Rect2(512, 240, 16, 16)]
	build_nav()
	message = "Last successful order: " + last_success if wins > 0 else "NOVA ready. Order [4] SOUTH PLATE, take NORTH yourself."

func make_ui() -> void:
	var names := ["1 FOLLOW", "2 HOLD", "3 COVER", "4 SOUTH PLATE"]
	for i in range(4):
		var b := Button.new()
		b.text = names[i]
		b.position = Vector2(24 + i * 128, 360)
		b.size = Vector2(120, 28)
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func(): set_order(MODES[i]))
		add_child(b)
		order_buttons.append(b)
	input_line = LineEdit.new()
	input_line.position = Vector2(28, 332)
	input_line.size = Vector2(584, 26)
	input_line.max_length = 240
	input_line.placeholder_text = "Tell NOVA your plan. Enter to send; Escape to cancel."
	input_line.visible = false
	input_line.text_submitted.connect(send_order)
	add_child(input_line)
	http = HTTPRequest.new()
	http.timeout = 18.0
	http.body_size_limit = 16384
	http.request_completed.connect(on_agent_response)
	add_child(http)
	if DisplayServer.is_touchscreen_available():
		for i in range(5):
			var b := Button.new()
			b.text = ["<", ">", "^", "v", "FIRE"][i]
			b.position = Vector2([24, 104, 64, 64, 546][i], [274, 274, 242, 306, 290][i])
			b.size = Vector2(38 if i < 4 else 62, 30)
			if i < 4:
				var d: Vector2 = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][i]
				b.button_down.connect(func(): touch_vector = d)
				b.button_up.connect(func(): touch_vector = Vector2.ZERO)
			else:
				b.button_down.connect(func(): touch_firing = true)
				b.button_up.connect(func(): touch_firing = false)
			add_child(b)

func _unhandled_key_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	if e.keycode == KEY_ESCAPE:
		input_line.visible = false
		input_line.release_focus()
		return
	if input_line.has_focus():
		return
	if e.keycode == KEY_R and not request_busy:
		reset_game()
	if request_busy:
		return
	if e.keycode >= KEY_1 and e.keycode <= KEY_4:
		set_order(MODES[e.keycode - KEY_1])
	if e.keycode == KEY_ENTER:
		input_line.visible = true
		input_line.grab_focus()
	if e.keycode == KEY_E:
		pickup()

func set_order(value: String) -> bool:
	if value not in MODES or phase != "playing" or request_busy:
		return false
	mode = value
	ally_target = ally if value == "hold" else PLATE_S
	ally_path.clear()
	message = {"follow":"NOVA: On your six.", "hold":"NOVA: Holding this position.", "cover":"NOVA: Push forward. I will cover you.", "plate":"NOVA: Taking the south pressure plate."}[value]
	return true

func send_order(text: String) -> void:
	input_line.visible = false
	input_line.release_focus()
	if request_busy or phase != "playing":
		return
	if bridge_url.is_empty():
		message = "No model connected. Use 1-4: offline orders, not language AI."
		return
	request_busy = true
	request_status = "OpenGameAgent / reasoning (world paused)"
	var payload := {"request":text, "epoch":epoch, "run_id":run_id, "world":snapshot()}
	var err := http.request(bridge_url + "/decide", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		request_busy = false
		request_status = "Agent unavailable / explicit orders still work"
		message = "Could not connect. No action applied."

func on_agent_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	request_busy = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		request_status = "Agent request failed / no action applied"
		return
	var response: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not response is Dictionary or response.get("epoch", -1) != epoch or response.get("run_id", "") != run_id or str(response.get("mode", "")) not in MODES:
		request_status = "Rejected stale or invalid agent intent"
		return
	if set_order(str(response.mode)):
		request_status = "OpenGameAgent / intent accepted"
		message = "NOVA: " + str(response.get("reason", mode)).left(90)

func snapshot() -> Dictionary:
	return {"player":{"x":player.x,"y":player.y,"hp":hp},"ally":{"x":ally.x,"y":ally.y,"mode":mode},"north_plate":{"x":320,"y":136},"south_plate":{"x":320,"y":280},"gate_open":gate_open,"carrying_core":carrying,"enemies":enemies.size(),"last_successful_order":last_success,"objective":"Hold both plates, recover the core, return to extraction."}

func build_nav() -> void:
	nav.region = Rect2i(0, 0, 40, 25)
	nav.cell_size = Vector2(16, 16)
	nav.offset = Vector2(8, 8)
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav.update()
	for y in range(25):
		for x in range(40):
			nav.set_point_solid(Vector2i(x, y), blocked(Vector2(x * 16 + 8, y * 16 + 8), 6))

func blocked(p: Vector2, radius: float = 6.0) -> bool:
	if not FIELD.grow(-radius).has_point(p):
		return true
	for w in walls:
		if w.grow(radius).has_point(p):
			return true
	return not gate_open and GATE.grow(radius).has_point(p)

func move_actor(p: Vector2, direction: Vector2, speed: float, dt: float) -> Vector2:
	var d := direction.normalized() * speed * dt
	if not blocked(p + Vector2(d.x, 0)):
		p.x += d.x
	if not blocked(p + Vector2(0, d.y)):
		p.y += d.y
	return p

func toward(p: Vector2, target: Vector2) -> Vector2:
	if p.distance_to(target) < 4:
		return Vector2.ZERO
	var start := Vector2i(p / 16)
	var end := Vector2i(target / 16)
	if not nav.is_in_boundsv(start) or not nav.is_in_boundsv(end) or nav.is_point_solid(end):
		return Vector2.ZERO
	var route := nav.get_point_path(start, end)
	return (route[1] if route.size() > 1 else target) - p

func pickup() -> void:
	if gate_open and not carrying and player.distance_to(CORE) < 24 and phase == "playing":
		carrying = true
		message = "CORE SECURED. Regroup with NOVA and return to extraction."
		burst(CORE, Color("ffe8a3"), 20)

func _process(dt: float) -> void:
	queue_redraw()
	if self_test:
		return
	for i in range(order_buttons.size()):
		order_buttons[i].modulate = Color("bdf578") if mode == MODES[i] else Color.WHITE
	if phase != "playing" or input_line.has_focus() or request_busy:
		return
	dt = minf(dt, 0.05)
	elapsed += dt
	cooldown -= dt
	ally_cooldown -= dt
	hurt_cooldown -= dt
	var direction := touch_vector
	if demo:
		if elapsed > 1 and mode == "follow" and not gate_open:
			set_order("plate")
		var target: Vector2 = PLATE_N if not gate_open else CORE if not carrying else EXIT
		direction = toward(player, target)
		pickup()
		if carrying and mode != "follow":
			set_order("follow")
	else:
		direction += Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	player = move_actor(player, direction, 76 if not carrying else 66, dt)
	if DisplayServer.is_touchscreen_available():
		pickup()
	if direction.length() > 0.1:
		aim = direction.normalized()
	var target_pos := player + Vector2(-22, 18) if mode == "follow" else player + Vector2(-40, 0) if mode == "cover" else ally_target
	if blocked(target_pos):
		target_pos = player
	ally = move_actor(ally, toward(ally, target_pos), 90, dt)
	if demo or touch_firing or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if cooldown <= 0:
			var shot_dir := nearest_enemy(player) - player if demo or touch_firing else get_global_mouse_position() - player
			if Input.is_physical_key_pressed(KEY_SPACE) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				shot_dir = nearest_enemy(player) - player
			shoot(player, shot_dir, false)
			cooldown = 0.20
	if ally_cooldown <= 0 and not enemies.is_empty():
		var target := nearest_enemy(ally)
		if ally.distance_to(target) < 190:
			shoot(ally, target - ally, true)
			ally_cooldown = 0.50
	for enemy in enemies:
		var pos: Vector2 = enemy.pos
		enemy.pos = move_actor(pos, toward(pos, player), 27, dt)
		if player.distance_to(enemy.pos) < 14 and hurt_cooldown <= 0:
			hp -= 12
			hurt_cooldown = 0.75
			burst(player, Color("ff8c84"), 8)
	for b in bullets:
		b.pos += b.vel * dt
		b.life -= dt
		if blocked(b.pos, 1):
			b.life = -1
			burst(b.pos, Color("ecb266"), 3)
		for enemy in enemies:
			if b.life > 0 and b.pos.distance_to(enemy.pos) < 10:
				enemy.hp -= 1
				b.life = -1
				burst(b.pos, Color("ffac89"), 5)
	bullets = bullets.filter(func(b): return b.life > 0)
	enemies = enemies.filter(func(e): return e.hp > 0)
	for s in sparks:
		s.pos += s.vel * dt
		s.life -= dt
	sparks = sparks.filter(func(s): return s.life > 0)
	var north := minf(player.distance_to(PLATE_N), ally.distance_to(PLATE_N)) < 17
	var south := minf(player.distance_to(PLATE_S), ally.distance_to(PLATE_S)) < 17
	if north and south and not gate_open:
		gate_charge += dt
		if gate_charge >= 1.2:
			gate_open = true
			build_nav()
			message = "LINK COMPLETE. Gate open. Recover the core [E]."
			burst(GATE.get_center(), Color("94f7dc"), 24)
	elif not gate_open:
		gate_charge = 0.0
	if carrying and player.distance_to(EXIT) < 25 and ally.distance_to(EXIT) < 45:
		extraction += dt
		if extraction > 1.5:
			phase = "won"
			last_success = "plate"
			wins += 1
			if not demo:
				save_memory()
			print("ECHO_WIN seconds=", snapped(elapsed, .01), " hp=", hp)
	else:
		extraction = 0
	if hp <= 0 or elapsed >= 150:
		phase = "lost"

func nearest_enemy(p: Vector2) -> Vector2:
	var result := p + aim * 100
	var best := INF
	for e in enemies:
		var d: float = p.distance_squared_to(e.pos)
		if d < best:
			best = d
			result = e.pos
	return result

func shoot(p: Vector2, d: Vector2, friendly: bool) -> void:
	if bullets.size() < 64 and d.length() > 0:
		bullets.append({"pos":p + d.normalized() * 9,"vel":d.normalized() * 270,"life":1.1,"friendly":friendly})

func burst(p: Vector2, c: Color, amount: int) -> void:
	for i in range(amount):
		if sparks.size() < 160:
			sparks.append({"pos":p,"vel":Vector2.from_angle(float(i) * 2.4) * (12 + i * 3),"life":.4,"color":c})

func save_memory() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("squad", "wins", wins)
	cfg.set_value("squad", "last_order", last_success)
	cfg.save("user://echo-memory.cfg")

func load_memory() -> void:
	if demo or self_test:
		return
	var cfg := ConfigFile.new()
	if cfg.load("user://echo-memory.cfg") == OK:
		wins = clampi(int(cfg.get_value("squad", "wins", 0)), 0, 99999)
		last_success = str(cfg.get_value("squad", "last_order", "none")).left(24)

func make_sprites() -> void:
	var pattern := ["................",".....oooooo.....","....oooooooo....","....oHHHHHHo....","...ooHHHHHHoo...","...oHHEEEEHHo...","....oHHHHHHo....",".....oooooo.....","....oBBBBBBo....","...oBBBBBBBBo...","...oBBoBBoBBo...","....oBBBBBBo....",".....oBBoBBo....",".....ooooooo....",".....oo..oo.....","................"]
	for key in ["player", "ally", "enemy"]:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		var armor := Color("e9bc74") if key == "player" else Color("70dbbc") if key == "ally" else Color("c06485")
		for y in range(16):
			for x in range(16):
				var c: String = pattern[y][x]
				var color := Color.TRANSPARENT
				if c == "o": color = Color("131c2c")
				if c == "H": color = armor.lightened(.18)
				if c == "B": color = armor.darkened(.18)
				if c == "E": color = Color("26394b") if key != "enemy" else Color("ffdae2")
				img.set_pixel(x, y, color)
		sprites[key] = ImageTexture.create_from_image(img)

func label_at(text: String, p: Vector2, color: Color = Color("dce6e8"), size: int = 14) -> void:
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 400), Color("0b1220"))
	for y in range(5, 21):
		for x in range(1, 39):
			var color := Color("202d3b") if (x * 3 + y * 7) % 4 else Color("233341")
			draw_rect(Rect2(x * 16, y * 16, 15, 15), color)
			if (x * 11 + y * 13) % 19 == 0:
				draw_rect(Rect2(x * 16 + 3, y * 16 + 11, 4, 1), Color("3b4b52"))
	draw_rect(FIELD, Color("486471"), false, 2)
	for w in walls:
		draw_rect(Rect2(w.position + Vector2(3, 4), w.size), Color("121b28"))
		draw_rect(w, Color("3d4d60"))
		draw_rect(Rect2(w.position, Vector2(w.size.x, 3)), Color("677b8b"))
		for y in range(int(w.position.y) + 14, int(w.end.y), 16):
			draw_line(Vector2(w.position.x, y), Vector2(w.end.x, y), Color("273445"), 2)
	for plate in [PLATE_N, PLATE_S]:
		var on: bool = minf(player.distance_to(plate), ally.distance_to(plate)) < 17
		draw_rect(Rect2(plate - Vector2(14, 14), Vector2(28, 28)), Color("1d514a") if on else Color("334253"))
		draw_rect(Rect2(plate - Vector2(10, 10), Vector2(20, 20)), Color("83e8b7") if on else Color("8296a3"), false, 2)
	label_at("A", PLATE_N + Vector2(-4, -19), Color("85a6ab"), 11)
	label_at("B", PLATE_S + Vector2(-4, 28), Color("85a6ab"), 11)
	if not gate_open:
		for y in range(176, 240, 8):
			draw_rect(Rect2(433, y, 14, 4), Color("ee7d83"))
		draw_rect(Rect2(424, 162, 32 * clampf(gate_charge / 1.2, 0, 1), 3), Color("75ebbf"))
	else:
		draw_rect(Rect2(432, 174, 16, 3), Color("75ebbf"))
		draw_rect(Rect2(432, 240, 16, 3), Color("75ebbf"))
	draw_rect(Rect2(EXIT - Vector2(20, 20), Vector2(40, 40)), Color("385a59"), false, 2)
	label_at("EXTRACT", EXIT + Vector2(-24, 34), Color("83c6bf"), 10)
	if not carrying:
		draw_rect(Rect2(CORE - Vector2(10, 12), Vector2(20, 24)), Color("916537"))
		draw_rect(Rect2(CORE - Vector2(6, 8), Vector2(12, 16)), Color("ffe3a1"))
		label_at("CORE", CORE + Vector2(-14, 29), Color("e9c87d"), 10)
	for e in enemies:
		draw_rect(Rect2(e.pos + Vector2(-7, 5), Vector2(14, 4)), Color("111c27"))
		draw_texture(sprites.enemy, (e.pos - Vector2(8, 12)).round())
		draw_rect(Rect2(e.pos + Vector2(-6, -16), Vector2(4 * e.hp, 2)), Color("d47b99"))
	for data in [[player, "player"], [ally, "ally"]]:
		draw_rect(Rect2(data[0] + Vector2(-7, 5), Vector2(14, 4)), Color("111c27"))
		draw_texture(sprites[data[1]], (data[0] - Vector2(8, 12)).round())
	label_at("YOU", player + Vector2(-9, -17), Color("f6d79f"), 9)
	label_at("NOVA", ally + Vector2(-13, -17), Color("89ecd1"), 9)
	if carrying:
		draw_rect(Rect2(player + Vector2(-3, -25), Vector2(6, 7)), Color("ffe3a1"))
	for b in bullets:
		draw_rect(Rect2(b.pos, Vector2(4, 2)), Color("8dffde") if b.friendly else Color("ffe3a1"))
	for s in sparks:
		draw_rect(Rect2(s.pos.round(), Vector2(2, 2)), s.color)
	label_at("ECHO / SQUAD", Vector2(24, 28), Color("d4f0cf"), 23)
	label_at("01   THE RELAY VAULT", Vector2(26, 48), Color("819eaa"), 11)
	label_at("HP", Vector2(450, 26), Color("9caeba"), 11)
	draw_rect(Rect2(474, 16, 100, 8), Color("2c3448"))
	draw_rect(Rect2(474, 16, maxf(hp, 0), 8), Color("d3eb9b") if hp > 30 else Color("ef7c87"))
	label_at(str(int(150 - elapsed)) + "s", Vector2(582, 26), Color("d5dca9"), 12)
	label_at(request_status, Vector2(24, 66), Color("70bcaa"), 11)
	var objective := "01 / HOLD BOTH PLATES" if not gate_open else "02 / RECOVER CORE [E]" if not carrying else "03 / EXTRACT TOGETHER"
	label_at(objective, Vector2(352, 63), Color("e9c784"), 12)
	label_at(message, Vector2(24, 349), Color("ccd9dc"), 11)
	label_at("WASD move / mouse shoot / SPACE auto-aim / E collect / ENTER talk / R retry", Vector2(24, 396), Color("81949f"), 10)
	if phase != "playing":
		draw_rect(Rect2(100, 134, 440, 138), Color("0c1421f0"))
		label_at("BETTER TOGETHER." if phase == "won" else "ONE MORE RUN.", Vector2(142, 181), Color("d3eea4"), 28)
		label_at("Core recovered. NOVA made it home." if phase == "won" else "Stay close, use cover, try another order.", Vector2(144, 212), Color("aabec6"), 14)
		label_at("[R] PLAY AGAIN  /  Powered by OpenGameAgent", Vector2(144, 245), Color("85bdb4"), 12)
	if request_busy:
		label_at("NOVA IS THINKING...", Vector2(225, 190), Color("d3efaa"), 18)

func run_tests() -> void:
	var errors := 0
	if set_order("teleport"): errors += 1
	if not set_order("plate") or mode != "plate": errors += 1
	if not blocked(GATE.get_center()): errors += 1
	gate_open = true
	build_nav()
	if blocked(GATE.get_center()): errors += 1
	player = CORE
	pickup()
	if not carrying: errors += 1
	var current_epoch := epoch
	reset_game()
	if epoch <= current_epoch or carrying or gate_open or hp != 100: errors += 1
	on_agent_response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), JSON.stringify({"mode":"plate","epoch":epoch - 1,"run_id":run_id}).to_utf8_buffer())
	if mode != "follow": errors += 1
	var p := Vector2(425, 208)
	if move_actor(p, Vector2.RIGHT, 100, .1).x > 426: errors += 1
	print("ECHO_TESTS ", "PASS" if errors == 0 else "FAIL", " errors=", errors)
	get_tree().quit(errors)
