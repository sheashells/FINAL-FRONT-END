create table if not exists public.lease_requests (
    id uuid primary key default gen_random_uuid(),
    tenant_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    tenant_name text not null check (char_length(btrim(tenant_name)) between 1 and 120),
    tenant_email text not null check (char_length(btrim(tenant_email)) between 3 and 320),
    property_name text not null check (char_length(btrim(property_name)) between 1 and 160),
    unit_name text not null check (char_length(btrim(unit_name)) between 1 and 160),
    request_type text not null check (request_type in ('Renewal', 'Termination')),
    status text not null default 'Pending' check (status in ('Pending', 'Approved', 'Denied')),
    management_note text not null default '' check (char_length(management_note) <= 1000),
    reviewed_by uuid references auth.users(id) on delete set null,
    reviewed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists lease_requests_tenant_created_idx
    on public.lease_requests (tenant_id, created_at desc);
create index if not exists lease_requests_status_created_idx
    on public.lease_requests (status, created_at desc);
create unique index if not exists lease_requests_one_pending_per_type_idx
    on public.lease_requests (tenant_id, request_type)
    where status = 'Pending';

alter table public.lease_requests enable row level security;
revoke all on table public.lease_requests from anon, public;
grant select, insert, update on table public.lease_requests to authenticated;

drop policy if exists "Tenants and admins can read lease requests" on public.lease_requests;
create policy "Tenants and admins can read lease requests"
    on public.lease_requests
    for select
    to authenticated
    using (
        tenant_id = (select auth.uid())
        or coalesce((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false)
    );

drop policy if exists "Tenants can submit their own lease requests" on public.lease_requests;
create policy "Tenants can submit their own lease requests"
    on public.lease_requests
    for insert
    to authenticated
    with check (
        tenant_id = (select auth.uid())
        and lower(tenant_email) = lower((select auth.jwt() ->> 'email'))
        and status = 'Pending'
        and management_note = ''
        and reviewed_by is null
        and reviewed_at is null
    );

drop policy if exists "Admins can review lease requests" on public.lease_requests;
create policy "Admins can review lease requests"
    on public.lease_requests
    for update
    to authenticated
    using (
        status = 'Pending'
        and coalesce((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false)
    )
    with check (
        coalesce((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false)
        and status in ('Approved', 'Denied')
        and reviewed_by = (select auth.uid())
        and reviewed_at is not null
    );
