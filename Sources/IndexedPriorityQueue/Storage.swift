//
//  Storage.swift
//  IndexedPriorityQueue
//
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

import Foundation

final internal class Storage<Element> {
    internal let sort: (Element, Element) -> Bool
    
    internal fileprivate(set) var capacity: Int
    
    internal fileprivate(set) var count: Int
    
    internal fileprivate(set) var elements: UnsafeMutablePointer<Element?>
    
    internal fileprivate(set) var pq: UnsafeMutablePointer<Int>
    
    internal fileprivate(set) var qp: UnsafeMutablePointer<Int>
    
    internal init(_ capacity: Int = 0, sort: @escaping (Element, Element) -> Bool) {
        let realCapacity = Self._convenientCapacityFor(capacity: capacity)
        self.capacity = realCapacity
        self.elements = UnsafeMutablePointer.allocate(capacity: realCapacity)
        self.elements.initialize(repeating: nil, count: realCapacity)
        self.pq = UnsafeMutablePointer.allocate(capacity: realCapacity)
        self.qp = UnsafeMutablePointer.allocate(capacity: realCapacity)
        self.qp.initialize(repeating: -1, count: realCapacity)
        self.count = 0
        self.sort = sort
    }
    
    deinit {
        self.elements.deinitialize(count: capacity)
        self.elements.deallocate()
        self.pq.deinitialize(count: count)
        self.pq.deallocate()
        self.qp.deinitialize(count: capacity)
        self.qp.deallocate()
    }
    
    fileprivate init(capacity: Int, count: Int, keys: UnsafeMutablePointer<Element?>, pq: UnsafeMutablePointer<Int>, qp: UnsafeMutablePointer<Int>, sort: @escaping (Element, Element) -> Bool) {
        self.capacity = capacity
        self.count = count
        self.elements = keys
        self.pq = pq
        self.qp = qp
        self.sort = sort
    }
    
}

// MARK: - Computed properties
extension Storage {
    @usableFromInline
    internal var isEmpty: Bool {
        count == 0
    }
    
    @usableFromInline
    internal var residualCapacity: Int { capacity - count }
    
    @usableFromInline
    internal var isFull: Bool { residualCapacity == 0 }
    
    @usableFromInline
    internal var optimalCapacity: Int {
        guard
            !isEmpty
        else { return Self._minCapacity }
        
        guard
            !isFull
        else {
            return capacity < Int.max ? capacity << 1 : capacity
        }
        
        guard
            residualCapacity > capacity / 2
        else { return capacity }
        
        let proposedCapacity = _largestUsedKey! + 1
        
        return Self._convenientCapacityFor(capacity: proposedCapacity)
    }
    
}

// MARK: - copy(minimumCapacity:) and optimizeCapacity() methods
extension Storage {
    @usableFromInline
    internal func copy(minimumCapacity: Int = 0) -> Self {
        let newCapacity = residualCapacity >= minimumCapacity ? capacity : Self._convenientCapacityFor(capacity: (capacity + (minimumCapacity - residualCapacity)))
        let newPQ = UnsafeMutablePointer<Int>.allocate(capacity: newCapacity)
        newPQ.moveInitialize(from: pq, count: count)
        let newKeys = UnsafeMutablePointer<Element?>.allocate(capacity: newCapacity)
        newKeys.moveInitialize(from: elements, count: capacity)
        newKeys.advanced(by: capacity).initialize(repeating: nil, count: newCapacity - capacity)
        let newQP = UnsafeMutablePointer<Int>.allocate(capacity: newCapacity)
        newQP.moveInitialize(from: qp, count: capacity)
        newQP.advanced(by: capacity).initialize(repeating: -1, count: newCapacity - capacity)
        
        return Self.init(capacity: newCapacity, count: count, keys: newKeys, pq: newPQ, qp: newQP, sort: sort)
    }
    
    @usableFromInline
    func optimizeCapacity() {
        _resizeTo(newCapacity: optimalCapacity)
    }
    
}

// MARK: - get/set methods
extension Storage {
    @usableFromInline
    @discardableResult
    func getElement(for key: Int) -> Element? {
        _validateKey(key)
        
        return elements.advanced(by:key).pointee
    }
    
    @usableFromInline
    @discardableResult
    func setElement(_ element: Element?, for key: Int) -> Element? {
        _validateKey(key)
        let slot = qp.advanced(by: key).pointee
        if let newElement = element {
            // We have to either set a new element or change one already stored at this index
            guard
                slot != -1
            else {
                // It's a new element that must be added to the heap
                assert(!isFull, "Trying to add new element in a full storage")
                defer {
                    qp.advanced(by: key).pointee = count
                    pq.advanced(by: count).initialize(to: key)
                    elements.advanced(by: key).pointee = newElement
                    _siftUp(from: count)
                    count += 1
                }
                
                return nil
            }
            
            // newElement goes in place of a previous stored element,
            // let's get the old element, return it and then change it with
            // the newElement mainining the heap property
            let oldElement = elements.advanced(by: key).pointee
            defer {
                elements.advanced(by: key).pointee = newElement
                _siftUp(from: slot)
                _siftDown(from: slot)
            }
            
            return oldElement
        } else {
            // It's a delete operation:
            // check if we actually have an element to delete associated to given index,
            // otherwise just return nil:
            guard
                slot != -1
            else { return nil }
            
            // get stored element and after returning it effectively
            // delete it maintaining heap property
            let oldElement = elements.advanced(by: key).pointee
            defer {
                _swapAt(slot, count - 1)
                count -= 1
                _siftUp(from: slot)
                _siftDown(from: slot)
                elements.advanced(by: key).pointee = nil
                pq.advanced(by: count).deinitialize(count: 1)
                qp.advanced(by: key).pointee = -1
            }
            
            return oldElement
        }
    }
    
}

// MARK: - Queue methods
extension Storage {
    @usableFromInline
    @discardableResult
    func peek() -> (key: Int, element: Element)? {
        guard !isEmpty else { return nil }
        
        let idx = pq.pointee
        
        return (idx, elements.advanced(by: idx).pointee!)
    }
    
    @usableFromInline
    @discardableResult
    func push(_ element: Element) -> Int {
        assert(!isFull, "Attempting to push an element into a full storage")
        let idx = _smallestFreeKey!
        
        defer {
            qp.advanced(by: idx).pointee = count
            pq.advanced(by: count).initialize(to: idx)
            elements.advanced(by: idx).pointee = element
            _siftUp(from: count)
            count += 1
        }
        
        return idx
    }
    
    @usableFromInline
    @discardableResult
    func pop() -> (key: Int, element: Element) {
        assert(!isEmpty, "Attempting to pop an element from an empty storage")
        let min = pq.pointee
        defer {
            _swapAt(0, count - 1)
            count -= 1
            _siftDown(from: 0)
            qp.advanced(by: min).pointee = -1
            elements.advanced(by: min).pointee = nil
            pq.advanced(by: count).deinitialize(count: 1)
        }
        
        return (min, elements.advanced(by: min).pointee!)
    }
    
}

// MARK: - fileprivate helpers
// MARK: - Heap helpers
extension Storage {
    @inline(__always)
    private func _leftChildIndexOf(parentAt idx: Int) -> Int {
        (2 * idx) + 1
    }
    
    @inline(__always)
    private func _rightChildIndexOf(parentAt idx: Int) -> Int {
        (2 * idx) + 2
    }
    
    @inline(__always)
    private func _parentIndexOf(childAt idx: Int) -> Int {
        (idx - 1) / 2
    }
    
    @inline(__always)
    fileprivate func _sort(_ i: Int, _ j: Int) -> Bool {
        let lhs = elements.advanced(by: pq.advanced(by: i).pointee).pointee
        let rhs = elements.advanced(by: pq.advanced(by: j).pointee).pointee
        
        return sort(lhs!, rhs!)
    }
    
    @inline(__always)
    fileprivate func _swapAt(_ i: Int, _ j: Int) {
        guard
            i != j
        else { return }
        
        swap(&pq.advanced(by: i).pointee, &pq.advanced(by: j).pointee)
        qp.advanced(by: pq.advanced(by: i).pointee).pointee = i
        qp.advanced(by: pq.advanced(by: j).pointee).pointee = j
    }
    
    @inline(__always)
    private func _siftDown(from index: Int) {
        var parent = index
        while true {
            let left = _leftChildIndexOf(parentAt: parent)
            let right = _rightChildIndexOf(parentAt: parent)
            var candidate = parent
            if left < count && _sort(left, candidate) {
                candidate = left
            }
            if right < count && _sort(right, candidate) {
                candidate = right
            }
            if candidate == parent {
                return
            }
            _swapAt(parent, candidate)
            parent = candidate
        }
    }
    
    @inline(__always)
    private func _siftUp(from index: Int) {
        var child = index
        var parent = _parentIndexOf(childAt: child)
        while child > 0 && _sort(child, parent) {
            _swapAt(child, parent)
            child = parent
            parent = _parentIndexOf(childAt: child)
        }
    }
    
}

// MARK: - Capacity helpers
extension Storage {
    @inline(__always)
    fileprivate static var _minCapacity: Int { 4 }
    
    // Returns the next power of 2 for given capacity value, or minCapacity for
    // a given value less than or equal to 2.
    // Returned value is clamped to Int.max, and given value must not be negative.
    @inline(__always)
    fileprivate static func _convenientCapacityFor(capacity: Int) -> Int {
        precondition(capacity >= 0, "Negative capacity values are not allowed.")
        
        guard capacity > (_minCapacity >> 1) else { return _minCapacity }
        
        guard capacity < ((Int.max >> 1) + 1) else { return Int.max }
        
        return 1 << (Int.bitWidth - (capacity - 1).leadingZeroBitCount)
    }
    
    @inline(__always)
    fileprivate var _smallestFreeKey: Int? {
        guard !isEmpty else { return 0 }
        
        guard !isFull else { return nil }
        
        var idx = 0
        while idx < capacity {
            guard
                qp.advanced(by: idx).pointee != -1
            else { return idx }
            
            idx += 1
        }
        
        return nil
    }
    
    @inline(__always)
    fileprivate var _largestUsedKey: Int? {
        guard !isEmpty else { return nil }
        
        guard !isFull else { return capacity - 1 }
        
        var idx = capacity - 1
        while idx >= 0 {
            guard
                qp.advanced(by: idx).pointee == -1
            else { return idx }
            
            idx -= 1
        }
        
        return nil
    }
    
    @inline(__always)
    fileprivate func _validateKey(_ index: Int) {
        precondition(0..<capacity ~= index, "index: \(index) is out bounds 0..<\(capacity)")
    }
    
    @inline(__always)
    fileprivate func _resizeTo(newCapacity: Int) {
        guard capacity != newCapacity else { return }
        
        let newPQ = UnsafeMutablePointer<Int>.allocate(capacity: newCapacity)
        newPQ.moveInitialize(from: pq, count: count)
        pq.deallocate()
        pq = newPQ
        let newElements = UnsafeMutablePointer<Element?>.allocate(capacity: newCapacity)
        let newQP = UnsafeMutablePointer<Int>.allocate(capacity: newCapacity)
        if newCapacity > capacity {
            // We are increasing capacity… Easy peasy!
            newElements.moveInitialize(from: elements, count: capacity)
            newElements.advanced(by: capacity).initialize(repeating: nil, count: newCapacity - capacity)
            newQP.moveInitialize(from: qp, count: capacity)
            newQP.advanced(by: capacity).initialize(repeating: -1, count: newCapacity - capacity)
        } else {
            // We are reducing overall buffer capacity…
            #if DEBUG
            // …we should have already checked that we won't leave any stored element
            // behind here:
            if let lastKey = _largestUsedKey {
                assert(lastKey < newCapacity)
            }
            #endif
            
            newElements.moveInitialize(from: elements, count: newCapacity)
            elements.advanced(by: newCapacity).deinitialize(count: capacity - newCapacity)
            newQP.moveInitialize(from: qp, count: newCapacity)
            pq.advanced(by: newCapacity).deinitialize(count: capacity - newCapacity)
        }
        elements.deallocate()
        elements = newElements
        qp.deallocate()
        qp = newQP
        capacity = newCapacity
    }
    
}
