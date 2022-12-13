--------------------------------------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_rowalesce" to load this file. \quit

--------------------------------------------------------------------------------------------------------------

-- Allow `readme.pg_extension_readme()` for other extensions to link to objects in this extension.
do $$
begin
    execute 'ALTER DATABASE ' || current_database()
        || ' SET pg_mockable.readme_url TO '
        || quote_literal('https://github.com/bigsmoke/pg_rowalesce/blob/master/README.md');
end;
$$;

--------------------------------------------------------------------------------------------------------------

-- Change `CREATE EXTENSION` to use the default `pg_readme` version instead of a hardcoded one.
create or replace function pg_rowalesce_readme()
    returns text
    volatile
    set search_path from current
    set pg_readme.include_view_definitions to 'true'
    set pg_readme.include_routine_definitions to 'false'
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
