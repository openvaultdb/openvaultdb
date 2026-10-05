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
registered on the same OVDB server, runs it where it is cheapest (inside the database when one
unprotected SQLite mount holds every source, otherwise in DALgo's bounded in-memory engine over
guarded source reads), and returns at most 1000 rows with ordered columns and an execution
summary. Every source read is authorised against the caller's grants for its database and
collection, every query is bounded, and the response never reveals the size of data the caller
cannot read. As a launch limit, a relational document that names a database with access policies
is refused; joins over such databases are planned after launch. Part 1 covers sources registered
on one server. External sources are Part 2 and are out of scope here.

## Problem

OVDB's single-collection DTQL profile is one unaliased root collection: joins, GROUP BY, HAVING,
cursors and aliases are outside it (`pkg/core/query.go` in openvaultdb/openvaultdb-go). Without the
relational profile of this Feature, a caller who wants "invoices joined to customers,
grouped by country" must pull each collection and join it client-side. The browser demo does
exactly that, in pages of up to 500 rows into IndexedDB, which costs round trips, hits the
browser engine's 10,000-row bound and burdens phones. (The paging and row-bound figures for the browser demo come from reading DataTug's
web app and were not executed.)

### Origin and authority

The founder's words (2026-10-04; these are the only verbatim founder statements in this Feature; Open Question 3 paraphrases a third, about aggregation). The first is a stated vision and desire, not a ruling; the second is a request
with "maybe" twice, not a ruling:

> "OVDB get DTQL query and pass it to DALgo that can join. So OVDB can join recordset from
> multiple sources as long as they are registered on that OVDB server. At least that's my vision
> and desire."

> "We should fix OVDB to allow joins. And maybe even external data sources (if allowed by OVDB
> server config). Maybe with support of both whitelisted and blacklisted external sources"

Everything else below, including every limit, route, error code and the profile's contents, is
the design of the OJ implementation plan (written from code reading on 2026-10-04; nothing in
it was executed). It is proposed for review, not ruled. Items are marked **PLAN DESIGN**. Parts
of them were added in review and are not in the plan: the rule that every document on `/v1/dtql`
is handled as relational, the default refusal and the offset, scan and parse-failure rules of
`REQ: profile-refusals`, name validation in `REQ: values-and-names-never-text` (the plan covers
parameter binding only), counting row and byte budgets after the policy filter, the 503
`query_capacity` code on the database route gate, collection-scoped grants, the refusal of
relational documents on databases with access policies (`REQ: protected-databases-refused`), the
rule that a subquery-only document and a root that names a database are relational on the
per-database endpoint while the endpoint's own database is dropped from the root, and the strict
field-name rule on relational documents. The last three groups are decisions taken in review and
reported to the founder, who has not answered them (the first is Open Question 3). The
first quotation covers Part 1; the second covers external sources, which are Part 2 and not in
this Feature's scope. This Feature was last revised on 2026-10-05 against openvaultdb-go main at
2961796, which holds the relational path (pull requests 48 and 51); where the code fixes a rule,
this Feature states it as the behaviour. "Main" below means openvaultdb-go main at 2961796.

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
| 2 | I post one DTQL document joining Chinook Invoice to Customer and grouping by country to `/v1/databases/chinook/dtql`. | One response, ordered columns, at most 1000 rows, `execution.route: database`; with an ORDER BY and more than 10,000 joined rows it still succeeds, which a streaming in-memory plan cannot serve, and the same data split across two mounts is a 422 `query_budget_exceeded`. A document on a mount with access policies is a 422 `authorization_unsupported`. | `single-database-join-pushdown`, `relational-profile-accepted`, `subquery-only-document-is-relational`, `response-shape`, `result-row-cap`, `result-byte-limit`, `consistency-documented`, `single-source-with-database-unchanged`, `default-schema-dropped`, `parameters-and-names-cannot-change-query`, `ambiguous-field-refused`, `wildcard-expands-in-field-order` |
| 3 | I post a document joining `chinook.Customer` to a countries database on the same server to `/v1/dtql`. | Joined rows; `execution.sources` lists both sources with rows and milliseconds. | `cross-database-join`, `cross-database-endpoint-single-source`, `default-schema-dropped`, `response-shape`, `mount-lease-drains-on-unmount`, `consistency-documented` |
| 4 | (nothing) The server decides where the work runs. | The route label says `database` or `in-memory`; a 501 `query_unsupported` or a 422 names an engine that cannot join; a lone-source read of such an engine is refused on `/v1/dtql` and served on the per-database endpoint; a relational document that names a database with access policies has no label and is a 422 `authorization_unsupported`. | `route-label-follows-routing`, `ingitdb-route-label`, `engine-outside-join-set-refused`, `lone-source-outside-join-set-by-endpoint` |
| 5 | My query is too big or too slow. | 422 `query_budget_exceeded` naming the limit and a hint; never partial rows. | `budget-exceeded-is-422-never-partial`, `timeout-is-504`, `budget-errors-report-limit-only`, `paging-headers-refused` |
| 6 | As alice, with a token for one database, I join it to another; as alice on a policy-protected database joined to a public one. | 403 naming the other database; on the protected database every join, COUNT, nested join and aggregate is the same 422 `authorization_unsupported` with no rows and no `execution`, while a single-collection read of it on the per-database endpoint returns only the rows she may read; refused profile elements are a 400 `invalid_dtql`. | `grant-checked-for-every-source`, `protected-database-refuses-relational-document`, `profile-refusals`, `check-order-decides-the-status`, `per-database-endpoint-refuses-foreign-source`, `subquery-source-authorised`, `collection-scoped-grant-checked` |
| 7 | (nothing) Two hundred visitors click the same demo question. | Identical GETs come from cache; excess in-memory queries get 503 with `Retry-After`; the instance stays up. | `identical-gets-cacheable`, `capacity-gate-503`, `database-route-capacity-gate` |
| 8 | As operator I deploy OVDB Cloud. | The deploy smoke join passes. | `deploy-smoke-join` |
| 9 | I run the demo question in the browser. | One query request; on a server without joins, the same answer by the browser path. | `demo-uses-server-join-when-advertised`, `demo-falls-back-on-failure` |

Whole-journey test: a single HTTP test walks steps 1 to 7 and asserts mechanism, not only output
(pushdown proved by the in-memory control, the budget error, the refusal of every relational shape
on a database with access policies): `journey-over-http`. Plan task OJ-08 must cite every id of the
steps it walks; the other OJ tasks cite the ids of the steps they implement. The criteria of
databases with access policies that are not testable at launch are under "After launch: joins over
databases with access policies" and belong to no step.

### Endpoints

#### REQ: endpoints

**PLAN DESIGN.** A DTQL document is **single-collection** when it reads one unaliased root
collection with plain unqualified field columns, and has no join, GROUP BY, HAVING, aggregate,
column alias, subquery, null test, `database`, `schema`, `scan` or cursor. Every other document
that the profile accepts is **relational**. Before a document on the per-database endpoint is
classified, two qualifiers of its root source that the endpoint already supplies are dropped, and
the document is read as if it carried neither: a `schema` equal to the default schema of the
engine of `{db}` (`main` on SQLite), and a `database` equal to `{db}`. Only the root source is
read for either, and only when the key is written once: the same schema on a joined or derived
source, the default schema in another letter case, and a key written twice stay in place and are
refused like any other.

A document that is single-collection after that takes the **single-collection path**. Its
response is exactly `{"records":[{"key","data"}]}` with no other member. A document that would be
single-collection but for a cursor, a limit above 1000, an offset above 10,000, a `schema` that is
not the default one, a `scan` or a `database` other than `{db}` is a 400 `invalid_dtql`. A
relational document, on either endpoint, and every
document on `/v1/dtql`, relational or not, take the **new path**: the refusals of
`REQ: profile-refusals`, the paging-header refusal of `REQ: limits` and the relational response
shape of `REQ: response-shape` apply to them. A document whose only relational feature is a
subquery is relational on the per-database endpoint: it is answered on the new path, in memory,
with `columns` and `execution` and no `key`, whether its sources name `{db}` or none.

`/v1/dtql` has no single-collection path: every document posted there, with or without a join and
with one source or several, is relational, requires a `database` on every source, and accepts no
`schema` at all (the default schema included). That includes a plain single-source read of an
engine outside the join set (Firestore, say): `/v1/dtql` refuses it with the 422 of
`REQ: routing`, and the per-database endpoint, which has the single-collection path, still
serves it. This is intended; a caller who wants that read uses the per-database endpoint. The
per-database endpoint `/v1/databases/{db}/dtql` MUST accept a relational document when every
source is in that database (a source that names no database is in `{db}`) and MUST refuse a
document that has a source whose `database` differs from `{db}`, a one-source document whose root
names another database included, with a 400 `invalid_dtql` that names the database and points to
`POST /v1/dtql`, before any read. A new `/v1/dtql` (POST, and GET with `q` and `parameters` as the
single-collection path has) MUST accept cross-database documents and MUST require a `database` on
every source, with a 400 `invalid_dtql` for one without. The Cloudflare Worker already forwards
every `/v1/` path, so no header change is needed because the execution summary travels in the
body.

#### REQ: check-order

**PLAN DESIGN.** A request MUST be answered by the first of these checks that fails, so that a
caller can predict the status of any request from this Feature alone:

1. Authentication (401), and on the per-database endpoint a database `{db}` that is mounted (404).
2. The request is a document: a URL over 8 KiB (414), an empty body, a URL parameter other than
   `q` and `parameters`, or a parameter that is not bound (400 `bad_request` or `invalid_dtql`);
   then a document that parses and that the profile accepts, so that every refusal of
   `REQ: profile-refusals` and every name that the wider quoted-name rule of
   `REQ: values-and-names-never-text` refuses is a 400 `invalid_dtql`.
3. Every source has a database: a source with none on `/v1/dtql`, or a database other than `{db}`
   on the per-database endpoint (400 `invalid_dtql`).
4. The caller's grant covers every database and collection a source names, at any depth (403
   `forbidden`, naming the first it does not cover, whether or not that database is mounted).
5. Every database a source names is mounted (404 `not_found`).
6. No database a source names has access policies (422 `authorization_unsupported`,
   `REQ: protected-databases-refused`).
7. Every collection a source names is one that its database declares, under its canonical name,
   where the engine builds SQL (404 `not_found`).
8. No paging header is present (422 `snapshot_unsupported`).
9. Every database is on an engine that can be queried (501 `query_unsupported`), and then on one
   in the join set (422 `join_engine_unsupported`).
10. The query runs: a free slot on its route (503 `query_capacity`), the bounds of `REQ: limits`
    (422 `query_budget_exceeded`), the time limit (504 `query_timeout`), a field name that the
    wider rule accepts and the strict one of a relational document refuses, and a shape that
    DALgo or the database refuses (400 `invalid_dtql`).

#### REQ: values-and-names-never-text

**PLAN DESIGN** for parameter binding; the rest was added in review. On both routes, parameter
values MUST be bound as values and never spliced into text. Names are refused unless plain, with a
400 `invalid_dtql`, and what passes MUST still reach a database only as a quoted identifier. A
relational document holds the strict field-name rule on every engine: a field name is one or more
dot-separated segments of Unicode letters, combining marks, digits, underscore and hyphen (a
segment starts with a letter, a digit or an underscore, or with `$` before a letter or underscore,
and a combining mark never starts one; no `--`; at most 256 bytes; Firestore field names may be
non-ASCII and numeric map keys are legal), so a field name with a space, a quote or a slash is a
400 `invalid_dtql` on a relational document even on SQLite. The single-collection path holds the
same rule on every engine except SQLite and inGitDB, which quote every name they write into a
statement and accept the wider rule of `pkg/core/query_guard.go` (a column named `zip code` can be
selected there and cannot be named by a relational document). A column alias, a source alias and a
field qualifier that names no source in scope are ASCII identifiers (`[A-Za-z_][A-Za-z0-9_]*`); a
collection name follows the existing collection-name rule. These rules are defined in code
(`pkg/core/query_guard.go` and `pkg/joinexec/walk.go` on main). A database error's text MUST NOT
be returned to the caller. (Column aliases are new caller text in the generated SQL and in
`columns`.)

#### REQ: name-resolution

**PLAN DESIGN.** A source's `database` MUST equal a mounted database id exactly. A syntactically invalid id MUST be a 400, which
keeps URL-shaped names free for Part 2. A well-formed id that the caller may read but that is not
mounted MUST be a 404, returned only after the grant check (`REQ: grants-before-mounts`). Every
involved mount MUST be leased for the request so that unmounting drains.

### Profile

#### REQ: relational-profile

**PLAN DESIGN.** The profile MUST accept inner and left joins, nested join trees, GROUP BY,
HAVING, the aggregates DALgo provides, column aliases, subqueries, join algorithm hints, and
source aliases, plus everything the existing single-collection profile accepts (field columns,
WHERE, ORDER BY, a LIMIT up to 1000, parameters) and an `offset` up to 10,000. Subqueries always
run in memory. Engines in a join are limited at launch (`REQ: routing`). A join tree may nest to
any depth within the bound of 8 sources (`REQ: profile-refusals`); its depth is not bounded
separately. Window functions do not exist in DTQL; discovery MUST carry `windowFunctions: false` as
the seam. (Hints and the offset bound follow openvaultdb-go pull request 38, which accepts hints
and bounds `offset`; a hint only chooses among join algorithms DALgo bounds itself.)

#### REQ: field-resolution

**PLAN DESIGN.** An unqualified field that more than one source in scope carries MUST be refused
with a 400 `invalid_dtql`, and never bound to the first source. A wildcard column (`*` or
`source.*`) MUST expand to the fields of the sources in the order of the sources and of their
fields, on the database route and on the in-memory route alike, so that one document returns the
same columns whichever route runs it.

#### REQ: profile-refusals

**PLAN DESIGN** for the list; the default refusal and the last three rules were added in review.
In this first version a relational document MUST be refused, with a 400 `invalid_dtql` that names
the refused element, before any read: cursors (a DTQL document has no key for a cursor, so the
deserialiser's 400 names `startFrom`), `schema`, `money`, parent and collection-group sources,
more than 8 sources, subqueries nested deeper than 4, a limit above 1000 or an `offset` above
10,000 on the outermost query, and `scan` on any source (protected or not; this follows pull
request 38, and the reason is below). The depth of a join tree is not bounded separately. Any
element of a document on the new path that `REQ: relational-profile` does not list MUST be refused
with the same 400, naming the element. A document that DALgo's deserialiser rejects (a right join,
say) is the same 400 `invalid_dtql`, because it cannot be classed before it parses. The status and
code are the same on both endpoints and on both paths, and the paging headers, which are not part
of the document, are a 422 `snapshot_unsupported` (`REQ: limits`). (`schema` is refused because
DALgo's access layer treats a schema-qualified source as an opaque resource that collection
policies do not match; `scan` is refused because DALgo's access layer does not check scan orders
and dalgo PR 197 has not landed.)

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
| One mount, SQLite (PostgreSQL after OV-01), no access policies, no subquery and no null test | `database` | The database, inside one read transaction. When the database cannot compile a join that has no aggregation, nothing has been read yet and the document is read again on the in-memory route, whose label the response then carries |
| Several mounts, none with access policies | `in-memory` | DALgo over leaf reads; a flat equality join without ORDER BY streams |
| One mount without access policies that holds a subquery or a null test, or one inGitDB mount | `in-memory` | DALgo over leaf reads |
| A mount with access policies among the databases the document names | refused, 422 `authorization_unsupported`, no route label | Nothing runs: the refusal comes before any collection name is looked up (`REQ: protected-databases-refused`) |
| PostgreSQL or MySQL mount | refused, 501 `query_unsupported` naming the engine | The guard on main (openvaultdb-go pull request 40, merged): every structured query on those mounts is refused until OV-01 |
| Any other engine outside the join set | refused, 422 `join_engine_unsupported` naming the engine | The operator's list of join engines, SQLite and local inGitDB by default; a GitHub-backed inGitDB mount is never joined |

The design follows the first quotation (OVDB passes the document to DALgo, which joins) and runs
a query inside one unprotected SQLite mount in SQLite; that extension to joins is the plan's
reading, not a founder statement. A policy-protected mount is refused at launch
(`REQ: protected-databases-refused`); how joins over it are served after launch is Open Question 3.
The label can say `database` or `in-memory` but not whether the adapter accepted the join,
because DALgo hides that decision behind an unexported wrapper; closing that needs a DALgo change
and the founder's stated reason (Open Question 5).

#### REQ: leaf-wrapper

**PLAN DESIGN.** A single wrapper MUST be the only place that authorises a source read, counts
it and budgets it. Every source read of the in-memory route, including subquery sources, MUST
pass through it. Row and byte budgets MUST count only rows the secured handle returns to the
caller's principal, never rows scanned.

### Response

#### REQ: response-shape

**PLAN DESIGN.** A successful response MUST be
`{"records":[{"data":{...}}],"columns":["..."],"execution":{"route","elapsedMs","rowsReturned","sources":[{"database","collection","rows","elapsedMs"}]}}`,
where each source carries `rows` and `elapsedMs` on the `in-memory` route and only its `database`
and `collection` on the `database` route, where the database reports no more.
Every response on the new path, including one over a single source and every successful response
from `/v1/dtql`, has `columns` and `execution` and no `key`. A non-relational response on the
per-database endpoint keeps exactly `{"records":[{"key","data"}]}`: `columns` and `execution` are
never added to it. A relational row is not passed through the schema coercion of the
single-collection path: a declared boolean of a SQLite mount is 0 or 1 in a relational row and
`true` or `false` in a single-collection record. This difference is accepted for the first
version.

### Limits

#### REQ: limits

**PLAN DESIGN.** Defaults, sized for a 512 MiB instance (Open Questions 6 and B). The time limit,
the source-read bounds and the two concurrency limits are settings of the server, so that a test
can set them small; the request body, the result and the DALgo bounds are fixed:

| Limit | Default | Told to the caller as |
|---|---|---|
| Request body | 1 MiB (existing) | 400 |
| Result | 1000 rows, 8 MiB | 422 `query_budget_exceeded` |
| Time | 10 s | 504 `query_timeout` |
| Source reads per request | 100,000 rows, 64 MiB (streamed) | 422 with limit name and hint |
| DALgo join | 10,000 rows, 16 MiB | 422, path of the join node |
| DALgo aggregation | 100,000 groups, 64 MiB | 422 |
| Concurrent in-memory queries | 2 (1 on OVDB Cloud at 512 MiB) | 503 `query_capacity`, `Retry-After` |
| Concurrent database-route queries | 4 | 503 `query_capacity`, `Retry-After` |

Budget errors MUST report the limit, never the observed figure. A query MUST never return
partial rows. Joined results are returned whole: the paging headers on a document on the new path
(a relational document, or any document on `/v1/dtql`) MUST return a 422 `snapshot_unsupported`,
and no snapshot is taken.

### Access control

#### REQ: grants-before-mounts

**PLAN DESIGN.** For every source of a document on the new path the server MUST check
`Allows(database, records:read, collection)`, with the collection the source names, before any
mount is resolved (403 before 404), and again at each leaf. On the `database` route the
leaf wrapper is not involved, so this check is the only grant check there. A 403 for a
cross-database document MUST name the database that is not allowed. Grants naming several databases: Open Question 4.

#### REQ: protected-databases-refused

**PLAN DESIGN.** This is a launch limit. A relational document that names a database with access
policies in any of its sources, at any depth and in a subquery included, MUST be refused with a
422 `authorization_unsupported` that carries no rows and no `execution`, and that names the
database and no collection. The refusal comes after the grant check (403) and the lookup of the
database (404), and before any collection name is looked up and before anything is read, so the
answer depends on the databases the document names and on nothing else: it is the same whichever
collections the document names, declared or not, readable or not, and whatever shape it has (a
join, a nested join, a COUNT, an aggregate, an alias, a subquery). A document of one plain
collection on the per-database endpoint is not relational and is still read through the mount's
policy: it returns only the rows the caller may read. Joins over databases with access policies
are planned after launch; the requirements below that concern them, and their criteria, are kept
under "After launch: joins over databases with access policies".

#### REQ: policy-per-leaf

**PLAN DESIGN, after launch.** Leaf reads MUST use the mount's secured handle with the request
principal; joins and aggregates MUST happen above it. A nested join MUST never be handed whole to
a protected handle (risk finding 2 below). Engines that cannot enforce policy cannot have policies
(the mount refuses the configuration), so grants alone govern them; they are outside the join set
at launch. At launch no relational document reads a database with access policies
(`REQ: protected-databases-refused`).

#### REQ: row-count-privacy

**PLAN DESIGN, after launch.** Results MUST derive only from rows the caller could read, source by
source. The execution summary MUST NOT report scanned rows and MUST omit the row count for any
source with access policies. A COUNT MUST equal the caller's readable rows. At launch the
execution summary reports the rows read from each source on the in-memory route, and every
source of a relational answer is a database without access policies.

#### REQ: subquery-sources-authorised

**PLAN DESIGN.** A source inside a subquery MUST be authorised exactly as a top-level source: the
grant check for its database and collection, before anything is read, and, for a database with
access policies (after launch), the mount's policy at its leaf read.

#### REQ: hidden-fields-unreachable

**PLAN DESIGN, after launch.** A field that policy redacts for the caller MUST NOT be usable,
directly or by alias, as a join key, group key, aggregate input, column, filter predicate (WHERE,
HAVING, join ON) or sort key, and MUST NOT appear in `data`. (This is the reason policy-protected
mounts are read one collection at a time; dalgo issue 148, a hidden field behind an alias, is
open.) At launch no relational document reads a database with access policies
(`REQ: protected-databases-refused`).

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

### AC: single-source-with-database-unchanged (verifies REQ:endpoints)

Journey step 2.

**Given** two databases mounted and a document of one root collection `from: {database: X, name: C}`
**When** it is posted to `/v1/databases/{db}/dtql`
**Then** with X equal to `{db}` the response is `{records:[{key,data}]}`, the same body as the document that names no database (the `database` written before or after the name, in flow or block form, with or without the default `schema`); with X different from `{db}` the response is a 400 `invalid_dtql` that points to `POST /v1/dtql`, and nothing is read

### AC: default-schema-dropped (verifies REQ:endpoints)

Journey step 2, 3.

**Given** a SQLite database mounted and a document of one root collection with `schema: main`
**When** it is posted to `/v1/databases/{db}/dtql`, and, with a `database` added, to `/v1/dtql`
**Then** the first response is the body of the document that carries no schema; the same document with another schema, with `MAIN`, with a `schema` on a joined source or with a `scan` is a 400 `invalid_dtql`; and the second is a 400 `invalid_dtql`, because `/v1/dtql` accepts no schema at all

### AC: subquery-only-document-is-relational (verifies REQ:endpoints)

Journey step 2.

**Given** the Chinook database mounted and a document over Invoice whose only relational feature is an EXISTS subquery over Customer, written with sources that name no database, with sources that name `chinook`, and with an alias on the root
**When** each is posted to `/v1/databases/chinook/dtql`, and the one whose sources name `chinook` is posted to `/v1/dtql`
**Then** each returns 200 with the same rows, `columns`, `execution.route: in-memory` and no `key`

### AC: parameters-and-names-cannot-change-query (verifies REQ:values-and-names-never-text)

Journey step 2.

**Given** relational documents whose parameter value, column alias, source alias and field name each contain a quote and SQL text, and a relational document with a field named with a space (`first name`)
**When** each is posted against an unprotected SQLite mount, and the alias, source-alias and field-name documents also against a policy-protected one
**Then** the parameter value comes back as data (no row has that name); each alias or field name that holds a quote is refused with a 400 `invalid_dtql` on both mounts; the field named with a space is refused with a 400 `invalid_dtql` on the unprotected mount, because a relational document holds the strict field-name rule on every engine; and no response has a different result set or contains database error text

### AC: relational-profile-accepted (verifies REQ:relational-profile, REQ:endpoints)

Journey step 2.

**Given** the Chinook database mounted
**When** a document with an inner join, a left join, a nested join, GROUP BY, HAVING, an aggregate, a column alias and a subquery is posted to `/v1/databases/chinook/dtql`
**Then** each returns 200 with the expected rows, and the single-collection request returns `{records:[{key,data}]}` with no other member

### AC: ambiguous-field-refused (verifies REQ:field-resolution)

Journey step 2.

**Given** a SQLite mount and a local inGitDB mount, each with a join whose two sources both carry a field `CustomerId`
**When** a document selects `CustomerId` with no source qualifier, against each mount
**Then** each returns a 400 `invalid_dtql` naming the field and no rows, and the same document with the field qualified returns 200

### AC: wildcard-expands-in-field-order (verifies REQ:field-resolution)

Journey step 2.

**Given** the same SQLite mount and local inGitDB mount, and a join of two sources with a wildcard column
**When** it is posted against each mount, so that the database route runs the first and the in-memory route the second
**Then** each returns 200 and the columns are the fields of the first source and then those of the second, each in its declared order, the same on both routes

### AC: single-database-join-pushdown (verifies REQ:routing)

Journey step 2.

**Given** a generated database with the Chinook table names and more than 10,000 invoices (Chinook itself has 412), unprotected SQLite, where Invoice joined to Customer, grouped by country and ordered by the country, reads more than 10,000 joined rows (ORDER BY puts the document outside DALgo's streaming aggregate plan), and the same two tables split across two mounts
**When** the document is posted to the endpoint of the one database, and the split document, with every source naming its database, is posted to `/v1/dtql`
**Then** the first response is 200 with `execution.route: database`; and, as the negative control, the second runs in memory and is a 422 `query_budget_exceeded` that names a join bound of 10,000 rows. OJ-08 first shows the control returns 422, then relies on it. The same document on a policy-protected mount is a 422 `authorization_unsupported` before anything is read

### AC: response-shape (verifies REQ:response-shape)

Journey step 2, 3.

**Given** a single-database join and a cross-database join
**When** each is posted
**Then** each response has `records[].data`, an ordered `columns` list and an `execution` object with `route`, `elapsedMs`, `rowsReturned` and `sources[]` (`database`, `collection`, and on the `in-memory` route `rows` and `elapsedMs`); `key` is absent on both and present on a non-relational result from the per-database endpoint; a relational document over one source (a COUNT, say) also has `columns` and `execution` and no `key`

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

### AC: cross-database-endpoint-single-source (verifies REQ:endpoints, REQ:profile-refusals, REQ:response-shape, REQ:limits)

Journey step 3.

**Given** `chinook` mounted and a single-source document `from: {database: chinook, name: Customer}` with no join
**When** it is posted to `/v1/dtql`
**Then** the response is 200 with `columns` and `execution` (with `route` set as the routing table says) and no `key`; the same document with a `schema`, with a `scan`, with a cursor or with `money` is a 400 `invalid_dtql`; and posted with a paging header it is a 422 `snapshot_unsupported`

### AC: route-label-follows-routing (verifies REQ:routing)

Journey step 4.

**Given** one unprotected SQLite mount, two mounts, one policy-protected mount and one document with a subquery
**When** a relational document runs against each
**Then** the answers are `database`, `in-memory`, a 422 `authorization_unsupported` that has no label, and `in-memory`, in that order

### AC: engine-outside-join-set-refused (verifies REQ:routing)

Journey step 4.

**Given** a PostgreSQL mount, and a mounted database whose engine is otherwise outside the join set (Firestore, say)
**When** a join over each is posted
**Then** the first returns a 501 `query_unsupported` naming the engine and the second a 422 naming the engine, each with no rows

### AC: lone-source-outside-join-set-by-endpoint (verifies REQ:endpoints, REQ:routing)

Journey step 4.

**Given** a mounted database whose engine is outside the join set but cleared for structured queries (Firestore, say, with a fake or emulated driver), and a non-relational single-source document `from: {database: X, name: C}` over it
**When** the document is posted to `/v1/dtql` and then to `/v1/databases/X/dtql`
**Then** the first returns a 422 naming the engine and no rows (every document on `/v1/dtql` is relational, and the routing table refuses the engine), and the second returns 200 with `{records:[{key,data}]}` exactly as the existing path does

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

### AC: budget-errors-report-limit-only (verifies REQ:limits)

Journey step 5.

**Given** an over-budget query that reads unprotected sources
**When** it is posted
**Then** the error names the limit and not the number of rows observed, and the response has no rows and no `execution`

### AC: profile-refusals (verifies REQ:profile-refusals)

Journey step 6.

**Given** relational documents with a cursor, a `schema`, a `money` value, a parent source, a collection-group source, nine sources, subqueries nested five deep, limit 1001, offset 10,001, a `scan` on a policy-protected source and a `scan` on an unprotected one; a relational document with a join algorithm hint, a relational document with `offset` 10,000, one with limit 1000 and one whose join tree is five levels deep, which the profile accepts; a document with a right join, which DALgo's deserialiser rejects; and one single-collection document with a cursor and another with limit 1001
**When** each is posted to the per-database endpoint
**Then** each refused document returns a 400 `invalid_dtql` naming the refused element (the cursor is refused by the deserialiser, which names `startFrom`) and none reaches a database, the scan on a policy-protected source included; the four accepted documents return 200; the right-join document returns the 400 `invalid_dtql`; and the two single-collection documents return the same 400 `invalid_dtql`

### AC: grant-checked-for-every-source (verifies REQ:grants-before-mounts)

Journey step 6.

**Given** alice's token grants `records:read` on database A only
**When** she posts a join of A and B to `/v1/dtql`
**Then** the response is a 403 naming B, returned even when B is not mounted (403 before 404), and no source is read

### AC: protected-database-refuses-relational-document (verifies REQ:protected-databases-refused)

Journey step 6.

**Given** a mount with access policies, a public database also mounted, and alice, who reads every database and belongs to a role the policy names
**When** she posts a join of the protected mount to the public one and the same join reversed, a COUNT over the protected mount, a nested join whose innermost source is protected, an aggregate over a field the policy hides, and a subquery over the protected mount, each also with a collection the database does not declare or that the policy hides
**Then** each returns the same 422 `authorization_unsupported`, with no rows, no `execution` and no collection name, and nothing is read from the mount; and a single-collection read of the protected mount on the per-database endpoint returns only the rows she may read, with keys

### AC: check-order-decides-the-status (verifies REQ:check-order)

Journey step 6.

**Given** a mount with access policies, a public database, a token granting one collection of the protected mount only, and a database name that is not mounted
**When** requests that fail two checks at once are posted: a join of two collections of the protected mount with the token, a join of the protected mount to the database that is not mounted, a document with a `scan` on the protected mount, a join of the protected mount posted with a paging header, and a join over the protected mount that names a collection it does not declare
**Then** each returns the status of the earlier check of `REQ: check-order`: 403 naming the collection the token does not cover, 404 naming the database that is not mounted, 400 `invalid_dtql` for the scan, and 422 `authorization_unsupported` for the join with the paging header and for the undeclared collection

### AC: per-database-endpoint-refuses-foreign-source (verifies REQ:endpoints)

Journey step 6.

**Given** two databases mounted
**When** a relational document with a source whose `database` is the other database is posted to `/v1/databases/{db}/dtql`
**Then** the response is a 400 naming that source and nothing is read

### AC: subquery-source-authorised (verifies REQ:subquery-sources-authorised)

Journey step 6.

**Given** alice holds a token granting only database `chinook`, and database `countries` is also mounted
**When** she posts a document over `chinook` whose subquery reads `countries`, and another whose subquery reads `chinook`
**Then** the first returns a 403 naming `countries` and the second returns its rows

### AC: collection-scoped-grant-checked (verifies REQ:grants-before-mounts, REQ:subquery-sources-authorised)

Journey step 6.

**Given** a token granting `records:read` on the collection Invoice of `chinook` only
**When** its holder posts to `/v1/databases/chinook/dtql` a join of Invoice to Customer, and another document over Invoice whose EXISTS subquery reads Customer
**Then** each returns a 403 and nothing is read

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

**Given** a join returning fewer than 1000 rows whose encoded size exceeds the result byte limit (8 MiB)
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

**Given** a relational document, and a single-source document on `/v1/dtql`
**When** each is posted with a paging header (`OVDB-Page-Size`, `OVDB-Page-Token` or `OVDB-Page-Close`)
**Then** each response is a 422 `snapshot_unsupported`, and no snapshot is spooled

### AC: consistency-documented (verifies REQ:consistency-statement)

Journey step 2, 3.

**Given** `docs/api.md` in openvaultdb-go after implementation
**When** it is read
**Then** it states the one-transaction guarantee of the `database` route and the no-snapshot behavior of the `in-memory` route

### AC: journey-over-http (verifies REQ:routing, REQ:limits, REQ:protected-databases-refused, REQ:check-order)

Journey step 1 to 7.

**Given** a server with Chinook, a countries database, a protected database and a scoped token
**When** one test walks journey steps 1 to 7 over HTTP
**Then** it asserts mechanism, not only output: the pushdown beyond the in-memory bound, the budget error, and the refusal of every relational shape on the protected database

## After launch: joins over databases with access policies

A relational document that names a database with access policies is refused at launch
(`REQ: protected-databases-refused`), so the criteria below cannot be tested yet. They keep their
original wording, with two changes of identifier for criteria whose first half holds at launch
and appears above under its original name. They state what joins over such databases must do when
they are built.

### AC: policy-applied-per-leaf (verifies REQ:policy-per-leaf)

After launch; no journey step.

**Given** a policy-protected database joined to a public one, alice readable on some of the protected rows, and alice holding a server-wide token, per Open Question 4
**When** alice posts the join
**Then** the result contains only joined rows built from rows she can read

### AC: count-equals-readable-rows (verifies REQ:policy-per-leaf, REQ:row-count-privacy)

After launch; no journey step.

**Given** the same databases and the same server-wide token
**When** alice posts a COUNT over the protected source
**Then** the count equals the number of protected rows she can read

### AC: no-row-count-for-protected-source (verifies REQ:row-count-privacy)

After launch; no journey step.

**Given** the same databases
**When** the join succeeds
**Then** `execution.sources` has no `rows` for the protected source, and no field of the response reports rows scanned

### AC: nested-join-authorised (verifies REQ:policy-per-leaf, REQ:leaf-wrapper)

After launch; no journey step.

**Given** a join tree of depth three whose innermost source is protected and which alice may read only in part
**When** alice posts it
**Then** the innermost source's policy is applied and no row she cannot read influences the result

### AC: hidden-field-not-reachable (verifies REQ:hidden-fields-unreachable)

After launch; no journey step.

**Given** a protected collection with a field redacted for alice
**When** she posts documents using that field as a join key, a group key, an aggregate input, an aliased column, a filter predicate and a sort key
**Then** none exposes the field's values, in `data` or by grouping, filtering or ordering, and each is refused or returns the field absent

### AC: subquery-source-authorised-over-protected (verifies REQ:subquery-sources-authorised)

After launch; no journey step.

**Given** alice holds a token granting only database P, which is policy-protected and readable by her in part, and database B is also mounted
**When** she posts a document over P whose subquery reads B, and another whose subquery reads P
**Then** the first returns a 403 naming B and the second returns only results built from rows she can read

### AC: budget-errors-report-limit-only-over-protected (verifies REQ:limits, REQ:row-count-privacy)

After launch; no journey step.

**Given** an over-budget query that reads a policy-protected source
**When** it is posted
**Then** the error names the limit and not the number of rows observed; and a protected source larger than the source-read limit, of which the caller can read fewer rows than the limit, returns no budget error

## Risk findings recorded as open items

Four findings from reading the code, independent of this Feature. Findings 1 and 2 were not
executed; findings 3 and 4 are closed by the tests named in them.

1. **Spool on Cloud Run.** Cloud Run's filesystem is memory and counts against the instance
   limit, while the snapshot spool allows 512 MiB per snapshot and two slots
   (`pkg/server/dtql_pages.go` in openvaultdb-go) on a 512 MiB instance. Small sample databases
   hide it; a large one will not. Closed by plan tasks OJ-13 and OJ-09.
2. **Nested join authorisation (INFERENCE).** DALgo's access layer builds its resource list from
   the base source and first-level joins only and refuses field rules on joined sources
   (`access/session.go` in dal-go/dalgo). A nested join handed whole to a protected handle may
   skip authorisation of the nested source. The design never does that (`REQ: policy-per-leaf`).
   At launch no relational document reaches a database with access policies
   (`REQ: protected-databases-refused`), and `nested-join-authorised`, under "After launch", tests
   it when joins over such databases are built.
3. **Schema-qualified sources and `scan` on the single-collection path (closed).** DALgo treats a
   schema-qualified source as an opaque resource, so collection policies may not match it, and
   DALgo's access layer has no check on scan orders either (it checks WHERE, GROUP BY, HAVING,
   ORDER BY and columns, not `ScanOrders`, at v0.88.0 or at dalgo origin/main 984e8bb). Closed:
   the single-collection path refuses a `schema` other than the default schema of the engine, a
   `scan` and a `database` other than the endpoint's own with a 400 `invalid_dtql`, and the new
   path refuses `schema` and `scan` on every source (`REQ: endpoints`,
   `REQ: profile-refusals`). It is pinned by `TestSingleCollectionDocumentAndTheDefaultSchemaOverHTTP`
   and `TestTheJourneyOfAJoinOverHTTP` (steps 3 and 6) in openvaultdb-go. The browser demo sends
   `schema` when a relation has one (read from code, not executed), so a relation in a schema
   other than the default one is a 400 there.
4. **Collection-scoped grants and EXISTS subqueries (closed).** A document of one collection can
   read others in a subquery, and a token scoped to one collection could be used to test rows of
   another collection in the same database if only the root collection were checked. Closed: a
   document with a subquery is relational, and the handler checks the capability on every source
   of the document, subqueries included (`REQ: subquery-sources-authorised`). It is pinned by
   `collection-scoped-grant-checked`, which `TestTheJourneyOfAJoinOverHTTP` (step 6) sends with a
   token scoped to Invoice, for a join and for an EXISTS subquery that reads Customer, and gets
   two 403.

## Out of scope for the first version

Window functions; trace headers; boolean coercion in joined rows; joins over databases with
access policies (after launch); all of Part 2 (external sources); CLI delegation. Items that are
open questions rather than settled scope (grants naming several databases, joins over databases
with access policies, exact labelling) are under Open Questions.

## Open Questions

None of the open questions is decided. Questions 1 to 8 are the implementation plan's, in its
order, each with the plan's recommendation. Questions A to D are the author's additions. Questions
7, 8, A and D are answered by the code on main and are closed under "Closed questions" below.
Questions 3 and 5 wait for the founder's own answer; until they are answered this Feature states
the cautious behaviour: for 3, a relational document that names a database with access policies
is refused; for 5, only what OVDB can do without DALgo's exported additions (the route label is
`database` or `in-memory`, and DALgo's bound messages are matched by text).

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
3. Policy-protected databases: the plan reads an earlier founder statement, that aggregation
   runs natively where the server supports it, as extending to joins. At launch a relational
   document that names a database with access policies is refused with a 422
   `authorization_unsupported`, because DALgo's access layer authorises the base and first-level
   join sources of a query and not what is nested deeper. Is that launch limit accepted? For
   after launch the plan recommends an exception: OVDB aggregates over policy-filtered rows
   itself, bounded at 10,000 rows, until dalgo issue 148 (hidden field behind an alias) is closed
   and nested joins are authorised. Recommendation: accept the launch limit and build the
   exception after launch. (`REQ: protected-databases-refused`, `REQ: routing`,
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

Author's additions (not from the plan):

B. Are the limits right for a 512 MiB instance (1000 rows, 10 s, 2 concurrent in-memory queries,
   1 on OVDB Cloud)? Recommendation: ship these defaults, configurable, and adjust after OJ-08
   records heap at the bounds; the plan measured nothing.
C. Does Cloud Run's default concurrency apply to OVDB Cloud? Recommendation: assume yes (the
   deploy sets no concurrency flag) and let the capacity gate, not Cloud Run, bound memory.

Cut order if the window slips (a plan note, not a question): OJ-11, OJ-10, OJ-12, then subqueries.

### Closed questions

These were open questions of this Feature. The code on main answers each, and the test that pins
the answer is named. The tests are in openvaultdb/openvaultdb-go, `pkg/server` unless a package is
named.

7. Engines in joins at launch. Closed: the join set is SQLite and local inGitDB. The operator's
   list can add an engine that the structured-query guard clears (Firestore, say); PostgreSQL,
   MySQL and an unknown engine are a 501 `query_unsupported` even when listed (PostgreSQL joins
   after OV-01); a GitHub-backed inGitDB mount is never joined; a database on an engine outside
   the list is a 422 `join_engine_unsupported`. Pinned by
   `TestRelationalHandlerRefusesEnginesTheGuardOrTheListLeavesOut` and
   `TestJoinEnginesOmitsTheGitHubEngineWhateverTheListSays`.
8. Paging of joined results. Closed: joined results are returned whole, at most 1000 rows, and a
   paging header on the new path is a 422 `snapshot_unsupported`. Pinned by
   `TestRelationalDTQLOverHTTPAcceptance` (the paging headers are refused on a relational
   document) and by `TestTheJourneyOfAJoinOverHTTP` (steps 3 and 5).
A. The status and code of relational-profile refusals. Closed: a 400 `invalid_dtql` that names the
   refused element, the same on both endpoints and on both paths; a relational document whose
   source carries a `database` other than the endpoint's is a 400 `invalid_dtql` that points to
   `POST /v1/dtql`; the paging headers are a 422 `snapshot_unsupported`. Pinned by
   `TestTheJourneyOfAJoinOverHTTP` (steps 2, 3 and 6) and
   `TestClassifierRefusalsOfADocumentTheSingleCollectionValidatorAcceptsAreClientErrors`.
D. A lone source that names a `database`, a `schema` or a `scan`. Closed: on the per-database
   endpoint a root that names the endpoint's own database is read as one that names none, with
   the same body and keys; a root that names another database, a `schema` other than the engine's
   default and a `scan` are a 400 `invalid_dtql`; on `/v1/dtql` every source names its database,
   a one-source document is relational with no keys, and no `schema` is accepted (`REQ: endpoints`).
   A client that sends such a document gets the 400. This was set in review and reported to the
   founder, who has not answered it. Pinned by
   `TestRelationalDTQLOverHTTPAcceptance` (a one-source document that names its own database),
   `TestSingleCollectionDocumentAndTheDefaultSchemaOverHTTP` and
   `TestTheJourneyOfAJoinOverHTTP` (step 2).

---
*This document follows the https://specscore.md/feature-specification*
