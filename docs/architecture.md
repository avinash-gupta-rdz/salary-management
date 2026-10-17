Architecture
------------

```
  [ React (vite, MUI) ]
         |  JSON /api/v1  (HTTP basic auth header)
         v
  [ Rails API ] -> controllers, models, query object, insights service
         |
         v
  [ SQLite ]
```

Prod -> single docker image, rails serves react build + api


Data model
- employees -> full_name, email (unique), job_title, department, country_code, currency, annual_salary, employment_type, hire_date
- salary_changes -> employee_id, old_salary, old_currency, new_salary, new_currency, effective_date, reason
- exchange_rates -> currency (unique), rate_to_usd
- indexes -> email, department, job_title, (country_code + job_title) which also covers country only lookups
- db constraints -> not null, salary > 0 and rate > 0 checks, salary_changes fk with cascade delete
- money -> decimal(12,2), never float

Fixed lists in code (not tables)
- Country -> code, name, currency. currency of an employee always comes from the country
- Department -> name + its job titles. job title must belong to the department
- reason: they change rarely, and free text would split one department into many in insights


