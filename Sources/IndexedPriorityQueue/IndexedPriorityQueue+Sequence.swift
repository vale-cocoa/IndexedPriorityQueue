//
//  IndexedPriorityQueue+Sequence.swift
//  IndexedPriorityQueue

//  Created by Valeriano Della Longa on 2021/07/23.
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

extension IndexedPriorityQueue: Sequence {
    internal struct StorageIterator: IteratorProtocol {
        internal var indexedPQ: IndexedPriorityQueue
        
        internal init(indexedPQ: IndexedPriorityQueue) {
            self.indexedPQ = indexedPQ
        }
        
        internal mutating func next() -> (index: Int, element: Element)? {
            guard
                !indexedPQ.isEmpty
            else { return nil }
            
            return indexedPQ.storage.pop()
        }
        
    }
    
    public var underestimatedCount: Int { storage.count }
    
    public func makeIterator() -> AnyIterator<(index: Int, element: Element)> {
        AnyIterator(StorageIterator(indexedPQ: self))
    }
    
}
