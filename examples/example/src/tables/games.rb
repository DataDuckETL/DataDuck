class Games < DataDuck::Table
  source :my_database, [:id, :first_user_id, :second_user_id, :game_type]

  output({
      :id => :integer,
      :first_user_id => :integer,
      :second_user_id => :integer,
      :game_type => :string,
  })
end
