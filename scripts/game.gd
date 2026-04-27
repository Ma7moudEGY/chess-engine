extends Node2D

var game_over
var player_color
var status
var player2_type

var is_dragging: bool
var selected_piece = null
var previous_position = null

# [moved, prev, curr]
var moves = []

@onready var board = $Board


func _ready() -> void:
	init_game()

func _input(event: InputEvent) -> void:
	if game_over:
		return

	if Input.is_action_just_pressed("undo"):
		undo_move()
		if player2_type == Globals.PLAYER_2_TYPE.AI and status == Globals.COLORS.BLACK:
			undo_move()

	# elif Input.is_action_just_pressed("redo"):
	# 	redo_move()

	elif Input.is_action_just_pressed("left_click"):
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

		if evaluate_end_game():
			return

		if is_valid_move:
			player2_move()


func init_game():
	game_over = false
	is_dragging = false
	player_color = Globals.COLORS.WHITE
	status = Globals.COLORS.WHITE
	player2_type = Globals.PLAYER_2_TYPE.AI # change to ai later

func undo_move():
	if !moves.is_empty():
		print(moves)
		var move = moves.pop_back()
		var src_piece = board.get_piece(move[1])
		src_piece.move_position(move[0])
		src_piece.moved = move[2]

		status = Globals.COLORS.BLACK if status == Globals.COLORS.WHITE else Globals.COLORS.WHITE

# func redo_move():
# 	if current_move < len(moves):
# 		print(moves, " ", current_move)
# 		var move = moves[current_move]
# 		var src_piece = board.get_piece(move[1])
# 		src_piece.move_position(move[0])
# 		src_piece.moved = move[2]
# 		current_move += 1

# 		status = Globals.COLORS.BLACK if status == Globals.COLORS.WHITE else Globals.COLORS.WHITE

func get_pos_under_mouse():
	var pos = get_global_mouse_position()
	pos.x = int(pos.x / board.CELL_SIZE)
	pos.y = int(pos.y / board.CELL_SIZE)
	return pos

func drop_piece():
	var to_move = get_pos_under_mouse()
	if valid_move(selected_piece.board_position, to_move):
		var dest_piece = board.get_piece(to_move)
		if dest_piece != null and dest_piece.color != selected_piece.color:
			board.delete_piece(dest_piece)

		moves.append([selected_piece.board_position, to_move, selected_piece.moved])
		selected_piece.move_position(to_move)
		status = Globals.COLORS.BLACK if status == Globals.COLORS.WHITE else Globals.COLORS.WHITE
		print(moves)

		return true
	return false

func valid_move(from_pos, to_pos):
	var board_copy = board.clone()
	var src_piece = board_copy.get_piece(from_pos)

	if (to_pos not in src_piece.get_moveable_positions() and to_pos not in src_piece.get_threatened_positions()):
		return false

	var dest_piece = board_copy.get_piece(to_pos)
	if dest_piece != null:
		board_copy.delete_piece(dest_piece)
	src_piece.move_position(to_pos)

	for piece in board_copy.pieces:
		if status == Globals.COLORS.BLACK and board_copy.black_king_pos in piece.get_threatened_positions():
			return false

		if status == Globals.COLORS.WHITE and board_copy.white_king_pos in piece.get_threatened_positions():
			return false

	return true

func get_valid_moves():
	var valid_moves = []
	for piece in board.pieces:
		if piece.color == status:
			var candi_pos = piece.get_moveable_positions()
			if piece.piece_type == Globals.PIECE_TYPES.PAWN:
				candi_pos += piece.get_threatened_positions()
			candi_pos = unique(candi_pos)
			for pos in candi_pos:
				if valid_move(piece.board_position, pos):
					valid_moves.append([piece, pos])

	return valid_moves

func unique(arr: Array) -> Array:
	var dict = {}
	for a in arr:
		dict[a] = 1
	return dict.keys()

func player2_move():
	if player2_type == Globals.PLAYER_2_TYPE.AI:
		var valid_moves = get_valid_moves()
		if valid_moves.is_empty():
			set_win(Globals.PLAYER.ONE)
			return

		var move = valid_moves.pick_random()
		var piece = move[0]
		var pos = move[1]
		var dest_piece = board.get_piece(pos)
		
		if dest_piece != null and dest_piece.color != piece.color:
			board.delete_piece(dest_piece)
		moves.append([piece.board_position, move[1], piece.moved])
		piece.move_position(pos)
		status = Globals.COLORS.BLACK if status == Globals.COLORS.WHITE else Globals.COLORS.WHITE
		evaluate_end_game()

func evaluate_end_game():
	var m = get_valid_moves()
	if m.is_empty():
		set_win(Globals.PLAYER.TWO if status == player_color else Globals.PLAYER.ONE)
		return true
	return false

func set_win(who: Globals.PLAYER):
	game_over = true
	if who == Globals.PLAYER.ONE:
		print("Player One Won")
	else:
		print("Player Two Won")
