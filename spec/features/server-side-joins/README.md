---
format: https://specscore.md/feature-specification
status: Draft
---

# Feature: Server-side joins and relational DTQL profile

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/server-side-joins?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/server-side-joins?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/server-side-joins?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/server-side-joins?op=request-change) |
**Status:** Draft
**Date:** 2026-10-04
**Owner:** alex
**Source Ideas:** —
**Supersedes:** —

## Summary

OVDB accepts one DTQL document that joins, groups and aggregates records from several sources
registered on the same OVDB server, runs it where it is safe and cheapest (inside the database
when one unprotected SQLite mount holds every source, otherwise in DALgo's bounded in-memory
engine over policy-checked source reads), and returns at most 1000 rows with ordered columns and
an execution summary. Every source read is authorised twice (grants, then the mount's access
policies), every query is bounded, and the response never reveals the size of data the caller
cannot read. Part 1 covers sources registered on one server. External sources are Part 2 and are
out of scope here.

## Problem

Today OVDB's DTQL profile is one unaliased root collection: joins, GROUP BY, HAVING, cursors and
aliases are refused (`pkg/core/query.go` in openvaultdb/openvaultdb-go). A caller who wants "invoices joined to customers,
grouped by country" must pull each collection and join it client-side. The browser demo does
exactly that, in pages of up to 500 rows into IndexedDB, which costs round trips, hits the
browser engine's 10,000-row bound and burdens phones. (The paging and row-bound figures for the browser demo come from reading DataTug's
web app and were not executed.)

### Origin and authority

The founder's words (2026-10-04, verbatim; these are the only statements in this Feature that are
the founder's). The first is a stated vision and desire, not a ruling; the second is a request
with "maybe" twice, not a ruling:

> "OVDB get DTQL query and pass it to DALgo that can join. So OVDB can join recordset from
> multiple sources as long as they are registered on that OVDB server. At least that's my vision
> and desire."

> "We should fix OVDB to allow joins. And maybe even external data sources (if allowed by OVDB
> server config). Maybe with support of both whitelisted and blacklisted external sources"

Everything else below, including every limit, route, error code and the profile's contents, is
the design of the OJ implementation plan (written from code reading on 2026-10-04; nothing in
it was executed). It is proposed for review, not ruled. Items are marked **PLAN DESIGN**. The
first quotation covers Part 1; the second covers external sources, which are Part 2 and not in
this Feature's scope.

Where things live. The OJ implementation plan is filed in sneat-co/backstage at
`spec/research/datatug-ecosystem-review-2026-10/14-ovdb-joins-plan.md`; the ids OJ-nn, OV-01 and
DG-J1 in this Feature are that plan's task ids. Code paths named here are in
openvaultdb/openvaultdb-go (`pkg/...`, `docs/api.md`) or dal-go/dalgo (`access/...`); this
repository holds only the specification.

## Behavior

### Journey

Actors: an API caller (the demo or the CLI), a scoped-token user, the OVDB Cloud operator.

| # | Step | Good outcome | Criteria |
|---|---|---|---|
| 1 | I fetch `/.well-known/openvaultdb`. | A `query` block lists the endpoint, joins, GROUP BY, aggregates, cross-database support and the limits. | `discovery-advertises-query`, `capabilities-per-database` |
| 2 | I post one DTQL document joining Chinook Invoice to Customer and grouping by country to `/v1/databases/chinook/dtql`. | One response, ordered columns, at most 1000 rows, `execution.route: database`; with an ORDER BY and more than 10,000 joined rows it still succeeds, which a streaming in-memory plan cannot serve; the same document on a protected mount is refused. | `single-database-join-pushdown`, `relational-profile-accepted`, `response-shape`, `result-row-cap`, `result-byte-limit`, `consistency-documented` |
| 3 | I post a document joining `chinook.Customer` to a countries database on the same server to `/v1/dtql`. | Joined rows; `execution.sources` lists both sources with rows and milliseconds. | `cross-database-join`, `response-shape`, `mount-lease-drains-on-unmount` |
| 4 | (nothing) The server decides where the work runs. | The route label says `database` or `in-memory`. | `route-label-follows-routing`, `ingitdb-route-label`, `engine-outside-join-set-refused` |
| 5 | My query is too big or too slow. | 422 `query_budget_exceeded` naming the limit and a hint; never partial rows. | `budget-exceeded-is-422-never-partial`, `timeout-is-504`, `budget-errors-report-limit-only`, `paging-headers-refused` |
| 6 | As alice, with a token for one database, I join it to another; as alice on a policy-protected database joined to a public one. | 403 naming the other database; only her rows; a COUNT equals her readable rows; no row count for the protected source. | `grant-checked-for-every-source`, `policy-applied-per-leaf`, `count-equals-readable-rows`, `no-row-count-for-protected-source`, `nested-join-authorised`, `profile-refusals`, `per-database-endpoint-refuses-foreign-source`, `subquery-source-authorised`, `hidden-field-not-reachable` |
| 7 | (nothing) Two hundred visitors click the same demo question. | Identical GETs come from cache; excess in-memory queries get 503 with `Retry-After`; the instance stays up. | `identical-gets-cacheable`, `capacity-gate-503`, `database-route-capacity-gate` |
| 8 | As operator I deploy OVDB Cloud. | The deploy smoke join passes. | `deploy-smoke-join` |
| 9 | I run the demo question in the browser. | One query request; on a server without joins, the same answer by the browser path. | `demo-uses-server-join-when-advertised`, `demo-falls-back-on-failure` |

Whole-journey test: a single HTTP test walks steps 1 to 7 and asserts mechanism, not only output
(pushdown proved by the in-memory control, the budget error, policy counts): `journey-over-http`.
Plan task OJ-08 must cite every id; the other OJ tasks cite the ids of the steps they implement.

### Endpoints

#### REQ: endpoints

**PLAN DESIGN.** A DTQL document is **relational** when it has a join, GROUP BY, HAVING, an
aggregate, a column alias, a subquery, or a `database` on any source. Every other document takes
the existing single-collection path, and its request, response and errors (including the 400
`invalid_dtql` for a cursor or a limit above 1000) MUST NOT change. The per-database endpoint
`/v1/databases/{db}/dtql` MUST accept a relational document when every source is in that database
and MUST refuse, with a 400 naming the source and before any read, a source whose `database`
differs from `{db}`. A new `/v1/dtql` (POST, and GET with `q` and `parameters` as the
single-collection path has today) MUST accept cross-database documents and MUST require a
`database` on every source. The Cloudflare Worker already forwards every `/v1/` path, so no header change is
needed because the execution summary travels in the body.

#### REQ: name-resolution

**PLAN DESIGN.** A source's `database` MUST equal a mounted database id exactly. A syntactically invalid id MUST be a 400, which
keeps URL-shaped names free for Part 2. A well-formed id that the caller may read but that is not
mounted MUST be a 404, returned only after the grant check (`REQ: grants-before-mounts`). Every
involved mount MUST be leased for the request so that unmounting drains.

### Profile

#### REQ: relational-profile

**PLAN DESIGN.** The profile MUST accept inner and left joins, nested join trees, GROUP BY,
HAVING, the aggregates DALgo provides, column aliases, and subqueries. Subqueries always run in
memory. Engines in a join are limited at launch (Open Question 7). Window functions do not exist in DTQL; discovery MUST carry `windowFunctions: false` as
the seam.

#### REQ: profile-refusals

**PLAN DESIGN.** In this first version the relational profile MUST refuse, with a 422 naming the
refused element: cursors, `schema`, `money`, parent and collection-group sources, more than 8
sources, join depth above 4, a limit above 1000, and `scan` on a policy-protected source. The 422
applies to relational documents only; a non-relational document keeps the existing 400. The status
and code are Open Question A. (`schema` is refused because DALgo's access layer treats a
schema-qualified source as an opaque resource that collection policies do not match; `scan` is
refused until dalgo PR 197 lands.)

### Discovery

#### REQ: discovery

**PLAN DESIGN.** `/.well-known/openvaultdb` MUST gain a `query` block (endpoint, format,
features, limits, join engines) in both authentication modes, and each database's `capabilities`
MUST gain `joins` and `aggregation`. The protocol string MUST NOT change.

### Routing

#### REQ: routing

**PLAN DESIGN.** The server MUST choose the route by this table and label the response with it.

| Condition | Route | Who computes |
|---|---|---|
| One mount, SQLite (PostgreSQL after OV-01), no access policies, no subquery | `database` | The database, inside a read transaction; if the adapter declines the join, DALgo's bounded engine runs inside the same transaction |
| Several mounts | `in-memory` | DALgo over leaf reads; a flat equality join without ORDER BY streams |
| One mount with access policies, or a subquery, or inGitDB | `in-memory` | DALgo over leaf reads through the secured handle |
| Engine outside the join set | refused, 422 | |

The design follows the first quotation (OVDB passes the document to DALgo, which joins) and runs
a query inside one unprotected SQLite mount in SQLite; that extension to joins is the plan's
reading, not a founder statement. The exception, a policy-protected mount, is Open Question 3.
The label can say `database` or `in-memory` but not whether the adapter accepted the join,
because DALgo hides that decision behind an unexported wrapper; closing that needs a DALgo change
and the founder's stated reason (Open Question 5).

#### REQ: leaf-wrapper

**PLAN DESIGN.** A single wrapper MUST be the only place that authorises a source read, counts
it and budgets it. Every source read of the in-memory route, including subquery sources, MUST
pass through it.

### Response

#### REQ: response-shape

**PLAN DESIGN.** A successful response MUST be
`{"records":[{"data":{...}}],"columns":["..."],"execution":{"route","elapsedMs","rowsReturned","sources":[{"database","collection","rows","elapsedMs"}]}}`.
`key` MUST be present only for single-collection results. A single-collection response keeps exactly
`{"records":[{"key","data"}]}`: `columns` and `execution` are never added to it. Known difference, accepted for the
first version: SQLite booleans are not coerced back in joined rows.

### Limits

#### REQ: limits

**PLAN DESIGN.** Defaults, sized for a 512 MiB instance (Open Questions 6 and B), each configurable
so a test can set it small:

| Limit | Default | Told to the caller as |
|---|---|---|
| Request body | 1 MiB (existing) | 400 |
| Result | 1000 rows, 8 MiB | 422 `query_budget_exceeded` |
| Time | 10 s | 504 `query_timeout` |
| Source reads per request | 100,000 rows, 64 MiB (streamed) | 422 with limit name and hint |
| DALgo join | 10,000 rows, 16 MiB | 422, path of the join node |
| DALgo aggregation | 100,000 groups, 64 MiB | 422 |
| Concurrent in-memory queries | 2 (1 on OVDB Cloud at 512 MiB) | 503 `query_capacity`, `Retry-After` |
| Concurrent database-route queries | 4 | 503 |

Budget errors MUST report the limit, never the observed figure. A query MUST never return
partial rows. Joined results are returned whole; the paging headers on a relational document
MUST return 422. Paging refused: Open Question 8.

### Access control

#### REQ: grants-before-mounts

**PLAN DESIGN.** For every source the server MUST check `Allows(database, records:read,
collection)` before any mount is resolved (403 before 404), and again at each leaf. A 403 for a
cross-database document MUST name the database that is not allowed. Grants naming several databases: Open Question 4.

#### REQ: policy-per-leaf

**PLAN DESIGN.** Leaf reads MUST use the mount's secured handle with the request principal;
joins and aggregates MUST happen above it. A nested join MUST never be handed whole to a
protected handle (risk finding 2 below). Engines that cannot enforce policy cannot have policies
(the mount refuses the configuration), so grants alone govern them; they are outside the join set
at launch.

#### REQ: row-count-privacy

**PLAN DESIGN.** Results MUST derive only from rows the caller could read, source by source. The
execution summary MUST NOT report scanned rows and MUST omit the row count for any source with
access policies. A COUNT MUST equal the caller's readable rows.

#### REQ: subquery-sources-authorised

**PLAN DESIGN.** A source inside a subquery MUST be authorised exactly as a top-level source: the
grant check for its database and collection, then the mount's policy at its leaf read.

#### REQ: hidden-fields-unreachable

**PLAN DESIGN.** A field that policy redacts for the caller MUST NOT be usable, directly or by
alias, as a join key, group key, aggregate input or column, and MUST NOT appear in `data`. (This is
the reason policy-protected mounts run in memory over redacted rows; dalgo issue 148, a hidden
field behind an alias, is open.)

### Consistency

#### REQ: consistency-statement

**PLAN DESIGN.** The `database` route is one statement in one read transaction. The `in-memory`
route reads each source once per request with no cross-source snapshot. `docs/api.md` (openvaultdb-go) MUST state
both.

### Caching and demo

#### REQ: cacheable-gets

**PLAN DESIGN.** GET responses MUST be public for the smallest `cache_ttl` of the involved
databases only when the server is read-only, authentication is off and no involved database has
policies; otherwise they MUST NOT be publicly cacheable. (An edge cache in the Worker is
cuttable, OJ-11.)

#### REQ: demo-fallback

**PLAN DESIGN.** The browser demo MUST use one server request when discovery advertises joins and
MUST otherwise use its existing browser path, including after any failure of the server request (Open Question 2). Launch MUST NOT depend on server joins.

## Dependencies

None.

## Acceptance Criteria

Each criterion names the journey step it proves on its first line.

### AC: discovery-advertises-query (verifies REQ:discovery)

Journey step 1.

**Given** a server in either authentication mode
**When** `GET /.well-known/openvaultdb` is fetched
**Then** the body has a `query` block with endpoint, format, features (joins, GROUP BY, aggregates, cross-database), `windowFunctions: false`, the limits and the join engines, and the protocol string is unchanged

### AC: capabilities-per-database (verifies REQ:discovery)

Journey step 1.

**Given** one SQLite database and one inGitDB database mounted
**When** discovery is fetched
**Then** each database's `capabilities` carries `joins` and `aggregation` values that match what the routing table allows for it

### AC: relational-profile-accepted (verifies REQ:relational-profile, REQ:endpoints)

Journey step 2.

**Given** the Chinook database mounted
**When** a document with an inner join, a left join, a nested join, GROUP BY, HAVING, an aggregate, a column alias and a subquery is posted to `/v1/databases/chinook/dtql`
**Then** each returns 200 with the expected rows, and the existing single-collection request returns exactly what it returned before

### AC: single-database-join-pushdown (verifies REQ:routing)

Journey step 2.

**Given** an unprotected SQLite database where Invoice joined to Customer, grouped by country and ordered by the total, reads more than 10,000 joined rows (ORDER BY puts the document outside DALgo's streaming aggregate plan)
**When** that document is posted to its endpoint
**Then** the response is 200 with `execution.route: database`; and, as the negative control, the identical document over the same data on a route that must run in memory (a policy-protected mount) returns 422 `query_budget_exceeded`. OJ-08 confirms the control fails before relying on it

### AC: response-shape (verifies REQ:response-shape)

Journey step 2, 3.

**Given** a single-database join and a cross-database join
**When** each is posted
**Then** each response has `records[].data`, an ordered `columns` list and an `execution` object with `route`, `elapsedMs`, `rowsReturned` and `sources[]` (`database`, `collection`, `rows`, `elapsedMs`); `key` is absent on both and present on a single-collection result

### AC: result-row-cap (verifies REQ:limits)

Journey step 2.

**Given** a join whose result exceeds 1000 rows
**When** it is posted without a limit
**Then** the response is a 422 `query_budget_exceeded` naming the result limit, not 1000 rows presented as complete

### AC: cross-database-join (verifies REQ:endpoints, REQ:name-resolution, REQ:routing)

Journey step 3.

**Given** `chinook` and a countries database mounted on one server
**When** a document joining `chinook.Customer` to the countries database is posted to `/v1/dtql`
**Then** the response is 200 with the joined rows and `execution.sources` lists both sources with rows and milliseconds; a source without `database` returns 400, a syntactically invalid id returns 400, and a well-formed granted id that is not mounted returns 404

### AC: route-label-follows-routing (verifies REQ:routing)

Journey step 4.

**Given** one unprotected SQLite mount, two mounts, one policy-protected mount and one document with a subquery
**When** a relational document runs against each
**Then** the labels are `database`, `in-memory`, `in-memory` and `in-memory` in that order

### AC: engine-outside-join-set-refused (verifies REQ:routing)

Journey step 4.

**Given** a mounted database whose engine is outside the join set
**When** a join over it is posted
**Then** the response is a 422 naming the engine, and no rows

### AC: budget-exceeded-is-422-never-partial (verifies REQ:limits)

Journey step 5.

**Given** a query that reads more than the source-read, join or aggregation bound
**When** it is posted
**Then** the response is a 422 `query_budget_exceeded` naming the limit and a hint (the join's path for a join bound), with no records at all

### AC: timeout-is-504 (verifies REQ:limits)

Journey step 5.

**Given** the time limit configured to a small value and a query that runs longer than it
**When** it is posted
**Then** the response is a 504 `query_timeout` and the server remains able to answer the next request

### AC: budget-errors-report-limit-only (verifies REQ:limits, REQ:row-count-privacy)

Journey step 5, 6.

**Given** an over-budget query that reads a policy-protected source
**When** it is posted
**Then** the error names the limit and not the number of rows observed

### AC: profile-refusals (verifies REQ:profile-refusals)

Journey step 6.

**Given** relational documents with a cursor, a `schema`, a `money` value, a parent source, a collection-group source, nine sources, join depth five, limit 1001, and a `scan` on a policy-protected source; and one single-collection document with a cursor and another with limit 1001
**When** each is posted
**Then** each relational document returns a 422 naming the refused element and none reaches a database; the two single-collection documents return the existing 400 `invalid_dtql`

### AC: grant-checked-for-every-source (verifies REQ:grants-before-mounts)

Journey step 6.

**Given** alice's token grants `records:read` on database A only
**When** she posts a join of A and B to `/v1/dtql`
**Then** the response is a 403 naming B, returned even when B is not mounted (403 before 404), and no source is read

### AC: policy-applied-per-leaf (verifies REQ:policy-per-leaf)

Journey step 6.

**Given** a policy-protected database joined to a public one and alice readable on some of the protected rows
**When** alice posts the join
**Then** the result contains only joined rows built from rows she can read

### AC: count-equals-readable-rows (verifies REQ:policy-per-leaf, REQ:row-count-privacy)

Journey step 6.

**Given** the same databases
**When** alice posts a COUNT over the protected source
**Then** the count equals the number of protected rows she can read

### AC: no-row-count-for-protected-source (verifies REQ:row-count-privacy)

Journey step 6.

**Given** the same databases
**When** the join succeeds
**Then** `execution.sources` has no `rows` for the protected source, and no field of the response reports rows scanned

### AC: per-database-endpoint-refuses-foreign-source (verifies REQ:endpoints)

Journey step 6.

**Given** two databases mounted
**When** a document with a source whose `database` is the other database is posted to `/v1/databases/{db}/dtql`
**Then** the response is a 400 naming that source and nothing is read

### AC: subquery-source-authorised (verifies REQ:subquery-sources-authorised)

Journey step 6.

**Given** alice's token grants database A only, and a policy-protected database P readable by alice in part
**When** she posts a document whose subquery reads database B, and another whose subquery reads P
**Then** the first returns a 403 naming B and the second returns only results built from rows she can read

### AC: hidden-field-not-reachable (verifies REQ:hidden-fields-unreachable)

Journey step 6.

**Given** a protected collection with a field redacted for alice
**When** she posts documents using that field as a join key, a group key, an aggregate input and an aliased column
**Then** none exposes the field's values, in `data` or by grouping, and each is refused or returns the field absent

### AC: nested-join-authorised (verifies REQ:policy-per-leaf, REQ:leaf-wrapper)

Journey step 6.

**Given** a join tree of depth three whose innermost source is protected and which alice may read only in part
**When** alice posts it
**Then** the innermost source's policy is applied and no row she cannot read influences the result

### AC: identical-gets-cacheable (verifies REQ:cacheable-gets)

Journey step 7.

**Given** a read-only server with authentication off and no policies
**When** the same GET joined query is sent twice
**Then** the response carries a public cache lifetime equal to the smallest `cache_ttl` of the involved databases; with authentication on, or any policy present, it does not

### AC: capacity-gate-503 (verifies REQ:limits)

Journey step 7.

**Given** the in-memory concurrency limit already in use
**When** another in-memory query arrives
**Then** the response is a 503 `query_capacity` with `Retry-After`, and queries already running and later requests still succeed

### AC: deploy-smoke-join (verifies REQ:routing, REQ:endpoints)

Journey step 8.

**Given** an OVDB Cloud deployment
**When** the deploy smoke step posts a small join
**Then** it returns the expected rows, and the deploy fails when it does not

### AC: demo-uses-server-join-when-advertised (verifies REQ:demo-fallback)

Journey step 9.

**Given** a server that advertises joins, and another that does not
**When** the browser demo runs the same question against each
**Then** the first receives one query request, and the second is answered by the browser path with the same answer

### AC: database-route-capacity-gate (verifies REQ:limits)

Journey step 7.

**Given** the database-route concurrency limit already in use
**When** another database-route query arrives
**Then** the response is a 503 `query_capacity` with `Retry-After`

### AC: result-byte-limit (verifies REQ:limits)

Journey step 2.

**Given** a join returning fewer than 1000 rows whose encoded size exceeds the result byte limit (configured small)
**When** it is posted
**Then** the response is a 422 `query_budget_exceeded` naming the byte limit and no records

### AC: mount-lease-drains-on-unmount (verifies REQ:name-resolution)

Journey step 3.

**Given** a cross-database query in flight over a mount
**When** that mount is unmounted
**Then** the query completes with its full result and the unmount finishes only after it

### AC: ingitdb-route-label (verifies REQ:routing)

Journey step 4.

**Given** one local inGitDB mount
**When** a join over it is posted
**Then** `execution.route` is `in-memory`

### AC: demo-falls-back-on-failure (verifies REQ:demo-fallback)

Journey step 9.

**Given** a server that advertises joins but answers the joined request with a 503 `query_capacity`
**When** the browser demo runs the question
**Then** it answers through the browser path with the same answer

### AC: paging-headers-refused (verifies REQ:limits)

Journey step 5.

**Given** a relational document
**When** it is posted with the paging headers
**Then** the response is a 422

### AC: consistency-documented (verifies REQ:consistency-statement)

Journey step 2, 3.

**Given** `docs/api.md` in openvaultdb-go after implementation
**When** it is read
**Then** it states the one-transaction guarantee of the `database` route and the no-snapshot behavior of the `in-memory` route

### AC: journey-over-http (verifies REQ:routing, REQ:limits, REQ:policy-per-leaf, REQ:row-count-privacy)

Journey step 1 to 7.

**Given** a server with Chinook, a countries database, a protected database and a scoped token
**When** one test walks journey steps 1 to 7 over HTTP
**Then** it asserts mechanism, not only output: the pushdown beyond the in-memory bound, the budget error, and the policy-aware counts

## Risk findings recorded as open items

Three findings from reading the code, independent of this Feature, kept here until closed.
**None of the three was executed.**

1. **Spool on Cloud Run.** Cloud Run's filesystem is memory and counts against the instance
   limit, while the snapshot spool allows 512 MiB per snapshot and two slots
   (`pkg/server/dtql_pages.go` in openvaultdb-go) on a 512 MiB instance. Small sample databases
   hide it; a large one will not. Closed by plan tasks OJ-13 and OJ-09.
2. **Nested join authorisation (INFERENCE).** DALgo's access layer builds its resource list from
   the base source and first-level joins only and refuses field rules on joined sources
   (`access/session.go` in dal-go/dalgo). A nested join handed whole to a protected handle may
   skip authorisation of the nested source. The design never does that (`REQ: policy-per-leaf`);
   `nested-join-authorised` tests it.
3. **Schema-qualified sources on the existing single-collection path.** DALgo treats a
   schema-qualified source as an opaque resource, so collection policies may not match it, and the
   existing validator (`pkg/core/query.go`) has no `schema` check. That path is frozen by
   `REQ: endpoints`, so `REQ: profile-refusals` does not reach it; this finding stays open for it.
   A reading of DALgo (`access/policy.go`, also not executed) suggests the policy is default-deny
   and an opaque resource matches only opaque-query rules, so the probable result is a denial, not
   a leak. It closes with a test in openvaultdb-go that posts a `schema`-qualified
   single-collection document to a policy-protected mount and asserts denial, or with a `schema`
   refusal added to the existing validator.

## Out of scope for the first version

Window functions; trace headers; boolean coercion in joined rows; all of Part 2 (external
sources); CLI delegation. Items that are open questions rather than settled scope (paging,
engine set, grants naming several databases, native execution on protected mounts, exact
labelling) are under Open Questions.

## Open Questions

None of these is decided. Questions 1 to 8 are the implementation plan's, in its order, each with
the plan's recommendation. Questions A to C are the author's additions.

1. External sources, first form: must a caller be able to put any URL in a DTQL document, checked
   against an allow-list, or is it enough that the operator registers named external sources and
   callers use those names? Recommendation: registered sources only, built after launch (6 to 8
   agent-days); caller-supplied URLs and server-to-server delegation wait for a named user. Start
   earlier only if the Data Fabric lane finds a dataset whose licence allows querying but not
   redistribution. (Part 2; no requirement here depends on it.)
2. Launch demo: may the demo depend on server-side joins? Recommendation: no hard dependence. The
   browser sends one joined request when the server advertises joins and falls back to today's
   browser join on any failure, so the demo cannot be taken down by two 512 MiB instances being
   busy. (`REQ: demo-fallback`.)
3. Policy-protected databases: the plan reads an earlier founder instruction, that aggregation
   runs natively where the server supports it, as extending to joins. On a database with access
   policies the plan recommends an exception: OVDB aggregates over policy-filtered rows itself,
   bounded at 10,000 rows, until dalgo issue 148 (hidden field behind an alias) is closed and
   nested joins are authorised. Accept the exception? Recommendation: yes. (`REQ: routing`,
   `REQ: policy-per-leaf`, `REQ: hidden-fields-unreachable`.)
4. Tokens: a scoped application token names one database or all of them. Cross-database joins
   would therefore work for the owner token, server-wide tokens and auth-off public servers only.
   Is a grant that names several databases needed for launch? Recommendation: no; add it when the
   first authenticated cross-database user appears. (`REQ: grants-before-mounts`.)
5. DALgo exported API: a typed budget error and a plan report need the founder's stated reason
   under dalgo's AGENTS.md. Recommendation: approve with the reason "OVDB and DataTug must tell a
   user which limit stopped a query and whether the database or DALgo ran it"; it is not on the
   critical path, and without it OVDB reports the route as `database` or `in-memory` and matches
   DALgo's bound messages by text (plan task DG-J1). (`REQ: routing`, `REQ: limits`.)
6. OVDB Cloud memory: raise the Cloud Run instance from 512 MiB to 1 GiB (a deploy flag) so two
   in-memory joins can run at once and the Data Fabric datasets have room? Recommendation: yes;
   otherwise one in-memory join at a time. Prices were not checked. (`REQ: limits`.)
7. Engines in joins at launch: SQLite and local inGitDB only; PostgreSQL right after the
   PostgreSQL stream's OV-01; Firestore, GitHub-backed inGitDB and MySQL refused (full scans there
   cost money or API quota, and MySQL has no safe compiler). Recommendation: yes.
   (`REQ: relational-profile`, `engine-outside-join-set-refused`.)
8. Joined results are returned whole, at most 1000 rows, with no consistent paging in the first
   version of this feature. Recommendation: yes; charts and lookups fit, and paging a joined
   result needs a spool that the 512 MiB instance cannot hold. (`REQ: limits`,
   `paging-headers-refused`.)

Author's additions (not from the plan):

A. What status and code should relational-profile refusals use? This Feature writes a 422 scoped
   to relational documents, keeping today's 400 `invalid_dtql` for everything else; the plan names
   none. Alternative: reuse the 400 `invalid_dtql` everywhere. Recommendation: the scoped 422 with
   a stable code naming the refused element, recorded in `docs/api.md` at implementation.
B. Are the limits right for a 512 MiB instance (1000 rows, 10 s, 2 concurrent in-memory queries,
   1 on OVDB Cloud)? Recommendation: ship these defaults, configurable, and adjust after OJ-08
   records heap at the bounds; the plan measured nothing.
C. Does Cloud Run's default concurrency apply to OVDB Cloud? Recommendation: assume yes (the
   deploy sets no concurrency flag) and let the capacity gate, not Cloud Run, bound memory.

Cut order if the window slips (a plan note, not a question): OJ-11, OJ-10, OJ-12, then subqueries.

---
*This document follows the https://specscore.md/feature-specification*
