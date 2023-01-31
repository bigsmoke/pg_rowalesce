-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_rowalesce" to load this file. \quit

--------------------------------------------------------------------------------------------------------------

-- Change `pg_readme.include_view_definitions_like` to the new default.
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
    create extension if not exists pg_readme;

    _readme := pg_extension_readme('pg_rowalesce'::name);

    raise transaction_rollback;  -- to drop extension if we happened to `CREATE EXTENSION` for just this.
exception
    when transaction_rollback then
        return _readme;
end;
$plpgsql$;

--------------------------------------------------------------------------------------------------------------

-- Fix copy-paste omission in URL: ‘pg_readme’ → ‘pg_rowalesce’.
comment
    on function pg_rowalesce_meta_pgxn()
    is $markdown$
Returns the JSON meta data that has to go into the `META.json` file needed for
[PGXN—PostgreSQL Extension Network](https://pgxn.org/) packages.

The `Makefile` includes a recipe to allow the developer to: `make META.json` to
refresh the meta file with the function's current output, including the
`default_version`.

`pg_rowalesce` can be found on PGXN: https://pgxn.org/dist/pg_readme/
$markdown$;

--------------------------------------------------------------------------------------------------------------
