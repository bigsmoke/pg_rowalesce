-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_rowalesce" to load this file. \quit

--------------------------------------------------------------------------------------------------------------

do $$
declare
    _ddl_cmd_to_set_pg_readme_url text;
begin
    -- In the original 0.1.2 release, the setting name was set to `pg_mockable.readme_url` due to a copy-paste
    -- mistake.  Fixed it both here and in the subsequent upgrade script.
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
