Typed Index Integration Audit: Maximizing Type Safety Across Swift Primitives                                       
                                                                                                                      
  Abstract                                                                                                            
                                                                                                                      
  This document establishes the methodology and requirements for auditing fourteen Swift data structure packages to   
  identify and upgrade integer-based APIs to utilize the type-safe Index<Element> primitive. The audit enforces the   
  principle that consumers should never require unsafe conveniences—instead, APIs must be elevated to use semantically
   appropriate types that provide compile-time guarantees against cross-collection index confusion.                   
                                                                                                                      
  ---                                                                                                                 
  1. Introduction                                                                                                     
                                                                                                                      
  1.1 Background                                                                                                      
                                                                                                                      
  The Swift Primitives project has introduced Index<Element: ~Copyable>, a phantom-typed index that provides          
  compile-time safety by parameterizing positions on the element type they index into. This prevents a class of bugs  
  where indices from one collection are accidentally used with another:                                               
                                                                                                                      
  let stackIdx: Stack<Int>.Index = 5                                                                                  
  let queueIdx: Queue<Int>.Index = 5                                                                                  
  // stackIdx == queueIdx  // Does not compile - different types                                                      
                                                                                                                      
  1.2 Problem Statement                                                                                               
                                                                                                                      
  Initial integration added Index typealiases and basic subscript support to each package. However, many APIs still   
  accept or return raw Int values for positions, counts, offsets, and capacities. This creates "escape hatches" that  
  undermine the type safety guarantees and fail to maximize the utility of the typed index system.                    
                                                                                                                      
  1.3 Guiding Principle                                                                                               
                                                                                                                      
  "We should NOT provide unsafe conveniences. We should update our APIs to maximize use, upgrading instance variables,
   function parameter inputs, and outputs to higher-level, more appropriate types like Index."                        
                                                                                                                      
  This principle demands that wherever a position or index is semantically meaningful, it must use the typed          
  Index<Element> rather than a raw Int.                                                                               
                                                                                                                      
  ---                                                                                                                 
  2. Scope                                                                                                            
                                                                                                                      
  2.1 Packages Under Audit                                                                                            
                                                                                                                      
  The following packages have received initial Index integration and require comprehensive audit:                     
  Package: swift-deque-primitives                                                                                     
  Primary Types: Deque, Deque.Bounded, Deque.Inline, Deque.Small                                                      
  Index Typealias: Deque<Element>.Index                                                                               
  ────────────────────────────────────────                                                                            
  Package: swift-vector-primitives                                                                                    
  Primary Types: Vector, Vector.Inline                                                                                
  Index Typealias: Vector<Element, N>.Index                                                                           
  ────────────────────────────────────────                                                                            
  Package: swift-stack-primitives                                                                                     
  Primary Types: Stack, Stack.Bounded, Stack.Inline, Stack.Small                                                      
  Index Typealias: Stack<Element>.Index                                                                               
  ────────────────────────────────────────                                                                            
  Package: swift-heap-primitives                                                                                      
  Primary Types: Heap, Heap.Bounded, Heap.Inline, Heap.Small                                                          
  Index Typealias: Heap<Element>.Index                                                                                
  ────────────────────────────────────────                                                                            
  Package: swift-list-primitives                                                                                      
  Primary Types: List.Linked and variants                                                                             
  Index Typealias: List<Element>.Index                                                                                
  ────────────────────────────────────────                                                                            
  Package: swift-queue-primitives                                                                                     
  Primary Types: Queue, Queue.Bounded, Queue.Inline, Queue.Small                                                      
  Index Typealias: Queue<Element>.Index                                                                               
  ────────────────────────────────────────                                                                            
  Package: swift-array-primitives                                                                                     
  Primary Types: Array.Bounded, Array.Inline, Array.Small, Array.Unbounded                                            
  Index Typealias: Array<Element>.Index                                                                               
  ────────────────────────────────────────                                                                            
  Package: swift-set-primitives                                                                                       
  Primary Types: Set.Ordered and variants                                                                             
  Index Typealias: Set<Element>.Index                                                                                 
  ────────────────────────────────────────                                                                            
  Package: swift-dictionary-primitives                                                                                
  Primary Types: Dictionary.Ordered                                                                                   
  Index Typealias: Dictionary<Key, Value>.Index                                                                       
  ────────────────────────────────────────                                                                            
  Package: swift-handle-primitives                                                                                    
  Primary Types: Handle, Handle.Slots                                                                                 
  Index Typealias: Handle.Index<Phantom>                                                                              
  ────────────────────────────────────────                                                                            
  Package: swift-buffer-primitives                                                                                    
  Primary Types: Buffer, Buffer.Ring                                                                                  
  Index Typealias: Buffer.Index<Element>                                                                              
  ────────────────────────────────────────                                                                            
  Package: swift-tree-primitives                                                                                      
  Primary Types: Tree.N, Tree.Binary                                                                                  
  Index Typealias: Tree.Index<Element>                                                                                
  ────────────────────────────────────────                                                                            
  Package: swift-machine-primitives                                                                                   
  Primary Types: Machine, Machine.Capture                                                                             
  Index Typealias: Machine.CaptureIndex                                                                               
  2.2 Exclusions                                                                                                      
                                                                                                                      
  - swift-graph-primitives — Parallel work in progress; exclude from this audit.                                      
  - swift-index-primitives — The source of truth; no changes needed.                                                  
  - swift-input-primitives — Separate integration phase.                                                              
  - swift-bit-primitives — Already has Bit.Index.                                                                     
                                                                                                                      
  ---                                                                                                                 
  3. Audit Methodology                                                                                                
                                                                                                                      
  3.1 Phase 1: API Surface Inventory                                                                                  
                                                                                                                      
  For each package, enumerate all public and @usableFromInline APIs that involve positional semantics:                
                                                                                                                      
  1. Subscripts — subscript(position: Int), subscript(offset: Int), etc.                                              
  2. Methods with positional parameters — element(at:), insert(at:), remove(at:), index(of:)                          
  3. Methods returning positions — firstIndex(of:), lastIndex(of:), index(after:), index(before:)                     
  4. Properties exposing positions — startIndex, endIndex, any cursor or position properties                          
  5. Initializers with capacity/count — These typically remain Int (capacity is not a position)                       
  6. Internal state — _cursor: Int, _head: Int, _tail: Int that represent logical positions                           
                                                                                                                      
  3.2 Phase 2: Classification                                                                                         
                                                                                                                      
  Classify each identified API into one of three categories:                                                          
  ┌──────────┬────────────────────────────────────────────────────────────┬───────────────────────┐                   
  │ Category │                        Description                         │        Action         │                   
  ├──────────┼────────────────────────────────────────────────────────────┼───────────────────────┤                   
  │ UPGRADE  │ API represents a logical position in the collection        │ Change Int → Index    │                   
  ├──────────┼────────────────────────────────────────────────────────────┼───────────────────────┤                   
  │ RETAIN   │ API represents a count, capacity, or size (not a position) │ Keep as Int           │                   
  ├──────────┼────────────────────────────────────────────────────────────┼───────────────────────┤                   
  │ INTERNAL │ Internal implementation detail not exposed publicly        │ Evaluate case-by-case │                   
  └──────────┴────────────────────────────────────────────────────────────┴───────────────────────┘                   
  Classification Rules:                                                                                               
                                                                                                                      
  - Positions (UPGRADE): Anything that identifies a specific element's location                                       
  - Counts (RETAIN): count, capacity, reserveCapacity(_:), initializers taking capacity                               
  - Offsets (CONTEXT-DEPENDENT): If offset is from a known index, consider Index; if it's a delta, keep Int           
  - Physical indices (INTERNAL): Ring buffer physical positions may remain Int internally                             
                                                                                                                      
  3.3 Phase 3: Implementation                                                                                         
                                                                                                                      
  For each UPGRADE classification:                                                                                    
                                                                                                                      
  1. Update function signatures — Change parameter and return types                                                   
  2. Update internal usage — Use index.position to extract the raw value when needed for internal arithmetic          
  3. Update call sites — All callers must construct proper Index values                                               
  4. Update tests — Tests must use typed indices, potentially with .map({ Type.Index($0) }) for ranges                
                                                                                                                      
  3.4 Phase 4: Validation                                                                                             
                                                                                                                      
  1. Compile — swift build must succeed with no errors                                                                
  2. Test — swift test must pass all existing tests                                                                   
  3. API Review — Manual review that no Int-based positional APIs remain in public surface                            
                                                                                                                      
  ---                                                                                                                 
  4. Detailed Audit Checklist                                                                                         
                                                                                                                      
  4.1 Common Patterns to Identify and Upgrade                                                                         
                                                                                                                      
  4.1.1 Element Access Methods                                                                                        
                                                                                                                      
  // BEFORE (unsafe)                                                                                                  
  public func element(at position: Int) throws -> Element                                                             
                                                                                                                      
  // AFTER (type-safe)                                                                                                
  public func element(at index: Index) throws -> Element                                                              
                                                                                                                      
  4.1.2 Index Lookup Methods                                                                                          
                                                                                                                      
  // BEFORE                                                                                                           
  public func firstIndex(of element: Element) -> Int?                                                                 
                                                                                                                      
  // AFTER                                                                                                            
  public func firstIndex(of element: Element) -> Index?                                                               
                                                                                                                      
  4.1.3 Subscripts with Integer Parameters                                                                            
                                                                                                                      
  // BEFORE                                                                                                           
  public subscript(position: Int) -> Element                                                                          
                                                                                                                      
  // AFTER                                                                                                            
  public subscript(index: Index) -> Element                                                                           
                                                                                                                      
  4.1.4 Insertion and Removal                                                                                         
                                                                                                                      
  // BEFORE                                                                                                           
  public mutating func insert(_ element: Element, at position: Int)                                                   
  public mutating func remove(at position: Int) -> Element                                                            
                                                                                                                      
  // AFTER                                                                                                            
  public mutating func insert(_ element: Element, at index: Index)                                                    
  public mutating func remove(at index: Index) -> Element                                                             
                                                                                                                      
  4.1.5 Range-Based Operations                                                                                        
                                                                                                                      
  // BEFORE                                                                                                           
  public func elements(in range: Range<Int>) -> SubSequence                                                           
                                                                                                                      
  // AFTER                                                                                                            
  public func elements(in range: Range<Index>) -> SubSequence                                                         
                                                                                                                      
  4.1.6 Cursor/Position State                                                                                         
                                                                                                                      
  // BEFORE (internal state)                                                                                          
  @usableFromInline var _cursor: Int                                                                                  
                                                                                                                      
  // AFTER (if exposed or used in public APIs)                                                                        
  @usableFromInline var _cursor: Index                                                                                
                                                                                                                      
  4.2 Patterns to RETAIN as Int                                                                                       
                                                                                                                      
  4.2.1 Capacity and Count                                                                                            
                                                                                                                      
  // RETAIN - these are sizes, not positions                                                                          
  public var count: Int { get }                                                                                       
  public var capacity: Int { get }                                                                                    
  public init(capacity: Int) throws                                                                                   
  public mutating func reserveCapacity(_ minimumCapacity: Int)                                                        
                                                                                                                      
  4.2.2 Distance Calculations                                                                                         
                                                                                                                      
  // RETAIN - distance is a delta, not a position                                                                     
  public func distance(from start: Index, to end: Index) -> Int                                                       
                                                                                                                      
  4.2.3 Offset Parameters in Collection Protocol                                                                      
                                                                                                                      
  // RETAIN - offset is relative movement                                                                             
  public func index(_ i: Index, offsetBy distance: Int) -> Index                                                      
                                                                                                                      
  ---                                                                                                                 
  5. Package-Specific Considerations                                                                                  
                                                                                                                      
  5.1 Deque                                                                                                           
                                                                                                                      
  - Ring buffer has physical indices (internal) vs logical indices (public)                                           
  - _storage.header.head and _storage.header.tail are physical — may remain Int internally                            
  - Public element(at:) must use typed Index                                                                          
  - Collection conformance already upgraded; verify completeness                                                      
                                                                                                                      
  5.2 Stack                                                                                                           
                                                                                                                      
  - LIFO access means most operations don't need indices                                                              
  - element(at:) for peek-by-position should use Index                                                                
  - Consider if "distance from top" APIs should exist                                                                 
                                                                                                                      
  5.3 Queue                                                                                                           
                                                                                                                      
  - FIFO access similar to Stack                                                                                      
  - Ring buffer internals similar to Deque                                                                            
  - Collection conformance should use typed Index                                                                     
                                                                                                                      
  5.4 Heap                                                                                                            
                                                                                                                      
  - Heap indices represent positions in the underlying array                                                          
  - rootIndex(), leftChild(of:), rightChild(of:), parent(of:) should use typed Index                                  
  - Internal heapify operations may use raw Int for arithmetic                                                        
                                                                                                                      
  5.5 Array Variants (Bounded, Inline, Small, Unbounded)                                                              
                                                                                                                      
  - Primary subscript access should use typed Index                                                                   
  - element(at:) must use typed Index                                                                                 
  - Span-based access may have different considerations                                                               
                                                                                                                      
  5.6 Set.Ordered                                                                                                     
                                                                                                                      
  - index(of:) should return typed Index?                                                                             
  - Subscript by index should use typed Index                                                                         
  - Key lookup returns Index?                                                                                         
                                                                                                                      
  5.7 Dictionary.Ordered                                                                                              
                                                                                                                      
  - index(forKey:) should return typed Index?                                                                         
  - key(at:), value(at:), entry(at:) should use typed Index                                                           
  - Index is parameterized on Key (not tuple, due to ~Copyable limitations)                                           
                                                                                                                      
  5.8 List.Linked                                                                                                     
                                                                                                                      
  - Linked lists don't support O(1) random access                                                                     
  - Index may represent node identifier rather than position                                                          
  - Consider if Index is appropriate or if a different abstraction is needed                                          
                                                                                                                      
  5.9 Tree                                                                                                            
                                                                                                                      
  - Tree positions are arena indices                                                                                  
  - Tree.Position may wrap Index with generation/token for invalidation detection                                     
  - Parent, child navigation should use typed positions                                                               
                                                                                                                      
  5.10 Handle                                                                                                         
                                                                                                                      
  - Handle.Index<Phantom> for slot positions                                                                          
  - Generation-checked access patterns                                                                                
  - Slot allocation returns typed index                                                                               
                                                                                                                      
  5.11 Buffer                                                                                                         
                                                                                                                      
  - Byte-level access may use different index semantics                                                               
  - Consider Buffer.Index for byte positions                                                                          
                                                                                                                      
  5.12 Machine                                                                                                        
                                                                                                                      
  - Machine.CaptureIndex for capture group positions                                                                  
  - Instruction pointer may use separate index type                                                                   
                                                                                                                      
  ---                                                                                                                 
  6. Testing Requirements                                                                                             
                                                                                                                      
  6.1 Test Updates                                                                                                    
                                                                                                                      
  All tests must be updated to use typed indices:                                                                     
                                                                                                                      
  // BEFORE                                                                                                           
  for i in 0..<500 {                                                                                                  
      #expect(collection[i] == expected[i])                                                                           
  }                                                                                                                   
                                                                                                                      
  // AFTER                                                                                                            
  for i in (0..<500).map({ Collection.Index($0) }) {                                                                  
      #expect(collection[i] == expected[i.position])                                                                  
  }                                                                                                                   
                                                                                                                      
  6.2 Compile-Time Safety Verification                                                                                
                                                                                                                      
  Add tests that verify type safety:                                                                                  
                                                                                                                      
  @Test("Index types are distinct")                                                                                   
  func indexTypesAreDistinct() {                                                                                      
      let stackIdx: Stack<Int>.Index = 0                                                                              
      let queueIdx: Queue<Int>.Index = 0                                                                              
      // This should not compile if uncommented:                                                                      
      // #expect(stackIdx == queueIdx)                                                                                
                                                                                                                      
      // Verify they are different types                                                                              
      #expect(type(of: stackIdx) != type(of: queueIdx))                                                               
  }                                                                                                                   
                                                                                                                      
  6.3 Negative Index Prevention                                                                                       
                                                                                                                      
  The Index type has a precondition requiring non-negative positions. Tests that previously checked for negative index
   errors should be updated:                                                                                          
                                                                                                                      
  // BEFORE - tested runtime bounds error                                                                             
  #expect(throws: Error.self) {                                                                                       
      _ = collection.element(at: -1)                                                                                  
  }                                                                                                                   
                                                                                                                      
  // AFTER - negative indices prevented at construction                                                               
  // Note: Index(-1) triggers precondition failure                                                                    
  // This test case is no longer applicable                                                                           
                                                                                                                      
  ---                                                                                                                 
  7. Implementation Checklist                                                                                         
                                                                                                                      
  For each package, complete the following:                                                                           
                                                                                                                      
  - Inventory — List all APIs with positional parameters or returns                                                   
  - Classify — Mark each as UPGRADE, RETAIN, or INTERNAL                                                              
  - Implement — Update signatures and implementations                                                                 
  - Update tests — Modify all test code to use typed indices                                                          
  - Build — Verify swift build succeeds                                                                               
  - Test — Verify swift test passes                                                                                   
  - Review — Manual API surface review for completeness                                                               
                                                                                                                      
  ---                                                                                                                 
  8. Deliverables                                                                                                     
                                                                                                                      
  For each package, produce:                                                                                          
                                                                                                                      
  1. Modified source files with upgraded API signatures                                                               
  2. Modified test files using typed indices throughout                                                               
  3. Summary of changes listing each API that was upgraded                                                            
                                                                                                                      
  ---                                                                                                                 
  9. Success Criteria                                                                                                 
                                                                                                                      
  The audit is complete when:                                                                                         
                                                                                                                      
  1. No public API accepts Int where a logical position is intended                                                   
  2. No public API returns Int where a logical position is the result                                                 
  3. All tests pass using typed indices                                                                               
  4. The exports.swift re-exports ensure consumers need only import the direct package                                
  5. Code review confirms no "escape hatches" remain                                                                  
                                                                                                                      
  ---                                                                                                                 
  10. Package Locations                                                                                               
                                                                                                                      
  All packages are located under:                                                                                     
                                                                                                                      
  /Users/coen/Developer/swift-primitives/                                                                             
                                                                                                                      
  With the naming convention swift-{name}-primitives/.                                                                
                                                                                                                      
  Source files are in:                                                                                                
  Sources/{Name} Primitives/                                                                                          
                                                                                                                      
  Test files are in:                                                                                                  
  Tests/{Name} Primitives Tests/                                                                                      
                                                                                                                      
  ---                                                                                                                 
  11. Reference Implementation                                                                                        
                                                                                                                      
  The Deque package serves as the reference implementation for this audit. Key files:                                 
                                                                                                                      
  - Deque.swift — Collection conformance with typed Index                                                             
  - Deque+Conveniences.swift — Additional APIs using typed Index                                                      
  - exports.swift — Re-exports Index_Primitives                                                                       
  - Test files updated to use (0..<n).map({ Deque<T>.Index($0) }) pattern                                             
                                                                                                                      
  ---                                                                                                                 
  12. Conclusion                                                                                                      
                                                                                                                      
  This audit represents a systematic effort to maximize the value of the typed index system across all Swift          
  Primitives data structures. By eliminating integer-based positional APIs from the public surface, we ensure that    
  consumers benefit from compile-time safety guarantees that prevent cross-collection index confusion. The principle  
  is clear: no unsafe conveniences, only properly typed APIs that make invalid states unrepresentable.                
                                                                                                                      
  ---                                                                                                                 
  Appendix A: Index Primitives Reference                                                                              
                                                                                                                      
  // From swift-index-primitives                                                                                      
                                                                                                                      
  public struct Index<Element: ~Copyable>: Hashable, Comparable, Sendable {                                           
      public let position: Int                                                                                        
                                                                                                                      
      public init(_ position: Int) {                                                                                  
          precondition(position >= 0, "Index position must be non-negative")                                          
          self.position = position                                                                                    
      }                                                                                                               
  }                                                                                                                   
                                                                                                                      
  extension Index: ExpressibleByIntegerLiteral where Element: ~Copyable {                                             
      public init(integerLiteral value: Int) {                                                                        
          self.init(value)                                                                                            
      }                                                                                                               
  }                                                                                                                   
                                                                                                                      
  ---                                                                                                                 
  Appendix B: Packages Excluded from Audit                                                                            
  ┌───────────────────────────┬────────────────────────────┐                                                          
  │          Package          │           Reason           │                                                          
  ├───────────────────────────┼────────────────────────────┤                                                          
  │ swift-graph-primitives    │ Parallel work in progress  │                                                          
  ├───────────────────────────┼────────────────────────────┤                                                          
  │ swift-index-primitives    │ Source of truth            │                                                          
  ├───────────────────────────┼────────────────────────────┤                                                          
  │ swift-input-primitives    │ Separate integration phase │                                                          
  ├───────────────────────────┼────────────────────────────┤                                                          
  │ swift-bit-primitives      │ Already complete           │                                                          
  ├───────────────────────────┼────────────────────────────┤                                                          
  │ swift-identity-primitives │ No positional APIs         │                                                          
  └───────────────────────────┴────────────────────────────┘                                                          
