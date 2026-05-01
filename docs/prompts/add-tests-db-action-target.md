Ok. We've added a new db, test, and we should now add a new target for DB_TARGET. Add
the new DB_TARGET, "tests", so that from now on, migration actions like db_createfrom
and db_migrate can choose to target DB_TARGET=<dev|prod|proddev|tests>. Ofc, proddev
cannot have a db_createfrom command.

Also the tests that need DB access should now use the CPPBESSOT_DB_[PGSQL|SQLITE]_PRODDEV_CONNSTR. So you should get rid of the legacy ODB test connstr variables and replace them with CPPBESSOT_DB_[PGSQL|SQLITE]_PRODDEV_CONNSTR. This unifies everything nicely. So now we have 4 DB targets, both for Postgre and sqlite.

The legacy db-action PostgreSQL admin connstr variable should be removed as well.

The local YugabyteDB instance is configured at /media/latentprion/aafe96c9-7fcd-40ce-991d-ca2d23b5ba17/db/yugabytedb. The runtime proddev mapping should remain the real proddev DB (`couresilient_proddev`) with the real app user (`couresilient`). The separate `couresilient_tests` user and `couresilient_tests` DB are for the `DB_TARGET=tests` mapping, not for `DB_TARGET=proddev`.

If there are tests whose purpose is to test the clone command from prod to proddev, have them use the same clone hook as production: CPPBESSOT_DB_[PGSQL|SQLITE]_CLONE_PROD_TO_PRODDEV_COMMAND.

No backward compatibility or anything. Hard cutover.
----

Make sure to update cppbessot.env.cmake[.example] and README.md inside of couresilient.
