# frozen_string_literal: true

class GameSession < ApplicationRecord
  belongs_to :user

  has_many :game_states, dependent: :destroy

end
