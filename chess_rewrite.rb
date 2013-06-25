module SharedDirections
  def straight_directions
    directions += [[0,1],[1,0],[-1,0],[0,-1]]
  end

  def diagonal_directions
    directions += [[-1,1],[1,1],[1,-1],[-1,-1]]
  end
end

class ChessPiece
  attr_accessor :directions, :moves, :player, :position, :symbol

  def initialize(player,board,position)
    @player = player
    @board = board
    @moves = []
    @position = position
    set_symbol
    set_directions
    make_moves
  end

  # Worries about opponent's newly available moves
  def make_current_moves
    make_moves
    our_color = self.player
    opponents_color = self.player == "white" ? "black" : "white"

    @moves.select do |move|
      old_piece = temporary_board(move)
      opponents_pieces = gather_pieces(opponents_color)
      opponents_pieces.each do |piece|
        piece.make_move
        piece.moves.each do |position|
          y,x = position
          if board[y][x].class == King && board[y][x].player == our_color
            @moves.delete(move)
          end
        end
      end
      revert_board(move,old_piece)
    end
  end

  def placed_in_check?(move)
    opponenets_pieces.any? do |piece|
      piece.make_move
      placed_in_check?(piece)
    end
  end

  def placed_in_check?(piece)
    piece.moves.each do |position|
      y,x = position
      return true if board[y][x].class == King && board[y][x].player == our_color
    end
    false
  end

  def temporary_board(move)
    y,x = move
    old_piece = @board[y][x]
    @board[y][x] = self
    y,x = self.position
    @board[y][x] = nil

    return old_piece
  end

  def revert_board(move,old_piece)
    y,x = move
    @board[y][x] =
    y,x = self.position
    @board[y][x] = old_piece
  end

  def gather_pieces(color)
    pieces = []
    board.each do |row|
      row.each do |square|
        next if square.nil?
        pieces << square if square.player == color
      end
    end
    pieces
  end

  def  validity(position)
    y,x = position
    return "Next direction" if !((0..7).include?(x) && (0..7).include?(y))

    piece = @board.grid[y][x]
    if piece.nil?
      return "Empty spot"
    elsif piece.player == self.player
      return "Next direction"
    else
      return "Opponents piece"
    end
  end
end

class SlidingPiece < ChessPiece

  # Makes moves without worrying about opponents new valid moves
  def make_moves
    directions.each do |direction|
      new_position = @position
      bad_direction = false
      until bad_direction
        # Sums corresponding elements of two arrays
        new_position = new_position.zip(direction).map { |p| p.inject(:+) }
        case validity(new_position)
        when "Next direction"
          bad_direction = true
        when "Opponents piece"
          @moves << new_position
          bad_direction = true
        when "Empty spot"
          @moves << new_position
        end
      end
    end
  end

end

class SteppingPiece < ChessPiece

  def make_moves
    directions.each do |direction|
      new_position = @position
      new_position = new_position.zip(direction).map { |p| p.inject(:+) }
      @moves << new_position if validity(new_position) != "Next direction"
    end
  end

end

class King < SteppingPiece
  include ShareDirections

  def set_directions
    straight_directions
    diagonal_directions
  end

  def set_symbol
    @symbol = @player == "white" ? "\u2654" : "\u265A"
  end

end

class Queen < SlidingPiece
  include SharedDirections
  def set_directions
    straight_directions
    diagonal_directions
  end

  def set_symbol
    @symbol = @player == "white" ? "\u2655" : "\u265B"
  end

end

class Rook < SlidingPiece
  include SharedDirections

  def set_directions
    straight_directions
  end

  def set_symbol
    @symbol = @player == "white" ? "\u2656" : "\u265C"
  end

end

class Knight < SteppingPiece

  def set_directions
    [-2, -1, 1, 2].each do |n|
      [-2, -1, 1, 2].each do |m|
        next if n.abs == m.abs
        directions << [n,m]
      end
    end
  end

  def set_symbol
    @symbol = @player == "white" ? "\u2658" : "\u265E"
  end

end

class Bishop < SlidingPiece
  def set_directions
    diagonal_directions
  end

  def set_symbol
    @symbol = @player == "white" ? "\u2657" : "\u265D"
  end

end

class Pawn < ChessPiece
  def set_directions
    if @player == "white"
      directions += [[-1,0],[-1,-1],[-1,1],[-2,0]]
    else
      directions += [[1,0],[1,1],[1,-1],[2,0]]
    end
  end

  def set_symbol
    @symbol = @player == "white" ? "\u2659" : "\u265F"
  end
end

class Board
  attr_accessor :grid

  def initialize
    @grid = make_board
  end

  def make_board
    board = []
    8.times do |row|
      row = []
      8.times { row << nil }
      board << row
    end
    board
  end

  def change_board(player_move)
    start,finish = player_move
    y,x = start
    piece = @grid[y][x]
    @grid[y][x] = nil
    y,x = finish
    @grid[y][x] = piece
  end

  def display
    @grid.each do |row|
      row.each do |square|
        if square.nil?
          print "   "
        else
          print " #{square.symbol} "
        end
      end
      print "\n"
    end
  end

  def populate(white,black)
    white.each do |piece|
      y,x = piece.position
      @grid[y][x] = piece
    end
    black.each do |piece|
      y,x = piece.position
      @grid[y][x] = piece
    end
  end

end




