# Incremental vs Full Loading

Loading a table can be performed either incrementally or with a full reload each time. An incremental load is generally
better, since it takes less time and transfers less data, however not all tables cannot be loaded incrementally.

## Incremental loading

If you are running an ETL process regularly, rather than loading an entire table each time, it is more efficient
to load just the rows that have changed. This is known as an incremental load. By default, if a table contains
a row called `updated_at`, DataDuck ETL will use incremental loading based off of that column. If no such column
exists, it will load the entire table each time.

If rows can be deleted from a table, you should not use incremental loading either, since DataDuck ETL won't know which rows
have been deleted. Soft deleting a row, by setting a column to 'deleted' (for example) is fine to use with incremental loading.

Under the hood, before extracting, DataDuck ETL will check the destination for the latest value of a column, then use that value as a LIMIT
when running the extract query.

If you would like to base an incremental load on a different column, such as `id` or `created_at` (common in cases where
the rows are not expected to change, like an event stream), then you can do so by giving your table a method `extract_by_column`.

```ruby
class MyTable < DataDuck::Table
  source :source1, ["id", "created_at", "name"]

  def extract_by_column
    'created_at'
  end
  
  output({
      :id => :integer,
      :created_at => :datetime,
      :name => :string,
  })
end
```

## Full reloads

Fully reloading a table takes longer, so it is only recommended you do this with tables where it is not possible to use
incremental loads.

If you would like to fully reload the table each time, you may give your table an `extract_by_column` that returns `nil`.
Alternatively, if you want to have an `extract_by_column` but still reload the entire table each time, you may
give it a method `should_fully_reload?` that returns true. An example of when you might want to do this is if you are
reloading an entire table, but doing it in batches.

```ruby
class MyTableFullyReloaded < DataDuck::Table
  source :source1, ["id", "created_at", "name"]

  def batch_size
    1_000_000 # if there is a lot of data, and you want to use less memory (for example), batching is a good idea
  end

  def extract_by_column
    'created_at'
  end

  def should_fully_reload?
    true
  end
  
  output({
      :id => :integer,
      :created_at => :datetime,
      :name => :string,
  })
end
```
