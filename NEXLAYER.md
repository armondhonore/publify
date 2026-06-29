# Nexlayer — publify

<!-- nexlayer:meta version=1 analyzed=2026-06-29T22:25:29Z repo=https://github.com/armondhonore/publify branch=nexlayer -->

> **For AI agents (Claude Code, Cursor, Gemini CLI, Copilot):**
> This file is the **project context** for this Nexlayer deployment — tech stack, env vars, secrets, live URL.
> For full platform detail (nexlayer.yaml schema, Dockerfile rules, CI/CD, task recipes) read **`nexlayer.skills`** in this repo.
>
> **Critical rules (full detail in `nexlayer.skills`):**
> - Inter-pod refs: `${podName:port}` only — never `localhost` or bare hostnames
> - Docker Hub images: prefix with `mirror.gcr.io/library/` — bare tags fail on the cluster
> - Secrets: set in the Nexlayer dashboard — never commit to `nexlayer.yaml` or Dockerfile
>
> **This file:** `agent-managed` sections update automatically. `user-editable` sections (Local Development Setup, Nexlayer Deployment Plan, Build Notes) are yours — preserved across re-analysis.

## Project Summary
<!-- nexlayer:section agent-managed=project_summary -->
Publify is a long-standing Ruby on Rails web publishing and blogging platform that emphasizes IndieWeb principles and self-hosting.
<!-- nexlayer:end -->

## Technology Stack
<!-- nexlayer:section agent-managed=tech_stack -->
| Name | Kind | Version | Detected From |
|------|------|---------|---------------|
| Ruby | language | 3.3 | Dockerfile |
| Ruby on Rails | framework | 5.2.x | README.md |
| PostgreSQL | database | latest | Dockerfile |
<!-- nexlayer:end -->

## Repository Structure
<!-- nexlayer:section agent-managed=structure_map -->
- app/ — Rails application controllers, models, and views
- config/ — Application configuration including database settings
- db/ — Database migrations and schema
- public/ — Static assets
- themes/ — Custom website themes
- lib/ — Extended libraries and custom logic
<!-- nexlayer:end -->

## External Services Required
<!-- nexlayer:section agent-managed=external_deps -->
Services that must be configured separately (not deployed by Nexlayer):

- Twitter API (via message system)
<!-- nexlayer:end -->

## Local Development Setup
<!-- nexlayer:section user-editable=local_setup -->
### Prerequisites

- Ruby >= 3.3
- PostgreSQL >= 13
- Bundler

### Environment variables

Copy `.env.example` to `.env.local` and fill in:

```
DATABASE_URL=postgresql://postgres:password@localhost:5432/publify
RAILS_ENV=development
SECRET_KEY_BASE=generate_a_random_string
```

### Steps

1. `bundle install` — Install Ruby gems
2. `bin/rails db:create db:migrate` — Setup database schema
3. `bin/rails server` — Start the application on http://localhost:3000

<!-- nexlayer:end -->

## Nexlayer Setup
<!-- nexlayer:section agent-managed=nexlayer_setup -->
### Pod Environment Variables

| Pod | Variable | Value | Kind |
|-----|----------|-------|------|
| `app` | `RAILS_ENV` | `production` | plain |
| `app` | `RAILS_SERVE_STATIC_FILES` | `"true"` | plain |
| `app` | `RAILS_LOG_TO_STDOUT` | `"true"` | plain |
| `app` | `SECRET_KEY_BASE` | _(set via Nexlayer dashboard)_ | secret |
| `app` | `DATABASE_URL` | `"postgresql://publify:${POSTGRES_PASSWORD}@publify-postgres-service.pod:5432/publify"` | inter-pod |
| `publify-postgres-service` | `POSTGRES_DB` | `publify` | plain |
| `publify-postgres-service` | `POSTGRES_USER` | `publify` | plain |
| `publify-postgres-service` | `POSTGRES_PASSWORD` | `"${POSTGRES_PASSWORD}"` | inter-pod |
| `publify-db` | `mountPath` | `/var/lib/postgresql/data` | plain |
| `publify-db` | `size` | `5Gi` | plain |

### Secrets Required

Set these in the Nexlayer dashboard before deploying:

- `SECRET_KEY_BASE` (`app` pod)

### nexlayer.yaml

```yaml
application:
  name: publify
  pods:
  - name: app
    image: "registry.nexlayer.io/user_01kece1xyh817dwff7wnarhkxd/publify:19f157c765e"
    path: /
    servicePorts:
    - 3000
    vars:
      RAILS_ENV: production
      RAILS_SERVE_STATIC_FILES: "true"
      RAILS_LOG_TO_STDOUT: "true"
      SECRET_KEY_BASE: "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"
      DATABASE_URL: "postgresql://publify:${POSTGRES_PASSWORD}@publify-postgres-service.pod:5432/publify"
  - name: publify-postgres-service
    image: mirror.gcr.io/library/postgres:16-alpine
    servicePorts:
    - 5432
    vars:
      POSTGRES_DB: publify
      POSTGRES_USER: publify
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
    volumes:
    - name: publify-db
      mountPath: /var/lib/postgresql/data
      size: 5Gi
```

<!-- nexlayer:end -->

## Nexlayer Deployment Plan
<!-- nexlayer:section user-editable=deployment_plan -->
### Pod Topology

| Pod | Image | Port | Role |
|-----|-------|------|------|
| publify-web | mirror.gcr.io/library/ruby:3.3-slim | 3000 | web |
| publify-db | mirror.gcr.io/library/postgres:16-alpine | 5432 | database |

### Deployment notes

- The web pod communicates with the database pod using the mandatory Nexlayer format: publify-db.pod:5432
- The Dockerfile uses mirror.gcr.io to comply with Nexlayer's image sourcing rules
- Assets are precompiled during the build stage to ensure the container is production-ready

<!-- nexlayer:end -->

## Build Notes
<!-- nexlayer:section user-editable=build_notes -->
<!-- Add notes for future builds here — preserved across re-analysis -->
<!-- nexlayer:end -->

## Nexlayer Configuration
<!-- nexlayer:section agent-managed=nexlayer_config -->
**Last deployed:** 2026-06-29T22:31:59Z  
**Live URL:** https://relaxed-weasel-publify.cloud.nexlayer.ai  
**Runtime:**  · **Port:** auto-detected  
**Deploy branch:** nexlayer  

```yaml
application:
  name: publify
  pods:
  - name: app
    image: "registry.nexlayer.io/user_01kece1xyh817dwff7wnarhkxd/publify:19f157c765e"
    path: /
    servicePorts:
    - 3000
    vars:
      RAILS_ENV: production
      RAILS_SERVE_STATIC_FILES: "true"
      RAILS_LOG_TO_STDOUT: "true"
      SECRET_KEY_BASE: "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"
      DATABASE_URL: "postgresql://publify:${POSTGRES_PASSWORD}@publify-postgres-service.pod:5432/publify"
  - name: publify-postgres-service
    image: mirror.gcr.io/library/postgres:16-alpine
    servicePorts:
    - 5432
    vars:
      POSTGRES_DB: publify
      POSTGRES_USER: publify
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
    volumes:
    - name: publify-db
      mountPath: /var/lib/postgresql/data
      size: 5Gi
```
<!-- nexlayer:end -->

## Build History
<!-- nexlayer:section agent-managed=build_history -->
| Date | Status | Notes |
|------|--------|-------|
| 2026-06-29T22:25:29Z | analyzed | initial repo analysis |
| 2026-06-29T22:31:59Z | success | deployed https://relaxed-weasel-publify.cloud.nexlayer.ai |
<!-- nexlayer:end -->
