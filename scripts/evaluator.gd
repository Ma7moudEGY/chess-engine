extends RefCounted
class_name Evaluator

func evaluate(board, color) -> int:
	var white_total = 0
	var black_total = 0
	for cell in board.grid:
		if cell != null:
			var val = board.PIECE_VALUES.get(cell.type, 0)
			if cell.color == Globals.COLORS.WHITE:
				white_total += val
			else:
				black_total += val

	print("i got here")
	return white_total - black_total if color == Globals.COLORS.WHITE else black_total - white_total
