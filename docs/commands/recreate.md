# The `recreate` command

The `recreate` command will create a brand new version of table on your destination, then move the existing data over to the new table.

This is useful if you change the indexes or distribution keys of a table.

It takes the following steps, so that the original table is affected for as little amount of time as needed:

1. Creates a new table named zz_dataduck_recreating_(tablename)

2. Moves the table data from the original table to the new table.

3. Renames the original table to zz_dataduck_recreating_old_(tablename)

4. Renames the zz_dataduck_recreating_(tablename) to tablename.

5. Drops zz_dataduck_recreating_old_(tablename)

To recreate a table, use the command:

`$ dataduck recreate my_table_name`
