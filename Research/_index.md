# Research Index

Centralized memory, pointer, buffer, and storage research for swift-memory-primitives.

This directory consolidates all memory-related research from:
- `swift-memory-primitives/Research/` (original)
- `swift-pointer-primitives/Research/` (moved)
- `swift-primitives/Research/` (memory-related docs moved)
- `swift-institute/Research/` (memory-related docs moved)

## Memory Address

| Document | Topic | Status |
|----------|-------|--------|
| memory-address-mutability.md | Address as capability vs position—resolved to position-only model | IMPLEMENTED |
| buffer-base-nullability.md | `base` vs `baseNonNull` naming and API structure | DECISION |
| ordinal-cardinal-foundations.md | Foundational patterns for typed arithmetic (ordinals, cardinals, affine) | ANALYSIS |
| affine-scaling-operations.md | Arithmetic patterns for memory operations | ANALYSIS |

## Pointer Architecture

| Document | Topic | Status |
|----------|-------|--------|
| pointer-architecture-comparison.md | Compares Swift stdlib pointers with custom implementations | ANALYSIS |
| pointer-type-hierarchy.md | Typed-only pointer hierarchy design (no raw pointers) | DECISION |
| pointer-primitives-design.md | Best-in-class pointer wrapper architecture | SUPERSEDED |
| pointer-mutable-pointee-semantics.md | `Pointer.Mutable.pointee` mutation semantics (nonmutating vs var) | DECISION |
| mutable-cross-module-ambiguity.md | Cross-module `Mutable`/`Buffer` typealias ambiguity on `Tagged` | COMPLETED |
| unique-package-placement.md | Package organization and placement decisions | IN_PROGRESS |

## Pointer Interop and Migration

| Document | Topic | Status |
|----------|-------|--------|
| Pointer-Stdlib-Interop-Design.md | Design for interoperability with stdlib pointers | RESEARCH |
| stdlib-pointer-migration.md | Stdlib pointer migration analysis across all primitives | DECISION |

## Lifetime and Memory Safety

| Document | Topic | Status |
|----------|-------|--------|
| Lifetime-Memory-Safety-Plan.md | Experiment-driven investigation of ~Escapable types and lifetime system | COMPLETED |
| lifetime-dependent-borrowed-cursors.md | Comprehensive analysis of ~Escapable, @_lifetime, non-escapable types | ANALYSIS |

## Buffer and Storage

| Document | Topic | Status |
|----------|-------|--------|
| buffer-algebraic-structure.md | Algebraic modeling of buffer types | IN_PROGRESS |
| storage-primitives-design.md | Core storage primitive design | IN_PROGRESS |
| storage-primitives-first-principles.md | First-principles redesign of storage-primitives | IN_PROGRESS |
| unified-storage-primitive.md | Unified storage primitive abstraction | RECOMMENDATION |

## Span and Contiguous Access

| Document | Topic | Status |
|----------|-------|--------|
| contiguous-memory-access-standardization.md | Standardize span/mutableSpan/withUnsafe* across all types | DECIDED |
| span-access-abstraction.md | Whether span access should use protocols or ad-hoc methods | DECIDED |

## Index and Arithmetic

| Document | Topic | Status |
|----------|-------|--------|
| typed-index-arithmetic-unification.md | Unifying typed index arithmetic patterns | DECISION |
| ring-buffer-index-arithmetic.md | Type-safe modular arithmetic for ring buffer indices | IN_PROGRESS |
| Index Type Safety Audit.md | Comprehensive audit of index type safety | ANALYSIS |
| Typed Index Integration Audit.md | Integration audit for typed indices | ANALYSIS |
| Input Index Bit Analysis.md | Bit-level analysis of index types | ANALYSIS |

## Status Legend

| Status | Meaning |
|--------|---------|
| ANALYSIS | Research/investigation document |
| RESEARCH | Active research in progress |
| IN_PROGRESS | Implementation or design work ongoing |
| RECOMMENDATION | Analysis complete, recommendation made |
| DECISION | Final decision documented |
| DECIDED | Decision made and documented |
| COMPLETED | Research and implementation finished |
| SUPERSEDED | Replaced by newer research |
| IMPLEMENTED | Implemented in code |
