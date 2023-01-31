-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_rowalesce" to load this file. \quit

--------------------------------------------------------------------------------------------------------------

do $$
declare
    _ddl_cmd_to_set_pg_readme_url text;
begin
    -- In the original 0.1.2 release, the setting name was set to `pg_mockable.readme_url` due to a copy-paste
    -- mistake.  Fixed it both there and in this subsequent upgrade script.  (I know that it's unlikely that
    -- someone was running 0.1.2, but one has to be hygienic about these things.)
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
        ,'gpl_3'
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
