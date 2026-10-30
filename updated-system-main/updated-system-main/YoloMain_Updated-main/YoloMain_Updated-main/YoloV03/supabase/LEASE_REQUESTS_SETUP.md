# Tenant lease requests

Tenants can submit renewal and termination requests from the tenant dashboard. Requests are stored in the shared Supabase `lease_requests` table and appear in the Admin Dashboard under **Lease Agreements**. Admins can approve or deny requests; denied requests may be resubmitted. An approved termination request does not automatically terminate the lease.

## Deploy the database

From the `YoloV03` directory, link the project if needed and apply the migration:

```powershell
supabase link --project-ref uranjhaewlkyzpveedvj
supabase db push
```

The migration file is `supabase/migrations/20261030000000_lease_requests.sql`.

## Admin access

The signed-in administrator must have the trusted Supabase app metadata claim `{"role":"admin"}`. Configure this under **Authentication → Users → app metadata**, then sign out and back in so the JWT refreshes. Do not assign this role in user-editable metadata. Row-level security lets tenants read and submit only their own requests and restricts request review to admins.

If requests cannot be submitted or loaded, check that the migration was applied, the user is signed in, and the admin account has the app metadata claim. The dashboards display backend errors and do not report failed submissions as successful.
