extends Piece
class_name Bishop

func get_moves(board: Board) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var directions := [
		Vector2i(-1, -1),  # Arriba-Izquierda
		Vector2i(1, -1),   # Arriba-Derecha
		Vector2i(-1, 1),   # Abajo-Izquierda
		Vector2i(1, 1)     # Abajo-Derecha
	]

	for dir in directions:
		var current_coord: Vector2i = coord + dir
		# Loop while the coordinate is within the board limits
		while current_coord.x >= 0 and current_coord.x < board.board_size and \
			  current_coord.y >= 0 and current_coord.y < board.board_size:
			
			var piece_at = board.get_piece_at(current_coord)
			if piece_at == null:
				# The square is empty, add to moves and continue in the same direction
				moves.append(current_coord)
				current_coord += dir
			else:
				# The square is occupied
				if piece_at.color != self.color:
					# It's an enemy piece, we can capture it.
					moves.append(current_coord)
				# Stop searching in this direction, as we're blocked.
				break
	return moves
