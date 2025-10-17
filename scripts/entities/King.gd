extends Piece
class_name King

func get_moves(board: Board) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var move_offsets := [
		# All 8 directions, one step
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
		Vector2i(-1, -1), Vector2i(1, -1),
		Vector2i(-1, 1), Vector2i(1, 1)
	]

	for offset in move_offsets:
		var target_coord: Vector2i = coord + offset

		# Check if the move is within board boundaries
		if target_coord.x >= 0 and target_coord.x < board.board_size and \
		   target_coord.y >= 0 and target_coord.y < board.board_size:
			
			var piece_at = board.get_piece_at(target_coord)
			# A king can move to an empty square or capture an enemy piece.
			if piece_at == null or piece_at.color != self.color:
				moves.append(target_coord)
				
	# TODO: Add castling logic
	# TODO: Add check prevention logic
				
	return moves
