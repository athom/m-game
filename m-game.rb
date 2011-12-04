require 'thread'
module Game
  M=10
  P=5

  class Model
	attr_reader :level, :number
	def initialize(level, number)
	  @level = level
	  @number = number
	end

	def board_size
	  return[@level, @level]
	end

	def generate
	  a = []
	  (0 ... @level).to_a.each_with_index do |i|
		(0 ... @level).to_a.each_with_index do |j|
		  a << [i, j]
		end
	  end
	  m=a.sort_by{rand}[0...@number]
	  @h = {}
	  for i in 1..@number
		@h[i] = m[i-1]
	  end
	  @h
	end

	def hit?(coord,index)
	  @h[index] == coord
	end
  end

  class Controller
	attr_reader :show_time, :end_time
	attr_accessor :quit_time
	def initialize(m, a)
	  @model = m
	  @app = a
	  @@count = 1
	  @show_time = true
	  @end_time = false
	  @quit_time = false
	end

	def seed
	  @@count = 1
	  @show_time = true
	  @end_time = false
	  @quit_time = false
	  @model.generate
	end

	def play(coord)
	  @show_time = false
	  if @model.hit?(coord, @@count)
		@@count += 1
		@end_time = @@count-1 == @model.number
		return @@count - 1
		#return true
	  end
	  return false
	end

  end


  def left_top_corner_of_piece(a, b, w, h)
	[(a*w + P), (b*h + P)]
  end

  def right_bottom_corner_of_piece(a,b,w,h)
	left_top_corner_of_piece(a,b,w,h).map { |coord| coord + w }
  end

  def pos2coord(x,y,size)
	w = (self.width - 2*M - 2*P)/size
	h = (self.height - 2*M - 2*P)/size

	Array.new(size){Array.new(size){0}}.each_with_index { |row_array, row| 
      row_array.each_with_index { |col_array, col| 
        left, top = left_top_corner_of_piece(col, row, w, h).map { |i| i + M}
        right, bottom = right_bottom_corner_of_piece(col, row, w, h).map { |i| i + M }
        return [col, row] if x >= left && x <= right && y >= top && y <= bottom
      } 
    }
    return false
  end

  def coord2pos(coord,size)
	w = (self.width - 2*M - 2*P)/size
	h = (self.height - 2*M - 2*P)/size
	x = w*coord[0] + M + P
	y = h*coord[1] - P
	[x, y]
  end

  def render_board(size)
	#back ground
    clear do
      background rgb(11, 11, 11, 0.8)
	end

	#board
	u_width = (self.width - 2*M - 2*P)/size
	u_height = (self.height - 2*M - 2*P)/size

	stack :margin => M do
	  fill rgb(120, 190, 0)
	  rect :left => 0, :top => 0, :width => self.width - 2*M, :height => self.height - 2*M 

	  board = Array.new(size){Array.new(size){0}}
	  board.each_with_index do |col, col_index|
		col.each_with_index do |row, row_index|
		  left, top =  left_top_corner_of_piece(col_index, row_index, u_width, u_height)
		  strokewidth 1
		  fill rgb(219, 169, 109)
		  rect :left => left, :top => top, :width => u_width, :height => u_height
		end
	  end
	end
  end

  def render_ball(coord, size, index)
	pos = coord2pos(coord, size)
	r = (self.width-2*M)/size
	#stack :margin => M+P do
	stack  do
	  fill rgb(198, 70, 52)
	  oval(pos[0],pos[1], r)
	  para(index.to_s,:top => pos[1]+r/2.5, :left => pos[0]+r/3, :size => 30)
	end
  end
end


Shoes.app :width => 600 , :height => 600 do
  extend Game

  LEVEL = 6
  NUMBER = 6

  @m = Model.new(LEVEL,NUMBER)
  @c = Controller.new(@m,self)

  def render_b(coord, size, index)
	render_ball(coord, size, index)
  end

  @s = @c.seed
  p @s
  render_board(@m.level)

  @t = Time.now
  def update
    t = Time.now
    if t.sec != @t.sec
      @t = t
    else
      false
    end
  end

  @i = 1
  every 1 do
	if update && @c.show_time or @c.end_time
	  if @i <= @m.number
		for j in 1 .. @i
		  render_b(@s[j], @m.level, j)
		end
		@i += 1
	  else
		render_board(@m.level)
	  end
	end

  end
  
  cds = {}

  every 2 do
	if @c.end_time
	  cds.clear
	  @m = Model.new(LEVEL,@m.number + 1)
	  @c = Controller.new(@m,self)
	  @i = 1
	  @s = @c.seed
	  p @s
	  render_board(@m.level)
	end
	if @c.quit_time
	  @m = Model.new(LEVEL,@m.number - 1)
	  @c = Controller.new(@m,self)
	  @i = 1
	  @s = @c.seed
	  p @s
	  render_board(@m.level)
	end
  end

  click do |button, x, y| 
    if coord = pos2coord(x,y, @m.level)
      begin
        if index = @c.play(coord)
		  cds[index] = coord
		  cds.each do |k, v|		
			render_b(v, @m.level, k)
		  end
		  if @c.end_time
			para('Wonderful!',:top => self.height/2 -30, :left => self.width/2 - 100, :size => 30, :stroke => "#44fc37")
		  end
		else
			para('Ooooooops!',:top => self.height/2 -30, :left => self.width/2 - 100, :size => 30, :stroke => "#ff4141")
			cds.clear
			@c.quit_time = true
		end
      rescue => e
        alert(e.message)
      end
    else
        #alert("Not a piece.")
    end
  end 

end
