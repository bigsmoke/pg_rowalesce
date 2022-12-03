---
pg_extension_name: pg_rowalesce
pg_extension_version: 0.1.1
pg_readme_generated_at: 2022-12-03 10:17:40.917865+00
pg_readme_version: 0.1.1
---

# The `pg_rowalesce` PostgreSQL extension

The `pg_rowalesce` PostgreSQL extensions its defining feature is the
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

### Routines

#### Function: `rowalesce.insert_row(anyelement)`

Wraps around `INSERT INTO … RETURNING` so that it's friendlier to use in some contexts.

#### Function: `rowalesce.pg_rowalesce_readme()`

#### Function: `rowalesce.record_rowalesce_with_defaults(record,anyarray)`

This function could not be named plain `rowalesce_with-defaults()`, because
Postgres considers `rowalesce_with_defaults(record, variadic anyarray)`
ambiguous with `rowalesce_with_defaults(variadic anyarray)`.  Also, it doesn't
add much to calling `rowalesce_with_defaults(hstore, variadic anyarray)`
directly and feeding it a `hstore(record)`.  Yet, I decided to keep it (for
    now) for documentation sake.  I may still change my mind in a later release
(but not any more after 1.0).

#### Function: `rowalesce.rowalesce(anyarray)`

Coalesce the column/field values in the order of the argument records given.

Each argument must be of the same _explicit_ row type.

#### Function: `rowalesce.rowalesce(anyelement,jsonb)`

#### Function: `rowalesce.rowalesce(jsonb,anyarray)`

Coalesce the `JSONB` (first) argument with an arbitrary number of
explicitly-typed record/row arguments.

Example:

```sql
select rowalesce(
    '{"col1": 4, "col4": "2022-01-01"}'::jsonb,
    null::_tbl,
    row(null, null, false, null)
);
```

#### Function: `rowalesce.rowalesce(public.hstore,anyarray)`

Coalesces the fields in the `hstore` with the field values from each successive
record-type argument.

Example:

```sql
create type myrow (
    col1 int
    ,col2 text
    ,col3 timestamptz
);

select rowalesce(
  '"col1"=>"42", "col3"=>"2000-01-01"'::hstore,
  row(null, 'meaning', null)::myrow,
);
```

You can also use this function to rowalesce with rows of the unspecified type
`record`—just wrap it as `hstore(record)`:

```sql
create type myrow (
    col1 int
    ,col2 text
    ,col3 timestamptz
);

create function record_rowalesce(in record, variadic anyarray, out anyelement)
    immutable
    leakproof
    parallel safe
    language plpgsql
    as $$
begin
    $3 := rowalesce(hstore($1), variadic $2);
end;
$$;

create function use_record_rowalesce()
    language plpgsql
    as $$
declare
    _untyped_rec record;
    _typed_row
begin
    select 4::int as col1, now() as col3 into _untyped_rec;

    _typed_row := record_rowalesce(_untyped_rec, null::myrow);
end;
$$;
```

#### Function: `rowalesce.rowalesce_with_defaults(anyarray)`

Coalesces the column values in the order of the records given and fall back to column defaults. The argument may be `NULL` (coerced to the correct type) if you just want the column defaults for a table type.

#### Function: `rowalesce.rowalesce_with_defaults(jsonb,anyarray)`

#### Function: `rowalesce.rowalesce_with_defaults(public.hstore,anyarray)`

#### Function: `rowalesce.table_defaults(regclass,public.hstore)`

Get the (given) column default values for the given table.

#### Procedure: `rowalesce.test__pg_rowalesce()`

## Colophon

This `README.md` for the `pg_rowalesce` `extension` was automatically generated using the
[`pg_readme`](https://github.com/bigsmoke/pg_readme) PostgreSQL
extension.
