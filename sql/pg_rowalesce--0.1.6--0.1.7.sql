-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_rowalesce" to load this file. \quit

--------------------------------------------------------------------------------------------------------------

-- Change license from AGPL 3.0 to PostgreSQL.
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

-- Retain copy-paste error in URL. 🤦
comment
    on function pg_rowalesce_meta_pgxn()
    is $markdown$
Returns the JSON meta data that has to go into the `META.json` file needed for
[PGXN—PostgreSQL Extension Network](https://pgxn.org/) packages.

The `Makefile` includes a recipe to allow the developer to: `make META.json` to
refresh the meta file with the function's current output, including the
`default_version`.

`pg_rowalesce` can be found on PGXN: https://pgxn.org/dist/pg_rowalesce/
$markdown$;

--------------------------------------------------------------------------------------------------------------
