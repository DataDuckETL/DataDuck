# The Table Class

If you've run the `dataduck quickstart` command, you'll notice a bunch of table files were generated under /src/tables.
Each of these table files inherits from `DataDuck::Table`, the base table class. Tables need to have the `source` and `output` defined.

You may also define transformations with the `transforms` method and validations with `validates` method.

## Example Table

The following is an example table.

```ruby
class Decks < DataDuck::Table
  source :my_database, ["id", "name", "user_id", "cards",
      "num_wins", "num_losses", "created_at", "updated_at",
      "is_drafted", "num_draft_wins", "num_draft_losses"]

  transforms :calculate_num_totals

  validates :validates_num_total

  output({
      :id => :integer,
      :name => :string,
      :user_id => :integer,
      :num_wins => :integer,
      :num_losses => :integer,
      :num_total => :integer,
      :num_draft_total => :integer,
      :created_at => :datetime,
      :updated_at => :datetime,
      :is_drafted => :boolean,
      # Note that num_draft_wins and num_draft_losses
      # are not included in the output, but are used in
      # the transformation.
  })

  def calculate_num_totals(row)
    row[:num_total] = row[:num_wins] + row[:num_losses]
    row[:num_draft_total] = row[:num_draft_wins] + row[:num_draft_losses]
    row
  end

  def validates_num_total(row)
    return "Deck id #{ row[:id] } has negative value #{ row[:num_total] } for num_total." if row[:num_total] < 0
  end
end
```
