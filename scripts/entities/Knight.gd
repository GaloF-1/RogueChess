extends Piece
class_name Knight

func get_moves(board: Board) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var move_offsets := [
		Vector2i(1, 2), Vector2i(1, -2),
		Vector2i(-1, 2), Vector2i(-1, -2),
		Vector2i(2, 1), Vector2i(2, -1),
		Vector2i(-2, 1), Vector2i(-2, -1)
	]

	for offset in move_offsets:
		var target_coord: Vector2i = coord + offset

		# Check if the move is within board boundaries
		if target_coord.x >= 0 and target_coord.x < board.board_size and \
		   target_coord.y >= 0 and target_coord.y < board.board_size:
			
			var piece_at = board.get_piece_at(target_coord)
			# A knight can move to an empty square or capture an enemy piece.
			if piece_at == null or piece_at.color != self.color:
				moves.append(target_coord)
				
	return moves
