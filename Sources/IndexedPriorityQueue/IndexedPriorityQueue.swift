//
//  IndexedPriorityQueue.swift
//  IndexedPriorityQueue

//  Created by Valeriano Della Longa on 2021/07/16.
//  Copyright © 2021 Valeriano Della Longa. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import Queue

/// A Swift implementation of *Indexed Priority Queue* data structure.
///
/// `IndexedPriorityQueue` is a priority queue data structure which also associates
/// every stored element to an non-negative `Int` value, defined as its *key*.
/// That is elements can be accessed via enqueue/dequeue in priority order or via *key-based* subscription.
///
/// Traditionally the term *key* has been widely used referring to the *elements* stored in this type
/// of data structure; though in this implementation the term *key* refers to the `Int` value
/// associated to a stored *element*.
/// That is in this data structure the term  *element* refers to what is traditionally called a *key*,
/// while the term *key* referes to what is traditionally called an *index* in an indexed priority queue.
///
/// Priority of one element over another is defined via a *strict ordering function* given at creation time and
/// invariable during the life time of an instance.
///
/// Such that given `sort` as the ordering function, then for any elements `a`, `b`, and `c`,
/// the following conditions must hold:
/// -   `sort(a, a)` is always `false`. (Irreflexivity)
/// -   If `sort(a, b)` and `sort(b, c)` are both `true`,
///     then `sort(a, c)` is also `true`. ( Transitive comparability)
/// -   Two elements are *incomparable* if neither is ordered before the other according to the sort function.
/// -   If `a` and `b` are incomparable, and `b` and `c` are incomparable, then `a` and `c`
///     are also incomparable. (Transitive incomparability)
public struct IndexedPriorityQueue<Element> {
    internal fileprivate(set) var storage: Storage<Element>
    
    /// Instanciate a new empty indexed priority queue, able to store
    /// at least the number of elements specified as `minimumCapacity`
    /// without having to reallocate its memory and adopting the comparator
    /// specified as `sort:` parameter for calcutating the sorting —priority based—
    ///  between two elements.
    ///
    ///- Parameter minimumCapacity: The minimum number of elements this indexed priority queue will
    ///                             be able to store withouth having to reallocate its memory.
    ///                             **Must not be negative**.
    ///                             Note that the returned instance might have a real capacity
    ///                             greater than the value specified as this parameter.
    /// - Parameter sort:   A closure that given two elements returns either `true` if they are sorted,
    ///                     or `false` if they aren't sorted.
    ///                     Must be a *strict weak ordering function* over the elements.
    /// - Precondition: The value specified as `minimumCapacity` parameter must not be negative.
    public init(minimumCapacity: Int, sort: @escaping(Element, Element) -> Bool) {
        self.storage = Storage(minimumCapacity, sort: sort)
    }
    
    @usableFromInline
    internal mutating func makeUnique(reservingCapacity minimumCapacity: Int = 0) {
        if !isKnownUniquelyReferenced(&storage) || storage.residualCapacity < minimumCapacity {
            storage = storage.copy(minimumCapacity: minimumCapacity)
        }
    }
    
}

// MARK: - Public computed properties
extension IndexedPriorityQueue {
    public var capacity: Int { storage.capacity }
    
    public var count: Int { storage.count }
    
    public var isEmpty: Bool { storage.isEmpty }
    
    public var isFull: Bool { storage.isFull }
    
    /// An array of non-negative `Int` values representing the keys in use by this indexed priority queue.
    ///
    /// - Complexity: O(*N*) where *N* is the *capacity* of this indexed priority queue.
    public var usedKeys: [Int] {
        UnsafeBufferPointer(start: storage.qp, count: storage.capacity)
            .compactMap({
                $0 == -1 ? nil : storage.pq.advanced(by: $0).pointee
            })
    }
    
    /// An array containing all the elements stored in this indexed priority queue.
    ///
    /// The order of elements in this array doesn't refelct the priority order of the queue.
    /// - Complexity: O(*N*) where *N* is the *capacity* of this indexed priority queue.
    public var storedElements: [Element] {
        UnsafeBufferPointer(start: storage.qp, count: storage.capacity)
            .compactMap({
                $0 == -1 ? nil : storage.elements.advanced(by: storage.pq.advanced(by: $0).pointee).pointee
            })
    }
    
    /// An optional tuple containing the *top most* element of this indexed priority queue,
    /// that is the element with the highest priority stored in this indexed priority queue, and the key
    /// value associated with it. This value is `nil`  when the indexed priority queue is empty.
    ///
    /// - Complexity: O(1)
    public var topMost: (key: Int, element: Element)? { storage.peek() }
    
}

// MARK: - Public methods & Queue conformance
extension IndexedPriorityQueue: Queue {
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        precondition(minimumCapacity >= 0, "minimumCapacity parameter must not be negative.")
        makeUnique(reservingCapacity: minimumCapacity)
    }
    
    @discardableResult
    public func peek() -> Element? {
        storage.peek()?.element
    }
    
    /// Stores specified element in this indexed priority queue, associating the specified element to
    /// the smallest key available .
    ///
    /// - Parameter element:    The element to store.
    /// - Complexity: O(log(*n*) where *n* is the lenght of this indexed priority queue.
    /// - Note: The indexed priority queue will associate the given element with the smallest
    ///         available key, that is the `Int`  value not yet associated with an element already
    ///         contained in the indexed priority queue before the new element is enqueued.
    public mutating func enqueue(_ element: Element) {
        makeUnique(reservingCapacity: 1)
        storage.push(element)
    }
    
    /// Stores in this indexed priority queue all elements contained in the given sequence,
    /// associating them progressively to the smallest key available.
    ///
    /// - Parameter contentsOf: The sequence of elements to store.
    /// - Complexity:   O(*m* \* *N* ), where *N* and *m* are respectively
    ///                 the `capacity` of this indexed priority queue,
    ///                 and the lenght of the given sequence of new elements to insert.
    public mutating func enqueue<S: Sequence>(contentsOf newElements: S) where S.Iterator.Element == Element {
        let done: Bool = newElements.withContiguousStorageIfAvailable({ buffer in
            guard
                !buffer.isEmpty
            else { return true }
            
            makeUnique(reservingCapacity: buffer.count)
            
            buffer.forEach({ self.storage.push($0) })
            
            return true
        }) ?? false
        
        if !done {
            var iter = newElements.makeIterator()
            guard
                let firstElement = iter.next()
            else { return }
            
            let minCapacity = newElements.underestimatedCount > 0 ? newElements.underestimatedCount : 1
            makeUnique(reservingCapacity: minCapacity)
            storage.push(firstElement)
            while let newElement = iter.next() {
                if storage.isFull {
                    makeUnique(reservingCapacity: 1)
                }
                storage.push(newElement)
            }
        }
    }
    
    @discardableResult
    /// Removes and returns the first element of the queue, or `nil` when the queue is empty.
    /// When an element is effectively removed and returned from the indexed priority queue,
    /// than the to which it was associated becomes also available again for associating it to a new
    /// element.
    ///
    /// - Returns: the first element of the queue, or `nil` when the queue is empty.
    /// - Complexity: O(log *n*), where *n* is the count of elements stored in this indexed priority queue.
    public mutating func dequeue() -> Element? {
        defer {
            storage.optimizeCapacity()
        }
        guard
            !storage.isEmpty
        else { return nil }
        
        makeUnique()
        
        return storage.pop().element
    }
    
    public mutating func clear(keepingCapacity keepCapacity: Bool) {
        if isEmpty && keepCapacity { return }
        let c = keepCapacity ? storage.capacity : 0
        let s = storage.sort
        storage = Storage(c, sort: s)
    }
    
    /// Access the element associated with the given key for for reading and writing.
    ///
    /// The key based subscript of an indexed priority queue works pretty much as it does in a dictionary,
    /// except for the precondition that such key must be in range `0..<capacity>`. 
    /// - Parameter key: An `Int` value, that is the key to find in this indexed priority queue.
    ///                     **Must be in range** `0..<capacity>`.
    /// - Returns:  The element associated with the given key in this idexed priority queue,
    ///             otherwise `nil`.
    /// - Complexity: O(log *N*) where *N* is the `capacity` value of this indexed priority queue.
    /// - Precondition: The value passed as `key` parameter must be in range `0..<capacity>`,
    ///                 otherwise a runtime error occurs.
    public subscript(key: Int) -> Element? {
        get {
            storage.getElement(for: key)
        }
        
        mutating set {
            makeUnique()
            storage.setElement(newValue, for: key)
        }
    }
    
    @discardableResult
    /// Removes and returns the stored element with the highest priority and the key it was associated to.
    /// When the indexed priority queue is empty, then returns `nil`.
    ///
    /// - Returns:  An optional tuple containing the stored element with the highest priority
    ///             and the key it was associated to. `nil` if the indexed priority queue is empty.
    /// - Note: When an element and its associated key are removed and returned, then such key
    ///         becomes once again available to be associated to a new element.
    /// - Complexity: O(log *n*), where *n* is the count of elements stored in this indexed priority queue.
    public mutating func popTopMost() -> (key: Int, element: Element)? {
        guard
            !storage.isEmpty
        else { return nil }
        
        makeUnique()
        
        return storage.pop()
    }
    
    /// Check if the specified `key` has been associated to an element in this indexed priority queue.
    ///
    /// - Parameter key:    An `Int` value representing the key to check.
    ///                     **Must be in range** `0..<capacity>`.
    /// - Returns:  A boolean value: `true` if the specified `key` parameter is
    ///             associated to a stored element in this indexed priority queue, `false` otherwise.
    /// - Precondition: The specified parameter `key` must be in range `0..<capacity>`,
    ///                 otherwise a runtime error occurs.
    /// - Complexity: O(1).
    public func containsKey(_ key: Int) -> Bool {
        storage.getElement(for: key) != nil
    }
    
}

extension IndexedPriorityQueue where Element: Comparable {
    /// Returns an empty indexed priority queue which adopts `<` as sort function over its elements,
    /// able to store without having to reallocate memory at least the number of elements specified as
    /// `miniumCapacity` parameter.
    ///
    /// The returned indexed priority queue will adopt as its priority criteria `>` comparator over its elements:
    /// that is taking two elements `a` and `b`, then the smaller between the two has an higher priority.
    /// Moreover elements will be associatable to a key in range of `0..<minimumCapacity>`.
    /// - Parameter minimumCapacity:    The minimum number of elements this indexed priority queue
    ///                                 will be able to store withouth having to reallocate its memory.
    ///                                 **Must not be negative**.
    ///                                 Note that the returned instance might have a real capacity
    ///                                 greater than the value specified as this parameter.
    /// - Returns: A new empty indexed priority queue where its element's priority is calculated
    ///            by comparing elements' value with `<` comparator and able to store
    ///            without reallocating memory at least the number of elements specified as
    ///            `minimumCapacity` parameter.
    public static func indexedMinPQ(minimumCapacity: Int) -> Self {
        Self.init(minimumCapacity: minimumCapacity, sort: <)
    }
    
    /// Returns an empty indexed priority queue which adopts `>` as sort function over its elements,
    /// able to store without having to reallocate memory at least the number of elements specified as
    /// `miniumCapacity` parameter.
    ///
    /// The returned indexed priority queue will adopt as its priority criteria `>` comparator over its elements:
    /// that is taking two elements `a` and `b`, then the smaller between the two has an higher priority.
    /// Moreover elements will be associatable to a key in range of `0..<minimumCapacity>`.
    /// - Parameter minimumCapacity:    The minimum number of elements this indexed priority queue
    ///                                 will be able to store withouth having to reallocate its memory.
    ///                                 **Must not be negative**.
    ///                                 Note that the returned instance might have a real capacity
    ///                                 greater than the value specified as this parameter.
    /// - Returns: A new empty indexed priority queue where its element's priority is calculated
    ///            by comparing elements' value with `>` comparator and able to store
    ///            without reallocating memory at least the number of elements specified as
    ///            `minimumCapacity` parameter.
    public static func indexedMaxPQ(minimumCapacity: Int) -> Self {
        Self.init(minimumCapacity: minimumCapacity, sort: >)
    }
    
    /// Returns an indexed priority queue which adopts `<` as sort function over its elements,
    /// storing all elements contained in the specified sequence by associating them to their enumerating offset.
    ///
    /// The returned indexed priority queue will adopt as its priority criteria `>` comparator over its elements:
    /// that is taking two elements `a` and `b`, then the smaller between the two has an higher priority.
    /// Moreover elements will be associatable to a key in range of `0..<minimumCapacity>`.
    /// - Parameter elements:   A finite sequence containing the elements to store in the
    ///                         indexed priority queue.
    /// - Returns:  A new  indexed priority queue where priority is calculated
    ///             by comparing elements' value with `<` comparator, storing all elements in the
    ///             specified sequence by associating them to their enumerating offset.
    public static func indexedMinPQ<S: Sequence>(contentsOf elements: S) -> Self where S.Iterator.Element == Element {
        self.init(contentsOf: elements, sort: <)
    }
    
    /// Returns an indexed priority queue which adopts `>` as sort function over its elements,
    /// storing all elements contained in the specified sequence by associating them to their enumerating offset.
    ///
    /// The returned indexed priority queue will adopt as its priority criteria `>` comparator over its elements:
    /// that is taking two elements `a` and `b`, then the smaller between the two has an higher priority.
    /// Moreover elements will be associatable to a key in range of `0..<minimumCapacity>`.
    /// - Parameter elements:   A finite sequence containing the elements to store in the
    ///                         indexed priority queue.
    /// - Returns:  A new  indexed priority queue where priority is calculated
    ///             by comparing elements' value with `>` comparator, storing all elements in the
    ///             specified sequence by associating them to their enumerating offset.
    public static func indexedMaxPQ<S: Sequence>(contentsOf elements: S) -> Self where S.Iterator.Element == Element {
        self.init(contentsOf: elements, sort: >)
    }
    
}

extension IndexedPriorityQueue {
    /// Create a new indexed priority queue with the given sort closure as comparator for
    /// its element's priority, storing all elements in the speciofied sequence by associating
    /// each one to their enumeration offset.
    ///
    /// - Parameter elements:   A finite sequence containing the elements to store in the
    ///                         indexed priority queue.
    /// - Parameter sort: A closure that given two elements returns either `true` if they are sorted,
    ///                     or `false` if they aren't sorted.
    ///                     Must be a *strict weak ordering function* over the elements.
    public init<S: Sequence>(contentsOf elements: S, sort: @escaping(Element, Element) -> Bool) where S.Iterator.Element == Element {
        let s: Storage<Element>? = elements
            .withContiguousStorageIfAvailable({ buffer in
                let _s = Storage(buffer.count, sort: sort)
                for key in buffer.indices {
                    _s.setElement(buffer[key], for: key)
                }
                
                return _s
            })
        if let s = s {
            self.storage = s
        } else {
            var _s = Storage(elements.underestimatedCount, sort: sort)
            for (key, element) in elements.enumerated() {
                if _s.isFull {
                    _s = _s.copy(minimumCapacity: 1)
                }
                _s.setElement(element, for: key)
            }
            
            self.storage = _s
        }
    }
    
}
