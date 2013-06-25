module SharedDirections
  def generate_rook_directions
    (-7..7).each do |n|
      unless n == 0
        possible_directions << [0,n]
        possible_directions << [n,0]
      end
    end
  end

  def generate_bishop_directions
    (-7..7).each do |n|
      unless n == 0
        possible_directions << [-n,n]
        possible_directions << [n,n]
      end
    end
  end
end

class ChessPiece
  attr_accessor :position, :possible_directions

  def initialize(position)
    @possible_directions = []
    @position = position
    generate_possible_directions
  end

  def possible_movements
    possible_movements = []
    possible_directions.each do |direction|
      new_coordinate = @position.zip(direction).map { |item| item.inject(:+) }
      possible_movements << new_coordinate
    end

    possible_movements
  end

end

class King < ChessPiece

  def generate_possible_directions
    (-1..1).each do |n|
      (-1..1).each do |m|
        next if n == 0 && m == 0
        possible_directions << [n,m]
      end
    end
  end
end

class Queen < ChessPiece
  include SharedDirections
  def generate_possible_directions
    generate_bishop_directions
    generate_rook_directions
  end
end

class Rook < ChessPiece
  include SharedDirections

  def generate_possible_directions
    generate_rook_directions
  end
end

class Knight < ChessPiece

  def generate_possible_directions
    [-2, -1, 1, 2].each do |n|
      [-2, -1, 1, 2].each do |m|
        next if n.abs == m.abs
        possible_directions << [n,m]
      end
    end
  end
end

class Bishop < ChessPiece
  include SharedDirections

  def generate_possible_directions
    generate_bishop_directions
  end
end

class Pawn < ChessPiece
  def generate_possible_directions
    possible_directions += [[-1,0],[-1,-1],[-1,1],[-2,0],[1,0],[1,1],[1,-1],[2,0]]
  end
end

class Board

  player1.king.position[0] => row
  player1.king.position[1] => column

  8.times do |row|
    8.times do |column|

    end
  end



  def initialize
  end

  def display
  end

end

class Chess

  def initialize
    #start human players
    #set initial board
  end

  def

  def play
  end

end

class HumanPlayer
  attr_accessor :king, :queen, :bishop1, :bishop2, :knight1, :knight2,
  :rook1, :rook2, :pawn1, :pawn2, :pawn3, :pawn4, :pawn5, :pawn6, :pawn7, :pawn8

  def initialize(side)
    set_pieces(side)
  end

  def set_pieces(side)
    side.downcase == "black" ? set_pieces(0) : set_pieces(7)
  end

  def set_pieces(y)
    @king = King.new(y,4)
    @queen = Queen.new(y,3)
    @bishop1 = Bishop.new(y,2)
    @bishop2 = Bishop.new(y,5)
    @knight1 = Knight.new(y,1)
    @knight2 = Knight.new(y,1)
    @rook1 = Rook.new(y,0)
    @rook2 = Rook.new(y,7)
    y == 7 ? y -= 1 : y += 1
    8.times do |index|
      instance_variable_set("pawn#{index+1}",Pawn.new(y,index))
    end
  end

  def move
  end

  def chess_to_array_notation(chess_string)
    column_conversion = Hash[('a'..'h').to_a.zip((0..7).to_a)]
    row_conversion = Hash[(8.downto(1)).to_a.zip((0..7).to_a)]
    split_string = chess_string.split(',')
    [column_conversion[split_string.first],row_conversion[split_string.last]]
  end

end