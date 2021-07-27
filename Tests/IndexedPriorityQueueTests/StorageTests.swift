//
//  StorageTests.swift
//  IndexedPriorityQueueTests
//
//  Created by Valeriano Della Longa on 2021/07/20.
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

import XCTest
@testable import IndexedPriorityQueue

final class StorageTest: XCTestCase {
    var sut: Storage<String>!
    
    override func setUp() {
        super.setUp()
        
        let capacity = Int.random(in: 0..<100)
        sut = Storage(capacity, sort: <)
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    var sutElements: Array<String> {
        guard
            sut != nil,
            !sut.isEmpty
        else { return [] }
        
        let buff = UnsafeBufferPointer(start: sut.elements, count: sut.count)
        
        return buff.compactMap({ $0 })
    }
    
    var sutElementsWithKey: [Int : String] {
        guard
            sut != nil,
            !sut.isEmpty
        else { return [:] }
        
        let buff = UnsafeBufferPointer(start: sut.elements, count: sut.count)
        var result: [Int : String] = [:]
        for (idx, value) in buff.enumerated() {
            guard let value = value else { continue }
            
            result[idx] = value
        }
        
        return result
    }
    
    // MARK: - Given
    let givenElements = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "l", "m"]
    
    // MARK: - When
    func whenIsEmpty(sort: @escaping (String, String) -> Bool) {
        let capacity = Int.random(in: 10..<1000)
        sut = Storage(capacity, sort: sort)
    }
    
    func whenIsNotEmpty(sort: @escaping (String, String) -> Bool) {
        sut = Storage(givenElements.count, sort: sort)
        for (idx, element) in givenElements.enumerated() {
            sut.setElement(element, for: idx)
        }
        assertHeapProperty()
    }
    
    func whenIsFull(sort: @escaping (String, String) -> Bool) {
        sut = Storage(Int.random(in: 10..<1000), sort: sort)
        while !sut.isFull {
            sut.push("a")
        }
        XCTAssertTrue(sut.isFull)
    }
    
    func whenIsMoreThanHalfFull(sort: @escaping (String, String) -> Bool) {
        sut = Storage(Int.random(in: 10..<1000), sort: sort)
        let c = Int.random(in: (sut.capacity / 2)..<(sut.capacity - 1))
        for _ in 0..<c {
            sut.push("a")
        }
        XCTAssertLessThanOrEqual(sut.residualCapacity, (sut.capacity / 2))
    }
    
    func whenIsLessThanHalfFull(sort: @escaping (String, String) -> Bool) {
        sut = Storage(Int.random(in: 10..<1000), sort: sort)
        let c = Int.random(in: 1..<(sut.capacity / 2))
        for _ in 0..<c {
            sut.push("a")
        }
        XCTAssertGreaterThan(sut.residualCapacity, (sut.capacity / 2))
    }
    
    // MARK: - Tests
    func testInit() {
        let capacity = Int.random(in: 0..<100)
        sut = Storage(capacity, sort: <)
        XCTAssertNotNil(sut)
        XCTAssertGreaterThanOrEqual(sut.capacity, capacity)
        XCTAssertEqual(sut.count, 0)
        XCTAssertNotNil(sut.elements)
        XCTAssertNotNil(sut.pq)
        XCTAssertNotNil(sut.qp)
        XCTAssertEqual(sut.sort("a", "b"), ("a" < "b"))
        for idx in 0..<sut.capacity {
            XCTAssertNil(sut.elements.advanced(by:idx).pointee)
            XCTAssertEqual(sut.qp.advanced(by: idx).pointee, -1)
        }
        assertHeapProperty()
    }
    
    // MARK: - Computed properties tests
    func testIsEmpty_whenCountIsZero_thenReturnsTrue() {
        whenIsEmpty(sort: <)
        XCTAssertEqual(sut.count, 0)
        XCTAssertTrue(sut.isEmpty)
        
        whenIsEmpty(sort: >)
        XCTAssertEqual(sut.count, 0)
        XCTAssertTrue(sut.isEmpty)
    }
    
    func testIsEmpty_whenCountIsGreaterThanZero_thenReturnsFalse() {
        whenIsNotEmpty(sort: <)
        XCTAssertGreaterThan(sut.count, 0)
        XCTAssertFalse(sut.isEmpty)
        
        whenIsNotEmpty(sort: >)
        XCTAssertGreaterThan(sut.count, 0)
        XCTAssertFalse(sut.isEmpty)
    }
    
    func testResidualCapacity_whenIsEmpty_thenReturnsCapacityValue() {
        whenIsEmpty(sort: <)
        XCTAssertEqual(sut.residualCapacity, sut.capacity)
        
        whenIsEmpty(sort: >)
        XCTAssertEqual(sut.residualCapacity, sut.capacity)
    }
    
    func testResidualCapacity_whenIsNotEmpty_thenReturnsCapacityMinusCount() {
        whenIsNotEmpty(sort: <)
        XCTAssertEqual(sut.residualCapacity, sut.capacity - sut.count)
        
        whenIsNotEmpty(sort: >)
        XCTAssertEqual(sut.residualCapacity, sut.capacity - sut.count)
    }
    
    func testIsFull_whenResidualCapacityIsNotEqualToZero_thenReturnsFalse() throws {
        whenIsEmpty(sort: <)
        XCTAssertFalse(sut.isFull)
        
        whenIsNotEmpty(sort: <)
        try XCTSkipIf(sut.residualCapacity == 0)
        XCTAssertFalse(sut.isFull)
        
        whenIsNotEmpty(sort: >)
        try XCTSkipIf(sut.residualCapacity == 0)
        XCTAssertFalse(sut.isFull)
    }
    
    func testIsFull_whenResidualCapacityIsEqualToZero_thenReturnsFalse() {
        whenIsEmpty(sort: <)
        while sut.residualCapacity > 0 {
            sut.push("a")
        }
        
        XCTAssertTrue(sut.isFull)
        
        whenIsEmpty(sort: >)
        while sut.residualCapacity > 0 {
            sut.push("a")
        }
        
        XCTAssertTrue(sut.isFull)
    }
    
    func testOptimalCapacity_whenIsEmpty_thenReturns4() {
        whenIsEmpty(sort: <)
        XCTAssertEqual(sut.optimalCapacity, 4)
        
        whenIsEmpty(sort: >)
        XCTAssertEqual(sut.optimalCapacity, 4)
    }
    
    func testOptimalCapacity_whenIsFull_thenReturnsGreaterCapacity() {
        whenIsFull(sort: <)
        XCTAssertGreaterThan(sut.optimalCapacity, sut.capacity)
        
        whenIsFull(sort: >)
        XCTAssertGreaterThan(sut.optimalCapacity, sut.capacity)
    }
    
    func testOptimalCapacity_whenResidualCapacityIsLessThanOrEqualtToHalfCapacity_thenReturnsActualCapacity() {
        whenIsMoreThanHalfFull(sort: <)
        XCTAssertEqual(sut.optimalCapacity, sut.capacity)
        
        whenIsMoreThanHalfFull(sort: >)
        XCTAssertEqual(sut.optimalCapacity, sut.capacity)
    }
    
    func testOptimalCapacity_whenResidualCapacityIsMoreThanHalfCapacity_thenReturnsValueGreaterThanOrEqualToGreatestAssociatedKeyPlusOne() throws {
        whenIsLessThanHalfFull(sort: <)
        var expectedValue = sut.capacity - 1
        while expectedValue >= 0 {
            let candidate = sut.qp.advanced(by: expectedValue).pointee
            guard
                candidate == -1
            else {
                expectedValue = candidate + 1
                break
            }
            
            expectedValue -= 1
        }
        try XCTSkipIf(expectedValue <= 0)
        XCTAssertGreaterThanOrEqual(sut.optimalCapacity, expectedValue)
        
        whenIsLessThanHalfFull(sort: >)
        expectedValue = sut.capacity - 1
        while expectedValue >= 0 {
            let candidate = sut.qp.advanced(by: expectedValue).pointee
            guard
                candidate == -1
            else {
                expectedValue = candidate + 1
                break
            }
            
            expectedValue -= 1
        }
        try XCTSkipIf(expectedValue <= 0)
        XCTAssertGreaterThanOrEqual(sut.optimalCapacity, expectedValue)
        
        // Let's also check it out when the greatest associated key is a larger value
        // than half capacity:
        whenIsLessThanHalfFull(sort: <)
        expectedValue = (sut.capacity / 2) + 2
        sut.pop()
        sut.setElement("b", for: expectedValue - 1)
        XCTAssertGreaterThanOrEqual(sut.optimalCapacity, expectedValue)
        
        whenIsLessThanHalfFull(sort: >)
        expectedValue = (sut.capacity / 2) + 2
        sut.pop()
        sut.setElement("b", for: expectedValue - 1)
        XCTAssertGreaterThanOrEqual(sut.optimalCapacity, expectedValue)
    }
    
    // MARK: - copy(minimumCapacity:) tests
    func testCopyMinimumCapacity_whenMinimumCapacityIsZero_thenReturnsCopyWithSameCapacity() {
        whenIsEmpty(sort: <)
        var cloned = sut.copy()
        XCTAssertEqual(sut.capacity, cloned.capacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, 0)
        XCTAssertFalse(sut === cloned)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
        
        whenIsEmpty(sort: >)
        cloned = sut.copy()
        XCTAssertEqual(sut.capacity, cloned.capacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, 0)
        XCTAssertFalse(sut === cloned)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
        
        whenIsFull(sort: <)
        cloned = sut.copy()
        XCTAssertEqual(sut.capacity, cloned.capacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, 0)
        XCTAssertFalse(sut === cloned)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
        
        whenIsFull(sort: >)
        cloned = sut.copy()
        XCTAssertEqual(sut.capacity, cloned.capacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, 0)
        XCTAssertFalse(sut === cloned)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
    }
    
    func testCopyMinimumCapacity_whenResidualCapacityIsGreaterThanEqualToMinimumCapacity_thenReturnsCopyWithSameCapacity() {
        whenIsEmpty(sort: <)
        var minCapacity = Int.random(in: 1..<sut.residualCapacity)
        var cloned = sut.copy(minimumCapacity: minCapacity)
        XCTAssertEqual(sut.capacity, cloned.capacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, minCapacity)
        XCTAssertFalse(sut === cloned)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
        
        whenIsEmpty(sort: >)
        minCapacity = Int.random(in: 1..<sut.residualCapacity)
        cloned = sut.copy(minimumCapacity: minCapacity)
        XCTAssertEqual(sut.capacity, cloned.capacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, minCapacity)
        XCTAssertFalse(sut === cloned)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
        
        whenIsMoreThanHalfFull(sort: <)
        minCapacity = Int.random(in: 1..<sut.residualCapacity)
        cloned = sut.copy(minimumCapacity: minCapacity)
        XCTAssertEqual(sut.capacity, cloned.capacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, minCapacity)
        XCTAssertFalse(sut === cloned)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
        
        whenIsMoreThanHalfFull(sort: >)
        minCapacity = Int.random(in: 1..<sut.residualCapacity)
        cloned = sut.copy(minimumCapacity: minCapacity)
        XCTAssertEqual(sut.capacity, cloned.capacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, minCapacity)
        XCTAssertFalse(sut === cloned)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
    }
    
    func testCopyMinimumCapacity_whenResidualCapacityIsLessThanMinimumCapacity_thenReturnsCopyWithResidualCapacityGreaterThanOrEqualToMinimumCapacity() {
        whenIsEmpty(sort: <)
        var minCapacity = Int.random(in: (sut.residualCapacity + 1)..<(sut.residualCapacity + 10))
        var cloned = sut.copy(minimumCapacity: minCapacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, minCapacity)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
        
        whenIsEmpty(sort: >)
        minCapacity = Int.random(in: (sut.residualCapacity + 1)..<(sut.residualCapacity + 10))
        cloned = sut.copy(minimumCapacity: minCapacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, minCapacity)
        XCTAssertFalse(sut === cloned)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
        
        whenIsMoreThanHalfFull(sort: <)
        minCapacity = Int.random(in: (sut.residualCapacity + 1)..<(sut.residualCapacity + 10))
        cloned = sut.copy(minimumCapacity: minCapacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, minCapacity)
        XCTAssertFalse(sut === cloned)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
        
        whenIsMoreThanHalfFull(sort: >)
        minCapacity = Int.random(in: (sut.residualCapacity + 1)..<(sut.residualCapacity + 10))
        cloned = sut.copy(minimumCapacity: minCapacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, minCapacity)
        XCTAssertFalse(sut === cloned)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
        
        whenIsFull(sort: <)
        minCapacity = Int.random(in: (sut.residualCapacity + 1)..<(sut.residualCapacity + 10))
        cloned = sut.copy(minimumCapacity: minCapacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, minCapacity)
        XCTAssertFalse(sut === cloned)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
        
        whenIsFull(sort: >)
        minCapacity = Int.random(in: (sut.residualCapacity + 1)..<(sut.residualCapacity + 10))
        cloned = sut.copy(minimumCapacity: minCapacity)
        XCTAssertGreaterThanOrEqual(cloned.residualCapacity, minCapacity)
        XCTAssertFalse(sut === cloned)
        assertAreEquivalentQueues(lhs: sut, rhs: cloned)
    }
    
    // MARK: - optimizeCapacity() tests
    func testOptimizeCapacity_whenOptimalCapacityIsEqualToCapacity_thenNothingChanges() throws {
        sut = Storage(0, sort: <)
        try XCTSkipIf(sut.optimalCapacity != sut.capacity)
        var prevCapacity = sut.capacity
        var prevElements = sut.elements
        var prevPQ = sut.pq
        var prevQP = sut.qp
        sut.optimizeCapacity()
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevElements)
        XCTAssertEqual(sut.pq, prevPQ)
        XCTAssertEqual(sut.qp, prevQP)
        
        sut = Storage(0, sort: >)
        try XCTSkipIf(sut.optimalCapacity != sut.capacity)
        prevCapacity = sut.capacity
        prevElements = sut.elements
        prevPQ = sut.pq
        prevQP = sut.qp
        sut.optimizeCapacity()
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevElements)
        XCTAssertEqual(sut.pq, prevPQ)
        XCTAssertEqual(sut.qp, prevQP)
        
        whenIsMoreThanHalfFull(sort: <)
        try XCTSkipIf(sut.optimalCapacity != sut.capacity)
        var clone = sut.copy()
        prevCapacity = sut.capacity
        prevElements = sut.elements
        prevPQ = sut.pq
        prevQP = sut.qp
        sut.optimizeCapacity()
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevElements)
        XCTAssertEqual(sut.pq, prevPQ)
        XCTAssertEqual(sut.qp, prevQP)
        assertAreEquivalentQueues(lhs: sut, rhs: clone)
        
        whenIsMoreThanHalfFull(sort: >)
        try XCTSkipIf(sut.optimalCapacity != sut.capacity)
        clone = sut.copy()
        prevCapacity = sut.capacity
        prevElements = sut.elements
        prevPQ = sut.pq
        prevQP = sut.qp
        sut.optimizeCapacity()
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevElements)
        XCTAssertEqual(sut.pq, prevPQ)
        XCTAssertEqual(sut.qp, prevQP)
        assertAreEquivalentQueues(lhs: sut, rhs: clone)
    }
    
    func testOptimizeCapacity_whenIsFull_thenResizesToLargerCapacity() throws {
        whenIsFull(sort: <)
        try XCTSkipIf(sut.optimalCapacity <= sut.capacity)
        var prevCapacity = sut.capacity
        var prevElements = sut.elements
        var prevPQ = sut.pq
        var prevQP = sut.qp
        var clone = sut.copy()
        sut.optimizeCapacity()
        XCTAssertGreaterThan(sut.capacity, prevCapacity)
        XCTAssertNotEqual(sut.elements, prevElements)
        XCTAssertNotEqual(sut.pq, prevPQ)
        XCTAssertNotEqual(sut.qp, prevQP)
        assertAreEquivalentQueues(lhs: sut, rhs: clone)
        
        whenIsFull(sort: >)
        try XCTSkipIf(sut.optimalCapacity <= sut.capacity)
        prevCapacity = sut.capacity
        prevElements = sut.elements
        prevPQ = sut.pq
        prevQP = sut.qp
        clone = sut.copy()
        sut.optimizeCapacity()
        XCTAssertGreaterThan(sut.capacity, prevCapacity)
        XCTAssertNotEqual(sut.elements, prevElements)
        XCTAssertNotEqual(sut.pq, prevPQ)
        XCTAssertNotEqual(sut.qp, prevQP)
        assertAreEquivalentQueues(lhs: sut, rhs: clone)
    }
    
    func testOptimizeCapacity_whenOptimimalCapacityIsLessThanCapacity_thenResizesToSmallerCapacity() throws {
        whenIsLessThanHalfFull(sort: <)
        try XCTSkipIf(sut.optimalCapacity >= sut.capacity)
        var prevCapacity = sut.capacity
        var prevElements = sut.elements
        var prevPQ = sut.pq
        var prevQP = sut.qp
        var clone = sut.copy()
        sut.optimizeCapacity()
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertNotEqual(sut.elements, prevElements)
        XCTAssertNotEqual(sut.pq, prevPQ)
        XCTAssertNotEqual(sut.qp, prevQP)
        assertAreEquivalentQueues(lhs: sut, rhs: clone)
        
        whenIsLessThanHalfFull(sort: >)
        try XCTSkipIf(sut.optimalCapacity >= sut.capacity)
        prevCapacity = sut.capacity
        prevElements = sut.elements
        prevPQ = sut.pq
        prevQP = sut.qp
        clone = sut.copy()
        sut.optimizeCapacity()
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertNotEqual(sut.elements, prevElements)
        XCTAssertNotEqual(sut.pq, prevPQ)
        XCTAssertNotEqual(sut.qp, prevQP)
        assertAreEquivalentQueues(lhs: sut, rhs: clone)
    }
    
    // MARK: - C.R.U.D. tests
    func testGetElementAt_whenIsEmpty_thenReturnsNilForAnyKey() {
        whenIsEmpty(sort: <)
        for idx in 0..<sut.capacity {
            XCTAssertNil(sut.getElement(for: idx))
        }
        
        whenIsEmpty(sort: >)
        for idx in 0..<sut.capacity {
            XCTAssertNil(sut.getElement(for: idx))
        }
    }
    
    func testGetElementAt_whenIsNotEmpty_thenReturnsAppropriateElementAssociatedToKeyOrNilIfKeyHasNotAssociatedElement() {
        whenIsNotEmpty(sort: <)
        for idx in 0..<sut.capacity {
            guard
                givenElements.startIndex..<givenElements.endIndex ~= idx
            else {
                XCTAssertNil(sut.getElement(for:idx))
                continue
            }
            
            XCTAssertEqual(sut.getElement(for: idx), givenElements[idx])
        }
        
        whenIsNotEmpty(sort: >)
        for idx in 0..<sut.capacity {
            guard
                givenElements.startIndex..<givenElements.endIndex ~= idx
            else {
                XCTAssertNil(sut.getElement(for:idx))
                continue
            }
            
            XCTAssertEqual(sut.getElement(for: idx), givenElements[idx])
        }
        
    }
    
    func testSetElementAt_whenElementIsNotNilAndKeyIsNotInUse_thenSetsElementForThatKeyIncreasesCountByOneAndReturnsNil() {
        whenIsEmpty(sort: <)
        for idx in 0..<sut.capacity {
            let prevCount = sut.count
            XCTAssertNil(sut.setElement("a", for: idx))
            XCTAssertEqual(sut.count, prevCount + 1)
            assertHeapProperty()
        }
        
        whenIsEmpty(sort: >)
        for idx in 0..<sut.capacity {
            let prevCount = sut.count
            XCTAssertNil(sut.setElement("a", for: idx))
            XCTAssertEqual(sut.count, prevCount + 1)
            assertHeapProperty()
        }
    }
    
    func testSetElementAt_whenElementIsNotNilAndKeyIsInUse_thenReplacesOldElementWithNewOneAndReturnsOldElement() throws {
        whenIsNotEmpty(sort: <)
        for idx in givenElements.indices {
            try XCTSkipIf(sut.getElement(for: idx) == nil)
            let expectedValue = givenElements[idx]
            let prevCount = sut.count
            XCTAssertEqual(sut.setElement("z", for: idx), expectedValue)
            XCTAssertEqual(sut.count, prevCount)
            assertHeapProperty()
        }
        
        whenIsNotEmpty(sort: >)
        for idx in givenElements.indices {
            try XCTSkipIf(sut.getElement(for: idx) == nil)
            let expectedValue = givenElements[idx]
            let prevCount = sut.count
            XCTAssertEqual(sut.setElement("z", for: idx), expectedValue)
            XCTAssertEqual(sut.count, prevCount)
            assertHeapProperty()
        }
        
    }
    
    func testSetElement_whenElementIsNilAndKeyIsNotInUse_thenNothingChangesAndReturnsNil() throws {
        whenIsNotEmpty(sort: <)
        for idx in givenElements.endIndex..<sut.capacity {
            try XCTSkipIf(sut.getElement(for: idx) != nil)
            let cloned = sut.copy()
            XCTAssertNil(sut.setElement(nil, for: idx))
            assertAreEquivalentQueues(lhs: sut, rhs: cloned)
            assertHeapProperty()
        }
        
        whenIsNotEmpty(sort: >)
        for idx in givenElements.endIndex..<sut.capacity {
            try XCTSkipIf(sut.getElement(for: idx) != nil)
            let cloned = sut.copy()
            XCTAssertNil(sut.setElement(nil, for: idx))
            assertAreEquivalentQueues(lhs: sut, rhs: cloned)
            assertHeapProperty()
        }
    }
    
    func testSetElement_whenElementIsNilAndKeyIsInUse_thenRemovesAndReturnsSuchElement() throws {
        whenIsNotEmpty(sort: <)
        for idx in givenElements.indices {
            try XCTSkipIf(sut.getElement(for: idx) == nil)
            let prevCount = sut.count
            XCTAssertEqual(sut.setElement(nil, for: idx), givenElements[idx])
            XCTAssertEqual(sut.count, prevCount - 1)
            XCTAssertNil(sut.getElement(for: idx))
            assertHeapProperty()
        }
        
        whenIsNotEmpty(sort: >)
        for idx in givenElements.indices {
            try XCTSkipIf(sut.getElement(for: idx) == nil)
            let prevCount = sut.count
            XCTAssertEqual(sut.setElement(nil, for: idx), givenElements[idx])
            XCTAssertEqual(sut.count, prevCount - 1)
            XCTAssertNil(sut.getElement(for: idx))
            assertHeapProperty()
        }
    }
    
    // MARK: - Queue methods tests
    func testPeek_whenIsEmpty_thenReturnsNil() {
        whenIsEmpty(sort: <)
        XCTAssertNil(sut.peek())
        
        whenIsEmpty(sort: >)
        XCTAssertNil(sut.peek())
    }
    
    func testPeek_whenIsNotEmpty_thenReturnsFirstElementInHeapAndItsKey() throws {
        let elements = givenElements.shuffled()
        sut = Storage(elements.count, sort: <)
        for (idx, element) in elements.enumerated() {
            sut.setElement(element, for: idx)
        }
        while !sut.isEmpty {
            try XCTSkipIf(sut.peek() == nil)
            let expectedIdx = sut.pq.pointee
            let expectedElement = sut.elements.advanced(by: expectedIdx).pointee
            let result = sut.peek()
            XCTAssertEqual(result!.element, expectedElement)
            XCTAssertEqual(result!.key, expectedIdx)
            sut.setElement(nil, for: result!.key)
        }
        
        sut = Storage(elements.count, sort: >)
        for (idx, element) in elements.enumerated() {
            sut.setElement(element, for: idx)
        }
        while !sut.isEmpty {
            try XCTSkipIf(sut.peek() == nil)
            let expectedIdx = sut.pq.pointee
            let expectedElement = sut.elements.advanced(by: expectedIdx).pointee
            let result = sut.peek()
            XCTAssertEqual(result!.element, expectedElement)
            XCTAssertEqual(result!.key, expectedIdx)
            sut.setElement(nil, for: result!.key)
        }
    }
    
    func testPush_insertsElementAtSmallestAvailableKey() {
        sut = Storage(givenElements.count, sort: <)
        for idx in givenElements.indices.shuffled() {
            let prevElements = sutElementsWithKey
            let prevCount = sut.count
            let smallestKey = UnsafeBufferPointer(start: sut.qp, count: sut.capacity).firstIndex(where: { $0 == -1 })
            let usedKey = sut.push(givenElements[idx])
            XCTAssertEqual(smallestKey, usedKey)
            XCTAssertEqual(sut.getElement(for: usedKey), givenElements[idx])
            XCTAssertEqual(sut.count, prevCount + 1)
            assertContainsAtSameIndices(prevElements)
            assertHeapProperty()
        }
        
        sut = Storage(givenElements.count, sort: >)
        for idx in givenElements.indices.shuffled() {
            let prevElements = sutElementsWithKey
            let prevCount = sut.count
            let smallestKey = UnsafeBufferPointer(start: sut.qp, count: sut.capacity).firstIndex(where: { $0 == -1 })
            let usedKey = sut.push(givenElements[idx])
            XCTAssertEqual(smallestKey, usedKey)
            XCTAssertEqual(sut.getElement(for: usedKey), givenElements[idx])
            XCTAssertEqual(sut.count, prevCount + 1)
            assertContainsAtSameIndices(prevElements)
            assertHeapProperty()
        }
    }
    
    func testPop_returnsFirstElementInHeapAndItsKey() {
        sut = Storage(givenElements.count, sort: <)
        var expected = [Int : String]()
        for idx in givenElements.indices.shuffled() {
            let insertionKey = sut.push(givenElements[idx])
            expected[insertionKey] = givenElements[idx]
        }
        while !sut.isEmpty {
            var expectedElements = sutElementsWithKey
            let prevCount = sut.count
            let popped = sut.pop()
            XCTAssertEqual(sut.count, prevCount - 1)
            XCTAssertEqual(popped.element, expected[popped.key])
            expectedElements.removeValue(forKey: popped.key)
            assertContainsAtSameIndices(expectedElements)
            assertHeapProperty()
        }
        
        sut = Storage(givenElements.count, sort: <)
        expected = [Int : String]()
        for idx in givenElements.indices.shuffled() {
            let insertionKey = sut.push(givenElements[idx])
            expected[insertionKey] = givenElements[idx]
        }
        while !sut.isEmpty {
            var expectedElements = sutElementsWithKey
            let prevCount = sut.count
            let popped = sut.pop()
            XCTAssertEqual(sut.count, prevCount - 1)
            XCTAssertEqual(popped.element, expected[popped.key])
            expectedElements.removeValue(forKey: popped.key)
            assertContainsAtSameIndices(expectedElements)
            assertHeapProperty()
        }
    }
    
    // MARK: - Utilities
    private func assertHeapProperty(file: StaticString = #file, line: UInt = #line) {
        func isHeapPropertyRespected(parent: Int = 0) -> Bool {
            guard
                let parentElement = sut.elements[sut.pq[parent]]
            else {
                XCTFail("Got a nil element as parent", file: file, line: line)
                
                return false
            }
            
            var result = true
            let leftChild = (2 * parent) + 1
            let rightChild = (2 * parent) + 2
            if leftChild < sut.count {
                guard
                    let leftChildElement = sut.elements[sut.pq[leftChild]]
                else {
                    XCTFail("Got a nil element as left child", file: file, line: line)
                    
                    return false
                }
                
                result = !sut.sort(leftChildElement, parentElement)
                if result {
                    result = isHeapPropertyRespected(parent: leftChild)
                }
            }
            
            if result && rightChild < sut.count {
                guard
                    let rightChildElement = sut.elements[sut.pq[rightChild]]
                else {
                    XCTFail("Got a nil element", file: file, line: line)
                    
                    return false
                }
                
                result = !sut.sort(rightChildElement, parentElement)
                if result {
                    result = isHeapPropertyRespected(parent: rightChild)
                }
            }
            
            return result
        }
        
        guard
            !sut.isEmpty
        else { return }
        
        XCTAssertTrue(isHeapPropertyRespected(), "Heap property is not respected", file: file, line: line)
    }
    
    private func assertAreEquivalentQueues<Element: Comparable>(lhs: Storage<Element>, rhs: Storage<Element>, file: StaticString = #file, line: UInt = #line) {
        guard lhs.count == rhs.count else {
            XCTFail("Different elements count")
            
            return
        }
        
        while !lhs.isEmpty {
            let (lhsElement, lhsIndex) = lhs.pop()
            let (rhsElement, rhsIndex) = rhs.pop()
            guard
                lhsElement == rhsElement && lhsIndex == rhsIndex
            else {
                XCTFail("Are not equivalent")
                
                return
            }
        }
    }
    
    private func assertContainsAtSameIndices(_ elements: Dictionary<Int, String>, file: StaticString = #file, line: UInt = #line) {
        for idx in elements.keys {
            XCTAssertEqual(sut.getElement(for: idx), elements[idx])
        }
    }
    
}


