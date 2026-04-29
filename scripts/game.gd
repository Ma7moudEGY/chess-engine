extends Node2D

@export var start_fen: String
@export var current_fen: String

var game_over
var player_color
var status
var player2_type
var halfmove_clock := 0
var fullmove_number := 1

const DEBUG_LOG := false
const Move = preload("res://scripts/move.gd")
const MoveGenerator = preload("res://scripts/move_generator.gd")

var is_dragging: bool
var selected_piece = null
var previous_position = null
var selected_legal_targets = {}

var pending_promotion_pawn = null

var position_counts = {}
var position_history = []

var move_generator = null

# Move objects captured for undo.
var moves = []

@onready var board = $Board
@onready var ui_control = $Control
@onready var win_lable = $Control/WinLable
@onready var promotion_ui = $Promotion
@onready var k = $Promotion/Knight
@onready var b = $Promotion/Bishop
@onready var r = $Promotion/Rook
@onready var q = $Promotion/Queen

func _ready() -> void:
	position_counts = {}
	position_history = []
	init_game()
	if start_fen != "":
		load_fen(start_fen)

	var current_pos = get_current_pos()
	position_history.append(current_pos)
	position_counts[current_pos] = 1
	if status == Globals.COLORS.BLACK and player2_type == Globals.PLAYER_2_TYPE.AI:
		player2_move()

	ui_control.hide()
	promotion_ui.hide()

func _input(event: InputEvent) -> void:
	if game_over or pending_promotion_pawn != null:
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
		if pending_promotion_pawn != null:
			return
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
		if pending_promotion_pawn != null:
			return
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
	halfmove_clock = 0
	fullmove_number = 1
	move_generator = MoveGenerator.new(board, status)


func get_fen() -> String:
	return board.get_fen(status, halfmove_clock, fullmove_number)

func get_current_pos():
	var arr = get_fen().strip_edges().split(" ")
	return arr[0] + " " + arr[1] + " " + arr[2] + " " + arr[3]

func load_fen(fen: String) -> bool:
	clear_selection()
	board.clear_move_markers()
	board.clear_check_marker()
	position_counts = {}
	position_history = []
	pending_promotion_pawn = null
	moves.clear()
	board.en_passant_target = null
	board.en_passant_pawn = null

	var result = board.set_fen(fen)
	if not result.get("ok", false):
		return false

	status = result["active_color"]
	halfmove_clock = result["halfmove"]
	fullmove_number = result["fullmove"]
	game_over = false

	var current_pos = get_current_pos()
	position_history.append(current_pos)
	position_counts[current_pos] = 1

	move_generator.status = status
	
	return true

func undo_move():
	if !moves.is_empty():
		# if DEBUG_LOG:
		# 	print(moves)
		var king_pos = board.white_king_pos if status != Globals.COLORS.WHITE else board.black_king_pos
		var move = moves.pop_back()
		var src_piece = board.get_piece(move.to_pos)
		src_piece.move_position(move.from_pos)
		src_piece.moved = move.moved
		src_piece.piece_type = move.prev_type
		src_piece.update_sprite()

		var captured = move.captured
		if captured != null:
			board.restore_piece(captured)

		var rook = move.rook
		if rook != null:
			rook.move_position(move.rook_from)
			rook.moved = move.rook_prev_moved

		board.en_passant_target = move.prev_ep_target
		board.en_passant_pawn = move.prev_ep_pawn

		if move.was_in_check == true:
			board.draw_check_marker(king_pos)
		else:
			board.clear_check_marker()

		halfmove_clock = move.prev_halfmove
		fullmove_number = move.prev_fullmove

		status = Globals.COLORS.BLACK if status == Globals.COLORS.WHITE else Globals.COLORS.WHITE
		move_generator.status = status

		current_fen = get_fen()

		var last_pos = position_history.pop_back()
		position_counts[last_pos] -= 1

		if position_counts[last_pos] == 0:
			position_counts.erase(last_pos)

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

func set_buttons_color(col: Globals.COLORS):
	k.set_texture_normal(load(Globals.SPRITE_MAPPING[col][Globals.PIECE_TYPES.KNIGHT]))
	b.set_texture_normal(load(Globals.SPRITE_MAPPING[col][Globals.PIECE_TYPES.BISHOP]))
	r.set_texture_normal(load(Globals.SPRITE_MAPPING[col][Globals.PIECE_TYPES.ROOK]))
	q.set_texture_normal(load(Globals.SPRITE_MAPPING[col][Globals.PIECE_TYPES.QUEEN]))


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
	for move in move_generator.get_valid_moves():
		if move[0] == piece:
			targets[move[1]] = true
	return targets

func apply_move(piece, to_pos):
	var dest_piece = board.get_piece(to_pos)
	if piece.piece_type == Globals.PIECE_TYPES.PAWN and dest_piece == null and board.en_passant_target != null:
		if to_pos == board.en_passant_target and board.en_passant_pawn != null and board.en_passant_pawn.color != piece.color:
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

	if piece.piece_type == Globals.PIECE_TYPES.KING and abs(to_pos.x - piece.board_position.x) == 2:
		var y = piece.board_position.y
		if to_pos.x > piece.board_position.x:
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

	if piece.piece_type == Globals.PIECE_TYPES.PAWN:
		if (piece.color == Globals.COLORS.WHITE and to_pos.y == 0) or (piece.color == Globals.COLORS.BLACK and to_pos.y == 7):
			var is_ai = (piece.color != player_color and player2_type == Globals.PLAYER_2_TYPE.AI)
			if is_ai:
				piece.piece_type = Globals.PIECE_TYPES.QUEEN
				piece.update_sprite()
			else:
				pending_promotion_pawn = piece
				set_buttons_color(piece.color)
				promotion_ui.show()

	var in_check = move_generator.is_king_in_check(status)
	var prev_halfmove = halfmove_clock
	var prev_fullmove = fullmove_number
	var is_pawn_move = piece.piece_type == Globals.PIECE_TYPES.PAWN
	var is_capture = dest_piece != null and dest_piece.color != piece.color
	halfmove_clock = 0 if is_pawn_move or is_capture else halfmove_clock + 1
	if status == Globals.COLORS.BLACK:
		fullmove_number += 1

	moves.append(Move.new(piece.board_position, to_pos, piece.moved, dest_piece, prev_type, rook, rook_from, rook_to, rook_prev_moved, prev_ep_target, prev_ep_pawn, in_check, prev_halfmove, prev_fullmove))
	piece.move_position(to_pos)

	if piece.piece_type == Globals.PIECE_TYPES.PAWN and abs(to_pos.y - moves[-1].from_pos.y) == 2:
		var step = 1 if piece.color == Globals.COLORS.BLACK else -1
		board.en_passant_target = Vector2(to_pos.x, to_pos.y - step)
		board.en_passant_pawn = piece	

	if !move_generator.is_king_in_check(status):
		board.clear_check_marker()

	status = Globals.COLORS.BLACK if status == Globals.COLORS.WHITE else Globals.COLORS.WHITE

	move_generator.status = status

	var king_pos = board.white_king_pos if status == Globals.COLORS.WHITE else board.black_king_pos
	if move_generator.is_king_in_check(status):
		board.draw_check_marker(king_pos)

	current_fen = get_fen()
	# print(current_fen)

	# record pos
	var current_pos = get_current_pos()
	position_history.append(current_pos)
	if position_counts.has(current_pos):
		position_counts[current_pos] += 1
	else:
		position_counts[current_pos] = 1

func try_move_to(to_move) -> bool:
	if selected_piece == null:
		return false
	if not selected_legal_targets.is_empty():
		if not selected_legal_targets.has(to_move):
			return false

	if move_generator.valid_move(selected_piece.board_position, to_move):
		apply_move(selected_piece, to_move)

		if DEBUG_LOG:
			print(moves)

		return true
	return false


func player2_move():
	if player2_type == Globals.PLAYER_2_TYPE.AI:
		var valid_moves = move_generator.get_valid_moves()

		var move = valid_moves.pick_random()
		var piece = move[0]
		var pos = move[1]

		apply_move(piece, pos)

		evaluate_end_game()

func evaluate_end_game():
	var m = move_generator.get_valid_moves()
	if m.is_empty():
		if move_generator.is_king_in_check(Globals.COLORS.WHITE if status == Globals.COLORS.WHITE else Globals.COLORS.BLACK):
			set_win(Globals.PLAYER.TWO if status == player_color else Globals.PLAYER.ONE)
			return true
		else:
			set_draw()
			return true

	if is_insufficient_material():
		set_draw()
		return true

	var current_pos = get_current_pos()
	if position_counts[current_pos] >= 3:
		set_draw()
		return true

	if halfmove_clock >= 100:
		set_draw()
		return true

	return false

func is_insufficient_material() -> bool:
	var white_knights = 0
	var black_knights = 0
	var white_bishops = []
	var black_bishops = []
	var white_other = 0
	var black_other = 0

	for piece in board.pieces:
		if piece.piece_type == Globals.PIECE_TYPES.KING:
			continue
		match piece.piece_type:
			Globals.PIECE_TYPES.KNIGHT:
				if piece.color == Globals.COLORS.WHITE:
					white_knights += 1
				else:
					black_knights += 1
			Globals.PIECE_TYPES.BISHOP:
				var color_bit = (int(piece.board_position.x) + int(piece.board_position.y)) % 2
				if piece.color == Globals.COLORS.WHITE:
					white_bishops.append(color_bit)
				else:
					black_bishops.append(color_bit)
			Globals.PIECE_TYPES.PAWN, Globals.PIECE_TYPES.ROOK, Globals.PIECE_TYPES.QUEEN:
				if piece.color == Globals.COLORS.WHITE:
					white_other += 1
				else:
					black_other += 1

	if white_other > 0 or black_other > 0:
		return false

	var white_minor = white_knights + white_bishops.size()
	var black_minor = black_knights + black_bishops.size()

	if white_minor == 0 and black_minor == 0:
		return true

	if white_minor == 0 and black_minor == 1:
		return true

	if black_minor == 0 and white_minor == 1:
		return true

	if white_knights == 0 and black_knights == 0 and white_bishops.size() == 1 and black_bishops.size() == 1:
		return white_bishops[0] == black_bishops[0]

	return false

func set_win(who: Globals.PLAYER):
	game_over = true
	if who == Globals.PLAYER.ONE:
		win_lable.text = "Player One Won"
	else:
		win_lable.text = "Player Two Won"

	win_lable.show()
	ui_control.show()

func set_draw():
	game_over = true
	win_lable.text = "IT'S A DRAW"
	win_lable.show()
	ui_control.show()


func _on_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_knight_pressed() -> void:
	pending_promotion_pawn.piece_type = Globals.PIECE_TYPES.KNIGHT
	pending_promotion_pawn.update_sprite()
	promotion_ui.hide()
	pending_promotion_pawn = null
	if evaluate_end_game():
		return
	if player2_type == Globals.PLAYER_2_TYPE.AI and status == Globals.COLORS.BLACK:
		call_deferred("player2_move")


func _on_bishop_pressed() -> void:
	pending_promotion_pawn.piece_type = Globals.PIECE_TYPES.BISHOP
	pending_promotion_pawn.update_sprite()
	promotion_ui.hide()
	pending_promotion_pawn = null
	if evaluate_end_game():
		return
	if player2_type == Globals.PLAYER_2_TYPE.AI and status == Globals.COLORS.BLACK:
		call_deferred("player2_move")


func _on_rook_pressed() -> void:
	pending_promotion_pawn.piece_type = Globals.PIECE_TYPES.ROOK
	pending_promotion_pawn.update_sprite()
	promotion_ui.hide()
	pending_promotion_pawn = null
	if evaluate_end_game():
		return
	if player2_type == Globals.PLAYER_2_TYPE.AI and status == Globals.COLORS.BLACK:
		call_deferred("player2_move")


func _on_queen_pressed() -> void:
	pending_promotion_pawn.piece_type = Globals.PIECE_TYPES.QUEEN
	pending_promotion_pawn.update_sprite()
	promotion_ui.hide()
	pending_promotion_pawn = null
	if evaluate_end_game():
		return
	if player2_type == Globals.PLAYER_2_TYPE.AI and status == Globals.COLORS.BLACK:
		call_deferred("player2_move")
