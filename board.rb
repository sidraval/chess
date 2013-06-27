class Board
  attr_accessor :grid

  def initialize
    @grid = Array.new(8){Array.new(8)}
    instantiate_pieces
  end

  def instantiate_pieces
    2.times do |number|
      color = number == 0 ? :black : :white
      row = number * 7

      pieces = [Rook,Knight,Bishop,Queen,King,Bishop,Knight,Rook]
      pieces.each_with_index do |piece,column|
        piece.new(color,self,[row,column])
      end

      row == 7 ? row -= 1 : row += 1
      8.times do |index|
        Pawn.new(color,self,[row,index])
      end
    end
  end
  
  def is_valid?(player,move)
    start,finish = move
    y,x = start
    piece = @grid[y][x]
    return false if piece.nil?
    piece.valid_moves.include?(finish) && player.color == piece.color
  end

  def is_in_check?(color)
    opponents_color = color == :white ? :black : :white
    opponents_pieces = gather_pieces(opponents_color)

    opponents_pieces.any? do |piece|
      piece.unchecked_valid_moves
      puts_in_check?(piece,color)
    end
  end

  def puts_in_check?(piece,kings_color)
    piece.unchecked_valid_moves.each do |position|
      y,x = position
      return true if @grid[y][x].class == King && @grid[y][x].color == kings_color
    end
    false
  end

  def temporary_change(move,moving_piece)
    old_piece = get_piece(move)
    set_piece(move,moving_piece)
    set_piece(moving_piece.position,nil)
    old_piece
  end

  def revert_change(move,old_piece,moving_piece)
    set_piece(move,old_piece)
    set_piece(moving_piece.position,moving_piece)
  end

  def change_board(player_move)
    start,finish = player_move
    sy,sx = start
    fy,fx = finish
    piece = @grid[sy][sx]

    kill_piece(@grid[fy][fx])
    @grid[sy][sx], @grid[fy][fx] = nil, piece
    piece.position = [fy,fx]

    if piece.class == Pawn
      piece.has_moved = true
      promote_pawn(piece) if piece.position[0] == 7 || piece.position[0] == 0
    end

    display
  end

  def promote_pawn(pawn)
    y,x = pawn.position
    print "What piece would you like to promote to? Q K B R: "
    new_piece = gets.chomp
    case new_piece
    when "Q"
      @grid[y][x] = Queen.new(pawn.color,self,pawn.position)
    when "K"
      @grid[y][x] = Knight.new(pawn.color,self,pawn.position)
    when "B"
      @grid[y][x] = Bishop.new(pawn.color,self,pawn.position)
    when "R"
      @grid[y][x] = Rook.new(pawn.color,self,pawn.position)
    end
    kill_piece(pawn)
  end

  def display
    @grid.each_with_index do |row,row_index|
      print " #{8 - row_index} "
      row.each_with_index do |square,square_index|
        set_color = (row_index + square_index) % 2
        if square.nil?
          print "   ".white_on_red if set_color == 0
          print "   ".white_on_black if set_color != 0
        else
          print " #{square.symbol} ".white_on_red if set_color == 0
          print " #{square.symbol} ".white_on_black if set_color != 0
        end
      end
      print "\n"
    end
    print "    a  b  c  d  e  f  g  h \n"
  end

  def gather_pieces(color)
    pieces = []
    @grid.each do |row|
      row.each do |square|
        next if square.nil?
        pieces << square if square.color == color
      end
    end
    pieces
  end

  def kill_piece(piece)
    piece.position = [-1000,-1000] unless piece.nil?
  end

  def get_piece(position)
    y,x = position
    return nil if y < 0 || x < 0
    @grid[y][x]
  end

  def set_piece(position,piece)
    y,x = position
    @grid[y][x] = piece
  end

  def in_mate?(color)
    my_pieces = gather_pieces(color)
    valid_moves = []
    my_pieces.each do |piece|
      valid_moves += piece.valid_moves
    end
    valid_moves.empty?
  end

end