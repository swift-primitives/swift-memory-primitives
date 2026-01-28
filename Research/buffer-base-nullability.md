# Buffer Base Nullability

<!--
---
version: 1.0.0
last_updated: 2026-01-28
status: IN_PROGRESS
---
-->

## Context

`Memory.Buffer` internally guarantees a non-null `_start` address using a sentinel allocation for empty buffers. Two public interop properties exist:

- `base` — returns `UnsafeRawBufferPointer(start: nil, count: 0)` for empty buffers (stdlib convention)
- `baseNonNull` — returns `UnsafeRawBufferPointer(start: sentinel, count: 0)` for empty buffers

Extensive C interop is expected across the ecosystem, making non-null buffer access a primary use case rather than a niche concern. Many C APIs reject null pointers even when accompanied by a zero count.

The name `baseNonNull` is a compound identifier, which violates the spirit of [API-NAME-002].

## Question

What should the naming and API structure of `Memory.Buffer`'s stdlib interop properties be, given that both null and non-null forms serve real use cases?

## Analysis

### Option A: Keep current dual API (`base` + `baseNonNull`)

Current implementation. `base` returns nil-for-empty (stdlib convention); `baseNonNull` preserves the sentinel.

**Advantages:**
- Both interop modes are available
- Explicit about what each variant provides

**Disadvantages:**
- `baseNonNull` is a compound identifier — violates [API-NAME-002]
- Unclear which is the "primary" variant
- Name implies the non-null version is the exceptional case, when in practice it may be the common one

### Option B: `base` always non-null; add `base.nullable` or similar for stdlib

Make the default `base` return non-null (matching the internal invariant). Provide a stdlib-convention variant for code that expects nil.

This would require `base` to return a wrapper type with a `.nullable` property, since `base` returns `UnsafeRawBufferPointer` (a stdlib value type that cannot be extended with a nested accessor in a meaningful way).

**Advantages:**
- Default behavior matches the type's core invariant (non-null)
- C interop path is the simple, obvious one

**Disadvantages:**
- Returning a wrapper from `base` adds indirection
- Breaks existing code that checks `buffer.base.baseAddress == nil`
- The wrapper would need its own type — potentially over-engineered

### Option C: Nested accessor via namespace type

Introduce a namespace to hold both variants:

```swift
extension Memory.Buffer {
    struct Base {
        // Returns UnsafeRawBufferPointer with nil for empty (stdlib convention)
        var nullable: UnsafeRawBufferPointer { ... }
        // Returns UnsafeRawBufferPointer with sentinel for empty (C interop)
        var nonNull: UnsafeRawBufferPointer { ... }
    }
    var base: Base { ... }
}
```

Usage: `buffer.base.nullable`, `buffer.base.nonNull`.

**Advantages:**
- Follows [API-NAME-002] — nested accessor, no compound name
- Progressive disclosure: autocomplete on `buffer.base.` shows both options
- Neither variant is privileged — the user must choose explicitly
- Clean separation of concerns

**Disadvantages:**
- Neither `buffer.base.nullable` nor `buffer.base.nonNull` can be passed directly where `UnsafeRawBufferPointer` is expected without explicit access (but that's the same as today)
- Adds a namespace type for two properties
- `buffer.base` alone is no longer usable — you must pick a variant

### Option D: Non-null `base`; stdlib conversion via `init` on stdlib side

Make `base` always non-null. For stdlib interop where nil is needed, users construct the nil-base buffer themselves:

```swift
// Primary path (non-null, C-safe):
let raw = buffer.base  // always non-null

// Stdlib convention (when explicitly needed):
let stdlibBuffer = buffer.isEmpty
    ? UnsafeRawBufferPointer(start: nil, count: 0)
    : buffer.base
```

**Advantages:**
- Single property, simple API
- Non-null is the default (matches internal invariant and C interop needs)
- No compound names

**Disadvantages:**
- Stdlib nil-convention becomes manual — error-prone boilerplate
- Users must know the stdlib convention and remember to apply it
- Violates the principle of making the common case easy if stdlib interop is also common

### Option E: `base` returns non-null; add `stdlib` conversion property

```swift
extension Memory.Buffer {
    // Primary: always non-null (C-safe)
    var base: UnsafeRawBufferPointer { ... }

    // Stdlib-normal form: nil for empty
    var stdlib: UnsafeRawBufferPointer { ... }
}
```

**Advantages:**
- Non-null is the default — correct for C interop
- `stdlib` clearly communicates intent
- No compound names
- Simple — two properties, clear purpose

**Disadvantages:**
- `stdlib` is a vague name — stdlib of what?
- Two properties at the same level without namespace grouping

### Option F: Rename only — `base` stays nil; `cBase` or similar for C interop

Keep `base` as stdlib-convention. Rename `baseNonNull` to something convention-compliant.

Candidates: `cBase`, `rawBase`, `unsafeBase`

**Advantages:**
- `base` retains stdlib compatibility
- Fixes the compound-name violation

**Disadvantages:**
- All candidates are still compound-ish or carry misleading connotations (`unsafe` has strict meaning in Swift 6.2; `c` prefix is un-Swifty; `raw` is already the abstraction level)

### Comparison

| Criterion | A: Current | C: Nested | D: Non-null only | E: base + stdlib |
|-----------|-----------|-----------|-------------------|-----------------|
| [API-NAME-002] compliance | No (`baseNonNull`) | Yes | Yes | Yes |
| C interop (primary path) | Secondary | Explicit | Default | Default |
| Stdlib interop | Default | Explicit | Manual | Explicit |
| API simplicity | Two properties | Namespace + two | One property | Two properties |
| Discoverability | Flat | Progressive | Trivial | Flat |
| Code at call site | `buffer.base` / `buffer.baseNonNull` | `buffer.base.nonNull` / `buffer.base.nullable` | `buffer.base` | `buffer.base` / `buffer.stdlib` |

### Constraints

1. **C interop is extensive.** Non-null base is not a niche concern — it is a primary interop path. The API should make this easy.

2. **Stdlib convention is real.** Code throughout the Swift ecosystem checks `baseAddress == nil` for emptiness. A conversion to stdlib-normal form must exist.

3. **[API-NAME-002]** forbids compound identifiers. `baseNonNull` violates this.

4. **The sentinel is an implementation detail.** Neither `base` nor any renamed variant should expose sentinel semantics — it should expose the guarantee (non-null) or the convention (nullable).

5. **`start` already provides non-null access.** Code within the primitives layer uses `start: Memory.Address` directly. The `base` / `baseNonNull` properties are specifically for crossing the boundary to stdlib/C types.

## Outcome

**Status**: IN_PROGRESS

**Leaning**: Option C (nested accessor) or Option E (`base` + `stdlib`).

Option C is the most convention-compliant and provides progressive disclosure, but adds a namespace type for two properties. Option E is simpler but `stdlib` as a property name needs refinement.

**Open questions for resolution:**
1. Is the namespace type in Option C justified for only two properties, or is it over-engineering?
2. If Option E, what should the stdlib-convention property be named? (`base.stdlib`? `nullableBase`? Something else?)
3. Should `base` default to non-null (Options C/D/E) or nil-for-empty (Options A/F)?

## References

- `Memory.Buffer.swift:136-161` — current `base` and `baseNonNull` definitions
- `Memory.Buffer.Mutable.swift` — parallel mutable implementation
- `Memory.Buffer Tests.swift:128-140` — tests for both properties
- `memory-address-mutability.md` — address-as-position design philosophy
- [API-NAME-002] — no compound identifiers
