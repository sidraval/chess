# Organize code by method (i.e. group together methods that call one another whenever possible)
require 'debugger'

module SharedDirections
  def straight_directions
    @directions += [[0,1],[1,0],[-1,0],[0,-1]]
  end

  def diagonal_directions
    @directions += [[-1,1],[1,1],[1,-1],[-1,-1]]
  end
end

class ChessPiece
  # Figure out what actually needs to be accessible
  attr_accessor :directions, :moves, :player, :position, :symbol

  def initialize(color,board,position)
    @player = color
    @board = board
    @moves = []
    @position = position
    @directions = []
    set_symbol
    set_directions
    add_to_board
    
    # Where should valid_moves be called?
    # debugger
    # valid_moves

  end

  def add_to_board
    y,x = @position
    @board.grid[y][x] = self
  end

  # Worries about opponent's newly available moves
  def valid_moves
    unchecked_valid_moves
    moves_to_delete = []

    @moves.each do |move|
      old_piece = temporary_board(move)
      # placed_in_check? tells you if your move resulted in you being placed in check.
      moves_to_delete << move if placed_in_check?(move)
      revert_board(move,old_piece)
    end
    
    @moves = @moves - moves_to_delete
  end

  def placed_in_check?(move)
    opponents_color = self.player == "white" ? "black" : "white"
    opponents_pieces = gather_pieces(opponents_color)

    opponents_pieces.any? do |piece|
      piece.unchecked_valid_moves
      is_checked?(piece)
    end
  end

  # Deserves a rename
  # Maybe the player attribute does too.
  def is_checked?(piece)
    our_color = self.player
    piece.moves.each do |position|
      y,x = position
      return true if @board.grid[y][x].class == King && @board.grid[y][x].player == our_color
    end
    false
  end

  def temporary_board(move)
    y,x = move
    old_piece = @board.grid[y][x]
    @board.grid[y][x] = self

    y,x = self.position
    @board.grid[y][x] = nil

    return old_piece
  end

  def revert_board(move,old_piece)
    y,x = move
    @board.grid[y][x] = old_piece
    y,x = self.position
    @board.grid[y][x] = self
  end

  def gather_pieces(color)
    pieces = []
    @board.grid.each do |row|
      row.each do |square|
        next if square.nil?
        pieces << square if square.player == color
      end
    end
    pieces
  end

  def validity(position)
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
  # Needs to be more than one method?
  def unchecked_valid_moves
    @moves = []
    @directions.each do |direction|
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

  def unchecked_valid_moves
    @moves = []
    @directions.each do |direction|
      new_position = @position
      new_position = new_position.zip(direction).map { |p| p.inject(:+) }
      @moves << new_position if validity(new_position) != "Next direction"
    end
  end

end

class King < SteppingPiece
  include SharedDirections

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
  include SharedDirections

  def set_directions
    diagonal_directions
  end

  def set_symbol
    @symbol = @player == "white" ? "\u2657" : "\u265D"
  end

end

class Pawn < ChessPiece
  def unchecked_valid_moves
  end

  def set_directions
    if @player == "white"
      @directions += [[-1,0],[-1,-1],[-1,1],[-2,0]]
    else
      @directions += [[1,0],[1,1],[1,-1],[2,0]]
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
    # Change piece's position
    @grid[y][x] = nil
    y,x = finish
    @grid[y][x] = piece
  end
  
  # Color coding
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

end

class Chess
  attr_accessor :board, :player1, :player2

  def initialize
    @board = Board.new
    @player1 = Human.new("white",@board)
    @player2 = Human.new("black",@board)
  end
end

class Human
  attr_accessor :king, :queen, :bishop1, :bishop2, :knight1, :knight2, :color,
  :rook1, :rook2, :pawn1, :pawn2, :pawn3, :pawn4, :pawn5, :pawn6, :pawn7, :pawn8

  def initialize(color,board)
    @color = color
    set_pieces(board)
  end

  def set_pieces(board)
    # debugger
    y = @color == "white" ? 7 : 0

    @king = King.new(@color,board,[y,4])
    @queen = Queen.new(@color,board,[y,3])
    @bishop1 = Bishop.new(@color,board,[y,2])
    @bishop2 = Bishop.new(@color,board,[y,5])
    @knight1 = Knight.new(@color,board,[y,1])
    @knight2 = Knight.new(@color,board,[y,6])
    @rook1 = Rook.new(@color,board,[y,0])
    @rook2 = Rook.new(@color,board,[y,7])

    (y == 7) ? (y -= 1) : (y += 1)
    8.times do |index|
      instance_variable_set("@pawn#{index+1}",Pawn.new(@color,board,[y,index]))
    end
  end
end


