extends Node2D

var game_over
var player_color
var status
var player2_type

const DEBUG_LOG := false

var is_dragging: bool
var selected_piece = null
var previous_position = null
var selected_legal_targets = {}

# [from, to, moved, captured, prev_type, rook, rook_from, rook_to, rook_prev_moved, prev_ep_target, prev_ep_pawn]
var moves = []

@onready var board = $Board
@onready var ui_control = $Control
@onready var win_lable = $Control/WinLable



func _ready() -> void:
	init_game()
	ui_control.hide()

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
		var clicked_piece = board.get_piece(pos)

		if selected_piece == null:
			if clicked_piece == null or clicked_piece.color != status:
				return
			select_piece(clicked_piece)
			return

		if clicked_piece != null and clicked_piece.color == status:
			select_piece(clicked_piece)
			return

		var is_valid_move = try_move_to(pos)
		if !is_valid_move:
			return

		clear_selection()
		if evaluate_end_game():
			return
		call_deferred("player2_move")

	elif event is InputEventMouseMotion and selected_piece != null and Input.is_action_pressed("left_click"):
		is_dragging = true
		selected_piece.position = get_global_mouse_position()

	elif Input.is_action_just_pressed("escape") and selected_piece != null:
		clear_selection()
		return

	elif Input.is_action_just_released("left_click") and is_dragging:
		var is_valid_move = drop_piece()
		if !is_valid_move:
			selected_piece.position = previous_position
			clear_selection()
			return

		clear_selection()
		if evaluate_end_game():
			return
		if player2_type == Globals.PLAYER_2_TYPE.AI and status == Globals.COLORS.BLACK: 
			call_deferred("player2_move")


func init_game():
	game_over = false
	is_dragging = false
	player_color = Globals.COLORS.WHITE
	status = Globals.COLORS.WHITE
	player2_type = Globals.PLAYER_2_TYPE.AI # change to ai later

func undo_move():
	if !moves.is_empty():
		if DEBUG_LOG:
			print(moves)
		var move = moves.pop_back()
		var src_piece = board.get_piece(move[1])
		src_piece.move_position(move[0])
		src_piece.moved = move[2]
		src_piece.piece_type = move[4]
		src_piece.update_sprite()

		var captured = move[3]
		if captured != null:
			board.restore_piece(captured)

		var rook = move[5]
		if rook != null:
			rook.move_position(move[6])
			rook.moved = move[8]

		if move.size() > 9:
			board.en_passant_target = move[9]
			board.en_passant_pawn = move[10]

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
	return try_move_to(to_move)

func try_move_to(to_move) -> bool:
	if selected_piece == null:
		return false
	if not selected_legal_targets.is_empty():
		if not selected_legal_targets.has(to_move):
			return false
	if valid_move(selected_piece.board_position, to_move):
		var dest_piece = board.get_piece(to_move)
		if selected_piece.piece_type == Globals.PIECE_TYPES.PAWN and dest_piece == null and board.en_passant_target != null:
			if to_move == board.en_passant_target and board.en_passant_pawn != null and board.en_passant_pawn.color != selected_piece.color:
				dest_piece = board.en_passant_pawn

		if dest_piece != null and dest_piece.color != selected_piece.color:
			board.delete_piece(dest_piece, false)

		var prev_type = selected_piece.piece_type
		var prev_ep_target = board.en_passant_target
		var prev_ep_pawn = board.en_passant_pawn

		var rook = null
		var rook_from = null
		var rook_to = null
		var rook_prev_moved = null

		if selected_piece.piece_type == Globals.PIECE_TYPES.KING and abs(to_move.x - selected_piece.board_position.x) == 2:
			var y = selected_piece.board_position.y
			if to_move.x > selected_piece.board_position.x:
				rook_from = Vector2(7, y)
				rook_to = Vector2(selected_piece.board_position.x + 1, y)
			else:
				rook_from = Vector2(0, y)
				rook_to = Vector2(selected_piece.board_position.x - 1, y)

			rook = board.get_piece(rook_from)
			if rook != null:
				rook_prev_moved = rook.moved
				rook.move_position(rook_to)
				rook.moved = true

		board.en_passant_target = null
		board.en_passant_pawn = null

		moves.append([selected_piece.board_position, to_move, selected_piece.moved, dest_piece, prev_type, rook, rook_from, rook_to, rook_prev_moved, prev_ep_target, prev_ep_pawn])
		selected_piece.move_position(to_move)

		if selected_piece.piece_type == Globals.PIECE_TYPES.PAWN and abs(to_move.y - moves[-1][0].y) == 2:
			var step = 1 if selected_piece.color == Globals.COLORS.BLACK else -1
			board.en_passant_target = Vector2(to_move.x, to_move.y - step)
			board.en_passant_pawn = selected_piece

		status = Globals.COLORS.BLACK if status == Globals.COLORS.WHITE else Globals.COLORS.WHITE
		if DEBUG_LOG:
			print(moves)

		return true
	return false

func select_piece(piece):
	board.clear_move_markers()
	selected_piece = piece
	selected_legal_targets = build_legal_targets(selected_piece)
	for move in selected_legal_targets:
		board.draw_move_marker(move)
	previous_position = selected_piece.position
	selected_piece.z_index = 100
	is_dragging = false

func clear_selection():
	if selected_piece != null:
		selected_piece.z_index = 0
	selected_piece = null
	selected_legal_targets = {}
	is_dragging = false
	board.clear_move_markers()

func build_legal_targets(piece) -> Dictionary:
	var targets = {}
	if piece == null:
		return targets
	var candi_pos = unique(piece.get_moveable_positions())
	for pos in candi_pos:
		if valid_move(piece.board_position, pos):
			targets[pos] = true
	return targets

func simulate_move(from_pos, to_pos):
	var piece = board.get_piece(from_pos)
	var dest_piece = board.get_piece(to_pos)
	var moved = piece.moved
	var prev_pos = piece.board_position
	var prev_type = piece.piece_type
	var rook = null
	var rook_from = null
	var rook_to = null
	var rook_prev_moved = null

	if piece.piece_type == Globals.PIECE_TYPES.PAWN and dest_piece == null and board.en_passant_target != null:
		if to_pos == board.en_passant_target and board.en_passant_pawn != null and board.en_passant_pawn.color != piece.color:
			dest_piece = board.en_passant_pawn

	if dest_piece != null:
		board.delete_piece(dest_piece, false)

	if piece.piece_type == Globals.PIECE_TYPES.KING and abs(to_pos.x - from_pos.x) == 2:
		var y = from_pos.y
		if to_pos.x > from_pos.x:
			rook_from = Vector2(7, y)
			rook_to = Vector2(from_pos.x + 1, y)
		else:
			rook_from = Vector2(0, y)
			rook_to = Vector2(from_pos.x - 1, y)

		rook = board.get_piece(rook_from)
		if rook != null:
			rook_prev_moved = rook.moved
			rook.move_position(rook_to)
			rook.moved = true

	piece.move_position(to_pos)

	return {
		"piece": piece,
		"dest_piece": dest_piece,
		"moved": moved,
		"prev_pos": prev_pos,
		"prev_type": prev_type,
		"rook": rook,
		"rook_from": rook_from,
		"rook_to": rook_to,
		"rook_prev_moved": rook_prev_moved
	}

func undo_simulated_move(state: Dictionary):
	var piece = state["piece"]
	var prev_pos = state["prev_pos"]
	var prev_moved = state["moved"]
	var prev_type = state["prev_type"]

	piece.move_position(prev_pos)
	piece.moved = prev_moved
	piece.piece_type = prev_type
	piece.update_sprite()

	var dest_piece = state["dest_piece"]
	if dest_piece != null:
		board.restore_piece(dest_piece)

	var rook = state["rook"]
	if rook != null:
		rook.move_position(state["rook_from"])
		rook.moved = state["rook_prev_moved"]

func is_king_in_check(to_check: Globals.COLORS):
	var king_pos = board.white_king_pos if to_check == Globals.COLORS.WHITE else board.black_king_pos

	for piece in board.pieces:
		if piece.color != to_check and king_pos in piece.get_threatened_positions():
			return true

	return false

func is_square_attacked(pos, col):
	for piece in board.pieces:
		if piece.color == col and pos in piece.get_threatened_positions():
			return true
	return false

func valid_move(from_pos, to_pos):
	var src_piece = board.get_piece(from_pos)
	if src_piece == null:
		return false

	if (to_pos not in src_piece.get_moveable_positions() and to_pos not in src_piece.get_threatened_positions()):
		return false

	if src_piece.piece_type == Globals.PIECE_TYPES.KING and abs(to_pos.x - from_pos.x) == 2:
		var enemy = Globals.COLORS.BLACK if status == Globals.COLORS.WHITE else Globals.COLORS.WHITE
		if is_square_attacked(from_pos, enemy):
			return false

		var step = 1 if to_pos.x > from_pos.x else -1
		var pass_sqaure = from_pos + Vector2(step, 0)
		if is_square_attacked(pass_sqaure, enemy):
			return false
		if is_square_attacked(to_pos, enemy):
			return false

	var state = simulate_move(from_pos, to_pos)
	var illegal = is_king_in_check(status)
	undo_simulated_move(state)

	return not illegal

func get_valid_moves():
	var valid_moves = []
	for piece in board.pieces:
		if piece.color == status:
			var candi_pos = piece.get_moveable_positions()
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
		if piece.piece_type == Globals.PIECE_TYPES.PAWN and dest_piece == null and board.en_passant_target != null:
			if pos == board.en_passant_target and board.en_passant_pawn != null and board.en_passant_pawn.color != piece.color:
				dest_piece = board.en_passant_pawn
		
		if dest_piece != null and dest_piece.color != piece.color:
			board.delete_piece(dest_piece, false)
		var prev_type = piece.piece_type
		var prev_ep_target = board.en_passant_target
		var prev_ep_pawn = board.en_passant_pawn
		var rook = null
		var rook_from = null
		var rook_to = null
		var rook_prev_moved = null

		if piece.piece_type == Globals.PIECE_TYPES.KING and abs(pos.x - piece.board_position.x) == 2:
			var y = piece.board_position.y
			if pos.x > piece.board_position.x:
				rook_from = Vector2(7, y)
				rook_to = Vector2(piece.board_position.x + 1, y)
			else:
				rook_from = Vector2(0, y)
				rook_to = Vector2(piece.board_position.x - 1, y)

			rook = board.get_piece(rook_from)
			if rook != null:
				rook_prev_moved = rook.moved
				rook.move_position(rook_to)
				rook.moved = true

		board.en_passant_target = null
		board.en_passant_pawn = null
		moves.append([piece.board_position, move[1], piece.moved, dest_piece, prev_type, rook, rook_from, rook_to, rook_prev_moved, prev_ep_target, prev_ep_pawn])
		piece.move_position(pos)
		if piece.piece_type == Globals.PIECE_TYPES.PAWN and abs(pos.y - moves[-1][0].y) == 2:
			var step = 1 if piece.color == Globals.COLORS.BLACK else -1
			board.en_passant_target = Vector2(pos.x, pos.y - step)
			board.en_passant_pawn = piece
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
		win_lable.text = "Player One Won"
	else:
		win_lable.text = "Player Two Won"

	win_lable.show()
	ui_control.show()


func _on_button_pressed() -> void:
	get_tree().reload_current_scene()
