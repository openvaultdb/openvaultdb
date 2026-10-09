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
- **On record**: what a decision already on record says, with a link.
- **Recorder's account**: what the session writing this file says or infers. It
  is not the owner's ruling, whatever its tone.

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

**On record.** OpenVaultDB's representation contract has three published formats,
`ovdb-representation-contract/1`, `/2` and `/3`. A contract is a JSON file that a
publisher attaches in `ovdb.yaml` as `representation_contract` with the file's
SHA-256. It names, among other things, the ModelSpec model it points at (the
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
points at. The schemas contain the contract's own keys `entity` and `property`
(the names of a record type and of one of its members in the referenced model),
and nothing else about the model's spelling. What fixes the earlier vocabulary today is what the
readers do, not what a format says:

- `openvaultdb/ovdb` v0.42.0, package `publisher/representation`: `contract.go`
  lines 355 to 365, `native.go` lines 53 to 60 and `strict.go` lines 39 to 56
  read a model only if its `modelspec` identifier is `1.0-draft`, and only through
  the keys `entities` and `properties`.
- `openvaultdb/directory` at `ec53d75`: `scripts/lib/representation.mjs` reads a
  model or source schema in either vocabulary (pull request
  [#43](https://github.com/openvaultdb/directory/pull/43), merged 2026-10-09).

**On record.** This specification repository does not contain the text of formats
1 to 3. A search of `spec/` at `6c7e9f162514db9365b1258e16b2a4b84b594955` for
"representation contract", `ovdb-representation`, "frozen" and the format names
found no such text. So this record amends no sentence here; see "What does not
change" for where the format text lives.

**Recorder's account of the problem.** The formats are frozen, and a frozen format
that is silent about the model's vocabulary leaves a question that readers answer
differently (the two implementations above do). The stages of decision 0022 make
it urgent: the last stage makes the earlier spelling an error, and a model that a
contract pins by SHA-256 can then neither stay as it is nor be rewritten without
the contract's pin moving. The question needed one answer for all three formats.

**Recorder's account of the question.** The owner was asked on 2026-10-09, in a
numbered list of four questions, to choose between two courses: amend the frozen
formats on one point only (which ModelSpec vocabularies a contract may point at),
or add a new format. **The exact wording of that question is not preserved.** The
conversation that put it was compacted, and what survives is the putting session's
own paraphrase, written the same day, in a brief to the engineer of the Go change.
That paraphrase said the owner was shown, as an example, a contract's `target`
members (`datatype`, `entity`, `module`, `property`) staying as they are while the
model they point at changes from `entities`/`properties` to `records`/`fields`, and
with it the pinned hash. This record does not reconstruct the question beyond that
paraphrase, and the paraphrase is the recorder's account, not the owner's.

## Decision

**The owner's words.** His answer, 2026-10-09, was the fourth line of a numbered
reply (that this line answers the fourth of the four questions is the recorder's
account, in the session's brief):

> 4 - amend

Those are all the owner's words this record has on the point. He gave no reasons.

**Recorder's reading of the answer** (the reading is the recorder's; the owner has
not been shown this text): the answer chooses to amend over adding a format. The
amendment, on one point only:

> A ModelSpec model or source schema that a representation contract refers to may
> be written in either ModelSpec vocabulary: identifier `1.0-draft` with
> `entities`, `properties` and `entity`, or identifier `1.0-draft-2` with
> `records`, `fields` and `record`.

This holds for formats 1, 2 and 3 (`ovdb-representation-contract/1`, `/2`, `/3`).
Each referenced model is read in the vocabulary its own `modelspec` identifier
names.

The contract's own keys are not part of that vocabulary and do not move. `entity`,
`property`, and every other key a contract has keep their names and their meaning.
In a contract, `entity` names a record type of the referenced model in either
vocabulary, and `property` names a member of it in either.

Before and after, for the GeoNames target model that a contract names (a fragment;
the real model has more members):

```json
{"modelspec": "1.0-draft",
 "module": {"name": "geonames", "version": "0.1.0"},
 "entities": {"geonames_countries": {"key": ["iso"],
   "properties": {"iso": {"type": "string", "required": true}}}}}
```

```json
{"modelspec": "1.0-draft-2",
 "module": {"name": "geonames", "version": "0.1.0"},
 "records": {"geonames_countries": {"key": ["iso"],
   "fields": {"iso": {"type": "string", "required": true}}}}}
```

In the contract that points at either file, these members of `target` are
byte-identical before and after, and so is every other key and value the contract
has except the one named below:

```json
"datatype": "string", "entity": "geonames_countries", "module": "geonames", "property": "iso"
```

The only value in the contract that changes is the pin of the file that was
rewritten: `target.model.sha256` for a target model, `source.schema.sha256` for a
source schema. A rewritten model has new bytes and therefore a new SHA-256. That
is a value inside the contract, not a change to the format. The contract file's
own bytes change with it, so the SHA-256 that `ovdb.yaml` records for the contract
(`representation_contract.sha256`) moves too.

### What does not change

- No contract format changes: the three JSON Schemas, the names of their keys, the
  meaning of every key, and the format identifiers stay as published. No format
  number is introduced; there is no format 4 in this record.
- No contract file needs a new structure. A publisher that does not rewrite its
  model changes nothing.
- An older pin stays valid. A contract that pins a model by SHA-256 keeps pinning
  those bytes, in whichever vocabulary they are. A model that is pinned at an
  older revision of another repository (a source schema, for instance) stays
  readable in the vocabulary it was written in.
- The text of the formats is not in this repository (see Context), so this record
  edits no sentence of the specification. The sentences that describe the formats
  as frozen stay true of the schemas, which do not change. The reader code and its
  README, in `openvaultdb/ovdb` and `openvaultdb/directory`, are those
  repositories' to change, and this record changes none of them.

### Not settled by this record

- When the earlier vocabulary stops being accepted for a model that a contract
  refers to. On record, decision 0022 makes the earlier spelling an error only when
  no registered pin uses it, with an approval of its own. This record neither gives
  that approval nor sets a date for contracts.
- Whether a future format 4 renames the contract's own keys `entity` and
  `property`. This record does not propose it and does not rule it out.
- Whether a model that mixes the two vocabularies is refused. On record, the
  Directory's README (line 138 onward, about a manifest's own model) says the
  identifier decides the vocabulary and a document that mixes the two is refused,
  and the representation check in `scripts/lib/representation.mjs` applies the same
  word check to the models a contract points at (line 278); the publisher model
  reader of `ovdb` v0.42.0 refuses it too (`internal/publisher/repo/README.md`,
  line 337). This record says each model is read in the vocabulary its identifier
  names and adds no rule about mixing.

### Takes effect

Recorder's account, not the owner's. On the owner's approval of this text, as to
the specification. In running software, only when and as each implementation
changes, which this record does not do; see the consequences.

## Rationale

The owner gave no reasons. These are the recorder's.

- The contract's keys and the model's vocabulary are different things: a contract
  is OpenVaultDB's, the model's words are ModelSpec's. Amending only which
  vocabulary the pointed-at model may use leaves every existing contract, schema
  and reader of the contract's own keys as it is.
- A model that a contract pins can move to the current vocabulary under decision
  0022 without a new contract format and without waiting for one.
- Both vocabularies have to stay readable anyway, because older pins of older
  model revisions stay valid for ever (decision 0018: "A commit that is pinned
  today keeps its old spelling and stays readable").

## Declined Alternatives

### Add a new format (format 4) in which a contract points at current-vocabulary models

This was the other course put to the owner, on the recorder's account of the
question. He answered "4 - amend" and did not choose it. The recorder adds what it
would have meant: a new schema and format number, every reader taught a fourth
format, and every publisher that rewrites its model also rewriting its contract
into the new format. This record gives no reason of the owner's for not choosing it.

### Leave the formats silent (not put to the owner)

Recorder's account only: on the recorder's account of the question, this was not a
course the owner was asked to choose. It is listed because it is what the formats
do today, and because it leaves the readers answering differently.

## Consequences at Decision Time

Recorder's account, written on 2026-10-09 from the repositories as they were read
that day. It states what is true then and no more.

- Both vocabularies are permitted for any model or source schema a contract refers
  to, in formats 1, 2 and 3.
- A publisher that rewrites its model gets new model bytes, so it must update
  `target.model.sha256` (or `source.schema.sha256`) in its contract, which changes
  the contract's bytes, so it must update `representation_contract.sha256` in its
  `ovdb.yaml`. Nothing else in the contract has to change.
- A publisher that rewrites a model it does not own cannot. A source schema that
  lives in another publisher's repository is pinned by repository, revision and
  SHA-256; the contract moves to that schema's rewritten revision only when that
  repository has one.
- Readers must read `1.0-draft` for as long as any contract pins a model in it.
- Implementations, as read on 2026-10-09:
  - `openvaultdb/directory`, `main` at `ec53d7539aafd23d006b4943acdd7a31f4eb9340`:
    reads either vocabulary for these models (pull request #43, merged
    2026-10-09T04:44:36Z).
  - `openvaultdb/ovdb`, release v0.42.0 (`86c31700875661a011552c7ae28a55cc7a370dd7`),
    package `publisher/representation`: accepts only the earlier vocabulary. Its
    separate publisher model reader (`internal/publisher/repo`) already reads both
    (its README, line 113). A change to `publisher/representation` is open as pull
    request [#88](https://github.com/openvaultdb/ovdb/pull/88), not merged and not
    released as of this reading.
  - Until that change is released, a publisher that rewrites a model that its
    contract points at passes the Directory's check and fails `ovdb`'s
    representation check. Recorder's inference from the two code paths above, not
    a run.
- Contracts that exist today, read in each publisher's repository on 2026-10-09:
  GeoNames ([`ingitdb/geo-ingitdb`](https://github.com/ingitdb/geo-ingitdb), commit
  `5653b130fc30e5a597750db7cafa3039b7280ed1`, format 2, four contracts) and ROR
  ([`ingitdb/ror-ingitdb`](https://github.com/ingitdb/ror-ingitdb), commit
  `7ef2e98f80ab148d694a534992719499d4c9e607`, format 3, one contract). Both models
  are still `1.0-draft`. Neither is a database record in `openvaultdb/directory`
  today: the Directory's six database records (`databases/`) carry no
  `representation_contract`, and the `index.json` at `ec53d75` has none.

## Observed Consequences

None observed yet.

## Affected Features

None at this time.

---
*This document follows the https://specscore.md/decision-specification*
