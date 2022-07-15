---
title: Implementing a Garbage-Collected Graph CRDT (Part 2 of 2)
author: Austen Barker
layout: single
classes: wide
---

<script type="text/javascript"
src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML,https://decomposition.al/javascripts/MathJaxLocal.js">
</script>

by Austen Barker &middot; edited by Sohum Banerjea and Lindsey Kuper

## Background & Recap

In [my previous blog post](/CMPS290S-2018-09/2018/11/12/implementing-a-garbage-collected-graph-crdt-part-1-of-2.html), we discussed [Conflict-Free Replicated Types](https://hal.inria.fr/inria-00609399v1/document) (CRDTs), a class of specialized data structures designed to be replicated across a distributed system. We implemented a few CRDTs as described in [Shapiro et al.'s _A Comprehensive Study of Convergent and Commutative Replicated Data Types_](https://hal.inria.fr/inria-00555588/document). 

CRDT implementations often run into the issue of distributed garbage collection, a perennial problem in distributed systems.  My previous post discussed multiple challenges involved with implementing distributed garbage collection: high metadata storage costs, fault intolerance, and the need for synchronization, which runs counter to the asynchronous nature of a CRDT. 

To tackle these problems,  of research avenues, including Paxos Commit and Two-Phase Commit, [delta state CRDTs](https://arxiv.org/pdf/1603.01529.pdf), and various methods for reducing metadata overhead in Shapiro et al.'s garbage collection scheme. We explore these different garbage collection mechanisms in the context of our two-phase set (2P-Set) CRDT implementation. 

## Delta State CRDTs

Almeida, Shoker, and Baquero proposed [delta state CRDTs](https://arxiv.org/pdf/1603.01529.pdf), or delta-CRDTs for short, which help to avoid the issue of sending the entire state of a data structure over a network. The potentially large message sizes involved with classical state-based CRDTs result in them only being practical for small objects such as counters. A solution to this problem is to transmit a _delta_ that encompasses only changes made to a replica. Not only do delta-CRDTs address the problem of large message sizes, they also give us an efficient way to enable asynchronous garbage collection.

In delta-CRDTs, deltas use the same join operations as traditional state-based CRDTs to apply updates to a local state, with the additional ability to join multiple deltas into a group. Temporally ordered deltas can also be joined into groups called delta-intervals which allow the programmer to transmit and join deltas in batches and assist in establishing a causal ordering of events.  Almeida, Shoker, and Baquero present two anti-entropy algorithms that respectively ensure eventual consistency and per-object causal consistency of delta-CRDTs. 

In the causal-consistency-ensuring anti-entropy algorithm, each node maintains two metadata maps (for keeping track of the sequence of deltas $D$ and the sequence of acknowledgments $A$), and a counter that is incremented each time a delta is joined with the local state. When a node sends a delta-interval to another, the receiving node replies with an acknowledgment after merging the interval into its local state. In practice, this delta-interval is every delta merged into the sending node's local state after the last acknowledgment from the receiving node. A delta that has been acknowledged by all of a node's neighbors is then garbage-collected and removed from the map $D$.

In my previous blog post, we saw that for traditional CRDTs, the space complexity for storing the metadata necessary for $N$ nodes is $O(N^2)$ ($N$ vector clocks, each of size $N$, keeping track of the latest received vector clock from each replica).  This metadata is needed to show causal relationships between updates, so that we can know when an update is “stable” or received by all replicas.

For delta-CRDTs, Almeida, Shoker, and Baquero show that for delta-CRDTs, the metadata storage cost at each node with $\lvert A \rvert$ neighbors and $\lvert D \rvert$ stored deltas is $O(\lvert A \rvert + \lvert D \rvert)$. That is, instead of the state scaling quadratically with more replicas, it grows linearly with how many neighbors each node is keeping track of and how many deltas have been sent. 

Even though the delta-CRDT metadata is only described as a way to enable garbage collection of deltas cached on each node, it can serve an additional purpose. The causal-consistency-enforcing anti-entropy algorithm does pretty much the same thing as the $O(N^2)$ scheme from the previous paper, but to garbage-collect deltas. So, why not garbage-collect deltas and tombstones together? When a delta that contains an operation that created a tombstone is garbage-collected, we can assume that the tombstone is also garbage-collected. We do need to associate tombstones with their deltas, but that can be done with a simple pointer.

To apply this mechanism to [our 2P-Set implementation](https://github.com/atbarker/CRDTexperiments/tree/master/Twopset) from my previous post, we need only add the acknowledgment map, the delta map, and a counter. We can also re-use the `struct Twopset` to represent deltas.

```go
type IntMap map[int]interface{}

type Twopset struct{
        addGset         *Gset.Gset
        remGset         *Gset.Gset
        ACK             IntMap //map of acknowledgments from all neighbors
        Deltas          IntMap //map of deltas currently "in flight"
        DeltaCounter    int //incremented to the latest delta merged into the local state
        Interval        int //if this is an interval then this is the earliest counter value encompassed by the interval, -1 if not an interval
}

func Newtwopset() *Twopset{
        return &Twopset{ 
                addGset: Gset.NewGset(),
                remGset: Gset.NewGset(),
                DeltaCounter: 0, //overridden if the Twopset is a delta/interval
                Interval: -1,
        }
}
```

In practice, it is difficult to perform add/remove operations on the local state and then forward them to other replicas. Instead, we can treat all local operations as deltas that, though immediately merged into the local state, are persisted in the local delta map until they have been acknowledged by all neighbors. This creates a log similar to those in database systems.

Since the causally consistent delta-CRDT metadata allows us to garbage-collect tombstones, we can compare its space usage to the $O(N^2)$ overhead of Shapiro et al.'s approach. If we treat every node as neighboring every other node, the space complexity is $O(N+D)$. Therefore, if we keep the number of deltas in check and run local garbage collection regularly, the metadata overhead is considerably decreased. The $O(N)$ overhead may still prove costly at scale.  Therefore, instead of keeping track of each replica, we only keep track of a replica's immediate neighbors, which effectively caps the maximum metadata size on each node.

There are still a few drawbacks of delta-CRDTs. Firstly, they do not entirely eliminate the metadata overhead problem. Secondly, there still are cases where it is necessary to transmit the entire state, including when we have to send the empty map of deltas, and during crash recovery.

### Synchronized Garbage Collection

One way of providing distributed garbage collection for CRDTs is with strong synchronization using a distributed commitment protocol such as [Paxos Commit](https://lamport.azurewebsites.net/video/consensus-on-transaction-commit.pdf) or [two-phase commit](https://en.wikipedia.org/wiki/Two-phase_commit_protocol).  In this approach, the system will periodically run a garbage collection operation.  The frequency of this operation should be tuned to the rate at which tombstones are created, or the operation can be triggered when the system approaches a maximum number of tombstones. 

Under two-phase commit, each replica will vote on whether each tombstone is still necessary. If all the replicas agree that the tombstone is no longer needed, it is garbage-collected when the replicas are notified of the vote's outcome. The replicas need not vote on each tombstone sequentially, and can submit a list of their tombstones to a coordinator, instead, receiving in return a list of tombstones to delete. The trade-off between this mechanism and the delta-CRDT approach is that while very little extra metadata is needed in order to perform garbage collection, it requires a lot of coordination between nodes,  which runs counter to the asynchronous nature of CRDTs. In addition, the need for a coordinator creates a single point of failure and undermines the inherent fault tolerance of CRDTs.

Many implementations of two-phase commit will require additional entities (“transaction managers”) with which the replicas must register in order to perform garbage collection. These additional entities further complicate the programmer's job, as they must not only account for the CRDT implementation (a non-trivial task, as we saw in my previous post), but also separate synchronization mechanisms. 

In the end, whether or not to use synchronization for garbage collection depends on which resources are scarce in the production environment. If local storage space is scarce enough, it may be worth the additional network overhead and compromised availability to explicitly synchronize. 

### Space-Saving Optimizations

If a CRDT is not expected to have a long lifespan, instead of doing garbage collection it is likely sufficient to simply perform some common space-saving optimizations, in order to minimize the effect of state explosion.

As discussed in my previous post, a tombstone can actually be rather small.  In the case of a 2P-Set or an ARPO, the tombstone set can be represented as a bitmap with each bit corresponding to an element in the set being deleted. Using this trick, the storage space needed for tombstones become negligible. This does not eliminate the problem of garbage collection in its entirety, though, as the set can still contain deleted elements after all replicas have marked them as deleted. Therefore this sort of optimization is best applied in conjunction with another garbage collection scheme.

As a programmer, a metadata overhead of $O(N^2)$ gives me pause, but as we saw with delta-CRDTs, it is possible to use less space and still perform distributed garbage collection.  There are also other ways of achieving the same goal of $O(N)$ metadata overhead.

Recall that in Shapiro et al.'s approach, the key to garbage-collecting tombstones is to track causal relationships. In a [blog post](http://www.bailis.org/blog/causality-is-expensive-and-what-to-do-about-it/), Peter Bailis discusses [work by Bernadette Charron-Bost](https://www.sciencedirect.com/science/article/pii/002001909190055M) that showed that $O(N)$ is the lowest timestamp overhead one can achieve while still providing the information necessary to show causal relationships.  Bailis suggests various ways to reduce the space costs of vector clocks. The last method he describes is restricting the number of replicas participating, either by putting a total upper bound on the number of participants, or by only requiring a replica to store information about its immediate "neighbors". This may be one of the optimizations omitted from  the delta-CRDT paper that the authors nevertheless describe as being "important in practice".

## Conclusion

CRDTs often require maintaining tombstones in order to properly handle deleted elements. Without some kind of garbage collection mechanism, these tombstones cause a CRDT to require unbounded space.

Distributed garbage collection mechanisms are difficult to implement and are costly, whether that cost is in metadata overhead or synchronization. In the former case, we've discussed ways in which a programmer can significantly reduce the metadata cost, either through a few simple optimizations or through the use of delta-CRDTs. If a programmer wishes to use a state-based CRDT, it may be prudent for them to instead use a delta-CRDT as it provides a relatively easy solution to implementing garbage collection, among other benefits. In the latter case --- synchronisation --- there may be situations in which the additional overhead of performing a synchronized operation is considered acceptable. 

There are a multitude of environmental factors that can influence the programmer's choice of CRDT garbage collection mechanism. For instance, if it’s desirable to be able to adjust the frequency of the garbage collection operation based on load, it would be easier to avoid synchronization and choose a mechanism that runs individually at each replica.

The conclusion may be, of course, the same conclusion we drew in the last post: the easiest and best way to tackle this problem may just be to rely on CRDTs that do not require tombstones, or that keep the lifespan of a CRDT short.
