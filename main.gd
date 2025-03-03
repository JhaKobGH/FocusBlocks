extends Node2D

#############
# Resources #
#############


# Audio
@onready var audio: AudioStreamPlayer = $"AudioStreamPlayer"

@onready var audio_start: AudioStream = preload("sounds/Start.wav")
@onready var audio_finish: AudioStream = preload("sounds/Finish.wav")
@onready var audio_reset: AudioStream = preload("sounds/Reset.wav")
@onready var audio_select_h: AudioStream = preload("sounds/SelectH.wav")
@onready var audio_select_m: AudioStream = preload("sounds/SelectM.wav")
@onready var audio_select_l: AudioStream = preload("sounds/SelectL.wav")
@onready var audio_select_hb: AudioStream = preload("sounds/SelectHB.wav")
@onready var audio_select_mb: AudioStream = preload("sounds/SelectMB.wav")
@onready var audio_select_lb: AudioStream = preload("sounds/SelectLB.wav")

# Animations
@onready var lines_tl: AnimatedSprite2D = $"Lines/Lines_TL"
@onready var lines_tr: AnimatedSprite2D = $"Lines/Lines_TR"
@onready var lines_bl: AnimatedSprite2D = $"Lines/Lines_BL"
@onready var lines_br: AnimatedSprite2D = $"Lines/Lines_BR"

@onready var block: PackedScene = preload("block.tscn")
@onready var block_layer: Node = $"Blocks"
@onready var block_builder: Panel = $"BlockBuilder"
@onready var block_builder_viewer: Panel = $"BlockBuilderViewer"

@onready var progress_bar: ProgressBar = $"ProgressBar"

@onready var time: RichTextLabel = $"Time"

# Time Controls
@onready var time_buttons: Node2D = $"TimeButtons"
@onready var five_minutes: Button = $"TimeButtons/5_Min"
@onready var fifteen_minutes: Button = $"TimeButtons/15_Min"
@onready var thirty_minutes: Button = $"TimeButtons/30_Min"
@onready var one_hour: Button = $"TimeButtons/1_Hour"
@onready var three_hour: Button = $"TimeButtons/3_Hour"
@onready var six_hour: Button = $"TimeButtons/6_Hour"

# Timer Controls
@onready var reset_start: Node2D = $"Reset_Start"
@onready var reset_block: Button = $"Reset_Start/ResetBlock"
@onready var view_block: Button = $"Reset_Start/ViewBlock"
@onready var start_block: Button = $"Reset_Start/StartBlock"
@onready var go_back: Button = $"GoBack"

# Timer

# Saving
@onready var delete_save: Node2D = $"Delete_Save"
@onready var delete_block: Button = $"Delete_Save/DeleteBlock"
@onready var save_block: Button = $"Delete_Save/SaveBlock"

@onready var category_description: Node2D = $"Category_Description"
@onready var category: LineEdit = $"Category_Description/Category"
@onready var description: TextEdit = $"Category_Description/Description"

# Loading


var pallet: Array[Color] = [
	Color.html("#7f8c8d"),
	Color.html("#2c3e50"),
	Color.html("#34495e"),
	Color.html("#c0392b"),
	Color.html("#d35400"),
	Color.html("#e74c3c"),
	Color.html("#e67e22"),
	Color.html("#27ae60"),
	Color.html("#2ecc71"),
	Color.html("#f39c12"),
	Color.html("#f1c40f"),
	Color.html("#8e44ad"),
	Color.html("#9b59b6"),
	Color.html("#16a085"),
	Color.html("#1abc9c"),
	Color.html("#2980b9"),
	Color.html("#7f8c8d"),
	Color.html("#3498db"),
	Color.html("#95a5a6"),
	Color.html("#bdc3c7")
]

var _total_time: int = 0
var _elapsed_time: int = 0
var _second_counter: float = 0
var _block_time_counter: float = 0

var _is_started: bool = false

var _current_x = 400
var _current_y = 240

var MAX_NUM_OF_BLOCKS: float = 546
var _block_drop_rate: float = 0

enum States {
	FOCUS,
	SAVE,
	VIEW 
}

var _current_state: int = States.FOCUS
var _block_color: Color = pallet.pick_random()

var _categories: Array[String] = []
var _descriptions: Array[String] = []

var _currently_viewing: int = -1
var _done_loading = false

func _ready():
	# Time Controls
	five_minutes.button_up.connect(five_min_up)
	fifteen_minutes.button_up.connect(fifteen_min_up)
	thirty_minutes.button_up.connect(thirty_min_up)
	one_hour.button_up.connect(one_hour_up)
	three_hour.button_up.connect(three_hour_up)
	six_hour.button_up.connect(six_hour_up)

	# Timer Controls
	reset_block.button_up.connect(reset_block_up)
	view_block.button_up.connect(view_block_up)
	start_block.button_up.connect(start_block_up)
	go_back.button_up.connect(go_back_up)

	# Load/Save Controls
	delete_block.button_up.connect(delete_block_up)
	save_block.button_up.connect(save_block_up)

func _process(delta: float) -> void:
	if (_current_state == States.FOCUS):
		if (_is_started):
			_second_counter += delta
			_block_time_counter += delta

			# This is close enough from my limited testing
			if (_second_counter >= 1.0):
				_total_time -= 1
				_elapsed_time += 1
				_second_counter = 0.0

				time.text = get_time_string()
				progress_bar.value = _elapsed_time

			if ((_block_time_counter >= _block_drop_rate) && _current_y >= 80):
				_block_time_counter = 0.0

				var new_block = block.instantiate()
				new_block.color = _block_color
				new_block.global_position.x = _current_x
				new_block._max_y = _current_y
				block_layer.add_child(new_block)

				_current_x += 8

				if (_current_x > 600):
					_current_x = 400
					_current_y -= 8

			if (_total_time <= 0):
				audio.stream = audio_finish
				audio.play()

				show_load_save_ui()

	if (_current_state  == States.SAVE):
		pass

	if (_current_state  == States.VIEW):
		var mouse_coords = get_global_mouse_position()
		var bound_coords = mouse_coords / 8 as Vector2i
		_currently_viewing = (bound_coords.x - 30) + (46 * abs(bound_coords.y - 30))

		if (_currently_viewing < 0
		or _currently_viewing > _categories.size()
		or mouse_coords.x < 240
		or mouse_coords.x > 608
		or mouse_coords.y < 80
		or mouse_coords.y > 248
		or _done_loading == false):
			category.text = ""
			description.text = ""
		else:
			category.text = _categories[_currently_viewing]
			description.text = _descriptions[_currently_viewing]

func five_min_up():
	audio.stream = audio_select_h
	audio.play()
	_total_time += (5 * 60)
	time.text = get_time_string()
	view_block.hide()
	reset_block.show()

func fifteen_min_up():
	audio.stream = audio_select_m
	audio.play()
	_total_time += (15 * 60)
	time.text = get_time_string()
	view_block.hide()
	reset_block.show()

func thirty_min_up():
	audio.stream = audio_select_l
	audio.play()
	_total_time += (30 * 60)
	time.text = get_time_string()
	view_block.hide()
	reset_block.show()

func one_hour_up():
	audio.stream = audio_select_hb
	audio.play()
	_total_time += (1 * (60 * 60))
	time.text = get_time_string()
	view_block.hide()
	reset_block.show()

func three_hour_up():
	audio.stream = audio_select_mb
	audio.play()
	_total_time += (3 * (60 * 60))
	time.text = get_time_string()
	view_block.hide()
	reset_block.show()

func six_hour_up():
	audio.stream = audio_select_lb
	audio.play()
	_total_time += (6 * (60 * 60))
	time.text = get_time_string()
	view_block.hide()
	reset_block.show()

func reset_block_up():
	_total_time = 0
	_elapsed_time = 0
	time.text = get_time_string()

	five_minutes.disabled = false
	fifteen_minutes.disabled = false
	thirty_minutes.disabled = false
	one_hour.disabled = false
	three_hour.disabled = false
	six_hour.disabled = false
	start_block.disabled = false

	progress_bar.value = 0

	lines_tl.stop()
	lines_tr.stop()
	lines_bl.stop()
	lines_br.stop()

	for block_piece in block_layer.get_children():
		block_piece.queue_free()

	_current_x = 400
	_current_y = 240

	_block_drop_rate = 0
	_second_counter = 0
	_block_time_counter =  0

	category.text = ""
	description.text = ""

	view_block.show()
	reset_block.hide()

	_block_color = pallet.pick_random()

	audio.stream = audio_reset
	audio.play()

	_is_started = false

func view_block_up():
	show_view_ui()

	var dir_path = OS.get_executable_path().get_base_dir() + "/blocks"
	var fblck_dir = DirAccess.open(dir_path)

	if fblck_dir:
		fblck_dir.list_dir_begin()
		var file_name = fblck_dir.get_next()

		var _local_max_x = 600
		var _local_max_y = 80 
		var _local_current_x = 240
		var _local_current_y = 240
		
		var _current_count = 0

		while file_name != "" and _current_state == States.VIEW and _current_count < 966:
			if (!fblck_dir.current_is_dir()):
				var read_file = FileAccess.open(dir_path + "/" + file_name, FileAccess.READ)	
				var file_split = read_file.get_as_text().split(":-:")

				_categories.append(file_split[0])
				_descriptions.append(file_split[1])

				var new_block = block.instantiate()
				new_block.color = pallet.pick_random() 
				new_block.global_position.x = _local_current_x
				new_block._max_y = _local_current_y
				block_layer.add_child(new_block)

				_local_current_x += 8

				if (_local_current_x > 600):
					_local_current_x = 240
					_local_current_y -= 8

				_current_count += 1

				await get_tree().create_timer(0.01).timeout
		
			file_name = fblck_dir.get_next()

		_done_loading = true
	else:
		print("Could not find fblck directory")

func start_block_up():
	if (_total_time <= 0):
		return

	five_minutes.disabled = true
	fifteen_minutes.disabled = true
	thirty_minutes.disabled = true
	one_hour.disabled = true
	three_hour.disabled = true
	six_hour.disabled = true
	start_block.disabled = true

	progress_bar.max_value = _total_time

	lines_tl.play("default")
	lines_tr.play("default")
	lines_bl.play("default")
	lines_br.play("default")

	_block_drop_rate =  (_total_time - (_total_time * 0.25)) / MAX_NUM_OF_BLOCKS as float

	audio.stream = audio_start
	audio.play()

	_is_started = true

func delete_block_up():
	reset_block_up()
	show_focus_ui()

	_current_state = States.FOCUS

func save_block_up():
	var save_string = "" 

	save_string += category.text + ":-:"
	save_string += description.text

	var file_name: String = OS.get_executable_path().get_base_dir() + "/blocks/" + Time.get_datetime_string_from_system().replace(":", "-") + ".FBLK"

	var save_file = FileAccess.open(file_name, FileAccess.WRITE)

	save_file.store_line(save_string)
	reset_block_up()
	show_focus_ui()
	_current_state = States.FOCUS

func go_back_up():
	for block_piece in block_layer.get_children():
		block_piece.queue_free()
	
	_categories.clear()
	_descriptions.clear()
	_done_loading = false

	show_focus_ui()

func show_focus_ui():
	_current_state = States.FOCUS

	delete_save.hide()
	category_description.hide()
	block_builder_viewer.hide()
	go_back.hide()
	time_buttons.show()
	reset_start.show()
	block_builder.show()
	progress_bar.show()

func show_load_save_ui():
	_current_state = States.SAVE

	category.editable = true
	description.editable = true

	time_buttons.hide()
	reset_start.hide()
	delete_save.show()
	block_builder_viewer.hide()
	go_back.hide()
	block_builder.show()
	progress_bar.show()
	category_description.show()

func show_view_ui():
	_current_state = States.VIEW

	category.editable = false
	description.editable = false

	time_buttons.hide()
	reset_start.hide()
	delete_save.hide()
	block_builder.hide()
	progress_bar.hide()
	category_description.show()
	block_builder_viewer.show()
	go_back.show()

func get_time_string():
	var seconds: int = _total_time % 60
	var minutes: int = (_total_time / 60) % 60
	var hours: int = (_total_time / 60) / 60

	return "[center]%02d:%02d:%02d[/center]" % [hours, minutes, seconds]
