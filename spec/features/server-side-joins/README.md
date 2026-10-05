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
cannot read. On a database with access policies the answer is the one the same question gives on
a copy of the database that holds only the rows and fields the caller may read, and the policies
are compiled into the SQL statement, so that the database filters and aggregates. The first shape
it runs is a document of one collection that groups or aggregates, on SQLite; joins, subqueries
and documents over several databases are refused with a fixed 422 until they are built
(`REQ: protected-database-queries` states shape by shape what runs and what is refused). Part 1
covers sources registered on one server. External sources are Part 2 and are out of scope here.

## Problem

OVDB's single-collection DTQL profile is one unaliased root collection: joins, GROUP BY, HAVING,
cursors and aliases are outside it (`pkg/core/query.go` in openvaultdb/openvaultdb-go). Without the
relational profile of this Feature, a caller who wants "invoices joined to customers,
grouped by country" must pull each collection and join it client-side. The browser demo does
exactly that, in pages of up to 500 rows into IndexedDB, which costs round trips, hits the
browser engine's 10,000-row bound and burdens phones. (The paging and row-bound figures for the browser demo come from reading DataTug's
web app and were not executed.)

### Origin and authority

The founder's words (2026-10-04; these are the only verbatim founder statements in this Feature; Closed question 3 paraphrases a third, about aggregation, and the owner's decisions of 2026-10-05 are paraphrased and not quoted). The first is a stated vision and desire, not a ruling; the second is a request
with "maybe" twice, not a ruling:

> "OVDB get DTQL query and pass it to DALgo that can join. So OVDB can join recordset from
> multiple sources as long as they are registered on that OVDB server. At least that's my vision
> and desire."

> "We should fix OVDB to allow joins. And maybe even external data sources (if allowed by OVDB
> server config). Maybe with support of both whitelisted and blacklisted external sources"

The owner's decisions of 2026-10-05, paraphrased and not quoted. Asked whether relational queries
on a database with access policies may stay refused, the owner decided that they must be built,
and not left refused. Asked how, he decided that they run natively: row rules and field lists are
compiled into the SQL statement, so that the database filters and aggregates, with no row cap
where the engine runs the whole document. `REQ: protected-database-queries` states what runs
under that decision, shape by shape. The shape-by-shape rules of that requirement come from a
design of 2026-10-05 that an independent reviewer read; it is not in the original plan, and the
owner has not ruled on its details. It describes what the
server is to run: openvaultdb-go v0.13.0 still refuses every relational document on a database with
access policies, and the server work that makes the criteria of this requirement pass has not
landed.

Everything else below, including every limit, route, error code and the profile's contents, is
the design of the OJ implementation plan (written from code reading on 2026-10-04; nothing in
it was executed). It is proposed for review, not ruled. Items are marked **PLAN DESIGN**. Parts
of them were added in review and are not in the plan: the rule that every document on `/v1/dtql`
is handled as relational, the default refusal and the offset, scan and parse-failure rules of
`REQ: profile-refusals`, name validation in `REQ: values-and-names-never-text` (the plan covers
parameter binding only), counting row and byte budgets after the policy filter, the 503
`query_capacity` code on the database route gate, collection-scoped grants, the rule that a
subquery-only document and a root that names a database are relational on the
per-database endpoint while the endpoint's own database is dropped from the root, the strict
field-name rule on relational documents, the limit of the profile to five aggregate functions
and the refusal of `first` and `last` (the plan accepts every aggregate DALgo has), the parts of
`REQ: discovery` beyond the block and the two capabilities (the five aggregate names,
`protectedDatabases`, `fieldNames`, the keys of `limits`, the rule for `joinEngines` and the
reading of the metadata 422), and two whole requirements, `REQ: check-order` and
`REQ: field-resolution` (the plan has no order of checks, no ambiguous-field rule and no wildcard
rule). Those two are marked **Added in review; not in the plan**.
`REQ: protected-database-queries` replaces the requirement that refused every relational document
on a database with access policies, which was decided in review because the plan designed the
opposite for a protected mount (in-memory over its secured handle); it is marked
**Decided on 2026-10-05; not in the plan**. Two of the groups above are decisions taken in review
and reported to the founder, who has not answered them: the rule that a subquery-only document
and a root that names a database are relational on the per-database endpoint, and the strict
field-name rule (both Open Question D). The
first quotation covers Part 1; the second covers external sources, which are Part 2 and not in
this Feature's scope. This Feature was last revised on 2026-10-05 against openvaultdb-go main at
34eac4b, which holds the relational path, the discovery of the query profile, the field lists that
mounts supply to the join engine and the protected routes (pull requests 48, 51, 52, 53, 54 and
56); where the code fixes a rule, this Feature states it as the behaviour. "Main" below means
openvaultdb-go main at 34eac4b. The request and response shapes, the status table and the worked
examples of relational documents are owned by `docs/api.md` of openvaultdb-go, section "Query
profile and relational documents"; this Feature keeps the requirements and the acceptance
criteria and points there for the rest.

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
| 1 | I fetch `/.well-known/openvaultdb`. | A `query` block, in either authentication mode, lists the endpoint, joins, GROUP BY, five aggregate functions, cross-database support, the limits as data and the join engines; each database's `capabilities` says whether it takes part in joins and aggregation, and a new key says what runs on databases with access policies. | `discovery-advertises-query`, `discovery-limits-are-the-enforced-bounds`, `capabilities-per-database`, `protected-databases-flag-is-a-false-boolean`, `protected-database-queries-discovered` |
| 2 | I post one DTQL document joining Chinook Invoice to Customer and grouping by country to `/v1/databases/chinook/dtql`. | One response, ordered columns, at most 1000 rows, `execution.route: database`; with an ORDER BY and more than 10,000 joined rows it still succeeds, which a streaming in-memory plan cannot serve, and the same data split across two mounts is a 422 `query_budget_exceeded`. The same join on a mount with access policies is a 422 `authorization_unsupported`. | `single-database-join-pushdown`, `relational-profile-accepted`, `subquery-only-document-is-relational`, `response-shape`, `result-row-cap`, `result-byte-limit`, `consistency-documented`, `single-source-with-database-unchanged`, `default-schema-dropped`, `parameters-and-names-cannot-change-query`, `ambiguous-field-refused`, `field-without-list-refused`, `aggregate-reads-first-source`, `wildcard-expands-in-field-order` |
| 3 | I post a document joining `chinook.Customer` to a countries database on the same server to `/v1/dtql`. | Joined rows; `execution.sources` lists both sources with rows and milliseconds. | `cross-database-join`, `cross-database-endpoint-single-source`, `default-schema-dropped`, `response-shape`, `mount-lease-drains-on-unmount`, `consistency-documented` |
| 4 | (nothing) The server decides where the work runs. | The route label says `database` or `in-memory`; a 501 `query_unsupported` or a 422 names an engine that cannot join; a lone-source read of such an engine is refused on `/v1/dtql` and served on the per-database endpoint; a document of one collection that groups or aggregates on a SQLite database with access policies is labelled `database`, and any other relational document that names a database with access policies has no label and is a 422 `authorization_unsupported`. | `route-label-follows-routing`, `ingitdb-route-label`, `engine-outside-join-set-refused`, `lone-source-outside-join-set-by-endpoint` |
| 5 | My query is too big or too slow. | 422 `query_budget_exceeded` naming the limit and a hint; never partial rows. | `budget-exceeded-is-422-never-partial`, `timeout-is-504`, `budget-errors-report-limit-only`, `paging-headers-refused` |
| 6 | As alice, with a token for one database, I join it to another; as alice on a policy-protected database I count, group and aggregate one collection, and I join it to a public one. | 403 naming the other database; on the protected database a COUNT or an aggregate over one collection returns only her own figures, run by the database, while a field she may not read, and a collection she may not read or that the database does not declare, are the same 403 `ACCESS_DENIED`; every join, nested join, subquery and document over two databases is the same 422 `authorization_unsupported` with no rows and no `execution`; refused profile elements are a 400 `invalid_dtql`. | `grant-checked-for-every-source`, `protected-database-refuses-relational-document`, `protected-aggregate-runs-in-the-database`, `count-equals-readable-rows`, `aggregate-equals-permitted-copy`, `hidden-field-not-reachable`, `unknown-and-denied-collection-are-indistinguishable`, `no-row-count-for-protected-source`, `profile-refusals`, `first-and-last-refused`, `check-order-decides-the-status`, `per-database-endpoint-refuses-foreign-source`, `subquery-source-authorised`, `collection-scoped-grant-checked` |
| 7 | (nothing) Two hundred visitors click the same demo question. | Identical GETs come from cache; excess in-memory queries get 503 with `Retry-After`; the instance stays up. | `identical-gets-cacheable`, `capacity-gate-503`, `database-route-capacity-gate` |
| 8 | As operator I deploy OVDB Cloud. | The deploy smoke join passes. | `deploy-smoke-join` |
| 9 | I run the demo question in the browser. | One query request; on a server without joins, the same answer by the browser path. | `demo-uses-server-join-when-advertised`, `demo-falls-back-on-failure` |

Whole-journey test: a single HTTP test walks steps 1 to 7 and asserts mechanism, not only output
(pushdown proved by the in-memory control, the budget error, the refusal of every shape that a
database with access policies does not run, and the figures of the one it does): `journey-over-http`. Plan
task OJ-08 must cite every id of the steps it walks; the other OJ tasks cite the ids of the steps
they implement. The criteria of databases with access policies that cannot be tested yet are
under "Later: joins, subqueries and several databases with access policies" and belong to no
step.

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

**Added in review; not in the plan.** A request MUST be answered by the first of these checks that fails, so that a
caller can predict the status of any request from this Feature alone:

1. Authentication (401), and on the per-database endpoint a database `{db}` that is mounted (404).
2. The request is a document: a URL over 8 KiB (414), an empty body, a URL parameter other than
   `q` and `parameters`, or a `param` that the `parameters` object of a JSON body or of a GET does
   not bind (400 `bad_request` or `invalid_dtql`); then a document that parses and that the
   profile accepts, so that every refusal of `REQ: profile-refusals`, every alias or qualifier that is not an identifier and every name that
   the wider quoted-name rule of `REQ: values-and-names-never-text` refuses is a 400
   `invalid_dtql`, or `invalid_key` for a collection name. That includes a field or a wildcard with
   no source in a join that holds no subquery, which the DTQL parser refuses (`REQ: field-resolution`).
3. Every source has a database: a source with none on `/v1/dtql`, or a database other than `{db}`
   on the per-database endpoint (400 `invalid_dtql`).
4. The caller's grant covers every database and collection a source names, at any depth (403
   `forbidden`, naming the first it does not cover, whether or not that database is mounted).
5. Every database a source names is mounted (404 `not_found`).
6. No database a source names has access policies when the document is of a shape that such a
   database does not run (422 `authorization_unsupported`, `REQ: protected-database-queries`). The
   shape decides, and neither the collections the document names nor the policy do.
7. Every collection a source names is one that its database declares, under its canonical name,
   where the engine builds SQL (404 `not_found`); for a database with access policies, a
   collection that it does not declare, or that is spelled otherwise than its canonical name, is
   answered exactly as a collection that the policy denies (403 `ACCESS_DENIED`, the same status,
   headers and body; `REQ: protected-database-queries`).
8. No paging header is present (422 `snapshot_unsupported`).
9. Every database is on an engine that can be queried (501 `query_unsupported`), and then on one
   in the join set (422 `join_engine_unsupported`).
10. The executor's own check of the document, before it asks for a slot: a field name that the
    wider rule accepts and the strict one of a relational document refuses, one output name on
    two columns, a `param` in a YAML body, which binds none (400 `invalid_dtql`). A database with
    access policies refuses a document of a shape it does not run at check 6 first, with the 422;
    the same `param` in a JSON body or a GET that does not bind it is check 2.
11. A free slot on the route, after the queue wait of the server's settings (503
    `query_capacity`); then, before a row is read, the field-list refusals of `REQ: field-resolution`
    (400 `invalid_dtql`); then, while the query runs, the bounds of
    `REQ: limits` (422 `query_budget_exceeded`), the time limit (504 `query_timeout`) and a shape
    that DALgo or the database refuses (400 `invalid_dtql`). On a database with access policies the
    access layer refuses a field that the caller's policy hides (403 `ACCESS_DENIED`) when the read
    starts, before any statement is sent.

Checks 3 to 11 apply to a document on the new path. None of them applies as written to a
single-collection document. It passes checks 1 and 2 and the grant on its one collection (403
`forbidden`), and is then read by the single-collection path, which has its own rules for field
names (`REQ: values-and-names-never-text`) and for bounds (`REQ: limits`): a database with access
policies is read through its policy, and the paging headers page the result. The answer for a
collection that the database does not declare, on that path, is not changed by this Feature and is
not specified here, except for a database with access policies, where it is the 403 of check 7.

#### REQ: values-and-names-never-text

**PLAN DESIGN** for parameter binding; the rest was added in review. On both routes, parameter
values MUST be bound as values and never spliced into text. Names are refused unless plain, with a
400 `invalid_dtql` (`invalid_key` for a collection name), and what passes MUST still reach a database only as a quoted identifier. A
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
collection name follows the existing collection-name rule, and a collection name that breaks it
is a 400 `invalid_key`. These rules are defined in code
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
HAVING, the aggregate functions `count`, `sum`, `avg`, `min` and `max` (in any letter case),
column aliases, subqueries, join algorithm hints, and source aliases, plus everything the existing
single-collection profile accepts (field columns,
WHERE, ORDER BY, a LIMIT up to 1000, parameters) and an `offset` up to 10,000. Subqueries always
run in memory. Engines in a join are limited at launch (`REQ: routing`). The plan accepts every
aggregate DALgo has; the limit to five functions is a launch limit added in review and not in the
plan. `first` and `last`, which DALgo also provides, are not in the profile: they need a stable row
order, which no engine the server runs declares, and they return after launch together with an
ordering for aggregates (`REQ: profile-refusals`). A join tree may nest to
any depth within the bound of 8 sources (`REQ: profile-refusals`); its depth is not bounded
separately. Window functions do not exist in DTQL; discovery MUST carry `windowFunctions: false` as
the seam. (Hints and the offset bound follow openvaultdb-go pull request 38, which accepts hints
and bounds `offset`; a hint only chooses among join algorithms DALgo bounds itself.)

#### REQ: field-resolution

**Added in review; not in the plan.** A source supplies a **field list** to the join engine: the
names of the fields a record of it can hold. A SQLite mount supplies the columns of the table in
the table's order, the key column `id` included, whatever its schema declares. A strict database on
an engine whose driver supplies no columns (local inGitDB at launch, Firestore when the operator
lists it) supplies the fields its schema declares, sorted by name, when it declares at least one
and none of them has the type object or any; a record's key is not a field there. On those
engines, a partial or schemaless database and a collection that declares no field or one of the
type object or any supply none. So does a database with access policies (a document of more than
one source does not reach one yet), and so does a subquery used as a source.

The rules below apply to a query of more than one source. The outermost query, a derived source, a
scalar subquery and an EXISTS test are each a query with the sources of their own; a query of one
source is not looked at, and a field qualified with its source is read as written, declared or
not.

- An unqualified field that two sources of the query carry MUST be refused with a 400
  `invalid_dtql` that names the field, and never bound to the first source. A field that only one
  source carries is bound to that source, except where the third rule below says otherwise. The key
  column is a column of every SQLite table, so an unqualified `id` over two SQLite tables is
  ambiguous.
- When any source of the query supplies no field list, an unqualified field of the query MUST be
  refused with a 400 `invalid_dtql` that tells the caller to qualify it with its source, because
  the engine cannot tell which source carries it. This is not an ambiguity and does not say so.
- In a query that aggregates (GROUP BY, HAVING or an aggregate function), a bare name in GROUP BY,
  HAVING, ORDER BY, the columns or the argument of an aggregate MUST be a field of the first
  source; a name that only another source carries is refused with a 400 `invalid_dtql` that tells
  the caller to qualify it, and is never read from the first source. HAVING and ORDER BY of such a
  query read the alias of a column of the select list as that column. WHERE and ON read a name from
  the source that carries it.
- A wildcard of a source (`source.*`, with or without `exclude`) MUST expand to the fields of that
  source's field list, on the database route and on the in-memory route alike. A SQLite source
  therefore returns its key column and a strict inGitDB source does not. In `columns` a wildcard
  stands, at its position, for the names the rows of the answer carry that no other column of the
  select list names and that it does not exclude, sorted by name; an answer with no rows lists no
  name for it. A wildcard of a source that supplies no field list is not specified here. A
  wildcard that names no source, and a document of several sources that has no column list, are
  not specified here.

A document that has a join and no subquery never reaches these rules with an unqualified field: the
DTQL parser refuses a field or a wildcard that carries no source in such a document, with a 400
`invalid_dtql`, before a field list is asked for. The rules decide a query that has a join and holds
a subquery, in a clause or as a source; such a query runs in memory (`REQ: routing`). The parser's
rule applies to each query of the document on its own.

#### REQ: profile-refusals

**PLAN DESIGN** for the list; the default refusal, the aggregate-function rule and the last three
rules were added in review. In this first version a relational document MUST be refused, with a
400 `invalid_dtql` that names
the refused element, before any read: cursors (a DTQL document has no key for a cursor, so the
deserialiser's 400 names `startFrom`), `schema`, `money`, parent and collection-group sources,
more than 8 sources, subqueries nested deeper than 4, a limit above 1000 or an `offset` above
10,000 on the outermost query, an aggregate function outside the five that the profile accepts
(`first` and `last` included, in any letter case and in any position of the document, on every
route), and `scan` on any source (protected or not; this follows pull request 38, and the reason
is below). The depth of a join tree is not bounded separately. Any
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

**PLAN DESIGN** for the block and the two capabilities; the five aggregate names,
`protectedDatabases`, `fieldNames`, the keys of `limits`, the rule for `joinEngines` and the
reading of the metadata 422 were added in review; the key `protectedDatabaseQueries` and the
computing of the two capabilities apart were decided on 2026-10-05 and are not in the plan.
`/.well-known/openvaultdb` MUST carry a `query` block in both authentication
modes, and each database's `capabilities` MUST carry `joins` and `aggregation`. The protocol
string MUST NOT change. Every value is read from the code that enforces it, so that a client that
follows discovery is not refused for what discovery said. The shape of both documents, with
examples, is owned by `docs/api.md` of openvaultdb-go (section "Query profile and relational
documents", subsection "Discovery"); this requirement states what a client may rely on.

- The `query` block holds the endpoint that reads several databases (`/v1/dtql`), the document
  format, `features`, `limits` and `joinEngines`. It holds nothing that belongs to one database, so
  it is the same in both modes. With authentication off the document also lists the databases;
  with it on no database is listed, and a caller whose token grants `collections:read` on a
  database reads its `capabilities` from its metadata (`GET /v1/databases/{db}`); a token without
  that capability gets a 403 `forbidden` there, whatever the database.
- `features` names five aggregate functions, `count`, `sum`, `avg`, `min` and `max`, and states
  `windowFunctions: false`, `externalSources: false`, `protectedDatabases: false` and
  `fieldNames: plain`, beside the join types (`inner` and `left`), grouping, HAVING, subqueries and
  cross-database support. `first` and `last` are not named: they are refused on every route
  (`REQ: profile-refusals`).
- `features.protectedDatabases` keeps its type, a JSON boolean, and its value, `false`, until no
  relational shape of the profile is refused on a database with access policies for its shape
  alone. A boolean cannot say "partly", and `false` promises nothing the server does not do. What
  does run on such databases is stated by a key added beside it, `features.protectedDatabaseQueries`,
  an object that holds `engines`, the engines on which a database with access policies runs
  relational documents (`["sqlite"]` at first), and one boolean each for `aggregation` (a
  document of one collection that groups or aggregates), `joins` (a join inside one database),
  `subqueries` (a subquery, a derived source or EXISTS) and `crossDatabase` (a document over
  several databases, one of which has access policies). Each value is read from the rule that
  decides the request, so that it is true exactly when a document of that shape is run; the first
  of them, `aggregation`, is `true` and the other three are `false` while only a document of one
  collection runs.
  The key names no database, so it is the same with authentication on and off. It is added and
  never changed in type, and a client that does not know it ignores it.
- `limits` states, as data, what one document may ask for: twelve keys, each the value the server
  enforces, and none of the capacity of the server (no concurrency slots and no queue wait). Three
  values come from the server's settings: `timeoutMs`, `maxSourceRows` and `maxSourceBytes`. Nine
  are fixed bounds: `maxResultRows` and `maxResultBytes` of the answer; `maxSources`,
  `maxSubqueryDepth`, `maxLimit` and `maxOffset` of the profile (`REQ: profile-refusals`); and
  `maxInMemoryJoinRows`, `maxInMemoryJoinBytes` and `maxGroups` of DALgo's in-memory engine
  (`REQ: limits`).
- `joinEngines` lists only the engines whose databases can take part in a relational document: the
  engines of the operator's list that the structured-query guard clears, without the GitHub-backed
  inGitDB engine, which no list enables (`REQ: routing`).
- A database's `joins` and `aggregation` are computed apart, each from the rule that decides a
  request of its own shape: `aggregation` is true exactly when a document of one source that
  groups or aggregates and names the database is not refused for the database itself, and
  `joins` exactly when a join of its collections is not. For a database without access policies
  both are true when its engine is in `joinEngines`, as before. For a SQLite database with access
  policies `aggregation` is `true` and `joins` is `false`; for a local inGitDB database with
  access policies both are `false`.
- A database with access policies is not described by its metadata: the metadata route answers
  422 `authorization_unsupported`, after the 403 for a token without `collections:read`. With
  authentication off the discovery list gives its `joins` and `aggregation` as above. With
  authentication on there is no list, and that 422 says only that the metadata of such a database
  is not served: what such databases run is stated by `features.protectedDatabaseQueries`, and by
  the 422 that a document of a shape they do not run gets (`REQ: protected-database-queries`).

### Routing

#### REQ: routing

**PLAN DESIGN.** The server MUST choose the route by this table and label the response with it.

| Condition | Route | Who computes |
|---|---|---|
| One mount, SQLite (PostgreSQL after OV-01), no access policies, no subquery and no null test | `database` | The database, inside one read transaction. When the database cannot compile a join that has no aggregation, nothing has been read yet and the document is read again on the in-memory route, whose label the response then carries |
| Several mounts, none with access policies | `in-memory` | DALgo over leaf reads; a flat equality join without ORDER BY streams |
| One mount without access policies that holds a subquery or a null test, or one inGitDB mount | `in-memory` | DALgo over leaf reads |
| One mount, SQLite, with access policies, and a document of one source that groups or aggregates, with no subquery, derived source or EXISTS and no scan clause; a null test does not change the route | `database` | The database, inside one read transaction under one policy snapshot, with the caller's row rules in the statement and the field lists checked before it (`REQ: protected-database-queries`). A refusal on this route is never followed by a read in memory |
| Any other document that names a mount with access policies (a join, a subquery, a derived source, several databases, or a protected inGitDB mount) | refused, 422 `authorization_unsupported`, no route label | Nothing runs: the refusal comes before any collection name is looked up (`REQ: protected-database-queries`) |
| PostgreSQL or MySQL mount | refused, 501 `query_unsupported` naming the engine | The guard on main (openvaultdb-go pull request 40, merged): every structured query on those mounts is refused until OV-01 |
| Any other engine outside the join set | refused, 422 `join_engine_unsupported` naming the engine | The operator's list of join engines, SQLite and local inGitDB by default; a GitHub-backed inGitDB mount is never joined |

The design follows the first quotation (OVDB passes the document to DALgo, which joins) and runs
a query inside one unprotected SQLite mount in SQLite; that extension to joins is the plan's
reading, not a founder statement. On a policy-protected mount the owner's decision of 2026-10-05
applies (`REQ: protected-database-queries`): what runs there is the first of the two rows for
such a mount, and the rest is refused until it is built.
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

**PLAN DESIGN.** A successful response MUST carry `records` (each row as `data`), `columns` in the
order the document selects them, and `execution` with the route, the elapsed time, the number of
rows returned and, for each source, its database and collection; on the `in-memory` route each
source also carries `rows` and `elapsedMs`, and on the `database` route the database reports no
more. When a source has access policies, the block carries no row count and no elapsed time for it,
and no elapsed time for the request (`REQ: protected-database-queries`). `docs/api.md` of
openvaultdb-go owns the shape, with examples.
Every response on the new path, including one over a single source and every successful response
from `/v1/dtql`, has `columns` and `execution` and no `key`. A non-relational response on the
per-database endpoint keeps exactly `{"records":[{"key","data"}]}`: `columns` and `execution` are
never added to it. A relational row is not passed through the schema coercion of the
single-collection path: a declared boolean of a SQLite mount is 0 or 1 in a relational row and
`true` or `false` in a single-collection record (pinned on the database route by
`TestDocumentedBooleanOfARelationalRowIsNotCoerced` in openvaultdb-go; the in-memory route is not
pinned, and a test over a declared boolean there is a follow-up). This difference is accepted for the first version.

### Limits

#### REQ: limits

**PLAN DESIGN.** Defaults, sized for a 512 MiB instance (Open Questions 6 and B). The time limit,
the source-read bounds, the two concurrency limits and the queue wait are settings of the server,
so that a test can set them small; the request body, the result and the DALgo bounds are fixed.
The last column is the key of `query.limits` in discovery that states the value (`REQ: discovery`):

| Limit | Default | Told to the caller as | Key of `query.limits` |
|---|---|---|---|
| Request body | 1 MiB (existing) | 400 | none |
| Result | 1000 rows, 8 MiB | 422 `query_budget_exceeded` | `maxResultRows`, `maxResultBytes` |
| Time | 10 s | 504 `query_timeout` | `timeoutMs` |
| Source reads per request | 100,000 rows, 64 MiB (streamed) | 422 with limit name and hint | `maxSourceRows`, `maxSourceBytes` |
| DALgo join | 10,000 rows, 16 MiB | 422, path of the join node | `maxInMemoryJoinRows`, `maxInMemoryJoinBytes` |
| DALgo aggregation | 100,000 groups, 64 MiB | 422 | `maxGroups` |
| Concurrent in-memory queries | 2 (1 on OVDB Cloud at 512 MiB) | 503 `query_capacity`, `Retry-After` | none |
| Concurrent database-route queries | 4 | 503 `query_capacity`, `Retry-After` | none |
| Queue wait for a slot | 1 s | the 503 above, after the wait | none |

A query that finds its route full waits up to the queue wait for a slot and is refused with the
503 only after it. The concurrency limits and the queue wait are capacity, which discovery does
not state. The profile's own bounds (`maxSources`, `maxSubqueryDepth`, `maxLimit` and `maxOffset`
of `query.limits`) are those of `REQ: profile-refusals`.

Budget errors MUST report the limit, never the observed figure. A query MUST never return
partial rows. Joined results are returned whole: the paging headers on a document on the new path
(a relational document, or any document on `/v1/dtql`) MUST return a 422 `snapshot_unsupported`,
and no snapshot is taken.

These limits and settings bind the new path. A single-collection document is not gated or timed
by them; it keeps the bounds of the single-collection path: without the paging headers at most
1000 records, 8 MiB and a fixed 10 s, and with them the bounds of the snapshot paging protocol,
which this Feature does not change.

### Access control

#### REQ: grants-before-mounts

**PLAN DESIGN.** For every source of a document on the new path the server MUST check
`Allows(database, records:read, collection)`, with the collection the source names, before any
mount is resolved (403 before 404), and again at each leaf. On the `database` route the
leaf wrapper is not involved, so this check is the only grant check there. A 403 for a
cross-database document MUST name the database that is not allowed. Grants naming several databases: Open Question 4.

#### REQ: protected-database-queries

**Decided on 2026-10-05; not in the plan.** It replaces the requirement that refused every
relational document on a database with access policies (Closed question 3). It states the rule for
every shape, what the server runs of it now, and what it refuses.

**The rule.** On a database with access policies a caller may ask the same questions as on any
other database: join, group, count, sum, average, minimum, maximum. The answer MUST equal the
answer that the same question gives on a **permitted copy** of the database, a copy that holds, for
this caller, only the rows the caller may read and only the fields the caller may read. A count
counts the caller's rows and no others. A question that names a field the caller may not read MUST
be refused whole, wherever the field stands: selected, filtered on, grouped by, sorted by, joined
on, aggregated, tested for empty, or hidden behind another name. The caller gets the whole answer
or a refusal, never a part of one, and a shape for which the server cannot keep this rule MUST be
refused.

**Bounds.** When every collection of a document is in one database whose engine can run the whole
document, the database does the filtering and the arithmetic itself, and no row cap applies to
what it reads. A document that spans several databases, or that the engine cannot run whole, is
answered by the server from the rows the caller may read of each collection; that way is bounded:
a join may hold at most 10,000 rows and 16 MiB, counted on the caller's own rows only. An answer
holds at most 1000 rows and 8 MiB either way. Only the first way is served so far: every document
that runs on a database with access policies runs on the `database` route.

**What runs.** A document runs on a database with access policies when all of this holds: it has
exactly one source, and that source is a collection of that database; it has no subquery, derived
source or EXISTS test and no `scan` clause; and the engine of the database is SQLite. It may
group, aggregate with the five functions of `REQ: relational-profile`, alias columns, filter,
test for null, order and limit, and it is accepted on both endpoints. Every other document that
names a database with access policies is refused as the table below says. A document of one plain
collection with no such feature is read by the single-collection path, through the mount's
policy, as before.

**How the policy is applied.** A document that runs is executed by the database, as one statement
in one read transaction under one snapshot of the policy:

- A row rule is added to the statement, joined with AND to the caller's own condition, which is
  kept as one group, so that the database drops the rows the caller may not read before it groups.
  Every aggregate sees only rows the caller may read, and `COUNT(*)` counts the rows that survive
  the rule. The aggregate and the GROUP BY are in the statement; the server does not compute them.
- A field list is checked before the statement is built, and nothing is redacted from rows after
  the read. Every column's expression, WHERE, GROUP BY, HAVING, ORDER BY, every operand of an
  aggregate and the operand of every null test is checked against the list. A hidden field is a 403
  `ACCESS_DENIED` with the fixed text "access denied", and nothing is read. An alias names an
  output and is never a permission: the check is on the expression behind it, so a hidden field
  selected under an allowed alias is refused, and so is a selection of which every column is
  refused. HAVING and ORDER BY may use an alias only for an aggregate over allowed fields.
- Every value of a rule (the caller's id, roles and groups) reaches the database as a bound
  value and never inside the statement text. A parameter of a rule that has no value denies the
  request. Names (collection, field, alias) are written as quoted identifiers after the name rules
  of `REQ: values-and-names-never-text`. The text of the statement depends on a value only by
  whether it is nil, by the length of a list and by its type: two callers whose values have the
  same types and lengths get byte-identical text.
- A relational answer carries no record key. The key column of the table appears in `data` only
  if the caller selected it and may read it.
- A database that is busy when the read transaction starts is answered with a retryable 503 and
  never with a denial or a 404.
- A refusal on this route is never followed by a read in memory, whatever code it carries.
- An answer that read a database with access policies is `Cache-Control: no-store`.
- The `execution` block of such an answer carries the route, `rowsReturned` and, for each source,
  its database and collection. It carries no row count for a source with access policies and no
  elapsed time, neither the request's nor a source's. The time that a request takes still grows
  with the rows the database scans, as in every system that filters rows, and the time limit and
  the request limits of the server bound it; the server's own stopwatch is left out of the block so
  that it is not a second signal.
- An error or a bound MUST NOT depend on rows the caller may not read: a table whose hidden rows
  hold hostile values (text in a numeric column, huge numbers, blobs) and outnumber every bound
  answers exactly as the same table without them.

**Unknown and denied collections.** For a database with access policies, a collection that the
database does not declare, or that is spelled otherwise than its canonical name, MUST be answered
exactly as a collection that the policy denies: the same status, headers and body, on both
endpoints and for every shape that runs, at the handler's own check and for any not-found error
that comes back from the executor. The database does not say which collections it declares.

**What is refused.** A refusal decided by the shape of the document and the engine of the
database never depends on a collection name or on the content of a policy: it is the same for
every caller and every collection, declared or not, readable or not, and it comes before any
collection name is looked up and before anything is read.

| Document on a database with access policies | Status and code | Message | Until |
|---|---|---|---|
| Names a field the caller may not read, in any clause, under any alias | 403 `ACCESS_DENIED` | "access denied" | Always |
| Names a collection the caller may not read, or one the database does not declare | 403 `ACCESS_DENIED`, the same body for both | "access denied" | Always |
| Any join | 422 `authorization_unsupported` | Names the database and says which kinds of document it runs; never a collection | Joins on such databases are built |
| A subquery, a derived source or an EXISTS test | 422 `authorization_unsupported` | Names the database | The in-memory route reads such sources |
| A document that reads several databases, one of them with access policies | 422 `authorization_unsupported` | Names the database | The in-memory route reads such sources |
| Any relational document on a protected local inGitDB mount | 422 `authorization_unsupported` | Names the database | The in-memory route reads such sources |
| A `scan` clause, or any other element that `REQ: profile-refusals` refuses | 400 `invalid_dtql` | As on a database without policies | Stays |
| A document that runs, sent with a paging header | 422 `snapshot_unsupported` | As on a database without policies | Stays |
| `first` and `last`, `money`, a cursor | As on a database without policies | As on a database without policies | Not part of this requirement |
| A relational document sent to the authorisation API (plan, inspect, sample) | 400, as today | As today | Not specified here |
| A PostgreSQL mount, or a GitHub-backed inGitDB mount, with access policies | The mount is refused when it opens | As today | Not planned here |

A 400 for a profile element is decided when the document is parsed (`REQ: check-order`, check 2),
before the policy is asked, and is the same on a database with and without policies. The rules
that only a join needs (where the row rule of a source goes, arithmetic in a join condition, a
wildcard over a join) are stated by the revision that serves joins; until then every join is the
422 above.

#### REQ: policy-per-leaf

**PLAN DESIGN, not yet built.** Leaf reads MUST use the mount's secured handle with the request
principal; joins and aggregates MUST happen above it. A nested join MUST never be handed whole to
a protected handle (risk finding 2 below). Engines that cannot enforce policy cannot have policies
(the mount refuses the configuration), so grants alone govern them; they are outside the join set
at launch. No relational document that needs leaf reads reads a database with access policies yet:
the one shape that runs there runs inside the database (`REQ: protected-database-queries`), and
every other is refused.

#### REQ: row-count-privacy

**PLAN DESIGN.** It applies now to a document of one source that runs on a database with access
policies (`REQ: protected-database-queries`), and to joins and in-memory reads when they are
built. Results MUST derive only from rows the caller could read, source by source. The execution
summary MUST NOT report scanned rows and MUST omit the row count for any source with access
policies; on an answer that read such a source it also carries no elapsed time. A COUNT MUST equal
the caller's readable rows. The execution summary reports the rows read from each source on the
in-memory route, and every source of an in-memory answer is a database without access policies.

#### REQ: subquery-sources-authorised

**PLAN DESIGN.** A source inside a subquery MUST be authorised exactly as a top-level source: the
grant check for its database and collection, before anything is read, and, for a database with
access policies (when the in-memory route reads such sources), the mount's policy at its leaf read.

#### REQ: hidden-fields-unreachable

**PLAN DESIGN.** It applies now to a document of one source that runs on a database with access
policies, and to joins when they are built. A field that policy redacts for the caller MUST NOT be
usable, directly or by alias, as a join key, group key, aggregate input, column, filter predicate
(WHERE, HAVING, join ON) or sort key, and MUST NOT appear in `data`. An alias is a name for an
output and never a permission: the check is on the expression behind it
(`REQ: protected-database-queries`). No join reads a database with access policies yet.

### Consistency

#### REQ: consistency-statement

**PLAN DESIGN.** The `database` route is one statement in one read transaction. The `in-memory`
route reads each source once per request with no cross-source snapshot. `docs/api.md` (openvaultdb-go) MUST state
both.

### Caching and demo

#### REQ: cacheable-gets

**PLAN DESIGN**; the `no-store` sentence was added on 2026-10-05. GET responses MUST be public for the smallest `cache_ttl` of the involved
databases only when the server is read-only, authentication is off and no involved database has
policies; otherwise they MUST NOT be publicly cacheable, and an answer that read a database with
access policies carries `Cache-Control: no-store`. (An edge cache in the Worker is
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
**Then** the body has a `query` block with the endpoint `/v1/dtql`, the format, `features` (the join types `inner` and `left`, grouping, HAVING, subqueries, cross-database support, the five aggregate functions `count`, `sum`, `avg`, `min` and `max`, `windowFunctions: false`, `externalSources: false`, `protectedDatabases: false`, `fieldNames: plain`, and the object `protectedDatabaseQueries`), `limits` and `joinEngines`; the block is the same in both modes; with authentication on the document lists no database; and the protocol string is unchanged

### AC: discovery-limits-are-the-enforced-bounds (verifies REQ:discovery, REQ:limits)

Journey step 1.

**Given** a server configured with a time limit and source-read bounds of its own, in either authentication mode
**When** discovery is fetched, and then documents at, and one step over, each of the four profile bounds (sources, subquery depth, limit, offset) are posted
**Then** `query.limits` has exactly twelve numeric keys (`timeoutMs`, `maxSourceRows`, `maxSourceBytes`, `maxResultRows`, `maxResultBytes`, `maxSources`, `maxSubqueryDepth`, `maxLimit`, `maxOffset`, `maxInMemoryJoinRows`, `maxInMemoryJoinBytes`, `maxGroups`) and no concurrency slot or queue wait; the first three carry the configured values and the others the fixed ones; and each document inside a bound is answered while each document over it is a 400 `invalid_dtql`

### AC: capabilities-per-database (verifies REQ:discovery)

Journey step 1.

**Given** a SQLite database, a local inGitDB database, a GitHub-backed inGitDB database, a database on an engine outside the join set (Firestore, say), a PostgreSQL database, a SQLite database with access policies and a local inGitDB database with access policies mounted, under several operator lists of join engines
**When** discovery is fetched with authentication off, and for each database a one-source document that groups or aggregates and a join are posted
**Then** each database's `capabilities` carries `joins` and `aggregation`, each true exactly when a document of its own shape that names the database is not refused for the database itself, so that a client that reads `true` is not refused by it; an engine is in `joinEngines` exactly when a database on it without access policies advertises `joins: true`, and the GitHub-backed engine never is; a database without access policies has the two equal as before; the SQLite database with access policies says `aggregation: true` and `joins: false`; the local inGitDB database with access policies says both `false`; and its metadata is a 422 `authorization_unsupported`, which a token without `collections:read` does not reach (403 `forbidden`)

### AC: protected-databases-flag-is-a-false-boolean (verifies REQ:discovery)

Journey step 1.

**Given** a server that mounts a SQLite database with access policies, in either authentication mode, and a client that decodes `query.features.protectedDatabases` as a JSON boolean
**When** discovery is fetched
**Then** the value decodes as a boolean and is `false`, whatever the server runs on databases with access policies

### AC: protected-database-queries-discovered (verifies REQ:discovery, REQ:protected-database-queries)

Journey step 1.

**Given** a server that mounts a SQLite database with access policies, in either authentication mode
**When** discovery is fetched
**Then** `query.features.protectedDatabaseQueries` is an object with `engines` listing `sqlite` and `aggregation: true`, `joins: false`, `subqueries: false` and `crossDatabase: false`; it names no database; it has the same content in both modes; and each of the four booleans equals whether a document of its shape that names a database with access policies on one of those engines is accepted

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

**Given** a SQLite mount and a strict local inGitDB mount, each with a join whose two sources both carry a field `CustomerId` and an EXISTS test on a third read, and, separately, two SQLite mounts whose tables both carry a column `city` and a key column `id`
**When** a document selects `CustomerId` (or `city`, or `id`) with no source qualifier, against each mount on each endpoint, and the same document with the field qualified
**Then** each unqualified document returns a 400 `invalid_dtql` that says the field is ambiguous and names it, and no rows; the qualified one returns 200; and a field that only one source carries is answered from that source

### AC: field-without-list-refused (verifies REQ:field-resolution)

Journey step 2.

**Given** a SQLite mount joined to a local inGitDB mount in partial mode (which supplies no field list), by a document that holds an EXISTS test
**When** a document selects a field with no source qualifier, and the same document with the field qualified
**Then** the unqualified one returns a 400 `invalid_dtql` that tells the caller to qualify the field and does not call it ambiguous, whether or not the name is one that only one source carries; the qualified one returns 200, a field that the manifest does not declare included; and a document of one source is read as it is written

### AC: aggregate-reads-first-source (verifies REQ:field-resolution)

Journey step 2.

**Given** a SQLite mount and a strict local inGitDB mount that supply their fields, and a join of invoices and customers with an EXISTS test, grouped and aggregated
**When** a document names, with no source qualifier, a field that only the second source carries, in GROUP BY, in the argument of an aggregate in the columns, in HAVING or in ORDER BY, and then the same document with every field qualified, with the field in the first source, or with the name only in WHERE
**Then** each of the first four returns a 400 `invalid_dtql` that names the field and tells the caller to qualify it, and no rows; the others return the same grouped rows, on each mount and each endpoint

### AC: wildcard-expands-in-field-order (verifies REQ:field-resolution)

Journey step 2.

**Given** a SQLite mount and a strict local inGitDB mount, and a join of two sources whose columns hold a wildcard of one source with an `exclude`, and a join of two SQLite mounts with a wildcard of one source
**When** each is posted, so that the database route runs the first, and the in-memory route runs the other two
**Then** each returns 200 and the wildcard stands for the fields of its source's field list less the excluded names: the columns of the SQLite table with its key column `id` on either route, and the declared fields of the inGitDB collection with no key; and in `columns` the wildcard stands, at its position, for the names the rows of the answer carry that no other column of the select list names and that it does not exclude, sorted by name, and an answer with no rows lists no name for it

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

**Given** one unprotected SQLite mount, two mounts, one policy-protected SQLite mount, one document with a subquery, and a document of one collection that aggregates
**When** a relational document runs against each: a join, a join across the two mounts, a join over the protected mount, the subquery document, and the aggregate over the protected mount
**Then** the answers are `database`, `in-memory`, a 422 `authorization_unsupported` that has no label, `in-memory`, and `database`, in that order

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
**Then** the response is a 504 `query_timeout` and the server remains able to answer the next request (a single-collection read, which the setting does not bind, is answered 200 under the same setting)

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

### AC: first-and-last-refused (verifies REQ:profile-refusals, REQ:relational-profile)

Journey step 6.

**Given** four documents that apply an aggregate function to a column: over one source, over a join that one database runs on the per-database endpoint, over the same join on `/v1/dtql`, and over a join across two databases that runs in memory; each written with `first`, with `last` (in lower, upper and mixed case) and with each of `count`, `sum`, `avg`, `min` and `max`
**When** each is posted
**Then** each document that uses `first` or `last`, in any letter case and in any position of the document, returns a 400 `invalid_dtql` that names the function, before anything is read, on every route; and each document that uses one of the five accepted functions returns 200

### AC: grant-checked-for-every-source (verifies REQ:grants-before-mounts)

Journey step 6.

**Given** alice's token grants `records:read` on database A only
**When** she posts a join of A and B to `/v1/dtql`
**Then** the response is a 403 naming B, returned even when B is not mounted (403 before 404), and no source is read

### AC: protected-database-refuses-relational-document (verifies REQ:protected-database-queries)

Journey step 6.

**Given** a SQLite mount with access policies, a public database also mounted, and alice, who reads every database and belongs to a role the policy names
**When** she posts a join of the protected mount to the public one and the same join reversed, a join of two collections of the protected mount, a nested join whose innermost source is protected, a subquery over the protected mount, an EXISTS test over it, a derived source over it, and a document of one collection that groups or aggregates on a protected local inGitDB mount, each also with a collection the database does not declare or that the policy hides
**Then** each returns the same 422 `authorization_unsupported`, with no rows, no `execution` and no collection name, whatever collections the document names, and nothing is read from the mount; and a single-collection read of the protected mount on the per-database endpoint returns only the rows she may read, with keys

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

### AC: journey-over-http (verifies REQ:routing, REQ:limits, REQ:protected-database-queries, REQ:check-order)

Journey step 1 to 7.

**Given** a server with Chinook, a countries database, a protected database and a scoped token
**When** one test walks journey steps 1 to 7 over HTTP
**Then** it asserts mechanism, not only output: the pushdown beyond the in-memory bound, the budget error, the refusal of every shape the protected database does not run, and, for the one it runs, the figures of the permitted copy and the route `database`

### AC: protected-aggregate-runs-in-the-database (verifies REQ:protected-database-queries, REQ:routing)

Journey step 6.

**Given** the fixture `shop`, a SQLite database with access policies. Its table `customers` holds c1 (Ada), c2 (Bob) and c3 (Cy), each with a name and an email; its table `orders` holds o1 (customer c1, rep maria, total 100), o2 (customer c2, rep omar, total 250) and o3 (customer c1, rep maria, total 40). The first column of each table is its key, `id`. The policy lets every signed-in user read `customers` without `email`, lets a user read the `orders` whose `rep` is that user, and lets a caller in the role `admin` read every order. Maria is signed in
**When** she posts "how many orders, and what total" (a COUNT and a SUM over `orders`), and "total per customer" (the same with GROUP BY), to `/v1/databases/shop/dtql` and, with every source naming `shop`, to `/v1/dtql`
**Then** each answer is a 200 with `columns`, `execution.route: database` and no `key`; and for each served request exactly one statement was sent to SQLite, which holds the aggregate and the GROUP BY and the row rule, in which the text holds no value of the caller's, and whose arguments hold the caller's id

### AC: count-equals-readable-rows (verifies REQ:protected-database-queries, REQ:row-count-privacy)

Journey step 6.

**Given** the fixture `shop`, a larger fixture of the same shape, and the callers maria, omar and an admin
**When** each posts a COUNT and a SUM over `orders`
**Then** each count equals the number of rows that caller can read: for `shop` Maria gets 2 and 140, Omar 1 and 250, and the admin 3 and 390, and never the rows another caller reads

### AC: aggregate-equals-permitted-copy (verifies REQ:protected-database-queries)

Journey step 6.

**Given** the fixture `shop`, a larger one, two callers and an admin, and for each caller a hand-built permitted copy (the fixture with the rows and the fields the caller may not read deleted) that carries no policy
**When** each caller posts documents with SUM, AVG, MIN, MAX, COUNT of a field, DISTINCT forms, GROUP BY, HAVING, ORDER BY, a column alias used in HAVING and in ORDER BY, a null test, a limit and an offset, to both endpoints, and the same document is run without a policy on the caller's permitted copy
**Then** the two answers are equal for every document, row for row and column for column; and, as the check of the test itself, the same comparison with the row rule removed from the policy reports a difference

### AC: hidden-field-not-reachable (verifies REQ:protected-database-queries, REQ:hidden-fields-unreachable)

Journey step 6.

**Given** the fixture `shop` and Maria, who may not read `customers.email`
**When** she posts documents that use that field as an aggregate input, as a selected column under an allowed alias, in GROUP BY, in HAVING, in ORDER BY, in a filter predicate and in a null test, and a document whose every selected column is refused
**Then** each is a 403 `ACCESS_DENIED` with the text "access denied", none exposes the field's values, in `data` or by grouping, filtering or ordering, and no statement is sent to the database

### AC: unknown-and-denied-collection-are-indistinguishable (verifies REQ:protected-database-queries)

Journey step 6.

**Given** the fixture `shop`, with a collection that the policy denies to Maria, one that the database does not declare, and one that is spelled otherwise than its canonical name
**When** she posts a document of one collection that aggregates over each, to both endpoints, and a single-collection read of each to the per-database endpoint
**Then** every answer has the same status, headers and body as the others, byte for byte (a 403 `ACCESS_DENIED`), so that the database does not say which collections it declares

### AC: no-row-count-for-protected-source (verifies REQ:protected-database-queries, REQ:row-count-privacy)

Journey step 6.

**Given** the fixture `shop`
**When** Maria posts an aggregate over `orders` and it succeeds
**Then** `execution.sources` has no `rows` for the protected source, and no field of the response reports rows scanned

### AC: protected-answer-carries-no-elapsed-time (verifies REQ:protected-database-queries, REQ:response-shape)

No journey step.

**Given** the fixture `shop`, and an unprotected database
**When** an aggregate over `orders` is posted to each
**Then** the `execution` block of the protected answer has the route, `rowsReturned` and the database and collection of each source, and no elapsed time, neither the request's nor a source's; and the answer of the unprotected database keeps the elapsed time of the request

### AC: protected-answer-is-not-stored (verifies REQ:protected-database-queries, REQ:cacheable-gets)

No journey step.

**Given** the fixture `shop`
**When** an aggregate is posted, and the same document is sent as a GET
**Then** each response carries `Cache-Control: no-store`

### AC: relational-answer-carries-no-record-key (verifies REQ:protected-database-queries)

No journey step.

**Given** the fixture `shop` and Maria, and a second table of the database whose policy hides its key column `id`
**When** she posts an aggregate over `orders`, a document that selects `id` of `orders`, and a document that selects `id` of the second table
**Then** the first answer carries no record key and no `id`; the second returns the `id` values of the rows she may read; and the third is a 403 `ACCESS_DENIED`

### AC: no-row-cap-on-the-database-route (verifies REQ:protected-database-queries)

No journey step.

**Given** a protected table of more than 10,000 rows that the caller may read
**When** the caller posts a COUNT and a grouped aggregate over it
**Then** each answers with the whole count over every row the caller may read, on `execution.route: database`, and no refusal names a row bound

### AC: hidden-rows-do-not-change-the-answer (verifies REQ:protected-database-queries)

No journey step.

**Given** two fixtures that hold the same rows for the caller, the second with added rows that the caller may not read, which outnumber every bound of the server and hold hostile values (text in a numeric column, huge numbers, blobs)
**When** the same aggregate documents are posted for the caller to each
**Then** the two answers have the same status, headers and body

### AC: policy-values-are-bound (verifies REQ:protected-database-queries)

No journey step.

**Given** callers whose ids are a quote, a semicolon followed by a second statement, a comment marker, a backslash, a NUL byte, text that looks like a number, very long text and an empty string, and a policy whose row rule names the caller (`rep == $currentUser`)
**When** each posts an aggregate over `orders`
**Then** each id is data: the answer is the one the permitted copy gives (an empty result for an id that is no `rep`), the statement text is byte-identical to that of another caller whose id has the same type and length, and the tables are whole afterwards

### AC: protected-refusal-reads-nothing (verifies REQ:protected-database-queries)

No journey step.

**Given** the fixture `shop`
**When** Maria posts a join, a subquery, a document over `shop` and a second database, and a document that SQLite refuses to run
**Then** each is refused as `REQ: protected-database-queries` says, and no statement is sent to the database after the refusal, in memory or otherwise

### AC: busy-protected-database-is-retryable (verifies REQ:protected-database-queries)

No journey step.

**Given** a protected SQLite database whose file another connection holds locked
**When** Maria posts an aggregate
**Then** the answer is a 503 that a client may retry, and never a 403 or a 404

## Later: joins, subqueries and several databases with access policies

A join, a subquery and a document over several databases that name a database with access
policies are refused (`REQ: protected-database-queries`), so the criteria below cannot be tested
yet. They state what such documents must do when they are built. Three criteria that hold now
for one source, `count-equals-readable-rows`, `hidden-field-not-reachable` and
`no-row-count-for-protected-source`, are above, and each has a join variant here.

### AC: policy-applied-per-leaf (verifies REQ:policy-per-leaf)

Not yet testable; no journey step.

**Given** a policy-protected database joined to a public one, alice readable on some of the protected rows, and alice holding a server-wide token, per Open Question 4
**When** alice posts the join
**Then** the result contains only joined rows built from rows she can read

### AC: count-equals-readable-rows-in-a-join (verifies REQ:policy-per-leaf, REQ:row-count-privacy)

Not yet testable; no journey step.

**Given** the same databases and the same server-wide token
**When** alice posts a COUNT over a join that holds the protected source
**Then** the count equals the number of joined rows built from the protected rows she can read

### AC: no-row-count-for-protected-join-source (verifies REQ:row-count-privacy)

Not yet testable; no journey step.

**Given** the same databases
**When** the join succeeds
**Then** `execution.sources` has no `rows` for the protected source, and no field of the response reports rows scanned

### AC: nested-join-authorised (verifies REQ:policy-per-leaf, REQ:leaf-wrapper)

Not yet testable; no journey step.

**Given** a join tree of depth three whose innermost source is protected and which alice may read only in part
**When** alice posts it
**Then** the innermost source's policy is applied and no row she cannot read influences the result

### AC: hidden-field-not-reachable-in-a-join (verifies REQ:hidden-fields-unreachable)

Not yet testable; no journey step.

**Given** a protected collection with a field redacted for alice, joined to another collection
**When** she posts documents using that field as a join key, a group key, an aggregate input, an aliased column, a filter predicate and a sort key
**Then** none exposes the field's values, in `data` or by grouping, filtering or ordering, and each is refused

### AC: subquery-source-authorised-over-protected (verifies REQ:subquery-sources-authorised)

Not yet testable; no journey step.

**Given** alice holds a token granting only database P, which is policy-protected and readable by her in part, and database B is also mounted
**When** she posts a document over P whose subquery reads B, and another whose subquery reads P
**Then** the first returns a 403 naming B and the second returns only results built from rows she can read

### AC: budget-errors-report-limit-only-over-protected (verifies REQ:limits, REQ:row-count-privacy)

Not yet testable; no journey step.

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
2. **Nested join authorisation (INFERENCE).** This finding was written when DALgo's access layer
   was read as building its resource list from the base source and first-level joins only; the
   layer at dalgo v0.89.6 lists every source of a query at any depth
   (`access/query_sources.go` in dal-go/dalgo) and still refuses field rules and row rules on
   joined sources. The design never hands a nested join whole to a protected handle
   (`REQ: policy-per-leaf`). No join reaches a
   database with access policies (`REQ: protected-database-queries`), and `nested-join-authorised`,
   under "Later: joins, subqueries and several databases with access policies", tests it when
   joins over such databases are built.
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

Window functions; trace headers; boolean coercion in joined rows; joins, subqueries and
documents over several databases that name a database with access policies, which are refused
until they are built (`REQ: protected-database-queries`); all of Part 2 (external sources); CLI
delegation. Items that are open questions rather than settled scope (grants naming several
databases, exact labelling) are under Open Questions.

## Open Questions

None of the open questions below is decided. Questions 1 to 8 are the implementation plan's, in its
order, each with the plan's recommendation. Questions A to D are the author's additions. Questions
7, 8 and A are answered by the code on main, and question 3 by the owner's decision of 2026-10-05;
all four are closed under "Closed questions" below. Questions 5 and D wait for the founder's own
answer; until they are answered this Feature states the cautious behaviour: for 5, only what OVDB
can do without DALgo's exported additions (the route label is `database` or `in-memory`, and
DALgo's bound messages are matched by text); for D, the behaviour that main has.

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
D. A lone source that names a `database`, a `schema` or a `scan`, a subquery-only document, and
   field names. The code on main answers it as follows. On the per-database endpoint a root that
   names the endpoint's own database is read as one that names none, with the same body and keys;
   a root that names another database, a `schema` other than the engine's default and a `scan`
   are a 400 `invalid_dtql`; on `/v1/dtql` every source names its database, a one-source document
   is relational with no keys, and no `schema` is accepted (`REQ: endpoints`). A document whose
   only relational feature is a subquery is relational on the per-database endpoint. A relational
   document holds the strict field-name rule on every engine, so a field named with a space is a
   400 `invalid_dtql` even on SQLite (`REQ: values-and-names-never-text`). A client that sends such
   a document gets the 400. This was set in review and reported to the founder, who has not
   answered it. Pinned by `TestRelationalDTQLOverHTTPAcceptance` (a one-source document that names
   its own database, and the subtest for a document whose only relational feature is a
   subquery), `TestSingleCollectionDocumentAndTheDefaultSchemaOverHTTP`,
   `TestTheJourneyOfAJoinOverHTTP` (step 2), `TestRelationalDTQLStatusesOverHTTP` (a field name
   that only the wider quoted-name rule accepts is refused on a relational document) and
   `TestSQLiteColumnWithASpaceIsQueryableOverHTTP` (the same column is read by the single-collection
   path). Is this accepted? The decision is the founder's.

Cut order if the window slips (a plan note, not a question): OJ-11, OJ-10, OJ-12, then subqueries.

### Closed questions

These were open questions of this Feature. The code on main answers each, and the test that pins
the answer is named, except question 3, which the owner's decision answers. The tests are in
openvaultdb/openvaultdb-go, `pkg/server` unless a package is named.

3. Policy-protected databases. Closed by the owner's decision of 2026-10-05 (paraphrased). The
   question was whether the launch limit may stand, under which a relational document that names a
   database with access policies is refused, and whether, after launch, OVDB should aggregate
   over the policy-filtered rows itself, bounded at 10,000 rows. The owner decided that the
   refusal must not stand and that the policies run natively: row rules and field lists are
   compiled into the SQL statement, so that the database filters and aggregates, with no row cap
   where the engine runs the whole document. `REQ: protected-database-queries` states what runs
   and what is refused; the criteria that prove it are `protected-aggregate-runs-in-the-database`
   and those listed with journey step 6. They are not yet passed by a released server:
   openvaultdb-go v0.13.0 refuses every relational document on such a database. Joins,
   subqueries and documents over several databases are built after the first slice, and the
   criteria under "Later: joins, subqueries and several databases with access policies" wait for
   them.

7. Engines in joins at launch. Closed: the join set is SQLite and local inGitDB. The operator's
   list can add an engine that the structured-query guard clears (Firestore, say); PostgreSQL,
   MySQL and an unknown engine are a 501 `query_unsupported` even when listed (PostgreSQL joins
   after OV-01); a GitHub-backed inGitDB mount is never joined; a database on an engine outside
   the list is a 422 `join_engine_unsupported`. Discovery lists as `joinEngines` only the engines
   whose databases can take part (`REQ: discovery`). Pinned by
   `TestRelationalHandlerRefusesEnginesTheGuardOrTheListLeavesOut`,
   `TestJoinEnginesOmitsTheGitHubEngineWhateverTheListSays` and
   `TestAdvertisedJoinsEqualWhatARelationalRequestGets`.
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

---
*This document follows the https://specscore.md/feature-specification*
