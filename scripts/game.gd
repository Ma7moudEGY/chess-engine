extends Node2D

var player_color
var status
var player2_type

var is_dragging: bool
var selected_piece = null
var previous_position = null

@onready  var board = $Board


func _ready() -> void:
	init_game()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click"):
		var pos = get_pos_under_mouse()
		selected_piece = board.get_piece(pos)

		if selected_piece == null or selected_piece.color != status:
			return

		is_dragging = true
		previous_position = selected_piece.position
		selected_piece.z_index = 100

	elif event is InputEventMouseMotion and is_dragging:
		selected_piece.position = get_global_mouse_position()

	elif Input.is_action_just_released("left_click") and is_dragging:
		var is_valid_move = drop_piece()
		
		if !is_valid_move:
			selected_piece.position = previous_position
		selected_piece.z_index = 0
		selected_piece = null
		is_dragging = false


func init_game():
	is_dragging = false
	player_color = Globals.COLORS.WHITE
	status = Globals.COLORS.WHITE
	player2_type = Globals.PLAYER_2_TYPE.HUMAN # change to ai later


func get_pos_under_mouse():
	var pos = get_global_mouse_position()
	pos.x = int(pos.x / board.CELL_SIZE)
	pos.y = int(pos.y / board.CELL_SIZE)
	return pos

func drop_piece():
	var to_move = get_pos_under_mouse()
	if valid_move(selected_piece.position, to_move):
		var dest_piece = board.get_piece(to_move)
		if dest_piece != null and dest_piece.color != selected_piece.color:
			board.delete_piece(dest_piece)

		selected_piece.move_position(to_move)
		status = Globals.COLORS.BLACK if status == Globals.COLORS.WHITE else Globals.COLORS.WHITE

		return true
	return false


func valid_move(from_pos, to_pos):
	return true