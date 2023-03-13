# lib/module

module GameLogic
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
        alive_neighbours = count_alive_neighbours(current_row, current_column, grid, height, width)
        # Any dead cell with exactly three live neighbours becomes a live cell
        if grid[current_row][current_column] == '.' && alive_neighbours == 3
          updated_grid[current_row][current_column] = '*'
        # Any live cell with fewer than two live neighbours or more than three live neighbours dies
        elsif grid[current_row][current_column] == '*' &&
          alive_neighbours < 2 || alive_neighbours > 3
          updated_grid[current_row][current_column] = '.'
        else
          updated_grid[current_row][current_column] = grid[current_row][current_column]
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

    current_row = row == 0 ? row : row - 1
    ending_row = row == height - 1 ? row : row + 1

    starting_column = column == 0 ? column : column - 1
    current_column = starting_column
    ending_column = column == width - 1 ? column : column + 1

    while current_row <= ending_row
      while current_column <= ending_column
        if (current_row != row || current_column != column) &&
          grid[current_row][current_column] == '*'
          alive_neighbours += 1
        end
        current_column += 1
      end

      current_row += 1
      current_column = starting_column
    end

    return alive_neighbours
  end
end
