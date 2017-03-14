# The Table Class

If you've run the `dataduck quickstart` command, you'll notice a bunch of table files were generated under /src/tables.
Each of these table files inherits from `DataDuck::Table`, the base table class. Tables need to have the `source` and `output` defined.

You may also define transformations with the `transforms` method and validations with `validates` method.

## Types of Loading Methods

There are a few different methods to load your table. You can load the whole table fresh with each ETL, or you can load
just the most recently changed rows (based off some column such as an updated_at column).

Loading just those rows that have changed is best for most tables, since it significantly reduces the amount of data you
transfer as well as the time your ETL process takes. Loading the whole table fresh each time is best if the table is
small or rows may be deleted from the table by your main application. (In the case that rows are deleted, you need to reload
the whole table each ETL, since the ETL process wouldn't otherwise know which rows no longer exist.)

## The `should_fully_reload?` method

If `should_fully_reload?` is true, the table will be fully reloaded each ETL. By default, this is false.

## The `extract_by_column` and `batch_size` methods

The alternative to fully reloading is to use an `extract_by_column`. By default, `extract_by_column` returns updated_at
if your table has an updated_at column. This way, only the rows that have changed need be ETLed. This can give you
significant performance improvements, which is why it is the default.

If the `batch_size` method is set, the extract query will use a `LIMIT batch_size` clause. This is useful if your table
is fairly big and you are running DataDuck on a small EC2 instance or other computer without a lot of memory.

In order to use `batch_size`, you must also set the `extract_by_column`

An example of where you might want to override the default `extract_by_column` is if you are tracking visitor events in
a table, and the visitor events are never modified. In this case, you might not even have an `updated_at` column. Instead,
you could use the `created_at` column or the `id` column (if ids are assumed to be generated always increasing).

## The `etl!` method

The `etl!` method is what gets called when you run the `dataduck etl` command. It first extracts the
data from your source via the `extract!` method, transforms the data according to any transformations you've created in
the `transform!` method, then loads the data into your destination with the `destination.load_table!` method.
You may overwrite this if you have some custom ETL process, however, it may be better to overwrite the `extract!` method
and leave the rest of the process (and the Redshift loading) up to DataDuck.

## The `extract!` method

The `extract!` method takes one argument: the destination. It then extracts the data from the source necessary to load
data into the destination. If you are writing your own Table class with some custom third party API, you will probably
want to overwrite this method.

## Overriding indexes (sortkeys)

By sortkey, Redshift means what other databases would generally call indexes. DataDuck ETL will use `id` and `created_at` as sortkeys by default. If you would like to specify your own, simply overwrite the `indexes` method on your table, like this example:

```ruby
class Decks < DataDuck::Table
  # source info goes here

  def indexes
    ["id", "user_id"]
  end

  # output info goes here
end
```

## Overriding distkeys and diststyles

For large datasets, Redshift can distribute the data across multiple compute nodes according to your distkey and diststyle. To use these, simply overwrite the distribution_key and distribution_style methods.

```ruby
class Decks < DataDuck::Table
  # source info goes here

  def distribution_key
    "company_id"
  end

  def distribution_style
    "all"
  end

  # output info goes here
end
```

For more info, read: [http://docs.aws.amazon.com/redshift/latest/dg/t_Distributing_data.html](Distributing Data)

## Example Table

The following is an example table.

```ruby
class Decks < DataDuck::Table
  source :source1, ["id", "name", "user_id", "cards",
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
