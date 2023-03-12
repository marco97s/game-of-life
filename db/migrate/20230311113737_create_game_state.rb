class CreateGameState < ActiveRecord::Migration[7.0]
  def change
    create_table :game_states do |t|
      t.references :game_session, null: false, foreign_key: {on_delete: :cascade}
      t.integer :generation
      t.integer :matrix_width
      t.integer :matrix_height
      t.string :raw_matrix
      t.timestamps
    end
  end
end
