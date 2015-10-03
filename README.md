# DataDuck ETL

##### Set up in under 5 minutes

DataDuck ETL is probably the quickest extract-transform-load framework system to set up. If you want to set up a data warehouse, give DataDuck ETL a try.

##### Extract-transform-load to Amazon Redshift

DataDuck ETL is currently focused on loading to Amazon Redshift (through Amazon S3).

![DataDuck ETL](static/logo.png "DataDuck ETL")

## Installation

##### Example project

See [https://github.com/DataDuckETL/DataDuckExample](https://github.com/DataDuckETL/DataDuckExample) for an example project setup.

##### Instructions for using DataDuck ETL

Create a new project, then add the following to your Gemfile:

```ruby
gem 'dataduck', :git => 'git://github.com/DataDuckETL/DataDuck.git'
```

Then execute:

    $ bundle install

Finally, run the quickstart command:

    $ dataduck quickstart

The quickstart wizard will ask you for credentials to your database, then create the basic setup for your project. After the setup, your project's ETL can be run by running `ruby src/main.rb`

If you'd like to run this regularly, such as every night, it's recommended to use the [whenever](https://github.com/javan/whenever) gem to manage a cron job to regularly run the ETL.

## Documentation

Tables are defined in their own file under /src/tables. Here's an example table:

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

## Contributing

There will be a Contributor License Agreement (CLA) soon. In the meantime, please hold off on contributing code.

## License

Get in touch at http://DataDuckETL.com/ for a license.
