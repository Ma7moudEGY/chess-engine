extends RefCounted
class_name Evaluator

func evaluate(board, color) -> int:
    var total_white = 0
    var total_black = 0

    for piece in board.pieces:
        if piece.color == Globals.COLORS.WHITE:
            total_white += piece.value
        else:
            total_black += piece.value

    return total_white - total_black if color == Globals.COLORS.WHITE else total_black - total_white
