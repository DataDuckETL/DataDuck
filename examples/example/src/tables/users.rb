class Users < DataDuck::Table
  source :my_database, [:id, :username, :rating, :credits]

  validate :non_negative_credits

  columns({
      :id => :integer,
      :username => :string,
      :rating => :integer,
      :credits => :integer,
  })

  def non_negative_credits(row)
    return "User id #{ row[:id] } has negative value of #{ row[:credits] } for credits." if row[:credits] < 0
  end
end
