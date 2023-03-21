-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_rowalesce" to load this file. \quit

--------------------------------------------------------------------------------------------------------------

-- Add test to expose `null_value_not_allowed` bug.
create or replace procedure test__pg_rowalesce()
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

-- Be okay when no defaults are found among the columns to include.
create or replace function table_defaults(pg_class$ regclass, include_columns$ hstore = null)
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

--------------------------------------------------------------------------------------------------------------
