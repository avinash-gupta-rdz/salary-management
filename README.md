# Salary Management

Web app for ACME's HR manager to manage salary data for ~10,000 employees across 6 countries and answer "how does the org pay people?" without spreadsheets.

- Employees: add / edit / delete, search, filter (country, department, job title, type), sort, paginated list
- Salary history: every salary change is recorded with reason and effective date
- Insights: org summary, pay by country, by department, by job title, salary distribution
- Multi-currency: salaries stored in local currency, compared across countries in USD using fixed rates

Docs (requirements, planning, tradeoffs, architecture) are in [`docs/`](docs/).

## Stack

- Backend: Ruby 3.4, Rails 8.1 (API only), SQLite
- Frontend: React 19 + TypeScript, Vite, MUI (DataGrid, Charts), TanStack Query, React Router
- Tests: RSpec + FactoryBot, Vitest + React Testing Library
- Deploy: single Docker image (Rails serves the React build), Kamal

## Setup

Needs Ruby 3.4.11 (see `.ruby-version`) and Node 22.

```bash
bin/setup --skip-server   # gems, npm packages, database
bin/rails db:seed         # 10,000 employees + exchange rates (skips if employees exist)
bin/dev                   # Rails on :3000 + Vite on :5173
```

Open http://localhost:5173 and sign in with `hr` / `password` (development default).

## Tests and checks

```bash
bin/ci                                # everything below, same as CI
bundle exec rspec                     # backend specs
bin/rubocop && bin/brakeman           # style + security
cd frontend && npm test               # frontend tests
cd frontend && npm run lint && npm run build
```

## Production

Rails serves the built React app:

- `public/assets/*` — hashed JS/CSS, cached for a year
- `public/app.html` — app shell, served with `no-cache` by `FrontendController` for every non-API page, so deep links like `/employees/42` work and deploys never leave browsers on stale assets

The Docker build does this automatically. To try production mode locally without Docker:

```bash
bin/build-frontend
RAILS_ENV=production HR_USERNAME=admin HR_PASSWORD=change-me bin/rails db:prepare
RAILS_ENV=production HR_USERNAME=admin HR_PASSWORD=change-me bin/rails server
```

### Configuration

| Variable | Purpose |
|---|---|
| `HR_USERNAME`, `HR_PASSWORD` | HR manager login. Required in production; if missing, every API request is refused. |
| `RAILS_MASTER_KEY` | Rails credentials (from `config/master.key`) |

### Deploy (own server, Kamal)

1. Set the server IP / host and registry in `config/deploy.yml`.
2. Export `HR_USERNAME` and `HR_PASSWORD` in your shell (read by `.kamal/secrets`).
3. `bin/kamal setup` the first time, then `bin/kamal deploy`.

The SQLite database lives in the `storage` volume. On first boot `db:prepare` creates it and runs the seeds, so the app starts with 10,000 employees. Later deploys keep the data.

## API

All endpoints are under `/api/v1` and need HTTP basic auth.

| Method | Path | Notes |
|---|---|---|
| GET | `/employees` | `page`, `per_page` (max 100), `q`, `country_code`, `department`, `job_title`, `employment_type`, `sort` (`full_name`, `hire_date`, `annual_salary`), `direction` |
| GET/POST/PATCH/DELETE | `/employees[/:id]` | salary changes accept `salary_change_reason`, `salary_effective_date` |
| GET | `/employees/:id/salary_changes` | latest first |
| GET | `/meta` | countries, departments, job titles, employment types |
| GET | `/insights/summary` | org totals in USD |
| GET | `/insights/by_country` | local currency stats + USD |
| GET | `/insights/by_job_title`, `/insights/by_department` | optional `country_code`: local currency if given, USD otherwise |
| GET | `/insights/distribution` | optional `country_code`, `job_title` |

Validation errors come back as `422 { "errors": { "field": ["message"] } }`.

## How I worked

> Rewrite this section in your own words.

- Wrote the requirements first, then cut scope (payroll, tax, payslips, employee portal) to focus on salary data + insights
- Built in vertical slices: data model -> API -> insights -> UI -> ship, specs in the same commit as the code
- Used Claude Code for scaffolding, implementation and review; reviewed every change and made the product decisions (scope, countries, currency per country, auth, login screen)
- Places where AI output was corrected: see `docs/planning.txt` (AI usage)
