class GameController < ApplicationController
  before_action :authenticate_user!

  def main_menu
    @game_sessions = current_user.game_sessions
  end

  def create
    begin
      generation, height, width, grid = validate_raw_input(params[:input])
      raw_grid = ''
      grid.each_with_index do |row, index|
        raw_grid += index == 0 ? row.join("") : "\r\n%s" % row.join("")
      end

      game_session = current_user.game_sessions.create!
      game_session.game_states.create!(generation: generation, grid_height: height, grid_width: width, raw_grid: raw_grid)

    rescue => err
      redirect_to "/game", notice: err.message
    else
      redirect_to controller: 'game', action: 'play', game_session: game_session
    end
  end

  def play
    p params[:game_session]
    @game_session = GameSession.find_by(id: params[:game_session])
    @current_state = @game_session.game_states.last
    @grid = extract_grid(
      @current_state.grid_height,
      @current_state.grid_width,
      @current_state.raw_grid.split("\r\n"),
      0
    )
  end

  def generate_next
    p params[:game_session]
    game_session = GameSession.find_by(id: params[:game_session])
    current_state = game_session.game_states.last
    grid = extract_grid(
      current_state.grid_height,
      current_state.grid_width,
      current_state.raw_grid.split("\r\n"),
      0
    )
    next_grid = build_next_generation(grid, current_state.grid_height, current_state.grid_width)
    raw_next_grid = ''
    next_grid.each_with_index do |row, index|
      raw_next_grid += index == 0 ? row.join("") : "\r\n%s" % row.join("")
    end
    game_session.game_states.create!(
      generation: current_state.generation+1,
      grid_height: current_state.grid_height,
      grid_width: current_state.grid_width,
      raw_grid: raw_next_grid
    )
    redirect_to controller: 'game', action: 'play', game_session: game_session
  end

  private

  def build_next_generation(grid, height, width)
    Rails.logger.debug "build_next_generation grid %s, height %d, width %d" % [grid, height, width]

    current_row = 1
    ending_row = height - 1

    starting_column = 1
    current_column = starting_column
    ending_column = width - 1

    updated_grid = grid.deep_dup

    while current_row < ending_row
      while current_column < ending_column
        if grid[current_row][current_column] == '.' && count_alive_neighbours(current_row, current_column, grid, height, width) >= 3
          updated_grid[current_row][current_column] = '*'
        else if grid[current_row][current_column] == '*' &&
          count_alive_neighbours(current_row, current_column, grid, height, width) < 2 || count_alive_neighbours(current_row, current_column, grid, height, width) > 3
               updated_grid[current_row][current_column] = '.'
             else
               updated_grid[current_row][current_column] = grid[current_row][current_column]
             end
        end

        current_column += 1
      end

      current_row += 1
      current_column = starting_column
    end

    return updated_grid
  end

  def count_alive_neighbours(row, column, grid, height, width)
    alive_neighbours = 0

    current_row = row == 0 ? row : row-1
    ending_row = row == height-1 ? row : row+1

    starting_column = column == 0 ? column : column-1
    current_column = starting_column
    ending_column = column == width-1 ? column : column+1


    while current_row <= ending_row
      while current_column <= ending_column
        if current_row != row || current_column != column
          "position %d, %d is %s" % [current_row, current_column, grid[current_row][current_column]]
          if  grid[current_row][current_column] == '*'
            alive_neighbours += 1
          end
        end
        current_column += 1
      end

      current_row += 1
      current_column = starting_column
    end

    return alive_neighbours
  end

  def validate_raw_input(uploaded_file)
      raw_input = uploaded_file.read.split("\r\n")
      generation = extract_generation(raw_input[0])
      height, width = extract_height_width(raw_input[1])
      Rails.logger.debug "Input file for generation %d, with dimensions %d, %d" % [generation, height, width]
      grid = extract_grid(height, width, raw_input, 2)
      return generation, height, width, grid
  end

  def extract_generation(input_generation_line)
    Rails.logger.debug "extract_generation input %s" % input_generation_line
    raw_generation =  input_generation_line.to_s.gsub(/Generation / ,"").to_s.gsub(/:/ ,"")
    Rails.logger.debug "extract_generation raw_generation %s" % raw_generation
    generation = nil
    if raw_generation.match(/^(\d)+$/)
      generation = Integer(raw_generation)
    end

    if generation.nil?
      raise "Unexpected generation format"
    end

    return generation
  end

  def extract_height_width(input_dimensions_line)
    Rails.logger.debug "extract_height_width input_dimensions_line %s" % [input_dimensions_line]
    raw_dimensions = input_dimensions_line.split
    if raw_dimensions.length != 2
      raise "Unexpected number of dimensions"
    end

    height = nil
    if raw_dimensions[0].match(/^(\d)+$/)
      height = Integer(raw_dimensions[0])
    end
    width = nil
    if raw_dimensions[1].match(/^(\d)+$/)
      width = Integer(raw_dimensions[1])
    end

    if height.nil? || width.nil?
      raise "Unexpected dimension format"
    end

    return height, width
  end

  def extract_grid(height, width, raw_input, starting_index)
    Rails.logger.debug "extract_grid height %d, width %d, raw_input %s, starting_index %d" % [height, width, raw_input, starting_index]
    current_index = starting_index

    if starting_index + height != raw_input.length
      raise "Unexpected grid dimensions"
    end

    grid = Array.new(height){Array.new(width)}

    while current_index < raw_input.length
      cells = raw_input[current_index].chars
      if cells.length > width
        raise "Unexpected grid dimensions"
      end
      cells.each_with_index do |cell, index|
        grid[current_index - starting_index][index] = cell
      end
      current_index += 1
    end

    return grid
  end
end
