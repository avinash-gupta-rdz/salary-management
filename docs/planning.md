Planning
--------

Approach: small vertical slices, backend + tests first then UI, commit after each step.

1) Setup -> rails api with rspec and factory bot, react with vite, docs
2) Employee data -> employee model with validations + indexes, exchange rates, seed 10k employees
3) Employee API -> CRUD with pagination, search, filter, sort + request specs
4) Employee UI -> list page with search/filter/pagination, add/edit form, delete
5) Salary history -> save every salary change, show history on employee page
6) Insights -> insights service + api + specs, dashboard page with cards and charts
7) Ship -> single docker image (react build served by rails), deploy, readme, demo video

Testing
- models -> validations, salary history
- services -> insight calculations on small known data
- requests -> api responses, filters, pagination, errors
- frontend -> few component tests for list and form
