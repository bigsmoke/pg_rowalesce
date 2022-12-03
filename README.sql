\pset tuples_only
\pset format unaligned

begin;

create schema rowalesce;

create extension pg_rowalesce
    with schema rowalesce
    cascade;

select rowalesce.pg_rowalesce_readme();

rollback;
