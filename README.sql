\pset tuples_only
\pset format unaligned

begin;

create extension pg_rowalesce cascade;

select pg_rowalesce_readme();

rollback;
