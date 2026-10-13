extends CanvasLayer

const Rally = preload("res://scripts/core/rally_manager.gd")
const Combat = preload("res://scripts/core/battle_manager.gd")
const Judge = preload("res://scripts/core/timing_judge.gd")
signal pause_requested
signal difficulty_requested(index: int)
signal restart_requested
signal sound_requested(enabled: bool)

var difficulty_picker: OptionButton
var pressure_label: Label
var pattern_label: Label
var subtitle: Label
var root: Control
var count_label: Label
var best_label: Label
var feedback: Label
var error_label: Label
var status_label: Label
var pause_button: Button
var resume_button: Button
var sound_button: Button
var sound_enabled: bool = true
var overlay: Panel
var enemy_hp_bar: ProgressBar
var player_hp_bar: ProgressBar
var enemy_hp_label: Label
var player_hp_label: Label
var defense_label: Label
var result_panel: Panel
var result_title: Label
var result_caption: Label
var player_hit_until: float = -1.0
var enemy_hit_until: float = -1.0
var defense_until: float = -1.0
var feedback_until: float = -1.0
var safe_top: float = 0.0
var safe_bottom: float = 640.0

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_label("ONE TAP / RALLY", Vector2(22, 22), Vector2(220, 26), 22, Color("fff4d2"))
	subtitle = _label("NORMAL · HP BATTLE", Vector2(23, 53), Vector2(250, 20), 11, Color("829aae"))
	count_label = _label("00", Vector2(22, 108), Vector2(94, 30), 24, Color("fff4d2"))
	_label("RETURNS", Vector2(23, 133), Vector2(100, 18), 10, Color("829aae"))
	best_label = _label("BEST 00", Vector2(22, 148), Vector2(130, 20), 12, Color("b9dfcb"))
	pause_button = _button("II", Rect2(284, 22, 52, 40))
	pause_button.pressed.connect(func(): pause_requested.emit())
	feedback = _label("GET READY", Vector2(30, 541), Vector2(300, 30), 25, Color("ffd166"))
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label = _label("", Vector2(30, 567), Vector2(300, 20), 12, Color("829aae"))
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label = _label("Tap once when the ball meets the ring", Vector2(15, 587), Vector2(330, 20), 12, Color("b9dfcb"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay = Panel.new()
	overlay.position = Vector2(24, 244)
	overlay.size = Vector2(312, 260)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("0b1020")
	style.border_color = Color("54c7e6")
	style.set_border_width_all(2)
	overlay.add_theme_stylebox_override("panel", style)
	root.add_child(overlay)
	overlay.hide()
	var title: Label = Label.new()
	title.text = "PAUSED"
	title.position = Vector2(20, 16)
	title.size = Vector2(272, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	overlay.add_child(title)
	resume_button = _button("RESUME", Rect2(39, 308, 136, 54))
	resume_button.reparent(overlay)
	resume_button.position = Vector2(15, 64)
	resume_button.pressed.connect(func(): pause_requested.emit())
	var restart_button: Button = _button("RESTART", Rect2(185, 308, 136, 54))
	restart_button.reparent(overlay)
	restart_button.position = Vector2(161, 64)
	restart_button.pressed.connect(func(): restart_requested.emit())
	difficulty_picker = OptionButton.new()
	difficulty_picker.position = Vector2(15, 124)
	difficulty_picker.size = Vector2(282, 34)
	difficulty_picker.focus_mode = Control.FOCUS_NONE
	difficulty_picker.add_theme_font_size_override("font_size", 13)
	for item in ["EASY", "NORMAL", "HARD"]:
		difficulty_picker.add_item(item)
	difficulty_picker.select(1)
	difficulty_picker.item_selected.connect(func(index: int): difficulty_requested.emit(index))
	overlay.add_child(difficulty_picker)
	var note: Label = _label("Changing difficulty restarts the battle", Vector2.ZERO, Vector2(282, 18), 10, Color("829aae"))
	note.reparent(overlay)
	note.position = Vector2(15, 164)
	pressure_label = _label("ENEMY PRESSURE 0 / 100", Vector2.ZERO, Vector2(282, 20), 11, Color("ffd166"))
	pressure_label.reparent(overlay)
	pressure_label.position = Vector2(15, 184)
	sound_button = _button("SOUND ON", Rect2(0, 0, 282, 34))
	sound_button.reparent(overlay)
	sound_button.position = Vector2(15, 211)
	sound_button.size = Vector2(282, 34)
	sound_button.pressed.connect(_toggle_sound)
	_label("ENEMY", Vector2(22, 74), Vector2(120, 16), 10, Color("ef7869"))
	enemy_hp_label = _label("100 / 100", Vector2(218, 74), Vector2(118, 16), 10, Color("fff4d2"))
	enemy_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	enemy_hp_bar = _hp_bar(Vector2(22, 94), Color("ef7869"))
	_label("PLAYER", Vector2(22, 609), Vector2(120, 16), 10, Color("54c7e6"))
	player_hp_label = _label("100 / 100", Vector2(218, 609), Vector2(118, 16), 10, Color("fff4d2"))
	player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	player_hp_bar = _hp_bar(Vector2(22, 627), Color("54c7e6"))
	defense_label = _label("", Vector2(22, 160), Vector2(148, 20), 11, Color("b9dfcb"))
	pattern_label = _label("BASIC RETURN", Vector2(22, 183), Vector2(148, 18), 10, Color("fff4d2"))
	_build_result_panel()
	get_viewport().size_changed.connect(_layout_safe_area)
	_layout_safe_area()

func _label(text: String, pos: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = pos
	label.size = dimensions
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)
	return label

func _button(text: String, rect: Rect2) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	root.add_child(button)
	return button

func _layout_safe_area() -> void:
	# The logical 9:16 court stays letterboxed. Transform device pixels to UI units.
	root.scale = Vector2.ONE
	root.position = Vector2.ZERO
	if OS.get_name() != "iOS":
		return
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var window_origin: Vector2i = DisplayServer.window_get_position()
	var inverse: Transform2D = get_viewport().get_screen_transform().affine_inverse()
	var top_left: Vector2 = inverse * Vector2(safe.position - window_origin)
	var bottom_right: Vector2 = inverse * Vector2(safe.end - window_origin)
	safe_top = clampf(top_left.y, 0, 640)
	safe_bottom = clampf(bottom_right.y, 0, 640)
	var safe_left: float = clampf(top_left.x, 0, 360)
	var safe_right: float = clampf(bottom_right.x, 0, 360)
	var factor: float = minf((safe_bottom - safe_top) / 640.0, (safe_right - safe_left) / 360.0)
	root.scale = Vector2.ONE * factor
	root.position = Vector2(safe_left + (safe_right - safe_left - 360.0 * factor) / 2.0, safe_top)

func show_judgement(grade: int, error_ms: float, now: float) -> void:
	feedback.text = Judge.NAMES[grade]
	var colors: Array[Color] = [Color("ffd166"), Color("b9dfcb"), Color("efb176"), Color("ef7869")]
	feedback.add_theme_color_override("font_color", colors[grade])
	error_label.text = "NO SWING — next serve coming" if is_inf(error_ms) else "%+d ms" % roundi(error_ms)
	feedback_until = now + 0.75

func clear_feedback() -> void:
	feedback_until = -1.0
	player_hit_until = -1.0
	enemy_hit_until = -1.0
	defense_until = -1.0
	defense_label.text = ""
	error_label.text = ""

func set_paused(value: bool) -> void:
	overlay.visible = value and not result_panel.visible
	pause_button.text = ">" if value else "II"

func set_sound_enabled(value: bool) -> void:
	sound_enabled = value
	sound_button.text = "SOUND ON" if value else "SOUND OFF"

func _toggle_sound() -> void:
	set_sound_enabled(not sound_enabled)
	sound_requested.emit(sound_enabled)

func update_state(model: RefCounted, now_us: int, paused: bool, combat: RefCounted = null) -> void:
	count_label.text = "%02d" % model.rally_count
	best_label.text = "BEST %02d" % model.best_count
	set_paused(paused)
	var now: float = float(now_us) / 1000000.0
	if now > feedback_until:
		feedback.add_theme_color_override("font_color", Color("fff4d2"))
		error_label.text = ""
		match model.state:
			Rally.State.RALLY_START, Rally.State.RALLY_RESULT:
				feedback.text = "GET READY"
			Rally.State.PLAYER_RETURN:
				feedback.text = "RETURN"
			_:
				feedback.text = "WATCH THE BALL"
	if now > defense_until:
		defense_label.text = ""
	status_label.text = "One swing per ball · early taps count" if model.state == Rally.State.PLAYER_RETURN else "Tap once when the ball meets the ring"
	if model.incoming_strong and model.state in [Rally.State.PLAYER_TIMING, Rally.State.HIT_PENDING]:
		status_label.text = "STRONG BALL — time your swing"
		if combat != null:
			status_label.text = "STRONG BALL — missing costs %d HP" % combat.config.strong_damage
	pattern_label.text = model.pattern.display_name if model.ball_visible() else "NEXT SERVE"
	if combat != null:
		pressure_label.text = "ENEMY PRESSURE %d / %d" % [combat.pressure.value, combat.config.pressure_max]
		if combat.difficulty != null:
			subtitle.text = combat.difficulty.display_name + " · HP BATTLE"
			var ids: Array[String] = ["easy", "normal", "hard"]
			difficulty_picker.select(ids.find(combat.difficulty.difficulty_id))
		_update_hp(enemy_hp_bar, enemy_hp_label, combat.enemy_hp, combat.config.max_hp)
		_update_hp(player_hp_bar, player_hp_label, combat.player_hp, combat.config.max_hp)
		enemy_hp_bar.modulate = Color("ffd166") if now < enemy_hit_until else Color.WHITE
		player_hp_bar.modulate = Color("ffd166") if now < player_hit_until else Color.WHITE
		pause_button.disabled = combat.state == Combat.State.BATTLE_END
		if combat.state == Combat.State.BATTLE_END:
			feedback.text = "VICTORY" if combat.winner == Combat.Side.PLAYER else "DEFEAT"
			status_label.text = "Battle over — tap PLAY AGAIN"

func _hp_bar(pos: Vector2, color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(314, 8)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.show_percentage = false
	# ProgressBar still includes its theme font in the minimum height.
	bar.add_theme_font_size_override("font_size", 1)
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color("26344b")
	background.border_color = Color("8bcaca")
	background.set_border_width_all(1)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	root.add_child(bar)
	bar.size = Vector2(314, 8)
	return bar

func _update_hp(bar: ProgressBar, label: Label, value: int, maximum: int) -> void:
	bar.max_value = maximum
	bar.value = value
	label.text = "%d / %d" % [value, maximum]

func show_enemy_defense(grade: int, now: float) -> void:
	defense_label.text = "ENEMY " + Judge.NAMES[grade]
	defense_until = now + 0.8

func show_damage(side: int, _amount: int, now: float) -> void:
	if side == Combat.Side.PLAYER:
		player_hit_until = now + 0.35
	else:
		enemy_hit_until = now + 0.35

func _build_result_panel() -> void:
	result_panel = Panel.new()
	result_panel.position = Vector2(24, 244)
	result_panel.size = Vector2(312, 180)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("0b1020")
	style.border_color = Color("ffd166")
	style.set_border_width_all(2)
	result_panel.add_theme_stylebox_override("panel", style)
	root.add_child(result_panel)
	result_panel.hide()
	result_title = _label("VICTORY", Vector2.ZERO, Vector2(272, 36), 28, Color("ffd166"))
	result_title.reparent(result_panel)
	result_title.position = Vector2(20, 18)
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_caption = _label("", Vector2.ZERO, Vector2(272, 30), 12, Color("b9dfcb"))
	result_caption.reparent(result_panel)
	result_caption.position = Vector2(20, 62)
	result_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var retry: Button = _button("PLAY AGAIN", Rect2(0, 0, 272, 54))
	retry.reparent(result_panel)
	retry.position = Vector2(20, 106)
	retry.pressed.connect(func(): restart_requested.emit())

func show_result(winner: int, best: int) -> void:
	result_title.text = "VICTORY" if winner == Combat.Side.PLAYER else "DEFEAT"
	result_title.add_theme_color_override("font_color", Color("ffd166") if winner == Combat.Side.PLAYER else Color("ef7869"))
	result_caption.text = "Opponent HP reached zero" if winner == Combat.Side.PLAYER else "Your HP reached zero"
	result_caption.text += "\nBEST RALLY  %02d" % best
	result_panel.show()
	overlay.hide()
	pause_button.disabled = true

func reset_result() -> void:
	result_panel.hide()
	pause_button.disabled = false
