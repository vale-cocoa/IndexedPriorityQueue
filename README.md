# IndexedPriorityQueue

A Swift implementation of *Indexed Priority Queue* data structure.

`IndexedPriorityQueue` is a priority queue data structure which also associates every element to an non-negative `Int` value, defined as its *key*. That is stored elements can be accessed via enqueue/dequeue in priority order or via *key-based* subscription.

Traditionally the term *key* has been widely used referring to the *elements* stored in this type of data structure; though in this implementation the term *key* refers to the `Int` value associated to a stored *element*. 
That is in this data structure the term  *element* refers to what is traditionally called a *key*, while the term *key* referes to what is traditionally called an *index* in an indexed priority queue.

Priority of one element over another is defined via a *strict ordering function* given at creation time and invariable during the life time of an instance.
Such that given `sort` as the ordering function, then for any elements `a`, `b`, and `c`,
the following conditions must hold:
-   `sort(a, a)` is always `false`. (Irreflexivity)
-   If `sort(a, b)` and `sort(b, c)` are both `true`, then `sort(a, c)` is also `true`.
    ( Transitive comparability)
-   Two elements are *incomparable* if neither is ordered before the other according to the sort function.
-   If `a` and `b` are incomparable, and `b` and `c` are incomparable, then `a` and `c` are also incomparable.
    (Transitive incomparability)

