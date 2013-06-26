class Human
  attr_accessor :color

  def initialize(color)
    @color = color
  end

  def move
    print "coordinates of the piece you want to move: "
    start = chess_to_array_notation(gets.chomp)
    print "coordinates of where you want it to go: "
    finish = chess_to_array_notation(gets.chomp)
    [start,finish]
  end

  def chess_to_array_notation(chess_string)
    column_conversion = Hash[('a'..'h').to_a.zip((0..7).to_a)]
    eight_to_one = 8.downto(1).to_a.map(&:to_s)
    row_conversion = Hash[eight_to_one.zip((0..7).to_a)]
    split_string = chess_string.split(//)
    [row_conversion[split_string.last],column_conversion[split_string.first]]
  end

end