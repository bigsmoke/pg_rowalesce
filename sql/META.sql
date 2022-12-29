\pset tuples_only
\pset format unaligned

begin;

create extension pg_rowalesce
    cascade;

select jsonb_pretty(pg_rowalesce_meta_pgxn());

rollback;
