//
//  IndexedPriorityQueueTests.swift
//  IndexedPriorityQueueTests
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

import XCTest
@testable import IndexedPriorityQueue

final class IndexedPriorityQueueTests: XCTestCase {
    var sut: IndexedPriorityQueue<String>!
    
    override func setUp() {
        super.setUp()
        
        sut = IndexedPriorityQueue(minimumCapacity: Int.random(in: 0..<10), sort: <)
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - Given
    let givenElements = ["a", "b", "c", "d", "e", "f", "g", "h", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "y", "x", "z"]
    
    // MARK: - Tests
    func testInitMinimumCapacitySort() {
        let minimumCapacity = Int.random(in: 0..<1000)
        sut = IndexedPriorityQueue(minimumCapacity: minimumCapacity, sort: <)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertGreaterThanOrEqual(sut.storage.capacity, minimumCapacity)
        XCTAssertEqual(sut.storage.sort("a", "b"), "a" < "b")
        
        sut = IndexedPriorityQueue(minimumCapacity: minimumCapacity, sort: >)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertGreaterThanOrEqual(sut.storage.capacity, minimumCapacity)
        XCTAssertEqual(sut.storage.sort("a", "b"), "a" > "b")
    }
    
    func testMakeUniqueReservingCapacity_whenStorageIsUniqueAndItsResidualCapacityIsGreaterThanEqualToMinimumCapacity_thenStorageStaysTheSame() {
        let maxC = sut.storage.residualCapacity
        for minCapacity in 0...maxC {
            weak var prevStorage = sut.storage
            sut.makeUnique(reservingCapacity: minCapacity)
            XCTAssertTrue(sut.storage === prevStorage)
        }
    }
    
    func testMakeUniqueReservingCapacity_whenStorageIsNotUnique_thenStorageIsCopied() {
        let clone = sut!
        XCTAssertTrue(sut.storage === clone.storage)
        sut.makeUnique()
        XCTAssertFalse(sut.storage === clone.storage)
    }
    
    func testMakeUniqueReservingCapacity_whenResidualCapacityIsLessThanMinimumCapacity_thenStorageGetsCopiedAndResized() {
        let minCapacity = sut.capacity + 1
        XCTAssertGreaterThan(minCapacity, sut.storage.residualCapacity)
        weak var prevStorage = sut.storage
        sut.makeUnique(reservingCapacity: minCapacity)
        XCTAssertFalse(sut.storage === prevStorage)
        XCTAssertGreaterThanOrEqual(sut.storage.residualCapacity, minCapacity)
    }
    
    func testMakeUniqueReservingCapacity_whenResidualCapacityIsLessThanMinimumCapacityAndStorageIsNotUniquelyReferenced_thenStorageGetsCopiedAndResized() {
        let clone = sut!
        XCTAssertTrue(sut.storage === clone.storage)
        let minCapacity = sut.capacity + 1
        XCTAssertGreaterThan(minCapacity, sut.storage.residualCapacity)
        sut.makeUnique(reservingCapacity: minCapacity)
        XCTAssertFalse(sut.storage === clone.storage)
        XCTAssertGreaterThanOrEqual(sut.storage.residualCapacity, minCapacity)
    }
    
    // MARK: - public computed properties tests
    func testCapacity() {
        XCTAssertEqual(sut.capacity, sut.storage.capacity)
        sut.reserveCapacity(100)
        XCTAssertEqual(sut.capacity, sut.storage.capacity)
    }
    
    func testCount() {
        for i in 0..<sut.storage.capacity {
            sut.storage.setElement("a", for: i)
            XCTAssertEqual(sut.count, sut.storage.count)
        }
    }
    
    func testIsEmpty() {
        XCTAssertEqual(sut.isEmpty, sut.storage.isEmpty)
        sut.storage.push("a")
        XCTAssertEqual(sut.isEmpty, sut.storage.isEmpty)
    }
    
    func testIsFull() {
        for i in 0..<sut.storage.capacity {
            sut.storage.setElement("a", for: i)
            XCTAssertEqual(sut.isFull, sut.storage.isFull)
        }
        XCTAssertTrue(sut.isFull)
    }
    
    func testUsedKeys() {
        XCTAssertEqual(sut.usedKeys.isEmpty, sut.isEmpty)
        let expectedElements = givenElements.shuffled()
        sut.enqueue(contentsOf: expectedElements)
        let usedKeys = sut.usedKeys
        XCTAssertFalse(usedKeys.isEmpty)
        for key in usedKeys {
            XCTAssertEqual(sut[key], expectedElements[key])
        }
        for _ in 0..<usedKeys.count / 2 {
            let rKey = usedKeys.randomElement()!
            sut[rKey] = nil
        }
        let newUsedKeys = sut.usedKeys
        XCTAssertNotEqual(usedKeys, newUsedKeys)
        for key in newUsedKeys {
            XCTAssertEqual(sut[key], expectedElements[key])
        }
        let freedKeys = usedKeys.filter({ !newUsedKeys.contains($0) })
        for key in freedKeys {
            XCTAssertNil(sut[key])
        }
    }
    
    func testStoredElements() {
        XCTAssertEqual(sut.isEmpty, sut.storedElements.isEmpty)
        let expectedElements = givenElements.shuffled()
        sut.enqueue(contentsOf: expectedElements)
        let storedElements = sut.storedElements
        XCTAssertEqual(storedElements, expectedElements)
    }
    
    func testTopMost() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.topMost)
        let elements = givenElements.shuffled()
        for element in elements {
            sut.enqueue(element)
            let expected = sut.storage.peek()
            let topMost = sut.topMost
            XCTAssertEqual(expected!.key, topMost!.key)
            XCTAssertEqual(expected!.element, topMost!.element)
        }
    }
    
    // MARK: - Public methods tests
    // MARK: - reserveCapacity(_:) tests
    func testReserveCapacity() {
        // leverages on Storage's method; we mainly to test Copy On Write mechanism
        let minCapacity = Int.random(in: 0..<100)
        let clone = sut!
        sut.reserveCapacity(minCapacity)
        XCTAssertFalse(sut.storage === clone.storage)
    }
    
    // MARK: - peek() tests
    func testPeek() {
        // Leveraging on Storage method.
        while !sut.storage.isFull {
            sut.storage.push(givenElements.randomElement()!)
            XCTAssertEqual(sut.peek(), sut.storage.peek()?.element)
        }
        while !sut.isEmpty {
            sut.storage.pop()
            XCTAssertEqual(sut.peek(), sut.storage.peek()?.element)
        }
        XCTAssertEqual(sut.peek(), sut.storage.peek()?.element)
    }
    
    // MARK: - enqueue(_:) tests
    func testEnqueue_whenIsNotFull_thenStoresElementInStorage() {
        weak var prevStorage = sut.storage
        for idx in 0..<sut.capacity {
            let element = givenElements.randomElement()!
            sut.enqueue(element)
            XCTAssertEqual(sut.storage.getElement(for: idx), element)
            XCTAssertTrue(sut.storage === prevStorage)
        }
    }
    
    func testEnqueue_whenIsFull_thenStoresElementInLargerStorage() {
        while !sut.isFull {
            let element = givenElements.randomElement()!
            sut.enqueue(element)
        }
        weak var prevStorage = sut.storage
        let element = "ZZ"
        let idx = sut.capacity
        sut.enqueue(element)
        XCTAssertEqual(sut.storage.getElement(for: idx), element)
        XCTAssertFalse(sut.storage === prevStorage)
    }
    
    func testEnqueue_whenStorageIsNotUniquelyReferenced_thenStoresElementInNewStorage() {
        var clone = sut!
        let element = "ZZ"
        sut.enqueue(element)
        XCTAssertFalse(sut.storage === clone.storage)
        XCTAssertTrue(clone.isEmpty)
        XCTAssertEqual(sut.storage.getElement(for: 0), element)
        
        // let's also check storage gets resized when is full and not uniquely referenced
        sut = IndexedPriorityQueue(minimumCapacity: 10, sort: <)
        while !sut.isFull {
            let rElement = givenElements.randomElement()!
            sut.enqueue(rElement)
        }
        clone = sut!
        let idx = sut.capacity
        sut.enqueue(element)
        XCTAssertFalse(sut.storage === clone.storage)
        XCTAssertGreaterThan(sut.storage.capacity, clone.storage.capacity)
        XCTAssertEqual(sut.storage.getElement(for: idx), element)
    }
    
    // MARK: - enqueue(contentsOf:) tests
    func testEnqueueSequence_whenSequenceIsEmpty_thenNothingHappens() {
        var clone = sut!
        sut.enqueue(contentsOf: [])
        XCTAssertTrue(sut.storage === clone.storage)
        XCTAssertTrue(sut.isEmpty)
        
        let other = MyTestSequence<String>(elements: [], underestimatedCount: 0, hasContiguousBuffer: false)
        sut.enqueue(contentsOf: other)
        XCTAssertTrue(sut.storage === clone.storage)
        XCTAssertTrue(sut.isEmpty)
        
        var expectedElements = [Int : String]()
        for (idx, element) in givenElements.enumerated() {
            sut.enqueue(element)
            expectedElements[idx] = element
        }
        
        clone = sut!
        sut.enqueue(contentsOf: [])
        XCTAssertTrue(sut.storage === clone.storage)
        assertContainsAtSameIndices(expectedElements)
        
        sut.enqueue(contentsOf: other)
        XCTAssertTrue(sut.storage === clone.storage)
        assertContainsAtSameIndices(expectedElements)
    }
    
    func testEqueueSequence_whenSequenceIsNotEmpty_thenStoresNewElements() {
        let expectedElements = Dictionary<Int, String>(uniqueKeysWithValues: Array(givenElements.enumerated()))
        sut.enqueue(contentsOf: givenElements)
        assertContainsAtSameIndices(expectedElements)
        
        sut = IndexedPriorityQueue(minimumCapacity: 0, sort: <)
        for i in 0..<givenElements.count / 2 {
            sut.enqueue(givenElements[i])
        }
        sut.enqueue(contentsOf: givenElements[(givenElements.count / 2)..<givenElements.endIndex])
        assertContainsAtSameIndices(expectedElements)
        
        sut = IndexedPriorityQueue(minimumCapacity: 0, sort: <)
        var other = MyTestSequence(givenElements, hasUnderestimatedCount: true, hasContiguousBuffer: false)
        sut.enqueue(contentsOf: other)
        assertContainsAtSameIndices(expectedElements)
        
        sut = IndexedPriorityQueue(minimumCapacity: 0, sort: <)
        other = MyTestSequence(givenElements, hasUnderestimatedCount: false, hasContiguousBuffer: false)
        sut.enqueue(contentsOf: other)
        assertContainsAtSameIndices(expectedElements)
        
        // Let's also test COW
        sut = IndexedPriorityQueue(minimumCapacity: 0, sort: <)
        var clone = sut!
        sut.enqueue(contentsOf: givenElements)
        XCTAssertFalse(sut.storage === clone.storage)
        XCTAssertTrue(clone.isEmpty)
        
        sut = IndexedPriorityQueue(minimumCapacity: 0, sort: <)
        clone = sut!
        sut.enqueue(contentsOf: other)
        XCTAssertFalse(sut.storage === clone.storage)
        XCTAssertTrue(clone.isEmpty)
        
        sut = IndexedPriorityQueue(minimumCapacity: 0, sort: <)
        for i in 0..<givenElements.count / 2 {
            sut.enqueue(givenElements[i])
        }
        clone = sut!
        sut.enqueue(contentsOf: givenElements[(givenElements.count / 2)..<givenElements.endIndex])
        XCTAssertFalse(sut.storage === clone.storage)
        let cloneExpectedElements = Dictionary<Int, String>(uniqueKeysWithValues: Array(givenElements[0..<(givenElements.count / 2)].enumerated()))
        for i in 0..<clone.capacity {
            XCTAssertEqual(clone.storage.getElement(for: i), cloneExpectedElements[i])
        }
    }
    
    // MARK: - dequeue() tests
    func testDequeue_whenIsEmpty_thenReturnsNil() throws {
        try XCTSkipIf(!sut.isEmpty)
        XCTAssertNil(sut.dequeue())
    }
    
    func testDequeue_whenContainsElements_thenReturnsElementsInSortOrder() {
        sut.enqueue(contentsOf: givenElements.shuffled())
        var expectedElements = givenElements.sorted(by: sut.storage.sort)
        expectedElements.reverse()
        while !sut.isEmpty {
            let expectedElement = expectedElements.popLast()
            XCTAssertEqual(sut.dequeue(), expectedElement)
        }
        XCTAssertTrue(sut.isEmpty)
        XCTAssertTrue(expectedElements.isEmpty)
    }
    
    func testDequeue_CopyOnWrite() {
        sut = IndexedPriorityQueue(minimumCapacity: 0, sort: <)
        var clone = sut!
        
        sut.dequeue()
        XCTAssertTrue(sut.storage === clone.storage)
        
        sut.enqueue(contentsOf: givenElements)
        clone = sut!
        sut.dequeue()
        XCTAssertFalse(sut.storage === clone.storage)
    }
    
    func testDequeue_reducesCapacityWhenNeeded() {
        sut = IndexedPriorityQueue(minimumCapacity: 0, sort: <)
        XCTAssertEqual(sut.storage.optimalCapacity, sut.capacity)
        var prevCapacity = sut.capacity
        sut.dequeue()
        XCTAssertEqual(sut.capacity, prevCapacity)
        
        sut.reserveCapacity(10)
        XCTAssertLessThan(sut.storage.optimalCapacity, sut.capacity)
        prevCapacity = sut.capacity
        sut.dequeue()
        XCTAssertLessThan(sut.capacity, prevCapacity)
        
        sut.enqueue(contentsOf: givenElements)
        sut.reserveCapacity(32)
        prevCapacity = sut.capacity
        XCTAssertGreaterThan((sut.storage.residualCapacity + 1), sut.capacity / 2)
        sut.dequeue()
        XCTAssertLessThan(sut.capacity, prevCapacity)
    }
    
    // MARK: - clear(keepingCapacity:) tests
    func testClearKeepingCapacity_whenKeepCapacityIsFalse_thenEmptiesStorageAndResizesItToMinimumCapacity() {
        sut.enqueue(contentsOf: givenElements)
        weak var prevStorage = sut.storage
        XCTAssertGreaterThan(sut.capacity, 4)
        sut.clear(keepingCapacity: false)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.capacity, 4)
        XCTAssertFalse(sut.storage === prevStorage)
    }
    
    func testCelarKeepingCapacity_whenKeepCapacityIsTrue_thenEmptiesStorageAndKeepItsCapacity() {
        var prevCapacity = sut.capacity
        weak var prevStorage = sut.storage
        sut.clear(keepingCapacity: true)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertTrue(sut.storage === prevStorage)
        
        sut.enqueue(contentsOf: givenElements)
        prevCapacity = sut.capacity
        prevStorage = sut.storage
        sut.clear(keepingCapacity: true)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertFalse(sut.storage === prevStorage)
    }
    
    func testClearKeepingCapacity_CopyOnWrite() {
        sut.enqueue(contentsOf: givenElements)
        let expectedCloneElements = Dictionary(uniqueKeysWithValues: Array(givenElements.enumerated()))
        var clone = sut!
        sut.clear(keepingCapacity: false)
        XCTAssertFalse(sut.storage === clone.storage)
        for i in 0..<clone.capacity {
            XCTAssertEqual(clone.storage.getElement(for: i), expectedCloneElements[i])
        }
        
        sut.enqueue(contentsOf: givenElements)
        clone = sut!
        sut.clear(keepingCapacity: true)
        XCTAssertFalse(sut.storage === clone.storage)
        for i in 0..<clone.capacity {
            XCTAssertEqual(clone.storage.getElement(for: i), expectedCloneElements[i])
        }
    }
    
    // MARK: - subscript tests
    func testSubscriptGetter_whenKeyIsNotAssociatedToAnElement_thenReturnsNil() {
        for i in 0..<sut.capacity {
            XCTAssertNil(sut[i])
        }
        
        let elements = givenElements.shuffled()
        sut.enqueue(contentsOf: elements)
        for i in sut.count..<sut.capacity {
            XCTAssertNil(sut[i])
        }
    }
    
    func testSubscriptGetter_whenKeyIsAssociatedToAnElement_thenReturnsSuchElement() {
        let elements = givenElements.shuffled()
        sut.enqueue(contentsOf: elements)
        for i in 0..<sut.count {
            XCTAssertEqual(sut[i], elements[i])
        }
    }
    
    func testSubscriptSetter_whenKeyHasNotAssociatedElementAndNewValueIsNil_thenNothingChnages() {
        sut.enqueue(contentsOf: givenElements)
        let expectedElements = Dictionary(uniqueKeysWithValues: Array(givenElements.enumerated()))
        for i in sut.count..<sut.capacity {
            let prevCount = sut.count
            sut[i] = nil
            XCTAssertEqual(sut.count, prevCount)
            assertContainsAtSameIndices(expectedElements)
        }
    }
    
    func testSubscriptSetter_whenKeyHasNotAssociatedElementAndNewValueIsNotNil_thenStoresSuchNewElementAssociatingItToGivenKey() {
        sut.enqueue(contentsOf: givenElements)
        var expectedElements = Dictionary(uniqueKeysWithValues: Array(givenElements.enumerated()))
        var newElement = "zz"
        for i in sut.count..<sut.capacity {
            expectedElements[i] = newElement
            let prevCount = sut.count
            sut[i] = newElement
            XCTAssertEqual(sut.count, prevCount + 1)
            newElement += "z"
        }
        assertContainsAtSameIndices(expectedElements)
    }
    
    func testSubscriptSetter_whenKeyHasAssociatedElementAndNewValueIsNil_thenRemovesElement() {
        sut.enqueue(contentsOf: givenElements.shuffled())
        for i in 0..<sut.count {
            let prevCount = sut.count
            sut[i] = nil
            XCTAssertNil(sut[i])
            XCTAssertEqual(sut.count, prevCount - 1)
        }
        XCTAssertTrue(sut.isEmpty)
    }
    
    func testSubscriptSetter_whenKeyHasAssociatedElementAndNewValueIsNotNil_thenChangesElementAssociatedToGivenKey() {
        sut.enqueue(contentsOf: givenElements.shuffled())
        var newElement = "z"
        for i in 0..<sut.count {
            newElement += "z"
            let prevCount = sut.count
            sut[i] = newElement
            XCTAssertEqual(sut[i], newElement)
            XCTAssertEqual(sut.count, prevCount)
        }
    }
    
    func testSubscriptSetter_CopyOnWrite() {
        sut.enqueue(contentsOf: givenElements)
        var clone = sut!
        let idx = Int.random(in: 0..<sut.capacity)
        sut[idx] = nil
        XCTAssertFalse(sut.storage === clone.storage)
        
        clone = sut!
        sut[idx] = "zz"
        XCTAssertFalse(sut.storage === clone.storage)
        
        clone = sut!
        sut[idx] = "zzz"
        XCTAssertFalse(sut.storage === clone.storage)
    }
    
    // MARK: - Sequence conformance tests
    func testUnderestimatedCount() {
        sut.enqueue(contentsOf: givenElements)
        while !sut.isEmpty {
            XCTAssertEqual(sut.underestimatedCount, sut.storage.count)
            sut.dequeue()
            XCTAssertEqual(sut.underestimatedCount, sut.storage.count)
        }
    }
    
    func testMakeIterator() {
        var iter = sut.makeIterator()
        XCTAssertNotNil(iter)
        XCTAssertNil(iter.next())
        
        let expectedElements = givenElements.shuffled()
        sut.enqueue(contentsOf: expectedElements)
        iter = sut.makeIterator()
        XCTAssertNotNil(iter)
        while let (key, element) = iter.next() {
            XCTAssertEqual(sut.storedElements, expectedElements)
            XCTAssertEqual(element, expectedElements[key])
            XCTAssertEqual(sut.storedElements, expectedElements)
        }
    }
    
    func testIterator_returnsElementsInSameOrderDequeuesThem() {
        let elements = givenElements.shuffled()
        sut.enqueue(contentsOf: elements)
        var result = [String]()
        for (_, element) in sut {
            result.append(element)
        }
        var idx = 0
        while !sut.isEmpty {
            let element: String? = sut.dequeue()
            XCTAssertEqual(element, result[idx])
            idx += 1
        }
    }
    
    func testPopTopMost() {
        for element in givenElements.shuffled() {
            sut.enqueue(element)
        }
        
        while !sut.isEmpty {
            let expected = sut.storage.peek()
            let result = sut.popTopMost()
            XCTAssertEqual(result?.key, expected!.key)
            XCTAssertEqual(result?.element, expected!.element)
        }
        XCTAssertNil(sut.popTopMost())
    }
    
    func testPopTopMost_COW() {
        for element in givenElements.shuffled() {
            sut.enqueue(element)
        }
        while !sut.isEmpty {
            let clone = sut!
            sut.popTopMost()
            XCTAssertFalse(sut.storage === clone.storage)
        }
        
        // when is empty:
        let clone = sut!
        sut.popTopMost()
        XCTAssertTrue(sut.storage === clone.storage)
    }
    
    func testContainsKey_whenIsEmpty_thenReturnsFalse() throws {
        try XCTSkipIf(!sut.isEmpty)
        for key in 0..<sut.capacity {
            XCTAssertFalse(sut.containsKey(key))
        }
    }
    
    func testContainsKey_whenIsFull_thenReturnsTrue() throws {
        for i in 0..<sut.capacity {
            sut[i] = givenElements[i]
        }
        try XCTSkipIf(!sut.isFull)
        for key in 0..<sut.capacity {
            XCTAssertTrue(sut.containsKey(key))
        }
    }
    
    func testContainsKey_whenContainsSomeelements_thenReturnsResultAccordinglyToGivenKeyBeingAssociatedWithAnElementOrFree() {
        sut.reserveCapacity(givenElements.count)
        let usedKeys = Set(givenElements.indices.shuffled()[0..<(givenElements.count / 2)])
        for key in usedKeys {
            sut[key] = givenElements[key]
        }
        
        for key in 0..<sut.capacity {
            if usedKeys.contains(key) {
                XCTAssertTrue(sut.containsKey(key))
            } else {
                XCTAssertFalse(sut.containsKey(key))
            }
        }
    }
    
    // MARK: - Helpers
    private func assertContainsAtSameIndices(_ elements: Dictionary<Int, String>, file: StaticString = #file, line: UInt = #line) {
        for idx in elements.keys {
            XCTAssertEqual(sut.storage.getElement(for: idx), elements[idx])
        }
    }
    
}

struct MyTestSequence<Element>: Sequence {
    let elements: Array<Element>
    let underestimatedCount: Int
    let hasContiguousBuffer: Bool
    
    init() {
        self.elements = []
        self.underestimatedCount = 0
        self.hasContiguousBuffer = true
    }
    
    init(elements: [Element], underestimatedCount: Int, hasContiguousBuffer: Bool) {
        self.elements = elements
        self.underestimatedCount = underestimatedCount >= 0 ? (underestimatedCount <= elements.count ? underestimatedCount : elements.count) : 0
        self.hasContiguousBuffer = hasContiguousBuffer
    }
    
    init(_ elements: [Element], hasUnderestimatedCount: Bool = true, hasContiguousBuffer: Bool = true) {
        self.elements = elements
        self.underestimatedCount = hasContiguousBuffer ? elements.count : 0
        self.hasContiguousBuffer = hasContiguousBuffer
    }
    
    // Sequence
    func makeIterator() -> AnyIterator<Element> {
        AnyIterator(elements.makeIterator())
    }
    
    func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Iterator.Element>) throws -> R) rethrows -> R? {
        guard hasContiguousBuffer else { return nil }
        
        return try elements.withUnsafeBufferPointer(body)
    }
    
}
