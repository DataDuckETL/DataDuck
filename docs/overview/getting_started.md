# Getting Started

## Requirements

DataDuck ETL currently supports extracting from MySQL and PostgreSQL databases. It supports loading into Amazon
Redshift. If you would like to extract or load into a database not yet supported, contact us.

## Instructions

First, create a new, empty directory. Inside this directory, create a file named Gemfile with the following:

```ruby
source 'https://rubygems.org'

gem 'dataduck'
```

Then execute:

    $ bundle install

For customer relationship management, we use [Supported Source](https://supportedsource.org/). This means you'll have to
get a client token with Supported Source in order to run DataDuck ETL. Run the following command:

    $ supso update

It will ask you for your work email, then send you a confirmation token. After confirming, you'll be able to continue.
 
Finally, run the quickstart command:

    $ dataduck quickstart

It will ask you for the credentials to your database, and then create the basic setup for your project.

You will still need to update your .env and config/base.yml files with additional details, such as your AWS S3 api keys.

After you are completely setup, your project's ETL can be run by running `dataduck etl all`

If you would like to run this regularly, such as every night, it's recommended to use the [whenever](https://github.com/javan/whenever) gem to manage a cron job to regularly run the ETL.
