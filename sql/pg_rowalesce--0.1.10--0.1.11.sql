-- Complain if script is sourced in `psql`, rather than via `CREATE EXTENSION`.
\echo Use "CREATE EXTENSION pg_rowalesce" to load this file. \quit

--------------------------------------------------------------------------------------------------------------

comment on extension pg_rowalesce is
$markdown$
# The `pg_rowalesce` PostgreSQL extension

The `pg_rowalesce` PostgreSQL extension its defining feature is the
`rowalesce()` function.  `rowalesce()` is like `coalesce()`, but for rows and
other composite types.  From its arbitrary number of argument rows, for each
field/column, `rowalesce()` takes the value from the first row for which that
particular field/column has a `not null` value.

`rowalesce()` comes in a number of variants:

1. `rowalesce(variadic anyarray, out anyelement)`
2. `rowalesce(in jsonb, variadic anyarray, out anyelement)`
3. `rowalesce(in record, variadic anyarray, out anyelement)`
4. `rowalesce(anyelement, jsonb, out anyelement)`

These variants make it easy to combine data from different sources, as long as
there is at least one argument to mark the type proper.  A properly
composite-typed `NULL` argument can be used to just force the correct row type,
as in:

```sql
select rowalesce('{"my_attr_1": 3, "my_attr_2": "b"}'::jsonb, null::my.type)
```

Besides these variations, there is also a `rowalesce_with_defaults()` variant
of the first 3 of those, plus one extra, to work with the so very loose
`record` type:

1. `rowalesce_with_defaults(variadic anyarray, out anyelement)`
2. `rowalesce_with_defaults(in jsonb, variadic anyarray, out anyelement)`
3. `rowalesce_with_defaults(in hstore, variadic anyarray, out anyelement)`
4. `rowalesce_with_defaults(in record, variadic anyarray, out anyelement)`

`rowalesce_with_defaults()` depends on `table_defaults()`, which can also be
used separately, if you wish to evaluate all of a table its default expressions
(or a subset thereof) for some other purpose.

Finally, there is the `insert_row()` function which makes inserting the result
of these functions easier.

## Dependencies

This extension only depends on the `hstore` extension. There _are_ extensions
which will _enhance_ `pg_rowalesce`, but these are not necessary for its proper
functioning.

## Installation

Installation is done by means of a `Makefile`, which depends on the
[PGXS](https://www.postgresql.org/docs/current/extend-pgxs.html) infrastructure
that should come as part of your PostgreSQL installation.

```bash
make install
```

Installing a PostgreSQL extension successfully requires access to the
`$(pg_config --sharedir)/extension` directory.

After the extension files have been installed by `make install`, as usual, the
extension can be installes by means of:

```sql
CREATE EXTENSION pg_rowalesce;
```

`pg_rowalesce` supports the `WITH SCHEMA` option of the [`CREATE
EXTENSION`](https://www.postgresql.org/docs/current/sql-createextension.html)
command.

## Schema relocation

`pg_rowalesce` supports schema relocation, _but_…  There is one manual step
involved if you want to make it work extra super-duper well: you have to call
the `pg_rowalesce_relocate(name)` function, either _instead_ of `ALTER
EXTENSION pg_rowalesce SET SCHEMA _new_schema_`, as

```sql
SELECT pg_rowalesce_relocate('new_schema');
```

Or _after_ `ALTER EXTENSION pg_rowalesce SET SCHEMA _new_schema_` (in which
case the name of the new schema doesn't need to be supplied):

```sql
ALTER EXTENSION pg_rowalesce SET SCHEMA new_schema;
SELECT pg_rowalesce_relocate();
```

## Extension object reference

<?pg-readme-reference context-division-depth="2" context-division-is-self="true" ?>

## Extension authors and contributors

* [Rowan](https://www.bigsmoke.us/) originated this extension in 2022 while
  developing the PostgreSQL backend for the [FlashMQ SaaS MQTT cloud
  broker](https://www.flashmq.com/).  Rowan does not like to see himself as a
  tech person or a tech writer, but, much to his chagrin, [he
  _is_](https://blog.bigsmoke.us/category/technology). Some of his chagrin
  about his disdain for the IT industry he poured into a book: [_Why
  Programming Still Sucks_](https://www.whyprogrammingstillsucks.com/).  Much
  more than a “tech bro”, he identifies as a garden gnome, fairy and ork rolled
  into one, and his passion is really to [regreen and reenchant his
  environment](https://sapienshabitat.com/).  One of his proudest achievements
  is to be the third generation ecological gardener to grow the wild garden
  around his beautiful [family holiday home in the forest of Norg, Drenthe,
  the Netherlands](https://www.schuilplaats-norg.nl/) (available for rent!).

## Colophon

<?pg-readme-colophon context-division-depth="2" context-division-is-self="true" ?>

$markdown$;

--------------------------------------------------------------------------------------------------------------
