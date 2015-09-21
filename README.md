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

Then use main.rb from the [DataDuckExample](https://github.com/DataDuckETL/DataDuckExample) project as a way to trigger your ETL.

## Contributing

There will be a Contributor License Agreement (CLA) soon. In the meantime, please hold off on contributing code.

## License

Get in touch at http://DataDuckETL.com/ for a license.
