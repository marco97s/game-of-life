# frozen_string_literal: true

class GameState < ApplicationRecord
  belongs_to :game_session
end
