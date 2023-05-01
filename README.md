---
pg_extension_name: pg_rowalesce
pg_extension_version: 0.1.10
pg_readme_generated_at: 2023-05-01 17:27:33.464643+01
pg_readme_version: 0.6.1
---

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

### Routines

#### Function: `insert_row (anyelement)`

Wraps around `INSERT INTO … RETURNING` so that it''s friendlier to use in some contexts.

Function arguments:

| Arg. # | Arg. mode  | Argument name                                                     | Argument type                                                        | Default expression  |
| ------ | ---------- | ----------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------- |
|   `$1` |    `INOUT` |                                                                   | `anyelement`                                                         |  |

Function return type: `anyelement`

Function-local settings:

  *  `SET search_path TO rowalesce, rowalesce, pg_temp`

#### Function: `pg_rowalesce_meta_pgxn()`

Returns the JSON meta data that has to go into the `META.json` file needed for PGXN—PostgreSQL Extension Network—packages.

The `Makefile` includes a recipe to allow the developer to: `make META.json` to
refresh the meta file with the function's current output, including the
`default_version`.

`pg_rowalesce` can be found on PGXN: https://pgxn.org/dist/pg_readme/

Function return type: `jsonb`

Function attributes: `STABLE`

Function-local settings:

  *  `SET search_path TO rowalesce, rowalesce, pg_temp`

#### Function: `pg_rowalesce_readme()`

Function return type: `text`

Function-local settings:

  *  `SET search_path TO rowalesce, rowalesce, pg_temp`
  *  `SET pg_readme.include_view_definitions TO true`
  *  `SET pg_readme.include_routine_definitions_like TO {test__%}`

#### Function: `record_rowalesce_with_defaults (record, anyarray)`

This function could not be named plain `rowalesce_with-defaults()`, because Postgres considers `rowalesce_with_defaults(record, variadic anyarray)` ambiguous with `rowalesce_with_defaults(variadic anyarray)`.

Also, it doesn't add much to calling `rowalesce_with_defaults(hstore, variadic
anyarray)` directly and feeding it a `hstore(record)`.  Yet, I decided to keep
it (for now) for documentation sake.  I may still change my mind in a later
release (but not any more after 1.0).

Function arguments:

| Arg. # | Arg. mode  | Argument name                                                     | Argument type                                                        | Default expression  |
| ------ | ---------- | ----------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------- |
|   `$1` |       `IN` |                                                                   | `record`                                                             |  |
|   `$2` | `VARIADIC` |                                                                   | `anyarray`                                                           |  |
|   `$3` |      `OUT` |                                                                   | `anyelement`                                                         |  |

Function return type: `anyelement`

Function-local settings:

  *  `SET search_path TO rowalesce, rowalesce, pg_temp`

#### Function: `rowalesce (anyarray)`

Coalesce the column/field values in the order of the argument records given.

Each argument must be of the same _explicit_ row type.

Function arguments:

| Arg. # | Arg. mode  | Argument name                                                     | Argument type                                                        | Default expression  |
| ------ | ---------- | ----------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------- |
|   `$1` | `VARIADIC` |                                                                   | `anyarray`                                                           |  |
|   `$2` |      `OUT` |                                                                   | `anyelement`                                                         |  |

Function return type: `anyelement`

Function attributes: `IMMUTABLE`, `LEAKPROOF`, `PARALLEL SAFE`

Function-local settings:

  *  `SET search_path TO rowalesce, rowalesce, pg_temp`

#### Function: `rowalesce (anyelement, jsonb)`

Function arguments:

| Arg. # | Arg. mode  | Argument name                                                     | Argument type                                                        | Default expression  |
| ------ | ---------- | ----------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------- |
|   `$1` |       `IN` |                                                                   | `anyelement`                                                         |  |
|   `$2` |       `IN` |                                                                   | `jsonb`                                                              |  |
|   `$3` |      `OUT` |                                                                   | `anyelement`                                                         |  |

Function return type: `anyelement`

Function attributes: `IMMUTABLE`, `LEAKPROOF`, `PARALLEL SAFE`

Function-local settings:

  *  `SET search_path TO rowalesce, rowalesce, pg_temp`

#### Function: `rowalesce (hstore, anyarray)`

Coalesces the fields in the `hstore` with the field values from each successive record-type argument.

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

Function arguments:

| Arg. # | Arg. mode  | Argument name                                                     | Argument type                                                        | Default expression  |
| ------ | ---------- | ----------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------- |
|   `$1` |       `IN` |                                                                   | `hstore`                                                             |  |
|   `$2` | `VARIADIC` |                                                                   | `anyarray`                                                           |  |
|   `$3` |      `OUT` |                                                                   | `anyelement`                                                         |  |

Function return type: `anyelement`

Function attributes: `IMMUTABLE`, `LEAKPROOF`, `PARALLEL SAFE`

Function-local settings:

  *  `SET search_path TO rowalesce, rowalesce, pg_temp`

#### Function: `rowalesce (jsonb, anyarray)`

Coalesce the `JSONB` (first) argument with an arbitrary number of explicitly-typed record/row arguments.

Example:

```sql
select rowalesce(
    '{"col1": 4, "col4": "2022-01-01"}'::jsonb,
    null::_tbl,
    row(null, null, false, null)
);
```

Function arguments:

| Arg. # | Arg. mode  | Argument name                                                     | Argument type                                                        | Default expression  |
| ------ | ---------- | ----------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------- |
|   `$1` |       `IN` |                                                                   | `jsonb`                                                              |  |
|   `$2` | `VARIADIC` |                                                                   | `anyarray`                                                           |  |
|   `$3` |      `OUT` |                                                                   | `anyelement`                                                         |  |

Function return type: `anyelement`

Function attributes: `IMMUTABLE`, `LEAKPROOF`, `PARALLEL SAFE`

Function-local settings:

  *  `SET search_path TO rowalesce, rowalesce, pg_temp`

#### Function: `rowalesce_with_defaults (anyarray)`

Coalesces the column values in the order of the records given and falls back to column defaults.

The argument may be `NULL` (coerced to the correct type) if you just want the column defaults for a table type.

Function arguments:

| Arg. # | Arg. mode  | Argument name                                                     | Argument type                                                        | Default expression  |
| ------ | ---------- | ----------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------- |
|   `$1` | `VARIADIC` |                                                                   | `anyarray`                                                           |  |
|   `$2` |      `OUT` |                                                                   | `anyelement`                                                         |  |

Function return type: `anyelement`

Function-local settings:

  *  `SET search_path TO rowalesce, rowalesce, pg_temp`

#### Function: `rowalesce_with_defaults (hstore, anyarray)`

Function arguments:

| Arg. # | Arg. mode  | Argument name                                                     | Argument type                                                        | Default expression  |
| ------ | ---------- | ----------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------- |
|   `$1` |       `IN` |                                                                   | `hstore`                                                             |  |
|   `$2` | `VARIADIC` |                                                                   | `anyarray`                                                           |  |
|   `$3` |      `OUT` |                                                                   | `anyelement`                                                         |  |

Function return type: `anyelement`

Function-local settings:

  *  `SET search_path TO rowalesce, rowalesce, pg_temp`

#### Function: `rowalesce_with_defaults (jsonb, anyarray)`

Function arguments:

| Arg. # | Arg. mode  | Argument name                                                     | Argument type                                                        | Default expression  |
| ------ | ---------- | ----------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------- |
|   `$1` |       `IN` |                                                                   | `jsonb`                                                              |  |
|   `$2` | `VARIADIC` |                                                                   | `anyarray`                                                           |  |
|   `$3` |      `OUT` |                                                                   | `anyelement`                                                         |  |

Function return type: `anyelement`

Function-local settings:

  *  `SET search_path TO rowalesce, rowalesce, pg_temp`

#### Function: `table_defaults (regclass, hstore)`

Get the (given) column default values for the given table.

Function arguments:

| Arg. # | Arg. mode  | Argument name                                                     | Argument type                                                        | Default expression  |
| ------ | ---------- | ----------------------------------------------------------------- | -------------------------------------------------------------------- | ------------------- |
|   `$1` |       `IN` | `pg_class$`                                                       | `regclass`                                                           |  |
|   `$2` |       `IN` | `include_columns$`                                                | `hstore`                                                             | `NULL::hstore` |

Function return type: `hstore`

Function-local settings:

  *  `SET search_path TO rowalesce, rowalesce, pg_temp`

#### Procedure: `test__pg_rowalesce()`

Procedure-local settings:

  *  `SET search_path TO rowalesce, rowalesce, pg_temp`
  *  `SET plpgsql.check_asserts TO true`

```sql
CREATE OR REPLACE PROCEDURE rowalesce.test__pg_rowalesce()
 LANGUAGE plpgsql
 SET search_path TO 'rowalesce', 'rowalesce', 'pg_temp'
 SET "plpgsql.check_asserts" TO 'true'
AS $procedure$
declare
    _rec record;
begin
    create local temporary table _tbl (
        col1 int default 9
        ,col2 text default 'iets'
        ,col3 bool default true
        ,col4 timestamptz default now()
    );

    assert table_defaults('_tbl')::text
        = hstore('"col1"=>"9","col2"=>"iets","col3"=>"t",col4=>"' || now()::text || '"')::text;

    assert table_defaults('_tbl', ''::hstore) = ''::hstore
        ,'table_defaults() should be okay with having nothing to do.';

    assert rowalesce(
            row(4, null, null, now())::_tbl
            ,row(5, 'blah', null, now() + interval '1 day')::_tbl
        ) = row(4, 'blah', null, now())::_tbl
        ,'NULL values (and _only_ NULL values) should be rowalesced.';
    assert rowalesce_with_defaults(
            row(4, null, null, now())::_tbl
            ,row(5, 'blah', null, now() + interval '1 day')::_tbl
        ) = row(4, 'blah', true, now())::_tbl
        ,'NULL values in arguments should be rowalesced, and fall back to table defaults.';

    assert rowalesce(
        '{"col1": 4, "col4": "2022-01-01"}'::jsonb,
        null::_tbl,
        row(null, null, false, null)::_tbl
    ) = row(4, null, false, '2022-01-01'::timestamptz)::_tbl;
    assert rowalesce_with_defaults(
        '{"col1": 4, "col4": "2022-01-01"}'::jsonb,
        null::_tbl
    ) = row(4, 'iets', true, '2022-01-01'::timestamptz)::_tbl;

    assert rowalesce(
        '{"col1": 4, "col4": "2022-01-01"}'::jsonb,
        row(5, 'blah', null, '2022-12-31'::timestamptz)::_tbl,
        null::_tbl,
        null::_tbl
    ) = row(4, 'blah', null, '2022-01-01'::timestamptz)::_tbl;
    assert rowalesce_with_defaults(
        '{"col4": "2022-01-01"}'::jsonb,
        row(null, 'blah', null, '2022-12-31'::timestamptz)::_tbl,
        null::_tbl,
        null::_tbl
    ) = row(9, 'blah', true, '2022-01-01'::timestamptz)::_tbl;

    assert rowalesce(
        'col1=>4,col4=>"2022-01-01"'::hstore,
        row(5, 'blah', null, '2022-12-31'::timestamptz)::_tbl
    ) = row(4, 'blah', null, '2022-01-01'::timestamptz)::_tbl;
    assert rowalesce_with_defaults(
        'col1=>4,col4=>"2022-01-01"'::hstore,
        row(5, 'blah', null, '2022-12-31'::timestamptz)::_tbl
    ) = row(4, 'blah', true, '2022-01-01'::timestamptz)::_tbl;

    /*
    assert record_rowalesce_with_defaults(
        _rec,
        row(5, 'blah', null, now() + interval '1 day')::_tbl
    ) = row(4, 'blah', true, now())::_tbl;
    */

    raise transaction_rollback;  -- I could have use any error code, but this one seemed to fit best.
exception
    when transaction_rollback then
end;
$procedure$
```

## Colophon

This `README.md` for the `pg_rowalesce` extension was automatically generated using the [`pg_readme`](https://github.com/bigsmoke/pg_readme) PostgreSQL extension.
