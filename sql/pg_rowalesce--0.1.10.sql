-- Complain if script is sourced in psql, rather than via CREATE EXTENSION.
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

## Colophon

<?pg-readme-colophon context-division-depth="2" context-division-is-self="true" ?>

$markdown$;

--------------------------------------------------------------------------------------------------------------

do $$
declare
    _ddl_cmd_to_set_pg_readme_url text;
begin
    _ddl_cmd_to_set_pg_readme_url := 'ALTER DATABASE ' || current_database()
        || ' SET pg_rowalesce.readme_url = ''https://github.com/bigsmoke/pg_rowalesce/blob/master/README.md''';
    execute _ddl_cmd_to_set_pg_readme_url;
exception
    when insufficient_privilege then
        -- We say `superuser = false` in the control file; so let's just whine a little instead of crashing.
        raise warning using
            message = format(
                'Because you''re installing the pg_rowalesce extension as non-superuser and because you'
                || ' are also not the owner of the %I DB, the database-level `pg_rowalesce.readme_url`'
                || ' setting has not been set.',
                current_database()
            )
            ,detail = 'Settings of the form `<extension_name>.readme_url` are used by the `pg_readme`'
                || ' extension to cross-link between extensions their README files.'
            ,hint = 'If you want full inter-extension README cross-linking, you can ask your friendly'
                || E' neighbourhood DBA to execute the following statement:\n'
                || _ddl_cmd_to_set_pg_readme_url || ';';
end;
$$;

--------------------------------------------------------------------------------------------------------------

create function pg_rowalesce_readme()
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

create function pg_rowalesce_meta_pgxn()
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
                "file": "pg_rowalesce--0.1.0.sql",
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

comment on function pg_rowalesce_meta_pgxn() is
$md$Returns the JSON meta data that has to go into the `META.json` file needed for PGXN—PostgreSQL Extension Network—packages.

The `Makefile` includes a recipe to allow the developer to: `make META.json` to
refresh the meta file with the function's current output, including the
`default_version`.

`pg_rowalesce` can be found on PGXN: https://pgxn.org/dist/pg_readme/
$md$;

--------------------------------------------------------------------------------------------------------------

create function rowalesce(variadic anyarray, out anyelement)
    immutable
    leakproof
    parallel safe
    set search_path from current
    language plpgsql
    as $$
declare
    _row_json json;
    _column_name name;
begin
    --$2 := $1[1];

    -- NOTE: This is not ideal. Ideally, we would go through the argument list from left to right and ignore
    --      not-NULL values from previous argument rows.
    --      Even more ideally, this would be a C function.
    for _row_json in
    select
        json_strip_nulls(row_to_json(row_args.*)) as row_json
    from
        unnest($1) with ordinality as row_args
    order by
        ordinality desc
    loop
        $2 := json_populate_record($2, _row_json);
    end loop;
end;
$$;

comment on function rowalesce(variadic anyarray) is
$md$Coalesce the column/field values in the order of the argument records given.

Each argument must be of the same _explicit_ row type.
$md$;

--------------------------------------------------------------------------------------------------------------

create function rowalesce(in jsonb, variadic anyarray, out anyelement)
    immutable
    leakproof
    parallel safe
    set search_path from current
    language plpgsql
    as $$
begin
    assert jsonb_typeof($1) = 'object';

    $3 := rowalesce(variadic jsonb_populate_record($3, $1) || $2);
end;
$$;

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

create function rowalesce(in hstore, variadic anyarray, out anyelement)
    immutable
    leakproof
    parallel safe
    set search_path from current
    language plpgsql
    as $$
begin
    $3 := rowalesce(variadic populate_record($3, $1) || $2);
end;
$$;

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

create function rowalesce(anyelement, jsonb, out anyelement)
    returns anyelement
    immutable
    leakproof
    parallel safe
    set search_path from current
    language plpgsql
    as $$
begin
    $3 := jsonb_populate_record($3, $2 || jsonb_strip_nulls(to_jsonb($1)));
end;
$$;

--------------------------------------------------------------------------------------------------------------

create function table_defaults(pg_class$ regclass, include_columns$ hstore = null)
    returns hstore
    set search_path from current
    language plpgsql
    as $$
declare
    _record record;
    _default_expressions_to_execute text;
begin
    _default_expressions_to_execute := (
        select
            string_agg(
                format(
                    '%s AS %I',
                    pg_get_expr(pg_attrdef.adbin, pg_attrdef.adrelid),
                    pg_attribute.attname
                ),
                ', '
            )
        from
            pg_catalog.pg_attribute
        join
            pg_catalog.pg_attrdef
            on pg_attrdef.adrelid = pg_attribute.attrelid
            and pg_attrdef.adnum = pg_attribute.attnum
        where
            pg_attribute.attrelid = $1.oid
            and pg_attribute.attnum > 0
            and pg_attribute.atthasdef = true
            and pg_attribute.attgenerated = ''  -- zero byte
            and (
                include_columns$ is null
                or coalesce((include_columns$ -> pg_attribute.attname)::bool, false)
            )
    );

    if _default_expressions_to_execute is null then
        return ''::hstore;
    end if;

    execute 'SELECT ' || _default_expressions_to_execute into _record;
    return hstore(_record);
end;
$$;

comment on function table_defaults(regclass, hstore) is
$md$Get the (given) column default values for the given table.
$md$;

--------------------------------------------------------------------------------------------------------------

create function rowalesce_with_defaults(variadic anyarray, out anyelement)
    set search_path from current
    language plpgsql
    as $$
begin
    $2 := rowalesce(variadic $1);
    $2 := populate_record(
            $2,
            table_defaults(
                pg_typeof($2)::name::regclass,
                hstore((
                    select  array_agg(array[col.key, 'true'])
                    from    each(hstore($2)) as col
                    where   col.value is null
                ))
            )
    );
end;
$$;

comment on function rowalesce_with_defaults(variadic anyarray) is
$md$Coalesces the column values in the order of the records given and falls back to column defaults.

The argument may be `NULL` (coerced to the correct type) if you just want the column defaults for a table type.
$md$;

--------------------------------------------------------------------------------------------------------------

create function rowalesce_with_defaults(in jsonb, variadic anyarray, out anyelement)
    volatile
    set search_path from current
    language plpgsql
    as $$
begin
    assert jsonb_typeof($1) = 'object';

    $3 := rowalesce_with_defaults(
        variadic jsonb_populate_record($3, $1) || $2
    );
end;
$$;

--------------------------------------------------------------------------------------------------------------

create function rowalesce_with_defaults(in hstore, variadic anyarray, out anyelement)
    volatile
    set search_path from current
    language plpgsql
    as $$
begin
    $3 := rowalesce_with_defaults(
        variadic populate_record($3, $1) || $2
    );
end;
$$;

--------------------------------------------------------------------------------------------------------------

create function record_rowalesce_with_defaults(in record, variadic anyarray, out anyelement)
    volatile
    set search_path from current
    language plpgsql
    as $$
begin
    $3 := rowalesce_with_defaults(hstore($1), variadic $2);
end;
$$;

comment on function record_rowalesce_with_defaults(record, variadic anyarray) is
$md$This function could not be named plain `rowalesce_with-defaults()`, because Postgres considers `rowalesce_with_defaults(record, variadic anyarray)` ambiguous with `rowalesce_with_defaults(variadic anyarray)`.

Also, it doesn't add much to calling `rowalesce_with_defaults(hstore, variadic
anyarray)` directly and feeding it a `hstore(record)`.  Yet, I decided to keep
it (for now) for documentation sake.  I may still change my mind in a later
release (but not any more after 1.0).
$md$;

--------------------------------------------------------------------------------------------------------------

create function insert_row(inout anyelement)
    returns anyelement
    volatile
    set search_path from current
    language plpgsql
    as $$
declare
    _non_generated_columns name[];
begin
    _non_generated_columns := array(
        select
            pg_attribute.attname
        from
            pg_catalog.pg_attribute
        where
            pg_attribute.attrelid = pg_typeof($1)::text::regclass::oid
            and pg_attribute.attnum > 0
            and pg_attribute.attidentity = ''  -- zero byte
            and pg_attribute.attgenerated = ''  -- zero byte
        order by
            pg_attribute.attnum
    );

    execute 'INSERT INTO ' || pg_typeof($1) || ' (' || array_to_string(_non_generated_columns, ', ')
            || ') VALUES ('
            || array_to_string((
                    select  array_agg(format('$1.%I', col))
                    from    unnest(_non_generated_columns) as col
                ), ', ')
            || ')'
            || ' RETURNING *'
        using $1
        into $1;  -- This overrides the local _copy of_ the input parameter, not the (IN) param itself!
end;
$$;

comment on function insert_row(inout anyelement) is
$md$Wraps around `INSERT INTO … RETURNING` so that it''s friendlier to use in some contexts.
$md$;

--------------------------------------------------------------------------------------------------------------

create procedure test__pg_rowalesce()
    language plpgsql
    set search_path from current
    set plpgsql.check_asserts to true
    as $$
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
$$;

--------------------------------------------------------------------------------------------------------------
