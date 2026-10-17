Tradeoffs
---------

1) Separate react app vs react inside rails -> separate vite app in /frontend, served from rails public/ in prod. clean separation and still one deploy, cost is two dev servers locally

2) SQLite vs Postgres -> sqlite, zero setup and 10k rows is small. not good for many concurrent writers, moving to postgres is mostly config

3) Aggregations in SQL vs Ruby -> SQL (group by, avg, min, max), fast and no loading all rows in memory. median not native in sqlite so done with window functions, still in SQL

4) Server side vs client side pagination -> server side, 10k rows in browser is heavy. cost is more api params to handle

5) Single annual salary vs salary components -> single salary, enough to answer pay questions. components can be added later

6) Fixed vs live currency rates -> fixed table in db, results same every time and easy to test. numbers can drift from real rates

7) Own salary_changes table vs paper_trail gem -> own table, only need salary changes and easy to query. doesn't track other field changes

8) Auth -> HTTP basic auth at app level with creds from env, single persona given so no users table / sessions / roles. not enough for real multi user prod, would need proper login + roles then

9) Seeding -> insert_all in batches with fixed random seed, 10k rows in seconds and same data every run. skips validations so seed data built carefully

10) Insights on request vs cached -> on request, 10k rows aggregates in ms and always fresh. add caching or summary tables if data grows a lot

11) UI library -> MUI, DataGrid does server side pagination/sort for 10k rows and MUI X Charts covers insights, widely known. cost is bigger bundle (~334KB gzip main chunk), insights page lazy loaded to cut it

12) One currency per country vs currency per employee -> one per country, set automatically so HR can't pick a wrong one. can't pay a contractor in India in USD, would need a currency field per employee then

13) Fixed department / job title list vs free text -> fixed list in code, job title must belong to its department. free text would split "Engineering" / "engineering" / "Engg" in insights. cost is a code change to add a role

14) Country change -> salary must be re-entered in the new currency and history keeps both currencies. otherwise INR 1,613,000 silently becomes USD 1,613,000. cost is one more field to fill when moving someone

15) Sort salary by USD vs local amount -> USD equivalent computed in SQL, local amounts across currencies aren't comparable (INR 5,000,000 is less than USD 100,000)

16) Missing exchange rate -> always an error (500 naming the currency) instead of $0 or dropping employees from totals. a wrong number is worse than a visible failure

17) SQLite decimal -> sqlite has no real decimal type, values stored as numeric/float. fine for salaries rounded to 1000s, postgres would be exact

18) Basic auth + sessionStorage over HTTP -> simplest for one HR user, no users table or sessions. credentials readable by XSS and sent unencrypted without a domain + https. real use needs https and a proper session

19) Fixed lists (countries, departments) in code vs tables -> code, they rarely change and code keeps them versioned and testable. would move to tables if HR needs to edit them
