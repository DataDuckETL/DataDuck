# The `quickstart` command

The `quickstart` command will give you a wizard for getting started with DataDuck. You should only use this with a brand new DataDuck project.

It will ask you for the credentials to your database, and then create the basic setup for your project. After you are completely setup, your project's ETL can be run by running `dataduck etl`

If you would like to run the ETL regularly, such as every night, it's recommended to use the [whenever](https://github.com/javan/whenever) gem to manage a cron job to regularly run the ETL.
