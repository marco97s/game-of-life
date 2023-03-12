class GameController < ApplicationController
  before_action :authenticate_user!

  def main_menu
    @game_sessions = current_user.game_sessions
  end

  def create
    begin
      generation, height, width, matrix = validate_raw_input(params[:input])
      raw_matrix = ''
      matrix.each_with_index do |row, index|
        raw_matrix += index == 0 ? row.join("") : "\r\n%s" % row.join("")
      end

      game_session = current_user.game_sessions.create!
      game_session.game_states.create!(generation: generation, matrix_height: height, matrix_width: width, raw_matrix: raw_matrix)

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
    @matrix = extract_matrix(
      @current_state.matrix_height,
      @current_state.matrix_width,
      @current_state.raw_matrix.split("\r\n"),
      0
    )
  end

  def generate_next
    p params[:game_session]
    game_session = GameSession.find_by(id: params[:game_session])
    current_state = game_session.game_states.last
    matrix = extract_matrix(
      current_state.matrix_height,
      current_state.matrix_width,
      current_state.raw_matrix.split("\r\n"),
      0
    )
    next_matrix = build_next_generation(matrix, current_state.matrix_height, current_state.matrix_width)
    raw_next_matrix = ''
    next_matrix.each_with_index do |row, index|
      raw_next_matrix += index == 0 ? row.join("") : "\r\n%s" % row.join("")
    end
    game_session.game_states.create!(
      generation: current_state.generation+1,
      matrix_height: current_state.matrix_height,
      matrix_width: current_state.matrix_width,
      raw_matrix: raw_next_matrix
    )
    redirect_to controller: 'game', action: 'play', game_session: game_session
  end

  private

  def build_next_generation(matrix, height, width)
    Rails.logger.debug "build_next_generation matrix %s, height %d, width %d" % [matrix, height, width]

    current_row = 1
    ending_row = height - 1

    starting_column = 1
    current_column = starting_column
    ending_column = width - 1

    updated_matrix = matrix.deep_dup

    while current_row < ending_row
      while current_column < ending_column
        if matrix[current_row][current_column] == '.' && count_alive_neighbours(current_row, current_column, matrix, height, width) >= 3
          updated_matrix[current_row][current_column] = '*'
        else if matrix[current_row][current_column] == '*' && count_alive_neighbours(current_row, current_column, matrix, height, width) < 2
               updated_matrix[current_row][current_column] = '.'
             else
               updated_matrix[current_row][current_column] = matrix[current_row][current_column]
             end
        end

        current_column += 1
      end

      current_row += 1
      current_column = starting_column
    end

    return updated_matrix
  end

  def count_alive_neighbours(row, column, matrix, height, width)
    alive_neighbours = 0

    current_row = row == 0 ? row : row-1
    ending_row = row == height-1 ? row : row+1

    starting_column = column == 0 ? column : column-1
    current_column = starting_column
    ending_column = column == width-1 ? column : column+1


    while current_row <= ending_row
      while current_column <= ending_column
        if current_row != row || current_column != column
          "position %d, %d is %s" % [current_row, current_column, matrix[current_row][current_column]]
          if  matrix[current_row][current_column] == '*'
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
      matrix = extract_matrix(height, width, raw_input, 2)
      return generation, height, width, matrix
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

  def extract_matrix(height, width, raw_input, starting_index)
    Rails.logger.debug "extract_matrix height %d, width %d, raw_input %s, starting_index %d" % [height, width, raw_input, starting_index]
    current_index = starting_index

    if starting_index + height != raw_input.length
      raise "Unexpected matrix dimensions"
    end

    matrix = Array.new(height){Array.new(width)}

    while current_index < raw_input.length
      cells = raw_input[current_index].chars
      if cells.length > width
        raise "Unexpected matrix dimensions"
      end
      cells.each_with_index do |cell, index|
        matrix[current_index - starting_index][index] = cell
      end
      current_index += 1
    end

    return matrix
  end
end
