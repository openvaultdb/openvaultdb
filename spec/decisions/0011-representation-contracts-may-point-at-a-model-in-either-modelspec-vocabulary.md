---
format: https://specscore.md/decision-specification
status: In Review
---

# Decision: Representation contracts may point at a model in either ModelSpec vocabulary

**Status:** In Review
**Date:** 2026-10-09
**Owner:** alex
**Tags:** representation-contract,modelspec,compatibility
**Source Idea:** —
**Supersedes:** —
**Superseded By:** —

## Context

How to read this record. Three kinds of statement appear in it, and each is
labelled:

- **The owner's words**, quoted exactly with their date.
- **On record**: what a message, a decision or a file already on record says, with
  a link or a place to find it. Where the source is not published, so that a reader
  cannot open it, the text says "not published".
- **Recorder's account**: what the session writing this file says or infers. It
  is not the owner's ruling, whatever its tone.

Two terms keep one meaning each. A **contract file** is one JSON file in a
representation contract format. A **contract entry** is one element of the
`contracts` list inside a contract file.

**On record.** ModelSpec renames its terms in stages. Decision 0018 renames the
entity to a record and gives the JSON form the format identifier `1.0-draft-2`;
decision 0020 makes `field` the one member word; decision 0019 removes the
collection and the recordset; decision 0022 fixes the order: readers accept both
spellings first, writers follow, each registered model is regenerated and
re-pinned, and the earlier spelling becomes an error only when no registered pin
uses it, and only with its own approval. These are decisions
[0018](https://github.com/specscore/modelspec/blob/main/spec/decisions/0018-entity-becomes-record.md),
[0019](https://github.com/specscore/modelspec/blob/main/spec/decisions/0019-collection-and-recordset-removed-three-words-reserved.md),
[0020](https://github.com/specscore/modelspec/blob/main/spec/decisions/0020-field-is-the-member-word.md)
and
[0022](https://github.com/specscore/modelspec/blob/main/spec/decisions/0022-prose-now-format-change-on-the-owners-word.md)
in the ModelSpec repository. In the JSON form the two vocabularies are:

| | Earlier | Current |
|---|---|---|
| Format identifier (`modelspec`) | `1.0-draft` | `1.0-draft-2` |
| Record types | `entities` | `records` |
| Members | `properties` | `fields` |
| Reference | `entity` | `record` |

**On record.** Decision 0022 carries a dated entry of 2026-10-09 about the last
stage, making the earlier spelling an error. The session recording it had told the
owner that this approval would come later and that it would ask then. The owner's words in
that entry are: "yes, you can and should make the old spelling an error". The
entry says the recording session reads this as approval of that step in its place
in the order, after the registered models are pinned anew, and that it put that
reading to him. The entry also says his next message, "proceed", does not say
whether the reading is right.

**On record.** OpenVaultDB's representation contract has three published formats,
`ovdb-representation-contract/1`, `/2` and `/3`. A publisher attaches a contract
file in `ovdb.yaml` as `representation_contract`, with the file's SHA-256. A
contract entry names, among other things, the ModelSpec model it points at (the
target model, and a source schema), each by path and SHA-256. The formats are
closed JSON Schemas (`schema.json`, `schema2.json`, `schema3.json`) in
[openvaultdb/ovdb](https://github.com/openvaultdb/ovdb/tree/v0.42.0/publisher/representation)
under `publisher/representation/`. They are described as unchanged since their
first publication in two places, read at the heads given here:
`openvaultdb/ovdb` at release v0.42.0 (commit
`86c31700875661a011552c7ae28a55cc7a370dd7`), `publisher/representation/README.md`
lines 119 ("Formats 1 and 2 retain their original schemas") and 169 ("The closed
format1 schema and existing fixtures remain unchanged"); and `openvaultdb/directory`
at commit `ec53d7539aafd23d006b4943acdd7a31f4eb9340`, `README.md` line 498 (the
"frozen OVDB formats 1, 2 and 3 schemas", "vendored unchanged from OVDB `v0.27.1`").

**On record, found by reading them.** None of the three schemas and no sentence
of those two README files names a ModelSpec vocabulary for the model a contract
entry points at. The schemas contain the contract entry's own keys `entity` and
`property` (the names of a record type and of one of its members in the referenced
model), and nothing else about the model's spelling. What fixes the earlier
vocabulary today is what the readers do, not what a format says:

- `openvaultdb/ovdb` v0.42.0, package `publisher/representation`: `contract.go`
  lines 355 to 365, `native.go` lines 48 to 61 and `strict.go` lines 39 to 56
  read a model only if its `modelspec` identifier is `1.0-draft`, and only through
  the keys `entities` and `properties`.
- `openvaultdb/directory` at `ec53d75`: `scripts/lib/representation.mjs` reads a
  model or source schema in either vocabulary (pull request
  [#43](https://github.com/openvaultdb/directory/pull/43), merged 2026-10-09).
- `openvaultdb/ovdb` v0.42.0 has a third reader of ModelSpec models,
  `publisher/source/pinchain/model.go` (line 120), which requires `1.0-draft`. It
  guards the model of the `ecb-daily` source through a pin chain, is not a
  representation contract reader, and is covered neither by this record nor by
  `openvaultdb/ovdb` pull request #88 (below). Nobody should infer from this
  record that `ovdb` reads both vocabularies everywhere.

**On record.** This specification repository does not contain the text of formats
1 to 3. A search of `spec/` at `6c7e9f162514db9365b1258e16b2a4b84b594955` for
"representation contract", `ovdb-representation`, "frozen" and the format names
found no such text. So this record amends no sentence here; see "What does not
change" for where the format text lives.

**On record, the two contracts that exist.** GeoNames
([`ingitdb/geo-ingitdb`](https://github.com/ingitdb/geo-ingitdb), read at commit
`5653b130fc30e5a597750db7cafa3039b7280ed1`: one contract file, format 2, four
contract entries, all `label-bridge`) and ROR
([`ingitdb/ror-ingitdb`](https://github.com/ingitdb/ror-ingitdb), read at commit
`7ef2e98f80ab148d694a534992719499d4c9e607`: one contract file, format 3, one
contract entry, `native-identifier`). Both models are still `1.0-draft`. Neither
is a database record in `openvaultdb/directory` (its six database records and its
`index.json` at `ec53d75` carry no `representation_contract`). Both are,
however, registered models, and so are among the pins that decision 0022's last
stage waits for: in the ModelSpec registry
([`modelspec-org/registry`](https://github.com/modelspec-org/registry), read at
`6b69fc922b7306fbebcec734e11b93a9b51a63d2`) `models/$records/geonames.yaml` pins
commit `6f4cf1269bc393048f6b204069135a62f0bb6c02` and `models/$records/ror.yaml`
pins commit `dc78c1e929f1f10018f8c39e690351059a50c71f`; and the MeaningGraph
registry ([`meaninggraph/registry`](https://github.com/meaninggraph/registry),
read at `8a9e57f02b99e33c1e9091d712c546906df0214d`) lists the same two commits in
`graphs/$records/geonames.yaml` and `graphs/$records/ror.yaml`. Those registered
commits are not the commits at which the contract files above were read.

**On record, the question.** On 2026-10-09 at 06:13 UTC the coordinating session
(the assistant session that was working for the owner) sent him a message that
opened "All three are landed and verified. Four questions for you are below; none
of them blocks the work now running." Its fourth numbered question read, in full
and exactly:

> 4. **Representation contracts: amend the frozen formats, or add a new one?** GeoNames and ROR cannot be rewritten while the contract accepts only `"modelspec": "1.0-draft"`. I recommend amending formats 1 to 3 on one point only: which model vocabularies a contract may point at. No contract byte changes, and the Directory's own checker already behaves this way.

The wording is read from the session's stored record of its turns (not published),
where an independent reviewer recovered it. The question carried no before-and-after
example and did not mention a hash.

**On record, the reply.** On 2026-10-09 at 06:25 UTC the owner replied in one
message of four lines, to the four numbered questions (read from the same stored
record, not published). Its fourth line was:

> 4 - amend

**Recorder's account of the question and the reply.**

- The question put two courses: amend the frozen formats, or "add a new one". It
  carried the session's recommendation ("I recommend amending") and two stated
  reasons for it: that GeoNames and ROR cannot be rewritten while the contract
  accepts only `"modelspec": "1.0-draft"`, and that the Directory's own checker
  already behaves this way. His reply gave no reasons of his own.
- The scope of the amendment, "on one point only: which model vocabularies a
  contract may point at", is the question's own wording. So the scope rests on the
  sentence he answered, and not only on the recorder's reading of it.
- The question's sentence "No contract byte changes" is false. That is the
  recorder's correction, and the record states it without softening it. What is
  true instead: no contract key, no format and no schema changes. A publisher that
  rewrites its model gets new model bytes, the contract entry pins those bytes by
  SHA-256, so values inside the contract file change, and for some kinds of
  contract entry more than one value; and then the contract file's own SHA-256 in
  `ovdb.yaml` changes too. The Decision section sets this out by case.
- The owner answered "amend" at 06:25 UTC having been told the false sentence. He
  was then told it was false and what changes, and asked again (below); he answered
  that "amend" still stands. The record was left In Review for the first answer's
  sake, and stays In Review until he has approved this text (see "What he is asked to
  approve").

**On record, the question put to him again** (read from the session's stored record,
not published, by the independent reviewer; the coordinating session confirms it).
On 2026-10-09 at 08:21 UTC, after the review that found the error, the coordinating
session told him that the sentence was false and what changes by kind of contract
entry, and asked: "does "amend" still stand, knowing that the pinned hashes inside
each contract do change?"

The coordinating session's argument in that message, not his words: a new format
would have required rewriting each contract wholesale, so amending is still the
smaller change.

**On record, the question repeated, and his answer.** The session repeated the
question in its messages through the morning. The last two are quoted here, from
the session's stored record (not published). The first was sent on 2026-10-09 at
09:44 UTC, in a message headed "Two questions that unblock openvaultdb/ovdb#88"
(a pull request in `openvaultdb/ovdb`); its first question, exactly:

> **1. Does "amend" still stand?**
>
> No contract key, format or schema changes. A publisher who rewrites its model must update the pinned hashes inside its contract: one per entry for GeoNames, three for ROR's entry, then the contract's own hash in `ovdb.yaml`.

and a later message, at 11:52 UTC, ended with a numbered list headed "Waiting on you",
whose first line was:

> 1. Does "amend" still stand?

His reply, 2026-10-09 at 11:58 UTC, was one message of five lines. Its first line was:

> 1. Yes

(Its second line, "2. Yes", answers the second question and is recorded in the
Decision section. Its other three lines concern other matters and are not part of
this decision.)

**Recorder's account.** His "1. Yes" says the course stands: he answered that
"amend" still stands after being told that the sentence "No contract byte changes"
was false and which pinned hashes change. It is not approval of this text.

**Recorder's account of the problem.** The formats are frozen, and a frozen format
that is silent about the model's vocabulary leaves a question that readers answer
differently (the readers above do). The stages of decision 0022 make it urgent:
the last stage makes the earlier spelling an error, and a model that a contract
entry pins by SHA-256 can then neither stay as it is nor be rewritten without the
pin moving. The question needed one answer for all three formats.

## Decision

**The owner's words.** His answer, 2026-10-09, was the fourth line of his
four-line reply to the four numbered questions:

> 4 - amend

Those are the owner's words this record has on the amendment itself, apart from the
later "1. Yes" recorded in the Context, which says the amendment still stands.

**Recorder's reading of the answer** (the reading is the recorder's; the owner had
not been shown this text when it was written): the answer chooses to amend over adding a format. The
amendment, on one point only, which is the question's own wording of the scope:

> A ModelSpec model or source schema that a representation contract refers to may
> be written in either ModelSpec vocabulary: identifier `1.0-draft` with
> `entities`, `properties` and `entity`, or identifier `1.0-draft-2` with
> `records`, `fields` and `record`.

This holds for formats 1, 2 and 3 (`ovdb-representation-contract/1`, `/2`, `/3`).
Each referenced model is read in the vocabulary its own `modelspec` identifier
names.

The contract entry's own keys are not part of that vocabulary and do not move.
`entity`, `property`, and every other key a contract file has keep their names and
their meaning. In a contract entry, `entity` names a record type of the referenced
model in either vocabulary, and `property` names a member of it in either. On
record, the ModelSpec conceptual design proposal (not published) has this sentence in
its "What does not change" section, in the version headed "8 October 2026, for
approval" and in the version headed "Revision 2, 9 October 2026", which came after:
"OVDB's representation contract formats 1 to 3. They are frozen and versioned. They keep their entity field; a
later format adopts the new word." Those are the proposal's words, not the owner's of
2026-10-09. On the recorder's account, the owner's answers of 8 October to the
ModelSpec questions (decisions 0018 to 0022) were given on the first of the two
versions.

Before and after, as the recorder's illustration, written afterwards and not in
the question put to the owner: the GeoNames target model that a contract entry names, abridged (the
real model has more members; the rewritten file is not published):

```json
{"modelspec": "1.0-draft",
 "module": {"id": "github.com/ingitdb/geo-ingitdb/model/geonames",
            "name": "geonames", "version": "0.1.0"},
 "entities": {"geonames_countries": {"key": ["iso"],
   "properties": {"iso": {"type": "string", "required": true}}}}}
```

```json
{"modelspec": "1.0-draft-2",
 "module": {"id": "github.com/ingitdb/geo-ingitdb/model/geonames",
            "name": "geonames", "version": "0.1.0"},
 "records": {"geonames_countries": {"key": ["iso"],
   "fields": {"iso": {"type": "string", "required": true}}}}}
```

In the contract entry that points at either file, these members of `target` are
byte-identical before and after:

```json
"datatype": "string", "entity": "geonames_countries", "module": "geonames", "property": "iso"
```

What does hold: no key and no schema changes. Other values in the contract file do change, by case.
This is the recorder's account, read from the two implementations (`ovdb` v0.42.0,
`publisher/representation/contract.go` lines 556 to 560 and `native.go` line 189;
`openvaultdb/directory` at `ec53d75`, `scripts/lib/representation.mjs` lines 156
and 175) and from fixtures, and from the two publishers' files at the commits
named in the Context, which show what their snapshot and receipt contain. It is
not from running either reader over a rewritten copy of a publisher's real bytes,
which do not exist yet. One run supports the Go half: the Go package at the head of
`ovdb` pull request #88 (`684b0c04bb0577e1188fd3c17649ab415e48ddd4`, not merged),
over that pull request's own test fixtures (the ROR, the GeoNames label-bridge
and the GeoNames native-identifier fixture, each in the earlier vocabulary and
rewritten). With only `target.model.sha256` changed to the rewritten model's
checksum, the label-bridge fixture is accepted and both native-identifier fixtures
are refused ("native data/model/binding/provenance must match snapshot artifact
checksums"); with the model, snapshot and provenance pins all changed, all three
are accepted. The probe was written by the independent reviewer of this
record; the recorder re-ran it and got the same result. The Directory's reader was read,
not run.

1. **A label-bridge contract entry** (all of format 1; the four GeoNames entries
   in format 2). The model's pin, `target.model.sha256`, once per contract entry
   that names the model; in GeoNames's contract file it occurs four times. Neither
   reader checks that the snapshot lists the model for such an entry. GeoNames's
   own `source/artifact-snapshot.json` does list the model's checksum, so a
   publisher that keeps its snapshot true also rewrites the snapshot, and then
   `target.snapshot.sha256` moves too.
2. **A native-identifier contract entry** (all of format 3; one kind of entry in
   format 2; ROR's one entry). Three values per contract entry:
   `target.model.sha256`, `native.provenance.sha256` and `target.snapshot.sha256`.
   Both readers require the snapshot to list the target model (and the binding
   document, the native dataset and the native provenance) at the entry's exact
   checksums, and the provenance receipt to name the same model reference as the
   entry. So the receipt is rewritten to name the new model, the snapshot is
   rewritten to list the new model and the new receipt, and their pins move with
   the model's. In ROR's files at `7ef2e98`, `source/artifact-snapshot.json` lists
   `model/ror.modelspec.json` and `source/validation.json` names it, both at the
   contract entry's current checksum.
3. **A source schema** (`source.schema`). It is external and pinned by repository,
   revision and SHA-256 (both readers require an external repository for it). So
   moving it changes `source.schema.revision` together with `source.schema.sha256`,
   and only when that other repository has a rewritten revision. A publisher that
   rewrites its own model does not touch `source.schema` at all: that pin belongs
   to whoever holds a contract entry that uses the model as a source. Whether the
   entry's own `decision.document` and `decision.scope` should be rewritten when
   its source pin moves is not settled here (see below); the GeoNames entries each
   carry a `decision.scope` that names the source revision.

In every case the contract file's own bytes change, so the SHA-256 that
`ovdb.yaml` records for it (`representation_contract.sha256`) moves too.

### The second rule: a referenced model that mixes the vocabularies, or carries a removed construct, is refused

This is a rule separate from the amendment above, and it was put to the owner as its
own question.

**On record, the question.** The coordinating session's message of 09:44 UTC that
put it, quoted exactly from its stored record (not published), relevant part in
full. Its heading was "Two questions that unblock openvaultdb/ovdb#88"; the second
question read:

> **2. May the representation check also refuse a model that mixes the two vocabularies or carries a removed construct?**
>
> A contract may point at a model in either vocabulary; that is the amendment. This is a separate rule. For example, a model like this, which today's `ovdb` v0.42.0 accepts when a contract uses it as a source schema, would be refused:
>
> ```json
> {"modelspec": "1.0-draft",
>  "entities": {"Customer": {"key": ["id"], "properties": {"id": {"type": "string"}}}},
>  "collections": {"customers": {"entity": "Customer"}}}
> ```
>
> - **Yes (my recommendation).**
>   - ModelSpec's specification already makes such a document an error.
>   - The Directory's checker already refuses it, and so does `ovdb`'s own model reader since v0.42.0.
>   - Without the rule, `ovdb publisher check` would pass a contract the Directory then refuses.
>   - The reviewer fetched every model and source schema that any contract in the two publishers' repositories pins and found none affected.
>   - It can be loosened later.
> - **No.** The Go reader keeps today's looser reading for earlier-spelling models and so differs from the Directory on these files. Four golden cases are then recorded as known differences.
>
> If you say yes to both, I record your words in decision 0011, have its text reviewed, and bring you that text to approve separately. Then #88 lands and releases `ovdb` v0.43.0.

and, in a later message, at 11:52 UTC, the second line of the "Waiting on you" list:

> 2. May the representation check refuse mixed or removed-construct models? (I recommend yes.)

**The owner's words.** His reply, 2026-10-09 at 11:58 UTC, the second line of the
same five-line message as "1. Yes":

> 2. Yes

**Recorder's reading of the answer** (the reading is the recorder's; the owner had
not been shown this text when it was written). The rule, stated by the recorder:

> A ModelSpec model or source schema that a representation contract refers to, whose
> identifier is `1.0-draft` or `1.0-draft-2`, is refused when it carries a key of the
> other vocabulary (at the top level, on a record type or on a member), or a removed
> top-level key (`collections`, `recordsets`).

The identifier limit is where the readers apply the check, not an extension.

**On record.** ModelSpec's specification makes a document that carries `projections`
or `migrations` an error as well. In `specscore/modelspec` at `origin/main`
(`17e2c503ce882e72aca2e277f5ed2d958da723cc`), `spec/json-format.md`, section
"Removed And Reserved Fields": "The top-level fields `collections` and `recordsets`
are removed, and `projections` and `migrations` are reserved with no content. A
document that carries any of the four is an error, under either identifier". The
Directory's reader refuses those two keys with the same check as the other two, and
so does the Go reader in `ovdb` pull request #88 (not merged; the independent
reviewer's run). The question he answered said "removed construct" and did not name
them, so refusing them rests on ModelSpec's specification, not on his "2. Yes".

**Recorder's note.** This text has the check refuse all four keys: `collections` and
`recordsets` on his "2. Yes", `projections` and `migrations` on ModelSpec's
specification. An approval of this text is an approval of the text as a whole.

The full question, with its example and reasons, was sent to him at 09:44 UTC. His
reply at 11:58 UTC followed the list of 11:52 UTC, which carried only the one line.

**Recorder's note on the example.** The quoted example is abridged: it has no
`module`, so that exact document would be refused by `ovdb` v0.42.0 for another
reason (the contract's module does not resolve; read in the code, not run). What the
question claims holds for a whole model, as the independent reviewer's run showed
(a `1.0-draft` source schema with a top-level `collections`, `recordsets`,
`projections` or `migrations` is accepted by v0.42.0 and refused by #88).

**Separate from the amendment.** The amendment widens what a contract may point at;
this rule narrows what is accepted in the earlier vocabulary, so it is a second
point. It is outside the sentence he answered on 2026-10-09 at 06:25 UTC ("on one
point only: which model vocabularies a contract may point at"), and rests on his
"2. Yes" to its own question, not on "4 - amend".

**What it changes** (recorder's account):

- A source schema in `1.0-draft` that carries a key of the other vocabulary or any
  of the four removed or reserved top-level keys, which `ovdb` v0.42.0 accepted, is
  refused (for `projections` and `migrations` by the specification, not by his
  answer). The Directory already refused it. The publisher's own model
  is also read by `internal/publisher/repo`, which has had the checks
  `repo-model-vocabulary` and `repo-model-removed` since v0.42.0 (its README, line
  113).
- A contract that points at a `1.0-draft` model without any such key is read as
  before.
- Older pins of clean earlier-vocabulary files stay valid.

**Evidence, the independent reviewer's check and not a guarantee.** The reviewer of
`openvaultdb/ovdb` pull request #88 ([comment](https://github.com/openvaultdb/ovdb/pull/88#issuecomment-6077613935),
at that pull request's head `684b0c04bb0577e1188fd3c17649ab415e48ddd4`) fetched, at
its pinned commit and checked against its SHA-256, every model and source schema
pinned by any revision of any contract file in the history of `ingitdb/geo-ingitdb`
and `ingitdb/ror-ingitdb`, by the contract fixtures of `datatug/datatug-apps` and
`demo-db/chinook`, and by the `ovdb` repository's own fixtures. The six real ones
are `1.0-draft` with the top-level keys `entities`, `modelspec` and `module` only,
and no `fields` or `record` at the two inner places; the reviewer found none
affected. The check covers the files fetched, not any file written later.

### What does not change

- No contract format changes: the three JSON Schemas, the names of their keys, the
  meaning of every key, and the format identifiers stay as published. No format
  number is introduced; there is no format 4 in this record.
- No contract file needs a new structure. A publisher that does not rewrite its
  model changes nothing.
- An older pin stays valid, with one exception, the second rule. A contract entry
  that pins a model by SHA-256 keeps pinning those bytes, and they are read in the
  vocabulary they are in, if they are clean: a file with a key of the other
  vocabulary or a removed or reserved top-level key is refused whichever pin names
  it (for the two reserved keys by the specification, not by his answer). A source schema pinned at an older revision of another repository stays
  readable in the vocabulary it was written in under the same condition.
- The text of the formats is not in this repository (see Context), so this record
  edits no sentence of the specification. The sentences that describe the formats
  as frozen stay true of the schemas, which do not change. The reader code and its
  README, in `openvaultdb/ovdb` and `openvaultdb/directory`, are those
  repositories' to change, and this record changes none of them.

### Not settled by this record

- When the earlier vocabulary stops being accepted for a model that a contract
  entry refers to. On record, decision 0022 makes the earlier spelling an error
  only when no registered pin uses it, with an approval of its own, and its dated
  entry of 2026-10-09 (quoted in the Context) records the owner's words on that
  approval and the recording session's reading of them. This record neither gives
  that approval nor sets a date for contracts.
- Whether a later format renames the contract entry's own keys `entity` and
  `property`. On record, the proposal quoted above says "a later format adopts the
  new word". This record does not propose such a format and does not rule it out.
- Whether a contract entry's own `decision.document` and `decision.scope` should be
  rewritten when its source pin moves (item 3 above). "Decision" here means those
  two members of the contract entry, not a decision record like this one. A
  GeoNames entry's `decision.scope` names the source revision. On record, neither
  reader compares `decision.scope` with the source revision: the Go reader of
  `ovdb` v0.42.0 declares the field and reads the pinned document's bytes
  (`contract.go` lines 100 to 103 and 278 to 281) and nowhere compares the scope;
  the Directory's reader at `ec53d75` resolves the document's bytes
  (`representation.mjs` line 116) and does not read `scope`. So nothing refuses an
  entry whose scope names the old revision; what is unsettled is whether one should
  be written.
- Recorder's account, not a rule he was asked about: a key that merely folds to a
  word of the other vocabulary by letter case (`Entities` under `1.0-draft-2`) is
  an unrelated key, matched by exact bytes, in both implementations (the
  Directory, and `ovdb` pull request #88 at `b7e1c4a7c172f9ceeb97f6482e56200d8a4dc8d3`, not merged);
  that is behaviour of the readers.

### Takes effect

Recorder's account, not the owner's. As to the specification, once the owner
approves this text. In running software, only when and as each implementation
changes, which this record does not do; see the consequences.

### What he is asked to approve

Recorder's account. A "Yes" to either question, "1. Yes" or "2. Yes", is not
approval of this text. The text is put to him separately, at a named commit, after
independent review. Until then the status stays In Review.

## Rationale

His reply gave no reasons. The question gave two (in the Context). The following
are the recorder's.

- The contract entry's keys and the model's vocabulary are different things: a
  contract is OpenVaultDB's, the model's words are ModelSpec's. Amending only which
  vocabulary the pointed-at model may use leaves every existing contract file,
  schema and reader of the contract's own keys as it is.
- A model that a contract entry pins can move to the current vocabulary under
  decision 0022 without a new contract format and without waiting for one.
- Both vocabularies have to stay readable anyway, because older pins of older
  model revisions stay valid for ever (decision 0018: "A commit that is pinned today
  keeps its old spelling and stays readable"), with one exception, the second rule:
  a clean file does, and a file with a key of the other vocabulary or a removed or
  reserved top-level key is refused.
- The second rule's reasons are the five listed in the question he answered "2. Yes"
  to (quoted in the Decision section); his reply gave none of his own.

## Declined Alternatives

### Add a new format (format 4) in which a contract points at current-vocabulary models

On record, this was the other course in the question ("or add a new one"), and he
answered "4 - amend". The detail of what a new format would mean is the recorder's
account: a new schema and format number, every reader taught a fourth format, and
every publisher that rewrites its model also rewriting its contract file into the
new format. The owner gave no reason for not choosing it.

### Keep the Go reader's looser reading of `1.0-draft` models (the "No" put to him on the second rule)

On record, this was the other answer to the second question: the Go reader keeps
today's looser reading for earlier-spelling models, differs from the Directory on
these files, and four golden cases are recorded as known differences. He answered
"2. Yes" and did not choose it.

### Leave the formats silent (not put to the owner)

Recorder's account only: the question offered two courses, amend or add a format,
and this was neither. It is listed because it is what the formats do today, and
because it leaves the readers answering differently.

## Consequences at Decision Time

Recorder's account, written on 2026-10-09 from the repositories as they were read
that day. It states what is true then and no more.

- Both vocabularies are permitted for any model or source schema a contract refers
  to, in formats 1, 2 and 3, and a referenced model that mixes them or carries a
  removed top-level key is refused (the second rule), as is one that carries a
  reserved top-level key, by ModelSpec's specification.
- A publisher that rewrites its own model must change the values listed by case in
  the Decision section: one value per contract entry for a label-bridge entry (and
  the snapshot's, if it keeps its snapshot true), three for a native-identifier
  entry, and then `representation_contract.sha256` in its `ovdb.yaml`. It changes
  no key and does not touch `source.schema`.
- A publisher cannot rewrite a model it does not own. A source schema that lives
  in another publisher's repository is pinned by repository, revision and SHA-256;
  a contract entry moves to that schema's rewritten revision only when that
  repository has one, and then `source.schema.revision` and `source.schema.sha256`
  change together.
- Readers must read `1.0-draft` for as long as any contract entry pins a model in
  it.
- Implementations, read with `gh` and `git` on 2026-10-09 after the owner's replies:
  - `openvaultdb/directory`, current `main` `bca7b8c07e66da3ee4b6020051c352ae76b173d8`
    (committed 2026-10-09T09:08:42Z): `scripts/lib/representation.mjs` and
    `scripts/lib/modelspec.mjs` are unchanged since `ec53d75`. It reads either
    vocabulary for these models (pull request #43, merged 2026-10-09T04:44:36Z) and
    already refuses a mixed model and the removed or reserved top-level keys
    (`modelWordProblems`, applied at `representation.mjs` line 278).
  - `openvaultdb/ovdb`: the latest release is v0.42.0
    (`86c31700875661a011552c7ae28a55cc7a370dd7`), whose package
    `publisher/representation` accepts only the earlier vocabulary. Its separate
    publisher model reader (`internal/publisher/repo`) already reads both (its
    README, line 113). Its pin-chain model reader
    (`publisher/source/pinchain/model.go`) requires `1.0-draft`. A change to
    `publisher/representation` is open as pull request
    [#88](https://github.com/openvaultdb/ovdb/pull/88): not merged, not released,
    head `b7e1c4a7c172f9ceeb97f6482e56200d8a4dc8d3`. It has been reviewed by an
    independent reviewer at `684b0c0` and, in a delta review, at `7f86ee3`; four
    commits follow that second review (`9339b72`, `66772c0`, `b280a82`, `b7e1c4a`)
    and the recorder knows of no review of them. The head and the figure are as of
    the recorder's reading on 2026-10-09 at about 12:14 UTC; the pull request may
    have moved since. It does not touch the pin-chain reader.
  - Until that change is released, a publisher that rewrites a model that its
    contract points at passes the Directory's check and fails `ovdb`'s
    representation check. Recorder's inference from the two code paths above, not
    a run.
- The two contracts that exist, and their registration, are in the Context.
  Because both models are registered, they are among the pins that decision 0022's
  last stage waits for.

## Observed Consequences

None observed yet.

## Affected Features

None at this time.

---
*This document follows the https://specscore.md/decision-specification*
