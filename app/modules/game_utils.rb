# frozen_string_literal: true

module GameUtils
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
