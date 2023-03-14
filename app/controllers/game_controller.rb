class GameController < ApplicationController
  include GameUtils
  include GameLogic

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
    @started = params[:started].nil? ? false : params[:started]
    @game_session = GameSession.find_by(id: params[:game_session])
    @game_session_id = params[:game_session]
    @current_state = @game_session.game_states.last
    @grid = extract_grid(
      @current_state.grid_height,
      @current_state.grid_width,
      @current_state.raw_grid.split("\r\n"),
      0
    )
  end

  def generate_next
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

    redirect_to controller: 'game', action: 'play', game_session: game_session, started: true
  end

end
