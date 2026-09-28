extends Node2D
# Original dark-cultivation scenario. Godot owns every consequence and memory gate.
const AREA := Rect2(24, 104, 912, 336)
const HERBALIST := Vector2(224, 224)
const CLERK := Vector2(416, 320)
const LEDGER := Vector2(624, 160)
const FURNACE := Vector2(704, 320)
const EXIT := Vector2(880, 256)
const WATCH := Vector2(680, 232)
const MODES := ["follow", "hold", "cover", "scout"]
const MEMORY_NAMES := {"ash":"甜灰入喉", "seal":"归炉之印", "names":"活人名册"}
const MEMORY_TEXT := {"ash":"那颗丹药的甜味来自引魂灰。试药，才有第二条路。", "seal":"出门即归炉。契纸背面藏着回收印，先拓契底再按印。", "names":"炉上没有妖魔的名字。只有你、阿砚，和这一年的弟子。"}
var player := Vector2(96, 320)
var ally := Vector2(120, 344)
var ally_target := ally
var mode := "follow"
var lives := 4
var life_no := 1
var hp := 100.0
var elapsed := 0.0
var lifetime := 0.0
var phase := "playing"
var stage := 0
var signed := false
var seal_broken := false
var gate_open := false
var rescue := true
var seen_ledger := false
var selected := ""
var learned: Array[String] = []
var death_reason := ""
var ending := ""
var message := "药房招呼你领丹。先看清代价，再按下选项。"
var modal_kind := ""
var panel: Panel
var title_label: Label
var body_label: Label
var choice_buttons: Array[Button] = []
var controls: Array[Button] = []
var font: Font
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var walls: Array[Rect2] = []
var nav := AStarGrid2D.new()
var cooldown := 0.0
var ally_cooldown := 0.0
var hurt_cooldown := 0.0
var extract_time := 0.0
var sprites: Dictionary = {}
var demo := false
var self_test := false
var demo_step := 0
var demo_next := 0.0
var epoch := 0
var run_id := ""
var request_busy := false
var agent_status := "离线明确指令"
var bridge_url := ""
var http: HTTPRequest
var input_line: LineEdit
var touch_vector := Vector2.ZERO
var touch_fire := false

func _ready() -> void:
	font = load("res://AshLedgerUI.otf")
	demo = "--demo" in OS.get_cmdline_user_args()
	self_test = "--self-test" in OS.get_cmdline_user_args()
	bridge_url = OS.get_environment("ASH_AGENT_URL").trim_suffix("/")
	if demo: agent_status = "实机演练 · 离线规则"
	elif not bridge_url.is_empty(): agent_status = "OpenGameAgent · 回车交谈"
	make_sprites()
	make_ui()
	load_memory()
	reset_life()
	if self_test: call_deferred("run_tests")

func reset_life() -> void:
	epoch += 1
	run_id = str(Time.get_unix_time_from_system()) + "-" + str(epoch)
	player = Vector2(96, 320)
	ally = Vector2(120, 344)
	ally_target = ally
	mode = "follow"
	hp = 100.0
	elapsed = 0.0
	cooldown = 0.0
	ally_cooldown = 0.0
	hurt_cooldown = 0.0
	extract_time = 0.0
	stage = 0
	signed = false
	seal_broken = false
	gate_open = false
	seen_ledger = false
	rescue = true
	phase = "playing"
	enemies.clear()
	bullets.clear()
	sparks.clear()
	close_modal()
	walls = [Rect2(304, 104, 32, 80), Rect2(304, 360, 32, 80), Rect2(528, 248, 32, 64), Rect2(784, 104, 24, 96), Rect2(784, 320, 24, 120)]
	nav.region = Rect2i(0, 0, 60, 38)
	nav.cell_size = Vector2(16, 16)
	nav.offset = Vector2(8, 8)
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav.update()
	for y in range(38):
		for x in range(60): nav.set_point_solid(Vector2i(x, y), blocked(Vector2(x * 16 + 8, y * 16 + 8)))
	message = "第 %d 世。带入记忆：%s。" % [life_no, MEMORY_NAMES.get(selected, "无 · 可按 M 查看背包")]

func style_box(bg: String, border: String) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(bg)
	s.border_color = Color(border)
	s.set_border_width_all(2)
	s.content_margin_left = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func button(text: String, pos: Vector2, size: Vector2, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_stylebox_override("normal", style_box("202a2b", "57615b"))
	b.add_theme_stylebox_override("hover", style_box("3e3830", "d9ad72"))
	b.pressed.connect(callback)
	return b

func make_ui() -> void:
	for i in range(4):
		var b := button(["1 跟随", "2 留守", "3 掩护", "4 望风"][i], Vector2(24 + i * 128, 542), Vector2(118, 36), func(): set_order(MODES[i]))
		add_child(b);controls.append(b)
	add_child(button("E 交互", Vector2(554, 542), Vector2(116, 36), interact))
	add_child(button("M 记忆背包", Vector2(686, 542), Vector2(178, 36), open_memory))
	input_line = LineEdit.new()
	input_line.position = Vector2(40, 480)
	input_line.size = Vector2(880, 44)
	input_line.add_theme_font_override("font", font)
	input_line.add_theme_font_size_override("font_size", 19)
	input_line.max_length = 240
	input_line.placeholder_text = "告诉阿砚你的计划。回车发送；Esc 取消。"
	input_line.visible = false
	input_line.text_submitted.connect(send_order)
	add_child(input_line)
	http = HTTPRequest.new();http.timeout = 18;http.body_size_limit = 16384
	http.request_completed.connect(on_agent_response);add_child(http)
	panel = Panel.new();panel.position = Vector2(152, 108);panel.size = Vector2(656, 392)
	panel.add_theme_stylebox_override("panel", style_box("151c23", "b69366"))
	panel.z_index = 20
	add_child(panel)
	title_label = Label.new();title_label.position = Vector2(26, 20);title_label.size = Vector2(604, 40)
	title_label.add_theme_font_override("font", font);title_label.add_theme_font_size_override("font_size", 27);title_label.modulate = Color("edcf98");panel.add_child(title_label)
	body_label = Label.new();body_label.position = Vector2(26, 72);body_label.size = Vector2(602, 134)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;body_label.add_theme_font_override("font", font);body_label.add_theme_font_size_override("font_size", 19);body_label.modulate = Color("c5d0cd");panel.add_child(body_label)
	for i in range(4):
		var b := button("", Vector2(26, 214 + i * 42), Vector2(604, 37), func(): choose(i))
		panel.add_child(b);choice_buttons.append(b)
	panel.visible = false
	if DisplayServer.is_touchscreen_available():
		for i in range(5):
			var b := button(["←", "→", "↑", "↓", "符"][i], Vector2([34, 146, 90, 90, 866][i], [358, 358, 302, 414, 382][i]), Vector2(52, 48), func(): pass)
			if i < 4:
				var d: Vector2 = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][i]
				b.button_down.connect(func(): touch_vector = d);b.button_up.connect(func(): touch_vector = Vector2.ZERO)
			else:
				b.button_down.connect(func(): touch_fire = true);b.button_up.connect(func(): touch_fire = false)
			add_child(b)

func show_modal(kind: String, heading: String, body: String, options: Array, disabled: Array = []) -> void:
	modal_kind = kind;title_label.text = heading;body_label.text = body;panel.visible = true
	for i in range(4):
		choice_buttons[i].visible = i < options.size()
		choice_buttons[i].disabled = i in disabled
		if i < options.size(): choice_buttons[i].text = str(i + 1) + "  " + str(options[i])

func close_modal() -> void:
	modal_kind = ""
	if panel: panel.visible = false

func unlock(key: String) -> void:
	if key in MEMORY_NAMES and key not in learned:
		learned.append(key);save_memory()
		print("ASH_MEMORY_UNLOCK ", key)

func die(reason: String, memory: String = "") -> void:
	if phase != "playing": return
	if not memory.is_empty(): unlock(memory)
	lives -= 1;phase = "dead";death_reason = reason
	print("ASH_DEATH life=", life_no, " remaining=", lives, " cause=", memory)
	show_death()

func show_death() -> void:
	var options: Array = []
	for key in learned: options.append(("已选 · " if selected == key else "带入 · ") + MEMORY_NAMES[key])
	options.append("重开下一世（剩余 %d 次）" % lives if lives > 0 else "命数已尽 · 开始新一轮")
	show_modal("death", "这一世，到此为止。", death_reason + "\n记忆不会自动生效。先选一枚碎片，再重开。", options)

func open_memory() -> void:
	if request_busy or phase != "playing": return
	var options: Array = []
	for key in learned: options.append(("已装配 · " if selected == key else "装配 · ") + MEMORY_NAMES[key])
	options.append("回到庭院")
	show_modal("memory", "记忆背包 / 一枚生效", "已知的事，不等于正在用的事。\n选择碎片可回看内容，并解锁对应交互选项。", options)

func equip(key: String) -> bool:
	if key not in learned: return false
	selected = key;save_memory();print("ASH_MEMORY_EQUIP ", key)
	return true

func choose(index: int) -> void:
	if index < 0 or index >= choice_buttons.size() or not choice_buttons[index].visible or choice_buttons[index].disabled: return
	var kind := modal_kind
	if kind == "death" or kind == "memory":
		if index < learned.size():
			equip(learned[index])
			if kind == "death": show_death()
			else:
				open_memory();body_label.text = MEMORY_TEXT[selected] + "\n已装配，回到场景主动使用。"
		else:
			if kind == "death":
				if lives <= 0: lives = 4;life_no = 0
				life_no += 1;reset_life()
			else: close_modal()
		return
	close_modal()
	match kind:
		"herb":
			if index == 0: die("你吞下赠丹，灵脉像一截点燃的灯芯。\n临死才闻见甜灰：所谓赠药，是替炉火试引。", "ash")
			elif index == 1:
				stage = 1;message = "你用银针挑出引魂灰。药师收起笑容，让你去契房。"
			else: stage = 1;message = "你谢绝赠丹。执事的目光停在你身上：去契房领出门牌。"
		"contract":
			stage = 2
			if index == 0: signed = true;message = "出门牌到手。契纸背面的印，仍在发烫。"
			elif index == 1: seal_broken = true;message = "你拓出回收印，划去归炉条款。东院的名册还在等你。"
			else: message = "不按印，就没有通行牌。你决定先查东院。"
		"ledger":
			unlock("names");seen_ledger = true;stage = 3;message = "记忆已得【活人名册】。按 M 主动装配，再去炼炉。"
		"furnace":
			if index < 2 and selected == "names" and "names" in learned:
				rescue = index == 0;hp -= 25 if rescue else 10;gate_open = true;signed = false;stage = 4
				if not rescue: mode = "hold";ally_target = ally
				for p in [Vector2(592, 368), Vector2(752, 384), Vector2(832, 160)]: enemies.append({"pos":p,"hp":3})
				burst(FURNACE, Color("e4aa65"), 35)
				message = "名册已焚！符刃驱散追魂影，带阿砚从东门离开。" if rescue else "你只划掉自己的名字。阿砚留在炉边，东门为你打开。"
				print("ASH_LEDGER_BURN rescue=", rescue)
		"exit":
			if index == 0 and signed: die("你捏碎通行牌，脚下却亮起归炉印。\n所谓离宗手续，原来是炼炉的回收凭据。", "seal")
		"ending":
			lives = 4;life_no = 1;reset_life()

func interact() -> void:
	if phase != "playing" or request_busy or not modal_kind.is_empty(): return
	if player.distance_to(HERBALIST) < 68 and stage == 0:
		show_modal("herb", "第一层 / 药师的好意", "药师笑道：新来的，领一枚暖脉丹。\n丹衣上有甜味，炉口也有。", ["接过吞下", "用银针试药（记忆：甜灰入喉）", "谢绝赠丹，去契房"], [1] if selected != "ash" else [])
	elif player.distance_to(CLERK) < 68 and stage <= 2:
		if stage == 0: message = "先去西侧药房报到。";return
		show_modal("contract", "第二层 / 出门的价钱", "执事递来一张契纸：按个印，就能领出门牌。\n阿砚低声说：纸背的纹路，我见过。", ["按印领牌", "拓出契底，划去归炉条款（记忆：归炉之印）", "先不签，去东院查名册"], [1] if selected != "seal" else [])
	elif player.distance_to(LEDGER) < 64:
		show_modal("ledger", "第三层 / 谁才是炉材", "你翻开名册。收货栏写的不是灵石。\n是你的名字，也是阿砚的名字。\n原来这次招徒，只是炼炉缺了一批耗材。", ["收下记忆碎片【活人名册】"])
	elif player.distance_to(FURNACE) < 70 and not gate_open:
		show_modal("furnace", "破局 / 划掉谁的名字", "装配【活人名册】后，你能看见炉契的落款。\n焚册可以救两人，却会烧去你的气血。\n只删自己的名字，代价更轻。", ["焚册，带阿砚一起走（气血 -25）", "只划掉我（气血 -10，留下阿砚）", "先离开，按 M 查看记忆"], [0, 1] if selected != "names" else [])
	elif player.distance_to(EXIT) < 64 and not gate_open:
		if signed: show_modal("exit", "东门 / 一张通行牌", "门外没有巡守，掌心的印却越来越烫。\n你要捏碎通行牌吗？", ["使用通行牌", "先退回，检查东院"])
		else: message = "东门受炉契束缚。查看东院名册，找到真正的出路。"
	else: message = "靠近药房、契房、名册或炼炉后按 E。M 可回看并装配记忆。"

func _unhandled_key_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo): return
	if e.keycode == KEY_ESCAPE:
		if phase == "playing": close_modal()
		input_line.visible = false;input_line.release_focus();return
	if input_line.has_focus(): return
	if request_busy: return
	if not modal_kind.is_empty():
		if e.keycode >= KEY_1 and e.keycode <= KEY_4: choose(e.keycode - KEY_1)
		return
	if e.keycode == KEY_M: open_memory()
	if e.keycode == KEY_E: interact()
	if e.keycode >= KEY_1 and e.keycode <= KEY_4: set_order(MODES[e.keycode - KEY_1])
	if e.keycode == KEY_ENTER and phase == "playing": input_line.visible = true;input_line.grab_focus()

func set_order(value: String) -> bool:
	if value not in MODES or phase != "playing" or request_busy or (not rescue and gate_open): return false
	mode = value;ally_target = ally if value == "hold" else WATCH
	message = {"follow":"阿砚：你走，我跟着。", "hold":"阿砚：我守这里。", "cover":"阿砚：后面交给我。", "scout":"阿砚：我去炉前望风，你查名册。"}[value]
	return true

func snapshot() -> Dictionary:
	var active_memory: Dictionary = {}
	if selected in MEMORY_NAMES: active_memory = {"id":selected,"text":MEMORY_TEXT[selected]}
	return {"game":"Ash Ledger", "player":{"x":player.x,"y":player.y,"hp":hp}, "ally":{"x":ally.x,"y":ally.y,"mode":mode}, "stage":stage,"gate_open":gate_open,"remaining_lives":lives,"equipped_memory":active_memory,"rescue_ally":rescue,"enemies":enemies.size(),"objective":"Investigate the ledger, actively equip its memory, break the furnace contract, escape."}

func send_order(text: String) -> void:
	input_line.visible = false;input_line.release_focus()
	if request_busy or phase != "playing" or not modal_kind.is_empty(): return
	if bridge_url.is_empty(): message = "未连接语言模型。1–4 是明确指令；模型版需连接本地侧车。";return
	request_busy = true;agent_status = "OpenGameAgent · 思考中，世界暂停"
	var payload := {"request":text,"epoch":epoch,"run_id":run_id,"world":snapshot()}
	var error := http.request(bridge_url + "/decide", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK: request_busy = false;agent_status = "连接失败 · 未应用动作"

func on_agent_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	request_busy = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200: agent_status = "请求失败 · 未应用动作";return
	var response: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not response is Dictionary or response.get("epoch", -1) != epoch or response.get("run_id", "") != run_id or str(response.get("mode", "")) not in MODES:
		agent_status = "拒绝失效或非法意图";return
	if set_order(str(response.mode)): agent_status = "OpenGameAgent · 意图已接受"

func blocked(p: Vector2, radius: float = 7) -> bool:
	if not AREA.grow(-radius).has_point(p): return true
	for w in walls:
		if w.grow(radius).has_point(p): return true
	return false

func move_actor(p: Vector2, d: Vector2, speed: float, dt: float) -> Vector2:
	var step := d.normalized() * speed * dt
	if not blocked(p + Vector2(step.x, 0)): p.x += step.x
	if not blocked(p + Vector2(0, step.y)): p.y += step.y
	return p

func toward(p: Vector2, target: Vector2) -> Vector2:
	if p.distance_to(target) < 4: return Vector2.ZERO
	var a := Vector2i(p / 16);var b := Vector2i(target / 16)
	if not nav.is_in_boundsv(a) or not nav.is_in_boundsv(b) or nav.is_point_solid(b): return Vector2.ZERO
	var path := nav.get_point_path(a, b)
	return (path[1] if path.size() > 1 else target) - p

func _process(dt: float) -> void:
	queue_redraw()
	if self_test: return
	dt = minf(dt, .05);lifetime += dt
	if demo: demo_tick()
	for i in range(controls.size()): controls[i].modulate = Color("e6c18c") if MODES[i] == mode else Color.WHITE
	if phase != "playing" or not modal_kind.is_empty() or request_busy or input_line.has_focus(): return
	elapsed += dt;cooldown -= dt;ally_cooldown -= dt;hurt_cooldown -= dt
	var direction := touch_vector
	if demo: direction = toward(player, demo_target())
	else: direction += Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	player = move_actor(player, direction, 132, dt)
	var target := player + Vector2(-26, 20) if mode == "follow" else player + Vector2(-50, 12) if mode == "cover" else ally_target
	if blocked(target): target = player
	ally = move_actor(ally, toward(ally, target), 152, dt)
	if not enemies.is_empty():
		if cooldown <= 0 and (demo or touch_fire or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			shoot(player, nearest_enemy(player) - player);cooldown = .23
		if ally_cooldown <= 0 and rescue:
			shoot(ally, nearest_enemy(ally) - ally);ally_cooldown = .42
	for enemy in enemies:
		enemy.pos = move_actor(enemy.pos, toward(enemy.pos, player), 42, dt)
		if player.distance_to(enemy.pos) < 19 and hurt_cooldown <= 0: hp -= 12;hurt_cooldown = .75;burst(player, Color("c77779"), 8)
	for b in bullets:
		b.pos += b.vel * dt;b.life -= dt
		if blocked(b.pos, 1): b.life = -1
		for enemy in enemies:
			if b.life > 0 and b.pos.distance_to(enemy.pos) < 15: enemy.hp -= 1;b.life = -1;burst(b.pos, Color("d9ba7b"), 6)
	bullets = bullets.filter(func(b): return b.life > 0);enemies = enemies.filter(func(e): return e.hp > 0)
	for p in sparks: p.pos += p.vel * dt;p.life -= dt
	sparks = sparks.filter(func(p): return p.life > 0)
	if gate_open and player.distance_to(EXIT) < 30 and (not rescue or ally.distance_to(EXIT) < 64):
		extract_time += dt
		if extract_time > 1:
			phase = "won";ending = "两人余生" if rescue else "独自余生"
			print("ASH_WIN time=", snapped(lifetime,.01), " life=",life_no," lives=",lives," hp=",hp," ending=",ending)
			show_modal("ending", "余生 / " + ending, "你没有变强，只是终于看懂了规矩。\n" + ("你和阿砚跨出东门，炉火在身后熄灭。" if rescue else "你独自出了东门。炉边再没有回应。") + "\n本章已完成。已发现的记忆保存在本机。", ["新一轮 · 保留记忆重玩"])
	else: extract_time = 0
	if hp <= 0: die("追魂影吞没了你的退路。\n下一世，先让阿砚掩护，再冲向东门。")
	elif elapsed >= 180: die("更漏耗尽。轮到这一批弟子入炉了。", "names")

func nearest_enemy(p: Vector2) -> Vector2:
	var point := p + Vector2.RIGHT;var best := INF
	for e in enemies:
		var d: float = p.distance_squared_to(e.pos)
		if d < best: best = d;point = e.pos
	return point

func shoot(p: Vector2, direction: Vector2) -> void:
	if bullets.size() < 48: bullets.append({"pos":p,"vel":direction.normalized() * 380,"life":1.2})

func burst(p: Vector2, color: Color, amount: int) -> void:
	for i in range(amount):
		if sparks.size() < 120: sparks.append({"pos":p,"vel":Vector2.from_angle(i * 2.4) * (12 + i * 2),"life":.7,"color":color})

func save_memory() -> void:
	if demo or self_test: return
	var cfg := ConfigFile.new();cfg.set_value("memory", "learned", learned);cfg.set_value("memory", "selected", selected);cfg.save("user://ash-ledger-memory.cfg")

func load_memory() -> void:
	if demo or self_test: return
	var cfg := ConfigFile.new()
	if cfg.load("user://ash-ledger-memory.cfg") == OK:
		var items: Variant = cfg.get_value("memory", "learned", [])
		if items is Array:
			for value in items:
				if str(value) in MEMORY_NAMES and str(value) not in learned: learned.append(str(value))
		var value := str(cfg.get_value("memory", "selected", ""))
		if value in learned: selected = value

# Capture driver uses normal movement, dialogs and memory equip; no teleports or rule bypass.
func demo_target() -> Vector2:
	match demo_step:
		0, 4, 13: return HERBALIST
		6, 15: return CLERK
		8: return EXIT
		17: return LEDGER
		20: return FURNACE
		22: return EXIT
	return player

func demo_tick() -> void:
	if lifetime < demo_next: return
	match demo_step:
		0, 4, 6, 8, 13, 15, 17, 20:
			if player.distance_to(demo_target()) > 48: return
			interact();demo_step += 1;demo_next = lifetime + 1.6
		1: choose(0);demo_step = 2;demo_next = lifetime + 2
		2: choose(0);demo_step = 3;demo_next = lifetime + 1.2
		3: choose(learned.size());demo_step = 4
		5: choose(1);demo_step = 6
		7: choose(0);demo_step = 8
		9: choose(0);demo_step = 10;demo_next = lifetime + 2
		10: choose(learned.find("seal"));demo_step = 11;demo_next = lifetime + 1.2
		11: choose(learned.size());demo_step = 13
		14: choose(2);demo_step = 15
		16: choose(1);demo_step = 17
		18: choose(0);open_memory();demo_step = 19;demo_next = lifetime + 1.6
		19: choose(learned.find("names"));demo_step = 23;demo_next = lifetime + 1.6
		23: choose(learned.size());demo_step = 20
		21: choose(0);set_order("follow");demo_step = 22

func make_sprites() -> void:
	var pattern := ["................","......oooo......",".....oooooo.....",".....oHHHHo.....",".....oHEEHo.....","......oHHo......",".....oooooo.....","....oBBBBBBo....","...oBBBBBBBBo...","...oBoBBBBoBo...","....oBBBBBBo....","....oBBBBBBo....","...oBBBBBBBBo...","....oooooooo....",".....oo..oo.....","................"]
	for key in ["player", "ally", "npc", "enemy"]:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		var palette: Color = {"player":Color("b8c8c1"),"ally":Color("67bba9"),"npc":Color("b0846a"),"enemy":Color("965c7e")}[key]
		for y in range(16):
			for x in range(16):
				var c: String = pattern[y][x];var color := Color.TRANSPARENT
				if c == "o": color = Color("121926")
				if c == "H": color = Color("cfb59a")
				if c == "E": color = Color("2a293a")
				if c == "B": color = palette if x < 8 else palette.darkened(.25)
				img.set_pixel(x, y, color)
		sprites[key] = ImageTexture.create_from_image(img)

func text_at(s: String, p: Vector2, size: int = 18, color: Color = Color("c3cfca")) -> void:
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func actor(p: Vector2, kind: String, name_text: String, color: Color) -> void:
	draw_rect(Rect2(p + Vector2(-12, 8), Vector2(24, 6)), Color("0c121c"))
	draw_texture_rect(sprites[kind], Rect2((p - Vector2(16, 25)).round(), Vector2(32, 32)), false)
	text_at(name_text, p + Vector2(-name_text.length() * 8, -31), 16, color)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 600), Color("111923"))
	for y in range(6, 28):
		for x in range(1, 59):
			var col := Color("293337") if (x * 7 + y * 3) % 5 else Color("2d3c3b")
			draw_rect(Rect2(x * 16, y * 16, 15, 15), col)
			if (x * 13 + y * 7) % 23 == 0: draw_rect(Rect2(x * 16 + 3, y * 16 + 11, 6, 2), Color("476055"))
	# Weathered courtyard walls, hanging red talismans, ash-scattered paving.
	draw_rect(AREA, Color("65716a"), false, 3)
	for w in walls:
		draw_rect(Rect2(w.position + Vector2(4, 5), w.size), Color("111b24"));draw_rect(w, Color("4b5154"))
		draw_rect(Rect2(w.position, Vector2(w.size.x, 5)), Color("818777"))
		for y in range(int(w.position.y) + 16, int(w.end.y), 16): draw_line(Vector2(w.position.x, y), Vector2(w.end.x, y), Color("303b40"), 2)
	for x in [70, 160, 380, 480, 580, 740, 870]:
		draw_rect(Rect2(x, 104, 4, 16), Color("8e7152"));draw_rect(Rect2(x - 5, 116, 14, 22), Color("a65b5d"));draw_rect(Rect2(x - 1, 120, 6, 10), Color("d4b67f"))
	for p in [HERBALIST, CLERK, LEDGER]: draw_rect(Rect2(p - Vector2(42, 24), Vector2(84, 56)), Color("867354"), false, 2)
	actor(HERBALIST, "npc", "药房 / 赠丹", Color("d9b885"));actor(CLERK, "npc", "契房 / 按印", Color("d9b885"))
	draw_rect(Rect2(LEDGER - Vector2(18, 10), Vector2(36, 28)), Color("463a36"));draw_rect(Rect2(LEDGER - Vector2(14, 14), Vector2(28, 22)), Color("b9ae91"))
	for x in range(3): draw_line(LEDGER + Vector2(-8 + x * 7, -9), LEDGER + Vector2(-8 + x * 7, 4), Color("786a5b"), 2)
	text_at("东院 / 名册", LEDGER + Vector2(-48, -31), 16, Color("d8bd89"))
	draw_rect(Rect2(FURNACE - Vector2(32, 26), Vector2(64, 50)), Color("4a4c50"));draw_rect(Rect2(FURNACE - Vector2(38, 32), Vector2(76, 8)), Color("77746a"))
	draw_rect(Rect2(FURNACE - Vector2(21, 10), Vector2(42, 23)), Color("6e3741") if not gate_open else Color("272c34"))
	if not gate_open:
		for i in range(7): draw_rect(Rect2(FURNACE + Vector2(-18 + i * 6, -4 - (i % 3) * 5), Vector2(4, 14 + (i % 3) * 5)), Color("d99761") if i % 2 else Color("edc281"))
	text_at("炼炉 / 归处", FURNACE + Vector2(-48, -43), 16, Color("d8a57f"))
	draw_rect(Rect2(EXIT - Vector2(24, 46), Vector2(48, 92)), Color("466b63") if gate_open else Color("634654"), false, 4)
	if not gate_open:
		for y in range(220, 295, 14): draw_rect(Rect2(856, y, 48, 3), Color("a36b71"))
	text_at("东门", EXIT + Vector2(-17, -58), 17, Color("a1cfbb") if gate_open else Color("d6a3a6"))
	for e in enemies: actor(e.pos,"enemy","追魂",Color("bf8dac"))
	actor(ally,"ally","阿砚",Color("8dcbb3"));actor(player,"player","你",Color("e6d2aa"))
	for b in bullets: draw_rect(Rect2(b.pos, Vector2(8, 3)), Color("bae6bf"))
	for p in sparks: draw_rect(Rect2(p.pos.round(), Vector2(3, 3)), p.color)
	text_at("烬 籍", Vector2(24, 41), 34, Color("ead5b0"));text_at("魔门余生 / 第一章 · 领丹日", Vector2(140, 38), 20, Color("a6b9b1"))
	text_at("第 %d 世" % life_no, Vector2(552, 37), 20, Color("e0b37c"));text_at("命数 %d / 4" % lives, Vector2(680, 37), 19, Color("c7d1be"))
	text_at("气血 %d" % int(hp), Vector2(820, 37), 19, Color("dba9a0"))
	text_at("生效记忆：" + MEMORY_NAMES.get(selected,"无"), Vector2(26, 75), 19, Color("cdb489"))
	text_at(agent_status, Vector2(628, 75), 16, Color("819d98"))
	var objective: String = ["01  赠丹背后的价钱 · 去西侧药房", "02  通行牌与回收印 · 去契房", "03  别急着出门 · 查东院名册", "04  M 装配【活人名册】· 到炼炉主动使用", "05  空格驱魂 · 从东门离开"][stage]
	text_at(objective,Vector2(28, 476),20,Color("e2c393"))
	text_at(message.left(50),Vector2(28, 513),17,Color("b8c7c1"))
	text_at("WASD 移动 / E 交互 / 1–4 选项或指令 / M 记忆 / 空格符刃 / Enter 交谈", Vector2(24, 596), 14, Color("758c8a"))
	if not modal_kind.is_empty(): draw_rect(Rect2(0, 92, 960, 440), Color("081019a8"))
	if request_busy: text_at("阿砚正在思考……", Vector2(365, 292), 27, Color("edce98"))

func run_tests() -> void:
	var errors := 0
	if equip("names"): errors += 1
	player = HERBALIST;interact()
	if not choice_buttons[1].disabled: errors += 1
	choose(0)
	if phase != "dead" or lives != 3 or "ash" not in learned or selected != "": errors += 1
	equip("ash");reset_life();player = HERBALIST;interact();choose(1)
	if phase != "playing" or stage != 1: errors += 1
	player = CLERK;interact();choose(0);player = EXIT;interact();choose(0)
	if lives != 2 or "seal" not in learned: errors += 1
	equip("seal");reset_life();stage = 1;player = CLERK;interact();choose(1)
	if signed or not seal_broken: errors += 1
	player = LEDGER;interact();choose(0)
	if "names" not in learned or selected != "seal": errors += 1
	player = FURNACE;interact()
	if not choice_buttons[0].disabled: errors += 1
	close_modal();equip("names");interact();choose(0)
	if not gate_open or not rescue or hp != 75: errors += 1
	var prior_epoch := epoch;reset_life()
	on_agent_response(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"mode":"scout","epoch":prior_epoch,"run_id":run_id}).to_utf8_buffer())
	if mode != "follow": errors += 1
	if set_order("unlock_gate"): errors += 1
	equip("names");player = FURNACE;interact();choose(1)
	if rescue or hp != 90 or not gate_open: errors += 1
	print("ASH_TESTS ", "PASS" if errors == 0 else "FAIL", " errors=",errors)
	get_tree().quit(errors)
