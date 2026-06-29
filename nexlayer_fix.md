# Nexlayer build guidance (publify)

Pinned: the committed `Dockerfile` and `nexlayer.yaml` are correct and must NOT be regenerated.

- Publify is a Rails 7.1 app. Build from the committed `Dockerfile` (Ruby 3.3 slim, libpq, bundle install, assets:precompile).
- Do NOT replace the `Dockerfile`. Do NOT change the `image` field on the postgres pod.
- The entrypoint runs `rake db:prepare` (create + migrate, idempotent) before starting Puma on port 3000.
- Postgres service name is `publify-postgres-service` (avoids shared-namespace `postgres.pod` DNS collision). The app connects via `publify-postgres-service.pod:5432`.
- `SECRET_KEY_BASE` and `DATABASE_URL` are set in the app pod vars; keep them.
