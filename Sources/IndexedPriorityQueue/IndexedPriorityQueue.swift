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

public struct IndexedPriorityQueue<Element> {
    internal fileprivate(set) var storage: Storage<Element>
    
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
    
}

// MARK: - Public methods
extension IndexedPriorityQueue {
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        precondition(minimumCapacity >= 0, "minimumCapacity parameter must not be negative.")
        makeUnique(reservingCapacity: minimumCapacity)
    }
    
    public func peek() -> Element? {
        storage.peek()?.element
    }
    
    public mutating func enqueue(_ element: Element) {
        makeUnique(reservingCapacity: 1)
        storage.push(element)
    }
    
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
    
    public subscript(key: Int) -> Element? {
        get {
            storage.getElement(for: key)
        }
        
        mutating set {
            makeUnique()
            storage.setElement(newValue, for: key)
        }
    }
    
}
