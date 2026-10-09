---
format: https://specscore.md/decision-specification
status: In Review
---

# Decision: A publisher manifest maps record types and fields in its list of recordsets

**Status:** In Review
**Date:** 2026-10-09
**Owner:** alex
**Tags:** publisher-manifest,modelspec,mapping,format
**Source Idea:** —
**Supersedes:** —
**Superseded By:** —

## Context

How to read this record. Three kinds of statement appear in it, and each is
labelled:

- **The owner's words**, quoted exactly with their date and time.
- **On record**: what a message, a decision or a file already on record says, with
  a link or a place to find it. Where the source is not published, so that a reader
  cannot open it, the text says "not published".
- **Recorder's account**: what the session writing this file says or infers. It
  is not the owner's ruling, whatever its tone.

Times are UTC. For every message quoted here the owner's local date is the same as
the UTC date. A quotation set off as a block is exact, character for character.
Where a block shows several plain lines inside a `text` fence, the fence is the
recorder's and the lines are the source's.

Five terms keep one meaning each. A **publisher manifest**, or manifest, is the file
a publisher's repository offers to the Directory, usually `ovdb.yaml`. A
**recordset** is a table or collection of one database, under the name the database
uses for it. A **column** is a member of a recordset, under the database's name for
it. A **record type** is a structure declared in a ModelSpec model, and a **field**
is a member of a record type; earlier ModelSpec drafts called them an entity and a
property.

Four writers are named below, and none of them is the owner. The **proposal's
author** is the assistant session that wrote the design proposal with the owner on
8 October 2026 and put its questions to him. The **coordinating session** is the
assistant session that was working for the owner on 9 October 2026. The
**contract's author** is the session that wrote a working contract for the
implementers of this change (not published). The **recorder** is the session
writing this file.

**On record, the manifest today.** The Directory's README describes the manifest
([`openvaultdb/directory`](https://github.com/openvaultdb/directory), `README.md`
at commit `2ed201d940f47df5b763ef94bc53d23573b69562`). Its format is
`ovdb-manifest/draft-1` (line 106). Among the things a manifest declares it lists
the "`recordsets` and optional `recordset_entities` mapping" (line 116), and it
says of the second (line 174): "`recordset_entities` maps native collection names to ModelSpec entity names.
Names not listed in the mapping keep the existing same-name behavior." So today a
manifest names each recordset in one list, and pairs a recordset with a record type
of another name in a second list at the end of the file. The example is made up for
this record, with made-up names; it is not the README's own:

```yaml
format: ovdb-manifest/draft-1
recordsets:
  - Customer
  - Order Lines
recordset_entities:
  Order Lines: OrderLine
```

The README describes no way for a manifest to say that a column and its field have
different names.

**On record, the proposal.** The questions recorded here were put to the owner as
decision D5 of the conceptual design proposal for ModelSpec, the proposal that
ModelSpec's decisions
[0018](https://github.com/specscore/modelspec/blob/9212dacc606cfcb7e131c67680fe1c1ec3c08f28/spec/decisions/0018-entity-becomes-record.md),
[0019](https://github.com/specscore/modelspec/blob/9212dacc606cfcb7e131c67680fe1c1ec3c08f28/spec/decisions/0019-collection-and-recordset-removed-three-words-reserved.md)
and
[0020](https://github.com/specscore/modelspec/blob/9212dacc606cfcb7e131c67680fe1c1ec3c08f28/spec/decisions/0020-field-is-the-member-word.md)
also record (each ModelSpec decision is linked in this record at commit `9212dac`,
where it was read). The proposal is not published. It exists in a first version,
dated 8 October 2026, and in a second version, dated 9 October 2026 and called
revision 2 here, which records the owner's answers. The session records quoted below
are not published either.

### Decision D5 as first put, and his rejection

**On record, the first form** (the first version of the proposal, not published).
D5 was headed "Foundation, three parts" and read, exactly:

> a. The mapping from a real table to a record type is written in OVDB's grammar, as record_type: and columns: in the publisher's manifest, replacing recordset_entities. b. A database that is not listed carries the same mapping in a source file inside the DataTug project. c. Where OpenVaultDB itself creates a store, the fields and references in its server manifest are generated from the model instead of typed; for an HTTP source, its three fields are.

Under it the proposal said what an approval would authorise:

> Approval authorises: part a, the manifest format change in Phase 3. Part b, a specification for the project's source file; building it is Phase 4. Part c, writing a change proposal for the server, and nothing else: no phase in section 14 changes the server.

Each part offered three answers. Recorder's reading of the stored text, which runs
the three together without spaces: for part a, Approve, Change or Reject; for part
b, Approve, Another home or Reject; for part c, Write the proposal, Change or Leave
the server as it is.

**The owner's words**, 2026-10-08 at 21:18 UTC, the four lines about D5 in the sheet
of answers he sent to the proposal's author:

> ```text
> D5a: Reject
>   note on D5: It's too much theory without example. Need split up and some examples for each item.
> D5b: Reject
> D5c: Write the proposal
> ```

### The three questions put again, and his answers

**On record, the questions as put again** (the stored record of the proposal
author's session, not published). On 2026-10-08 at 21:22 UTC, in its reply to that
sheet, the proposal's author put D5 again under the heading "D5 again, split, with
an example each". The text under that heading is quoted exactly below, up to the
message's closing paragraph. That paragraph, two sentences, is left out: it says
that other work had not started and when the proposal's document would be revised,
and it puts no question about D5.

> **Q1. One line per table in a public database's manifest.** Northwind's `Order Details` table today:
>
> ```yaml
> recordsets: [Customers, Order Details]
> recordset_entities:
>   Order Details: OrderDetails
> ```
>
> Proposed:
>
> ```yaml
> recordsets:
>   - Customers
>   - name: Order Details
>     record_type: OrderDetails
> ```
>
> **Q2. Columns whose names differ from the field.** Nothing can say this today. Proposed, as a made-up example:
>
> ```yaml
>   - name: users
>     record_type: User
>     columns:
>       email_address: email
> ```
>
> **Q3. A private database.** The manifest requires a public address, so an internal database has nowhere to write Q1 or Q2. Proposed: the same lines in a file inside the DataTug project:
>
> ```yaml
> id: payments
> model: { hcl: model/payments.modelspec.hcl }
> recordsets:
>   - name: payments
>     record_type: Payment
>     columns: { order_ref: OrderId }
> ```
>
> My opinion: Q3 matters most because it unblocks three phases, and Q2 is next. Q1 is mostly a rename and could be dropped.

**The owner's words**, 2026-10-08 at 21:34 UTC, one message, in full:

> Q1 - approved.
>
> Q2 - how about making it more expandable in future by using column attributes, something like
>
>
> ```
>   - name: users
>     record_type: User
>     columns:
>       email_address:
>         meaning: Contact.Email
>         # We can extend column with additional props, like
>         value_regex_pattern: \w+@acme.com
> ```
>
>
> Q3 - approved

**On record, the proposal author's reply**, 2026-10-08 at 21:35 UTC (the same
record). It opened, exactly:

> Yes to the shape. I would change one key and add two rules about what goes in it.
>
> **The shape.** A column takes a map so it can grow, and the bare string stays as a short form:
>
> ```yaml
> columns:
>   order_ref: OrderId             # short form
>   email_address:                 # long form, same thing plus room to grow
>     field: Contact.Email
> ```

Further on, the same message said of the key: "`Contact.Email` still works as
written: it is a path into a component of the record type." Of the second key in his
example it said: "I would use the same key name, `pattern`, on the column." And it
said: "So the first version has `field` only, `pattern` is the first candidate, and
an unknown key is an error so that typos are caught."

**The owner's words**, 2026-10-08 at 21:36 UTC, one message, in full:

> approved the "field" attribute of a column

**On record**, 2026-10-08 at 21:37 UTC, the proposal's author answered: "Recorded: a
column takes a map with `field:`."

**On record, the card as the proposal's revision 2 keeps it** (not published). It
was written after the answers above and describes them, so it is the proposal
author's record of the exchange and not the wording he answered. The stored copy is
plain text that has lost the indentation of its examples; the code fences below are
the recorder's, and the characters inside them are the copy's.

The card is quoted in part. Quoted, in the card's order: its note on the rejection,
questions 1 to 3 with their examples, the line on what his approvals authorise, and
the line that records his answers. Left out: the card's heading, the one line that
states its subject, its paragraph on part c, which stands between question 3 and the
line on what his approvals authorise, and the rows of answers offered at its end.

> You rejected parts a and b with this note: "It's too much theory without example. Need split up and some examples for each item." They are split below, each with its example. Section 8 has the rules in full.

> Question 1. In a public database's manifest, one line in the list of recordsets ties a table to its record type. It replaces the separate list recordset_entities. Northwind:
>
> ```text
> recordsets:
>  - Customers
>  - name: Order Details
>  record_type: OrderDetails
> ```

> Question 2. A column whose name differs from its field is listed under the recordset. It is written bare, or as a small map so that more can be said about the column later. The map was your suggestion; the key field: was mine, and it is what you approved. Keeping the short form beside the map, and the rules in section 8 for what may go in it, are my recommendation and were not part of your one-line approval.
>
> ```text
>  columns:
>  created: CreatedAt
>  email_address:
>  field: Contact.Email
> ```

> Question 3. A database with no public address cannot have a publisher's manifest. It carries the same lines in a source file inside the DataTug project.
>
> ```text
> id: payments
> model: { hcl: model/payments.modelspec.hcl }
> recordsets:
>  - name: payments
>  record_type: Payment
>  columns: { order_ref: OrderId }
> ```

> Your approvals authorise: questions 1 and 2, the manifest format change in Phase 3. Question 3, a specification for the project's source file; building it is Phase 4. Part c, writing a change proposal for the server, and nothing else: no phase in section 14 changes the server.

> Your answers, 8 October 2026. Parts a and b: Reject. Then question 1: "approved". Question 2: approved the "field" attribute of a column. Question 3: "approved". Part c: Write the proposal.

**Recorder's account of the questions and the answers.**

- The first form of D5 carried no example. He rejected parts a and b with a note
  about the form of the question, and answered part c "Write the proposal". The
  three questions with examples followed at 21:22 UTC. Part c was not put
  again; his answer to it is the one in the sheet.
- Question 1 was put with a two-recordset cut of Northwind's manifest. The example
  had no `format` line, and no question of 8 October named a format identifier for
  the manifest.
- Question 2 was put with the column written as a bare string
  (`email_address: email`). He did not approve that form. He proposed a map of
  column attributes, with his own key `meaning` and a second key
  `value_regex_pattern` given as an illustration ("# We can extend column with
  additional props, like"). The proposal's author then showed the bare string and
  the map side by side and asked for the key `field` in place of `meaning`. His
  reply names the key. So his words cover a column written as a map with `field`.
  They say neither yes nor no to the bare string as a short form, to the rules for
  what a map may hold, or to reading `Contact.Email` as a path into a component.
  The card says the same of itself: "Keeping the short form beside the map, and the
  rules in section 8 for what may go in it, are my recommendation and were not part
  of your one-line approval."
- Question 3 concerned a file inside a DataTug project, not a publisher manifest.
  The example he approved for it writes its column as a bare string.
- The card records his answers to questions 1 and 3 as "approved". His message of
  21:34 UTC reads "Q1 - approved." and "Q3 - approved".

### The manifest's format line: the question, and his answers

The questions of 8 October quoted above did not ask the owner what a manifest
written in the new way should say in its `format` line. The coordinating session
put that question on 9 October. The messages below are read from that session's
stored record (not published).

**On record, the question as first put**, 2026-10-09 at 09:39 UTC, in a message that
also showed Northwind's manifest before and after. The question was headed
"Question: what should the first line of a converted manifest say?", and its three
options were, exactly:

> - **Option 1: a new identifier, `ovdb-manifest/draft-2`.** Recommended by the contract's author, and I agree.
>   - The first line then tells every reader which form the file holds, as `1.0-draft-2` does for a model.
>   - Two identifiers exist from then on.
>   - The proposal you answered on 8 October said "New keys in ovdb-manifest/draft-1 need a new identifier", though in a list of things not yet settled.
> - **Option 2: keep `draft-1`; readers tell the form by its shape.**
>   - No first line changes anywhere.
>   - One string then names two shapes, and an older program fails on the table list with a message that does not tell a publisher what is wrong.
> - **Option 3: another new string that you name.** Everything else is as option 1.

The same message told him of one choice the coordinating session was taking
(recorded below as N21), exactly:

> **One follow-on choice I am taking, which you can overrule.** The contract's author had the shared generator write `draft-2` for Pubs, Employees and Sakila too, although they map nothing. The runs show the three programs above would then refuse those three databases until each is upgraded, for no benefit. I will have the generator write the new identifier only where the new form is actually used, so those three keep passing every reader.

**On record, the question listed by name only.** At 11:52 UTC a list headed "Waiting
on you" had as its fourth line: "4. The manifest's first line." **The owner's
words**, 2026-10-09 at 11:58 UTC, the fourth line of his five-line reply:

> 4 what?

**On record, the question restated with its three options**, 2026-10-09 at 12:01
UTC. The message said "Items 3 and 4 were my fault for burying them; here they are
again in short." Its section on the manifest was headed "4. OpenVaultDB manifest:
one question" and read, in full and exactly:

> Background: on 8 October you approved moving the table-to-record-type mapping onto each table's own line. Real example, Northwind's `ovdb.yaml`:
>
> ```yaml
> # today
>   - Order Details
> recordset_entities:
>   Order Details: OrderDetails
>
> # after
>   - name: Order Details
>     record_type: OrderDetails
> ```
>
> **What should the format line at the top of such a converted file say?**
>
> - **1: `format: ovdb-manifest/draft-2`** (my recommendation): the line tells every program which shape the file has.
> - **2: keep `format: ovdb-manifest/draft-1`**: programs work out the shape from the content.
> - **3: another name you choose.**
>
> Neither 3 nor 4 blocks today's work. They gate the next block.

At 12:46 UTC a later message listed the question as still open, with two questions
about another format:

> 3. **The three format questions** I restated after your "What 2 questions?" and "4 what?" are still open:
>    - whether `meaning/draft-2` may be published with the listed names;
>    - when the seven graphs are converted;
>    - the converted manifest's format line.

**On record, the line he answered**, 2026-10-09 at 13:39 UTC. The coordinating
session's list of things waiting on him, introduced by "Everything I can do without
you is now done or landed; the rest waits on your answers:", had as its fifth line,
exactly:

> 5. **The three format questions**: whether `meaning/draft-2` may be published with the listed names, when the seven graphs are converted, and the converted manifest's format line.

**The owner's words**, 2026-10-09 at 15:21 UTC, the last line of a four-line message
that answers that list by number:

> 5 - ok

(Its other three lines answer items 2, 3 and 4 of the list and are not part of this
decision.)

**On record, the reading put back to him**, 2026-10-09 at 15:28 UTC, exactly:

> **How I read your "5 - ok"**
>
> I take it as the recommended option on each of the three format questions:
> - `meaning/draft-2` may be published with the names as listed.
> - The core graph is converted first, then each of the six dataset graphs, one pull request each.
> - A converted manifest's format line is `ovdb-manifest/draft-2`.
>
> Say so if you meant something else. I am starting the reader-side work now; nothing that publishes either format name lands before your next message.

and again at 15:32 UTC, as the second of two points headed "Open with you:",
exactly:

> 2. **My reading of "5 - ok"**: the names as listed, the core graph then the six dataset graphs, and `ovdb-manifest/draft-2`. A word from you that this is right lets the three pieces above land once reviewed.

**On record, one more message before his reply**, 2026-10-09 at 15:38 UTC. The
coordinating session reported another matter, said of this record "It lands only
after you confirm my reading of "5 - ok".", and closed by naming the same two open
points again, in the same order and without numbers: the other matter first, then
"that reading".

**The owner's words**, 2026-10-09 at 15:43 UTC, the second line of a two-line
message. It follows the list of 15:32 UTC and the message of 15:38 UTC, and its
numbers are those of the list:

> 2 - correct

(Its first line answers the first point, which concerns another matter.)

**Recorder's account of this question and these answers.**

- The line he answered with "5 - ok" did not restate the options. It named three
  questions in one line, two of them about the `meaning/draft-2` format of
  MeaningGraph, which is not this repository's. The options for the manifest had
  been put to him twice that day, at 09:39 UTC and at 12:01 UTC, each time with
  `ovdb-manifest/draft-2` as the first option and the session's recommendation.
- "5 - ok" does not itself name an option. Taking it as the recommended option was
  the coordinating session's reading, and the session said so to him.
- His "2 - correct" follows both the numbered list of 15:32 UTC and the message of
  15:38 UTC. The list is the last numbered one put to him, and the later message
  names the same two points in the same order, so the recorder takes his "2" as the
  second point, the reading.
- His "2 - correct" confirms that reading. The point he confirmed names the string
  `ovdb-manifest/draft-2`. So the identifier rests on the reading he confirmed and
  no longer on the reading alone. He has not written the string himself.
- Neither answer is approval of this text (see "His approval of this text").

## Decision

**The owner's words.** These are all the words of his that this record rests on,
each quoted in its place in the Context:

| What was put to him | His words | When (UTC) |
|---|---|---|
| D5 parts a and b, first form | "D5a: Reject", "D5b: Reject", with the note "It's too much theory without example. Need split up and some examples for each item." | 2026-10-08, 21:18 |
| D5 part c, first form | "D5c: Write the proposal" | 2026-10-08, 21:18 |
| Question 1: one line per recordset | "Q1 - approved." | 2026-10-08, 21:34 |
| Question 2: columns whose names differ | "Q2 - how about making it more expandable in future by using column attributes, something like", with his example; then, of the proposal author's counter-proposal, `approved the "field" attribute of a column` | 2026-10-08, 21:34 and 21:36 |
| Question 3: a database with no public address | "Q3 - approved" | 2026-10-08, 21:34 |
| The three format questions, in one line | "5 - ok" | 2026-10-09, 15:21 |
| The coordinating session's reading of "5 - ok" | "2 - correct" | 2026-10-09, 15:43 |

### What a manifest says after this decision

**Recorder's statement of what those answers decide.** The owner had not been shown
this text when it was written.

1. An item of `recordsets` is a recordset's name, as today, or a map. In a map the
   key `name` holds the recordset's own name and the key `record_type` names the
   record type its rows have. This replaces the separate list `recordset_entities`.
   (Question 1, "Q1 - approved.")
2. A column whose name differs from its field is listed under its recordset, in a
   map `columns`. A column there is written as a map, and its key `field` names the
   field. (Question 2: the map was his suggestion, and `field` is the key he
   approved.)
3. A manifest written in this way says `format: ovdb-manifest/draft-2`. (His "5 -
   ok", in the reading he confirmed with "2 - correct".)

The same manifest before and after, with made-up names:

```yaml
# before
format: ovdb-manifest/draft-1
recordsets:
  - Customer
  - Order Lines
recordset_entities:
  Order Lines: OrderLine
```

```yaml
# after
format: ovdb-manifest/draft-2
recordsets:
  - Customer                  # a name alone: the record type of the same name
  - name: Order Lines         # a map: the recordset's own name,
    record_type: OrderLine    #        the record type its rows have,
    columns:                  #        and the columns whose names differ
      created:                # a column is a map
        field: CreatedAt      #        whose key field names the field
```

Everything this section states beyond those three points is in the recorder's notes
below and is not his ruling.

### Recorder's notes: choices that are not the owner's ruling

The proposal left points open, and the work that follows this decision had to
settle them. Each is listed here under the name of whoever chose. None is the
owner's ruling. "N" numbers are the working contract's (not published) and are kept
so that later records can refer to them. N1, the string of the format identifier,
was in that list as the one point put to the owner; his answers on it are in the
Context.

Five notes come first, because a reader could most easily mistake them for his
answer.

**N5. A column is written as a map only, for now. The coordinating session's
decision of 9 October 2026, not the owner's.** A bare string in a column's place,
such as `created: CreatedAt`, is refused. The proposal's author recommended allowing
both forms, and the card of revision 2 shows both. The coordinating session set that
recommendation aside for now: the map is the form his words cover, and allowing the
bare string on a later day is an addition that makes no existing manifest invalid,
while a bare string that a published manifest uses could not be withdrawn. The
exchange this rests on is quoted in the Context (21:22 to 21:37 UTC on 8 October).
The bare string falls due again when the file of question 3 is specified, because
the example he approved for that file is written with it, or when a second column
needs a line, whichever comes first.

**N6. A column's map holds the key `field` and no other; any other key is refused.
The proposal author's recommendation, followed by the contract's author, not the
owner's ruling.** One consequence should be seen. The owner's own example of the map
carried a second key, `value_regex_pattern`. A reader built this way refuses that
key until a check that reads it exists. The name `pattern` for it is the proposal
author's, not his. Adding a key later is an addition; refusing one now binds no
published manifest.

**N17. How long `recordset_entities` is read, and whether making it an error needs
an approval of its own. The contract's author's choice, not the owner's ruling.**
The key goes on being read, with a notice, until no record of the Directory pins a
manifest that has it, a search finds none elsewhere, and the owner has approved the
step. The proposal asks for a separate approval before ModelSpec's earlier spelling
becomes an error; applying that to this manifest key is the contract author's
choice. On record, ModelSpec's decision
[0022](https://github.com/specscore/modelspec/blob/9212dacc606cfcb7e131c67680fe1c1ec3c08f28/spec/decisions/0022-prose-now-format-change-on-the-owners-word.md)
quotes the owner on 2026-10-09: "yes, you can and should make the old spelling an
error". That was said about ModelSpec's spelling. Whether it covers this key is not
known, and this record does not give that approval.

**N21. Which identifier a generated manifest carries when its database maps nothing.
The coordinating session's choice, told to the owner as one he can overrule.** Three
listed manifests (those of Pubs, Employees and Sakila) pair no recordset with a
record type of another name, and a shared generator writes them. The contract's
author had the generator write `ovdb-manifest/draft-2` for them too. The
coordinating session chose otherwise and said so in its message of 09:39 UTC, quoted
in the Context: the new identifier is written only where the new form is used. The
owner has not answered on this point in words.

**N37. Whether the generator still writes an empty `recordset_entities`. The
contract's author's choice: it stops.** With N21 as the coordinating session took
it, this is a separate choice: the generator could go on writing the empty key, and
those three manifests would then not change at all. The recorder found no statement
by the coordinating session on it.

The other points, in the contract's order. The two middle columns restate the
working contract and the decision packet drawn from it; the recorder did not derive
them again from the code.

| # | The point | What is taken | Whose choice |
|---|---|---|---|
| N2 | A manifest that holds both `recordset_entities` and a map item, or whose format line and contents disagree. | Refused, even when the two say the same. | The contract's author. |
| N3 | A `draft-1` manifest with no `recordset_entities`, such as Chinook's. | It stays valid, draws no notice and is not edited. `ovdb-manifest/draft-1` is not retired by this change. | The contract's author. |
| N4 | A `draft-1` manifest that has `recordset_entities`, even an empty one. | Accepted, with a notice that names the key. A notice changes no verdict. | The contract's author. |
| N7 | Whether `field` may be left out of a column's map. | No. An empty map is refused. | The contract's author, from the proposal's text. |
| N8 | An unknown key in a recordset's map, such as a mistyped `columns`. | Refused. The three keys read are `name`, `record_type` and `columns`. | The contract's author. |
| N9 | Four ways of writing more than is needed: a map with `name` alone; `record_type` equal to `name`; a column listed with the field of its own name; an empty `columns`. | Accepted, without a notice. Once a released reader accepts them and a publisher writes one, refusing it later would refuse a published manifest. | The contract's author. |
| N10 | What a valid column name is. | The rule a recordset's name has today. It can be widened later; narrowing it later would refuse a name a publisher may have written. | The contract's author. |
| N11 | How a dotted value of `field`, such as `Contact.Email`, is written and read. | Names joined by single dots. A malformed value is refused from the manifest's text alone; a well-formed one that names no field of the record type is refused when the model is read. Resolving a path through a component is not due: neither checker reads a component today. | The contract's author. `Contact.Email` was the owner's own example value, under his key `meaning`; reading it as a path into a component is the proposal author's (21:35 UTC). |
| N12 | Two columns of one recordset holding one field, or a column taking the name of another field. | Refused. | The contract's author. |
| N13 | Database engines that fold the case of names. | No folding rule; names are matched exactly. Not due until such a database is listed. | The contract's author. |
| N14 | In the Directory's `index.json`, which name an item carries when a column and its field differ. | `name` keeps the column's name. A new key `modelField` holds the field, written only where the two differ. It becomes public the day a converted manifest lists a column and its pin moves. | The contract's author. |
| N15 | How a column mapped into a component appears in the index. | Not due; decided with N11's second half. | The contract's author. |
| N16 | The index's own format identifier. | It stays `ovdb-directory/draft-1`. | The contract's author; the coordinating session's brief for the index has the same rule. |
| N18 | The key `modelEntity` in the descriptor file `ovdb-database.json`. | It stays. Not due until that format is next revised. | The contract's author. |
| N19 | Keys named after "entity" inside the demo databases' own tooling. | They stay. | The contract's author. |
| N20 | `columns` on a recordset that an HTTP source definition or a representation contract already describes. | Refused. The contract's author wrote the rule while the reader of representation contracts was being changed, and meant it to be read again against the changed reader. That reader is `openvaultdb/ovdb` at commit `e2e959f1836cc456462cf10babfd7284010ecbc9` (pull request #88, tagged v0.43.0), under [decision 0011](0011-representation-contracts-may-point-at-a-model-in-either-modelspec-vocabulary.md) as it stands at commit `874cf42d1df26847a264bee13e64b62741d713bd` of this repository. This record does not check the rule against the reader at that commit. | The contract's author. |
| N22 | How `ovdb publisher check` reports the notice of N4. | In a new list `notices` of its output; `findings`, `ok` and the exit status are untouched. Fixed from the release that carries it. | The contract's author. |
| N23 | The names of the new findings of `ovdb publisher check`. | `manifest-columns`, `repo-columns` and, for the notice, `manifest-deprecated`. Fixed from the same release. | The contract's author. |
| N24 | Where the shared test cases live. | One file in the Directory, copied into the Go check's reference files. | The contract's author. |
| N25 | Comparing a listed column with the descriptor's list of columns. | Not in this change. Not due. | The contract's author. |
| N26 | The third checker, in `demo-db/chinook`. | It learns both forms before `ovdb publisher check` does. | The contract's author. |
| N27 | The manifest reader in `openvaultdb/cloud`. | It learns both forms before a hosted provider is prepared from a manifest in the new form. Not due: no provider uses it today. | The contract's author. |
| N28 | Where the manifest format is written down. | In this record and in the Directory's README. | The contract's author. |
| N29 | A command that rewrites a manifest from the old form to the new. | None. | The contract's author. |
| N30 | The rules for the values of `name` and `record_type`, and that a name is listed once. | Today's rules for a recordset's name and for a value of `recordset_entities`, unchanged. | The contract's author. |
| N31 | At which stage of a check each new rule runs. | Everything that needs no model is checked before the model is read. | The contract's author. |
| N32 | At which stage a `draft-1` manifest with one record type on two recordsets is refused. | Where it is refused today. | The contract's author. |
| N33 | A program that reads a manifest without checking it, meeting a mixed or unknown form. | It stops with an error. | The contract's author. |
| N34 | A Directory index that carries both the earlier and the current record-type key, with different values. | The current key wins. | The contract's author, following the consumers' code. |
| N35 | How much of this specification's prose about a ModelSpec "projection" is corrected alongside. | One file is named by the proposal; four more are the contract author's survey. None is corrected in the change that adds this record (see "Known and not done here"). | The contract's author for the list; the coordinating session for leaving it out of this change. |
| N36 | What this record holds. | His whole answer on D5, all four parts, and the choices above under their makers' names. | The contract's author. |

Six points the proposal leaves open are not taken up at all. None is due. They are
given in the recorder's words, not the proposal's:

- a reference to a key of several fields;
- a shared mapping file for databases with the same unusual names;
- keys of a column's map beyond `field` (N6 says what a reader does until then);
- checking a manifest against the live database;
- how a DataTug project reads this mapping, and DataTug as a later writer of
  manifests;
- the bare string as a short form of a column (N5).

### What this record records and this change does not build

Recorder's account, except the words quoted as his and the sentences marked "On
record". He answered all four parts of D5. Two of the answers start no work on a
publisher manifest, and they are recorded here so that a file holds them.

- **Question 3**, answered "Q3 - approved": a database with no public address
  carries the same lines in a source file inside the DataTug project. On record, the
  card says what the approval authorises: "Question 3, a specification for the
  project's source file; building it is Phase 4." That is a specification for
  DataTug. It is not written by this change, and nothing of it is built.
- **Part c**, answered "D5c: Write the proposal": where OpenVaultDB itself creates a
  store, the fields and references in its server manifest would be generated from
  the model. On record, the first form and the card both limit the answer: "Part c,
  writing a change proposal for the server, and nothing else: no phase in section 14
  changes the server." That proposal is not written by this change, and the server
  does not change.

### Known and not done here

Recorder's account. Outside this record and its row in the index, a search of `spec/`
at the commit named below for `ovdb-manifest`, `recordset_entities` and the words
"publisher manifest" finds nothing: the specification does not describe the
manifest. It does contain an older picture, in which an application
writes a ModelSpec "projection" to suggest where its data should be stored.
ModelSpec's decision
[0019](https://github.com/specscore/modelspec/blob/9212dacc606cfcb7e131c67680fe1c1ec3c08f28/spec/decisions/0019-collection-and-recordset-removed-three-words-reserved.md)
made `projection` a reserved word with no content, so a model can no longer carry
one. The sentences below are known to need correcting. The change that adds this
record corrects none of them. Lines are as read at commit
`874cf42d1df26847a264bee13e64b62741d713bd`.

| File and line | What is there |
|---|---|
| `spec/schema/modelspec-integration.md`, line 58 | The artifact for "Optional backend mapping suggestion" is "Advisory ModelSpec projection". This is the one phrase the proposal names for correction (the recorder's summary of the proposal, not a quotation from it). |
| The same file, lines 16 and 17 | "Projection" is defined as a mapping from a logical ModelSpec model, and "Advisory mapping hint" as a projection suggestion that an application provides. |
| The same file, line 27 | OpenVaultDB "MAY accept app-provided ModelSpec projection hints". |
| The same file, line 89 | "Treating projection hints as authoritative would move storage decisions back into applications." |
| The same file, line 13 | The identifier `1.0-draft`; ModelSpec's current identifier is `1.0-draft-2`. This belongs to the rename, not to the mapping. |
| `spec/schema/schema-model.md`, line 10 | A collection is "bound to a ModelSpec entity or projection". |
| `spec/storage/storage-backends.md`, lines 10 and 18 | "ModelSpec projection" as a term, and "vault-approved projections from ModelSpec". |
| `spec/glossary.md`, line 21 | "Projection" is defined as a mapping from a logical ModelSpec model. |
| `spec/graph/modules/schema/entities/projection.md`, lines 6, 15 and 16 | `model: modelspec:///schema.Projection`, and "App-provided projection hints are advisory and non-authoritative." |

The first row is the one the proposal names; the other eight are the contract
author's survey (N35). Lines 44 and 60 of `spec/schema/modelspec-integration.md`
speak of the vault's own "backend projection" and "Projection plan"; they describe
what the vault does and are not made false by decision 0019.

### Takes effect

Recorder's account, not the owner's. As to the specification, once the owner
approves this text. In running software, only when and as each program changes,
which this record does not do. The order the contract plans: the programs that read
a manifest learn both forms first; then the programs that write one; then the
manifests are converted and the Directory's pins moved. Until a reader has learned
the new form it refuses a manifest written in it (see the consequences).

### His approval of this text

Recorder's account. None of his answers above is approval of this text: not "Q1 -
approved." or the others of 8 October, and not "5 - ok" or "2 - correct". He has not
been shown this file. Its status is In Review until he approves the text or says
what to change.

## Rationale

The owner gave two reasons, both quoted in the Context. Of the first form of the
question: "It's too much theory without example. Need split up and some examples for
each item." Of the column: "how about making it more expandable in future by using
column attributes". He gave no reason for "Q1 - approved.", "Q3 - approved", "5 -
ok" or "2 - correct".

The following are not his.

- The proposal's author, in the questions he answered: a manifest cannot say today
  that a column and its field have different names ("Nothing can say this today.");
  and a manifest requires a public address, "so an internal database has nowhere to
  write Q1 or Q2".
- The proposal's author, for the key `field` in place of his `meaning` (21:35 UTC):
  a column maps to a field, and the field's meaning is stated once, in MeaningGraph.
- The coordinating session, for a new identifier (12:01 UTC): "the line tells every
  program which shape the file has."
- The recorder: the mapping moves to the line of the recordset it concerns, so a
  reader of the manifest finds a recordset's record type and its differing columns
  in one place, and the key says "record type", the word ModelSpec now uses
  (decision
  [0018](https://github.com/specscore/modelspec/blob/9212dacc606cfcb7e131c67680fe1c1ec3c08f28/spec/decisions/0018-entity-becomes-record.md)
  reports that "the proposal has OpenVaultDB's files spell their mapping key
  `record_type` once that format changes").

## Declined Alternatives

### D5 in its first form, three parts without an example

On record, he rejected parts a and b as put ("D5a: Reject", "D5b: Reject") with the
note quoted above. Recorder's account: the note is about the form of the question.
The content of part a came back as questions 1 and 2, and of part b as question 3,
each with an example. He approved questions 1 and 3 as put ("Q1 - approved.", "Q3 -
approved"). He did not approve question 2 as put, with the column as a bare string:
he answered it with a map of his own ("Q2 - how about making it more expandable in
future by using column attributes, something like") and then approved the key
(`approved the "field" attribute of a column`).

### A column written as a bare string only

On record, this is how question 2 was first put (`email_address: email`). He
answered with a map instead. Whether a bare string is also allowed beside the map
was not answered by him (N5).

### The key `meaning` on a column

On record, his own example used `meaning: Contact.Email`. The proposal's author
asked for `field` instead, and he answered `approved the "field" attribute of a
column`.

### Keep `ovdb-manifest/draft-1` for the new form

On record, this was the second option put to him: "**2: keep `format: ovdb-manifest/draft-1`**:
programs work out the shape from the content." He confirmed
the reading that takes the first option.

### Another identifier of his choosing

On record, this was the third option: "**3: another name you choose.**" He named
none.

## Consequences at Decision Time

Recorder's account, written on 2026-10-09 from the public repositories as they were
read that day. It states what is true then and no more.

- A manifest in the new form says `format: ovdb-manifest/draft-2`. A manifest that
  says `ovdb-manifest/draft-1` stays valid, by N3, which is the contract author's
  choice; whether one that still holds `recordset_entities` draws a notice, and when
  that key stops being read, are N4 and N17.
- Nothing of the new form is on the Directory's `main`. Its checker
  ([`openvaultdb/directory`](https://github.com/openvaultdb/directory) at
  `2ed201d`, `scripts/lib/directory.mjs`) requires the format line to be
  `ovdb-manifest/draft-1` (lines 24 and 208) and `recordsets` to be a list of names
  (line 267). So it refuses a manifest written in the new form until it has learned
  that form. This is read from the code, not from a run. The recorder did not read
  the other programs that check a manifest.
- The Directory lists six databases (`databases/$records/` at `2ed201d`). Their
  manifests, each read at the head of its repository's `main`, all say
  `ovdb-manifest/draft-1`:

  | Repository | Commit | Recordsets | Pairs in `recordset_entities` |
  |---|---|---|---|
  | `demo-db/adventureworks` | `c91e06e` | 71 | 71 |
  | `demo-db/northwind` | `c07b466` | 13 | 1 |
  | `demo-db/pubs` | `e99ca33` | 11 | none; the key is present and empty |
  | `demo-db/employees` | `add7744` | 6 | none; the key is present and empty |
  | `demo-db/sakila` | `113e54a` | 16 | none; the key is present and empty |
  | `demo-db/chinook` | `3e7bb31` | 11 | the key is absent |

  So two manifests carry the 72 pairs that become `record_type` lines; three hold
  only an empty key and change or not by N21 and N37; Chinook's does not change.
- One column is known whose name differs from its field: in
  `demo-db/adventureworks` at `c91e06e` the descriptor `ovdb-database.json` has the
  column `Database Version` (line 376) and the model
  `model/adventureworks.modelspec.json` has the field `Database_Version` (line
  2308). The recorder did not count the columns of the six databases.
- A publisher who writes a column by the new form writes a map with `field`. A
  reader built to the notes above refuses any other key in that map, the owner's
  example key included (N6).
- Question 3 and part c each wait for a document that does not exist yet: a
  specification for DataTug, and a change proposal for the server.

## Observed Consequences

None observed yet.

## Affected Features

None at this time.

---
*This document follows the https://specscore.md/decision-specification*
