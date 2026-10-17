# Salary Management

A web app for ACME's HR manager to manage salary data for 10,000 employees across six countries, and to answer **"how does the org pay people?"** in a couple of clicks instead of digging through spreadsheets.

**Live:** http://80.225.218.192 (login credentials shared separately · plain HTTP for now, no domain yet)
**Docs:** [requirements](docs/requirement.md) · [planning](docs/planning.md) · [architecture](docs/architecture.md) · [tradeoffs](docs/tradeoffs.md)

---

## The problem

ACME's HR team keeps salary data for ~10k employees in Excel files, one country at a time. Updating a salary is tedious, history gets lost, and simple questions such as *"what do we pay Software Engineers in India compared with the US?"* take an afternoon.

The user is a single persona: the **HR manager**.

## What it does

**Employees**
- Add, edit and delete employees. The list is paginated on the server, with search by name or email, filters for country, department, job title and employment type, and sorting.
- Filters, sort order and page live in the URL, so the back button and shared links work.
- Department and job title come from a fixed list, and a job title has to belong to its department, so insights never split "Engineering" into "engineering" and "Engg".

**Salary history**
- Every salary change is recorded automatically in the same database transaction as the update: old and new amount, both currencies, effective date and an optional reason.
- The employee page shows the history with the % change.

**Insights**
- Org summary in USD: headcount, total payroll, average and median salary.
- Pay by country: min, median, average, max and payroll, in local currency with USD next to it.
- Pay by department and by job title, either within one country (local currency) or across all countries (USD).
- Salary distribution histogram, optionally for one job title.

**Multi-currency, handled deliberately**
- Six countries (India, US, UK, Germany, Singapore, Canada), each paying in one currency. The currency is set from the country, so HR can't pick a mismatched one.
- Cross-country figures use fixed exchange rates to USD, so results are reproducible and testable.
- Sorting by salary uses the USD equivalent, because ₹50,00,000 is less than $100,000.
- Changing an employee's country requires re-entering the salary in the new currency. Otherwise ₹16,13,000 would silently become $1,613,000.
- A missing exchange rate is always a visible error, never a silent $0 or employees quietly dropped from a total.

## Out of scope (on purpose)

Payroll runs, payslips, tax, salary components, an employee self-service portal, roles and permissions, live exchange rates, leave and bonuses. The brief asks for salary *management and insight*, and each of these is a product of its own. The reasoning is in [docs/requirement.md](docs/requirement.md).

---

## Architecture

```
  Browser ── React + TypeScript (Vite, MUI, TanStack Query)
     │        JSON over /api/v1, HTTP basic auth header
     ▼
  Rails 8.1 (API only)
     ├─ controllers           thin: params in, JSON out
     ├─ models                validations, currency from country, salary history
     ├─ EmployeeSearch        filters, sort, pagination, USD salary in SQL
     └─ SalaryInsights        all aggregation in SQL, median via window functions
     ▼
  SQLite   (decimal money, NOT NULL / check constraints, FK with cascade)
```

In production, one Docker image serves both: Rails serves the React build (hashed assets cached for a year, the app shell never cached) and the API.

| Layer | Choice |
|---|---|
| Backend | Ruby 3.4, Rails 8.1 API, SQLite |
| Frontend | React 19, TypeScript, Vite, MUI (DataGrid, Charts), TanStack Query, React Router |
| Tests | RSpec + FactoryBot, Vitest + React Testing Library |
| Quality | RuboCop (rails-omakase), Brakeman, bundler-audit, oxlint, `tsc` |
| Deploy | Docker, Kamal, GitHub Actions, Oracle Cloud ARM VM |

Each choice and its cost is written up in [docs/tradeoffs.md](docs/tradeoffs.md).

### Project layout

```
app/
  controllers/api/v1/    employees, salary_changes, insights, meta
  models/                Employee, SalaryChange, ExchangeRate, Country, Department
  queries/               EmployeeSearch
  services/              SalaryInsights
  serializers/           EmployeeSerializer
lib/employee_seeder.rb   deterministic 10k-employee generator
db/seeds/                fixed exchange rates
frontend/src/
  api/                   client, React Query hooks, types
  auth/                  login session
  pages/                 list, form, detail, insights, login
spec/                    models, requests, services, seeder
docs/                    requirements, planning, architecture, tradeoffs
```

---

## Running it locally

**Requirements:** Ruby 3.4.11 (see `.ruby-version`) and Node 22.

```bash
bin/setup --skip-server   # gems, npm packages, database
bin/rails db:seed         # exchange rates + 10,000 employees (~1s, skipped if employees exist)
bin/dev                   # Rails on :3000 + Vite on :5173
```

Open **http://localhost:5173** and sign in with `hr` / `password` (development defaults).

The seed is deterministic: a fixed random seed and fixed date range give the same 10,000 employees on every run. Salaries come from a USD band per job title, scaled by a per-country pay factor and converted to local currency, so the insights look realistic.

## Tests and checks

```bash
bin/ci                   # everything below, the same as CI
bundle exec rspec        # 116 backend specs, ~1s
bin/rubocop
bin/brakeman
cd frontend && npm test  # 19 frontend tests
cd frontend && npm run lint && npm run build
```

- **Models:** validations, normalization, currency from country, the country-change rule, salary history.
- **Services:** every insight checked against a small hand-calculated dataset (including the even/odd median cases).
- **Requests:** auth, pagination, filters, USD sorting, validation errors, missing-rate behaviour, CSRF protections.
- **Seeder:** output passes model validations, is deterministic, and every job title has a salary band.
- **Frontend:** login flow, API client, form behaviour (salary-change reason, department → job title, country warning, server errors), salary history display.

Tests use fixed dates and seeds, with no network calls and no order dependence.

## API

All endpoints are under `/api/v1` and need HTTP basic auth. Write requests must be `application/json`.

| Method | Path | Notes |
|---|---|---|
| GET | `/employees` | `page`, `per_page` (max 100), `q`, `country_code`, `department`, `job_title`, `employment_type`, `sort` (`full_name` · `hire_date` · `annual_salary`), `direction` |
| POST | `/employees` | `{ "employee": { ... } }` |
| GET · PATCH · DELETE | `/employees/:id` | a salary change accepts `salary_change_reason`, `salary_effective_date` |
| GET | `/employees/:id/salary_changes` | latest first, with `old_currency` / `new_currency` |
| GET | `/meta` | countries, departments, job titles (also grouped by department), employment types |
| GET | `/insights/summary` | org totals in USD |
| GET | `/insights/by_country` | local-currency stats + USD |
| GET | `/insights/by_job_title` · `/insights/by_department` | optional `country_code`: local currency if given, otherwise USD |
| GET | `/insights/distribution` | optional `country_code`, `job_title` |

| Status | Body |
|---|---|
| 422 | `{ "errors": { "field": ["message"] } }` |
| 400 · 401 · 404 · 415 | `{ "error": "message" }` |
| 500 (missing exchange rate) | `{ "error": "No exchange rate for GBP" }` |

```bash
curl -u hr:password "http://localhost:3000/api/v1/employees?country_code=IN&sort=annual_salary&direction=desc&per_page=5"
curl -u hr:password "http://localhost:3000/api/v1/insights/by_job_title?country_code=US"
```

---

## Security

- **Single login:** one HR login, HTTP basic auth, credentials from `HR_USERNAME` / `HR_PASSWORD`. In production, if they aren't set, every request is refused.
- **CSRF:**
  - The 401 response never includes a `WWW-Authenticate` challenge, so browsers never cache the credentials and can't attach them to forged cross-site requests.
  - Write requests must be JSON, which an HTML form can't send.
- **Clients can't set derived fields:** currency is not accepted from clients.
- **Logs:** salary values are filtered out.
- **Database:**
  - Money is stored as `decimal(12,2)`.
  - Salaries and rates must be positive, enforced by check constraints.
  - Deleting an employee removes their history through a foreign key with cascade.
- **Brakeman is clean.** The five SQL warnings in `SalaryInsights` are reviewed and documented in `config/brakeman.ignore`. Those fragments are internal constants only, and user input always goes through bound parameters.

## Deployment

The app runs on an Oracle Cloud ARM VM (Ubuntu 24.04) with Kamal and kamal-proxy, which switches traffic to the new container only after it passes the health check, so deploys have no downtime.

- **Automatic:** a push to `main` runs CI. If CI passes, `.github/workflows/deploy.yml` deploys that exact commit:
  - It builds on a native ARM runner and pushes the image to `ghcr.io`.
  - The server pulls the image and switches over.
  - A final check confirms the site responds.
  - Only pushes to this repository deploy; pull requests (including from forks) never do.
- **From a laptop** (uses Kamal's local registry, so no registry account is needed):

  ```bash
  set -a; . ./.env.deploy; set +a   # HR_USERNAME / HR_PASSWORD, git-ignored
  bin/kamal deploy
  bin/kamal logs
  ```

- **Data:** SQLite lives in the `salary_maanagement_storage` Docker volume. The first boot runs migrations and seeds 10k employees; later deploys keep the data.

| Variable / secret | Purpose |
|---|---|
| `HR_USERNAME`, `HR_PASSWORD` | HR login |
| `RAILS_MASTER_KEY` | Rails credentials |
| `SSH_PRIVATE_KEY`, `SSH_KNOWN_HOSTS` | CI deploy key and the pinned server host key (GitHub Actions secrets) |

To try production mode locally without Docker:

```bash
bin/build-frontend
RAILS_ENV=production HR_USERNAME=admin HR_PASSWORD=change-me bin/rails db:prepare
RAILS_ENV=production HR_USERNAME=admin HR_PASSWORD=change-me bin/rails server
```

