extends RefCounted
class_name ai

var board

func _init(_board) -> void:
	board = _board

func get_best_move(valid_moves):
	var best_score = -10
	var best_move = null
	for move in valid_moves:
		var piece = move[0]
		var to_pos = move[1] 
		var score = get_move_score(piece, to_pos)
		if score >= best_score:
			best_score = score
			best_move = move

	return best_move

func get_move_score(piece, to_pos):
	var dest_piece = board.get_piece(to_pos)
	if dest_piece != null:
		# Capture: score based on material gained/lost
		return piece_to_score(dest_piece) - piece_to_score(piece)
	else:
		# Quiet move: prefer pawn advances
		if piece.piece_type == Globals.PIECE_TYPES.PAWN:
			return 0.3
		else:
			return 0.1


func piece_to_score(piece):
	match piece.piece_type:
		Globals.PIECE_TYPES.PAWN:
			return 1
		Globals.PIECE_TYPES.KNIGHT:
			return 3
		Globals.PIECE_TYPES.BISHOP:
			return 3
		Globals.PIECE_TYPES.ROOK:
			return 5
		Globals.PIECE_TYPES.QUEEN:
			return 9
		Globals.PIECE_TYPES.KING:
			return 100
		
