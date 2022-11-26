begin;

create extension pg_rowalesce cascade;

call test__pg_rowalesce();

rollback;
