-- Complain if script is sourced in psql, rather than via CREATE EXTENSION.
\echo Use "CREATE EXTENSION pg_rowalesce" to load this file. \quit

--------------------------------------------------------------------------------------------------------------

-- Add `WITH CASCADE` option to `CREATE EXTENSION` statement.
create or replace function pg_rowalesce_readme()
    returns text
    volatile
    set search_path from current
    set pg_readme.include_view_definitions to 'true'
    set pg_readme.include_routine_definitions_like to '{test__%}'
    language plpgsql
    as $plpgsql$
declare
    _readme text;
begin
    create extension if not exists pg_readme
        with cascade;

    _readme := pg_extension_readme('pg_rowalesce'::name);

    raise transaction_rollback;  -- to drop extension if we happened to `CREATE EXTENSION` for just this.
exception
    when transaction_rollback then
        return _readme;
end;
$plpgsql$;

--------------------------------------------------------------------------------------------------------------

-- Change entry point from 0.1.0 to 0.1.10.
create or replace function pg_rowalesce_meta_pgxn()
    returns jsonb
    stable
    set search_path from current
    language sql
    return jsonb_build_object(
        'name'
        ,'pg_rowalesce'
        ,'abstract'
        ,'rowalesce() is like coalesce(), but for rows and other composite types.'
        ,'description'
        ,'The pg_rowalesce PostgreSQL extensions its defining feature is the rowalesce() function.'
            ' rowalesce() is like coalesce(), but for rows and other composite types. From its arbitrary'
            ' number of argument rows, for each field/column, rowalesce() takes the value from the first row'
            ' for which that particular field/column has a not null value.'
        ,'version'
        ,(
            select
                pg_extension.extversion
            from
                pg_catalog.pg_extension
            where
                pg_extension.extname = 'pg_rowalesce'
        )
        ,'maintainer'
        ,array[
            'Rowan Rodrik van der Molen <rowan@bigsmoke.us>'
        ]
        ,'license'
        ,'postgresql'
        ,'prereqs'
        ,'{
            "runtime": {
                "requires": {
                    "hstore": 0
                }
            },
            "test": {
                "requires": {
                    "pgtap": 0
                }
            }
        }'::jsonb
        ,'provides'
        ,('{
            "pg_rowalesce": {
                "file": "pg_rowalesce--0.1.10.sql",
                "version": "' || (
                    select
                        pg_extension.extversion
                    from
                        pg_catalog.pg_extension
                    where
                        pg_extension.extname = 'pg_rowalesce'
                ) || '",
                "docfile": "README.md"
            }
        }')::jsonb
        ,'resources'
        ,'{
            "homepage": "https://blog.bigsmoke.us/tag/pg_rowalesce",
            "bugtracker": {
                "web": "https://github.com/bigsmoke/pg_rowalesce/issues"
            },
            "repository": {
                "url": "https://github.com/bigsmoke/pg_rowalesce.git",
                "web": "https://github.com/bigsmoke/pg_rowalesce",
                "type": "git"
            }
        }'::jsonb
        ,'meta-spec'
        ,'{
            "version": "1.0.0",
            "url": "https://pgxn.org/spec/"
        }'::jsonb
        ,'generated_by'
        ,'`select pg_rowalesce_meta_pgxn()`'
        ,'tags'
        ,array[
            'coalesce',
            'jsonb',
            'plpgsql',
            'function',
            'functions',
            'table'
        ]
    );

-- Put synopsis on single, first line, remove link from that synopsis line and fix punctuation.
comment on function pg_rowalesce_meta_pgxn() is
$md$Returns the JSON meta data that has to go into the `META.json` file needed for PGXN—PostgreSQL Extension Network—packages.

The `Makefile` includes a recipe to allow the developer to: `make META.json` to
refresh the meta file with the function's current output, including the
`default_version`.

`pg_rowalesce` can be found on PGXN: https://pgxn.org/dist/pg_readme/
$md$;

--------------------------------------------------------------------------------------------------------------

-- Put entire synopsis on first line.
comment on function rowalesce(variadic anyarray) is
$md$Coalesce the column/field values in the order of the argument records given.

Each argument must be of the same _explicit_ row type.
$md$;

--------------------------------------------------------------------------------------------------------------

-- Put entire synopsis on first line.
comment on function rowalesce(jsonb, variadic anyarray) is
$md$Coalesce the `JSONB` (first) argument with an arbitrary number of explicitly-typed record/row arguments.

Example:

```sql
select rowalesce(
    '{"col1": 4, "col4": "2022-01-01"}'::jsonb,
    null::_tbl,
    row(null, null, false, null)
);
```
$md$;

--------------------------------------------------------------------------------------------------------------

-- Put entire synopsis on first line.
comment on function rowalesce(hstore, variadic anyarray) is
$md$Coalesces the fields in the `hstore` with the field values from each successive record-type argument.

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
$md$;

--------------------------------------------------------------------------------------------------------------

-- Keep only synopsis on first line
comment on function rowalesce_with_defaults(variadic anyarray) is
$md$Coalesces the column values in the order of the records given and falls back to column defaults.

The argument may be `NULL` (coerced to the correct type) if you just want the column defaults for a table type.
$md$;

--------------------------------------------------------------------------------------------------------------

-- Reformat comment.
comment on function record_rowalesce_with_defaults(record, variadic anyarray) is
$md$This function could not be named plain `rowalesce_with-defaults()`, because Postgres considers `rowalesce_with_defaults(record, variadic anyarray)` ambiguous with `rowalesce_with_defaults(variadic anyarray)`.

Also, it doesn't add much to calling `rowalesce_with_defaults(hstore, variadic
anyarray)` directly and feeding it a `hstore(record)`.  Yet, I decided to keep
it (for now) for documentation sake.  I may still change my mind in a later
release (but not any more after 1.0).
$md$;

--------------------------------------------------------------------------------------------------------------
