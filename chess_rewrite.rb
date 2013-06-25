module SharedDirections
  def straight_directions
    directions << [[0,1],[1,0],[-1,0],[0,-1]]
  end

  def diagonal_directions
    directions << [[-1,1],[1,1],[1,-1],[-1,-1]]
  end
end

class ChessPiece
  attr_accessor :directions, :moves

  def initialize(player,board)
    @board = board
    @possible_moves =[]
    set_symbol(player)
    set_directions
  end

  def is_valid?
  end
end

class King < ChessPiece
  include ShareDirections

  def set_directions
    straight_directions
    diagonal_directions
  end

  def set_symbol(player)
    @symbol = player == "white" ? "\u2654" : "\u265A"
  end

  def make_moves
    # use is_valid? method from ChessPiece inheritance
  end
end

class Queen < ChessPiece
  include SharedDirections
  def set_directions
    straight_directions
    diagonal_directions
  end

  def set_symbol(player)
    @symbol = player == "white" ? "\u2655" : "\u265B"
  end

  def make_moves
  end
end

def