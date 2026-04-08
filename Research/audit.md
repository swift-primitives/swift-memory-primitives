# Audit: swift-memory-primitives

## Legacy — Consolidated 2026-04-08

### From: Index Type Safety Audit.md (2026-01-22)

**Scope**: Cross-package audit of index type safety across swift-index-primitives, swift-collection-primitives, swift-array-primitives, and swift-sequence-primitives.

**Auditor**: Claude | **Status**: RECOMMENDATION

| Package | Integration | Status |
|---------|-------------|--------|
| swift-index-primitives | N/A (provider) | Complete, well-designed |
| swift-collection-primitives | 0% | Critical architectural failure |
| swift-array-primitives | ~70% | Good, with legacy Int for protocols |
| swift-sequence-primitives | N/A (not applicable) | Correct by design |

**Findings by severity**:

| Severity | Count | Package |
|----------|-------|---------|
| Critical | 3 | swift-collection-primitives (Index_Primitives imported but unused; Collection.Rotated hardcodes Int; no bounds checking) |
| High | 2 | swift-collection-primitives (protocol examples use Int; unchecked arithmetic) |
| Minor | 1 | swift-sequence-primitives (unused swift-index-primitives dependency) |

**Key patterns**:
- Collection.Rotated uses raw Int throughout with no bounds validation — critical gap
- Collection protocols import then ignore Index_Primitives — architectural inconsistency
- Array primitives achieves ~70% type-safe indexing with Indexed<Tag> phantom wrappers
- Proposed 4-phase migration: (1) Collection.Rotated refactoring, (2) protocol doc updates, (3) array primitives Int deprecation, (4) sequence-primitives dependency cleanup

**Status**: All findings OPEN — migration not yet executed.

---

### From: Typed Index Integration Audit.md (2026-02-05)

**Scope**: Methodology and requirements for auditing 14 data structure packages to upgrade Int-based APIs to Index<Element>.

**Auditor**: Claude | **Status**: RECOMMENDATION

**Packages in scope**: deque, vector, stack, heap, list, queue, array, set, dictionary, handle, buffer, tree, machine (14 total; graph excluded — parallel work).

**Classification framework**:

| Category | Action |
|----------|--------|
| UPGRADE | API represents a logical position — change Int to Index |
| RETAIN | API represents count/capacity/size — keep as Int |
| INTERNAL | Implementation detail — evaluate case-by-case |

**Key patterns**:
- 6 common upgrade patterns identified: element access, index lookup, subscripts, insertion/removal, range-based ops, cursor state
- 3 retain patterns: capacity/count, distance, Collection protocol offsets
- Package-specific considerations documented for all 14 packages (ring buffer internals, LIFO/FIFO semantics, tree arena indices, handle generation checks)
- Test migration pattern: `(0..<n).map({ Type.Index($0) })`
- Success criteria: no public API accepts Int where a position is intended

**Status**: Methodology document — no per-package findings. Individual package audits not yet executed.

---

### From: swift-institute/Research/audits/implementation-naming-2026-03-20/swift-memory-primitives.md (2026-03-20)

**Implementation + naming audit**

HIGH=2, MEDIUM=8, LOW=5, INFO=0
Finding IDs: IMPL-002, IMPL-010, PATTERN-017, PATTERN-021
