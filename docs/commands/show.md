# The `show` command

The `show` command shows you the database tables that DataDuck is planning to ETL.

Usage to show all table names:

`$ dataduck show`


Usage to show info for just one table:

```bash
$ dataduck show users
Table users

Sources from users on my_database
  created_at
  updated_at
  id
  username

Outputs 
  created_at  datetime
  updated_at  datetime
  id          integer
  username    string
```
