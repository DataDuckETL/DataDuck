# DataDuck ETL Example

This gives an example project showing how to set up [DataDuck ETL](http://dataducketl.com/)

# Instructions

Copy /config/replace_me.yml to /config/secret/development.yml, then replace the secrets with your AWS and DB connection details.

For each table you want to import, create a table file in /src/tables. You can use /src/tables/games.rb and /src/tables/users.rb as examples. (You should also delete, modify, or rename games.rb and users.rb, by the way, otherwise DataDuck ETL will try to load them.)

For further help, reach out at [http://dataducketl.com/](http://dataducketl.com/)
