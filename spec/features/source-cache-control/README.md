---
format: https://specscore.md/feature-specification
status: Draft
---

# Feature: Cache-Control hint for directly read sources

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/source-cache-control?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/source-cache-control?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/source-cache-control?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/source-cache-control?op=request-change) |
**Status:** Draft
**Date:** 2026-10-23
**Owner:** alex
**Source Ideas:** —
**Supersedes:** —

## Summary

An OVDB descriptor (`ovdb-manifest/draft-1`) that points a client at a source it reads directly, for example an inGitDB database on GitHub, may carry `cacheControl`. This optional value is a standard HTTP `Cache-Control` directive string (RFC 9111 section 5.2) that tells clients how long they may keep the source's data files. It follows the inGitDB `cache_control` setting (ingitdb/ingitdb-go `spec/features/cache-control`) and adds one rule on top: the descriptor can only tighten what inGitDB declares. It is a hint to clients. It never grants anything the provider-reads boundary refuses.

## Problem

DataTug's public demo reads Countries from `ingitdb/geo-ingitdb` straight from `raw.githubusercontent.com`, pinned to a commit, as an OVDB-described source. GitHub sends `max-age=300` for every file, so each visitor fetches the same unchangeable bytes again every five minutes, and the demo keeps running into GitHub's limits. The founder asked (2026-10-23) for a cache setting in the OVDB source description, using the existing HTTP cache-control standard rather than new vocabulary. The founder also ruled that the same setting lives in inGitDB at database and collection level, so the descriptor must agree with inGitDB's rules.

`openvaultdb-go/docs/provider-reads.md` states that a provider "cannot admit arbitrary URL, decoder, snapshot or cache configuration". This Feature does not change that. `cacheControl` is read only by clients that already read a source directly. An OVDB server neither honours it nor admits it.

## Behavior

### REQ: descriptor-cache-control

A descriptor whose `storage` names a directly read location MAY carry `cacheControl` next to the revision it applies to. For an inGitDB database on GitHub that is `storage.github.cacheControl`:

```yaml
storage:
  engine: ingitdb
  github:
    repository: ingitdb/geo-ingitdb
    revision: 2a84199bcab79744b48ec529e48559a89a4b8851
    cacheControl: public, max-age=31536000, immutable
```

The value is a standard `Cache-Control` string with the same syntax, validation and reader leniency as inGitDB's `cache_control` (REQ: cache-control-validation and REQ: cache-control-reader-leniency there):

- validators reject malformed directives;
- readers drop malformed directives and keep the rest;
- unknown directives are ignored.

Absent or empty means not declared.

### REQ: precedence

For each data file, a client works out the declared value as follows:

1. Take the inGitDB value: the collection's `cache_control` when it has one, otherwise the database's. The collection value replaces the database value whole, and directives are never merged.
2. If there is no inGitDB value, take the descriptor's `cacheControl`.
3. If both exist, the descriptor can only tighten the inGitDB value. A shorter `max-age`, `no-cache` or `no-store` in the descriptor applies; a longer `max-age` or `immutable` is ignored.
4. Combine the declared value with the origin's own `Cache-Control` header as REQ: origin-combination states.

### REQ: origin-combination

Let O be the origin's response header and D the declared value from REQ: precedence.

- **Unpinned read** (a branch or a tag): D may only tighten O. The client keeps a file fresh for at most the smaller of O's and D's `max-age`, and ignores D's `immutable`.
- **Read pinned to a full commit SHA** (40 or 64 hexadecimal characters, declared as the revision): the bytes cannot change, so D's `max-age` replaces O's. D's `immutable` without a `max-age` gives one year (31536000 seconds).
- **Always:** `no-store` and `no-cache`, in D or in O, win. `no-store` means the file is never written to a cache. `no-cache` means it is not reused without revalidation.

### REQ: scope

The declared value applies to data files only: an inGitDB collection's record files and its published views under `$ingitdb`. Metadata files follow the origin's header alone. Those are the descriptor itself, `.ingitdb/settings.yaml`, `.ingitdb/root-collections.yaml` and collection definitions.

### REQ: client-cache-is-optional

A client MUST read correctly with no cache at all. When browser storage is missing, blocked or full, the client fetches as if nothing had been declared. Revalidation uses the HTTP machinery the platform already has. For example, a browser fetch with `cache: 'no-cache'` lets the browser send `If-None-Match`. GitHub refuses a cross-origin preflight for a script-set `If-None-Match`.

### REQ: no-server-effect

An OVDB server MUST NOT treat `cacheControl` as provider configuration: it admits no cache, snapshot or retention behaviour from it. Descriptor validation MAY check its syntax.

## Acceptance Criteria

### AC: pinned-data-kept

**Requirements:** source-cache-control#req:origin-combination

**Given** a descriptor pinned to a commit SHA with `cacheControl: public, max-age=31536000, immutable` and an origin that sends `max-age=300`
**When** a client reads a collection view, then reads it again ten days later
**Then** the second read makes no request for the view, while the descriptor and the metadata files are fetched again after 300 seconds

### AC: unpinned-only-tightens

**Requirements:** source-cache-control#req:origin-combination

**Given** a branch read with origin `max-age=300` and declared `public, max-age=31536000, immutable`
**When** the client works out freshness
**Then** the file is fresh for 300 seconds, and with declared `max-age=60` it is fresh for 60 seconds

### AC: descriptor-tightens-ingitdb

**Requirements:** source-cache-control#req:precedence

**Given** a pinned read whose collection declares `max-age=86400` and whose descriptor declares `max-age=600`
**When** the client works out freshness
**Then** the view is fresh for 600 seconds; with descriptor `max-age=31536000, immutable` it is fresh for 86400 seconds, and with descriptor `no-store` it is not stored

### AC: no-store-and-no-cache-win

**Requirements:** source-cache-control#req:origin-combination

**Given** a pinned read with declared `public, max-age=31536000, immutable`
**When** the origin sends `no-cache`
**Then** the client revalidates the file on every read

### AC: metadata-follows-origin

**Requirements:** source-cache-control#req:scope

**Given** a descriptor declaring `public, max-age=31536000, immutable` and an origin sending `max-age=300`
**When** the client reads `.ingitdb/root-collections.yaml`
**Then** that file is fresh for 300 seconds

### AC: storage-unavailable

**Requirements:** source-cache-control#req:client-cache-is-optional

**Given** browser storage that throws on open or on write
**When** the client reads a source
**Then** the read succeeds with network fetches

## Open Questions

- The browser client in datatug/datatug-apps#524 evaluates directives with `http-cache-semantics`. That library keeps the last of a repeated directive, while inGitDB's reader leniency keeps the first. It should switch to `@ingitdb/client`'s `effectiveCacheControl` once ingitdb/ingitdb-ts#105 is released, and run the shared conformance vectors.
- Should the Directory index expose `cacheControl` for discovery, or stay silent until a client asks for it?

---
*This document follows the https://specscore.md/feature-specification*
