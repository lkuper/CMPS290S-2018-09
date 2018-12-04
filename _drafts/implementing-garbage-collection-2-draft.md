---
title: Implementing a Garbage-Collected Graph CRDT (Part 2 of 2)
author: Austen Barker
layout: single
classes: wide
---

<script type="text/javascript"
src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML,http://composition.al/javascripts/MathJaxLocal.js">
</script>

by Austen Barker &middot; edited by Sohum and Lindsey Kuper

## Background & Recap

In the previous blog post we discuss [Conflict-Free Replicated Data Types](https://hal.inria.fr/inria-00609399v1/document) (CRDTs), a class of specialized data structures designed to be replicated across a distributed system. We implemented a few CRDTs as specified by [Shapiro et al.'s _A Comprehensive Study of Convergent and Commutative Replicated Data Types_](https://hal.inria.fr/inria-00555588/document). Some of these implementations run into a perennial problem in distributed systems, distributed garbage collection. In the previous post we discussed multiple issues facing distributed garbage collection such as, high metadata storage costs, fault intolerance, and the need to stronger synchronization that betrays the asynchronous nature of a CRDT. To tackle these problems we look at a series of research avenues that include Paxos or Two-Phase Commit, [delta-state CRDTs](https://arxiv.org/pdf/1603.01529.pdf), and different methods of reducing metadata overhead for Shapiro et al.'s garbage collection scheme. We then take the Two Phase Set (2P-set) and use it as a basis for exploring these different CRDT garbage collection possibilities. We do not consider the Add-Remove Partial Order (ARPO) implementation from the previous blog post as the 2P-set encompasses the same challenges with far fewer lines of code. We also do not cover the topics of [causal trees](https://github.com/gritzko/ctre) and [pure operation-based CRDTs](https://arxiv.org/abs/1710.04469) in this blog post.

## Delta State CRDTs

[Delta-state CRDTs](https://arxiv.org/pdf/1603.01529.pdf) help to avoid the issue of sending the entire state of a data type over a network. The potentially large message sizes involved with classical state-based CRDTs result in them only being practical for small objects such as counters. A solution to this problem is only to transmit a delta that encompasses only changes made to a replica. These deltas can utilize the same join operations to apply updates to a local state with the additional ability to join multiple deltas into a group. The authors present a few anti-entropy algorithms that are used to ensure convergence and either eventual or causal consistency of the delta CRDT. In the causal consistency algorithm each node maintains two maps, one for keeping track of a sequence of deltas $D$ and another for a series of acknowledgments $A$ from each neighbor. Along with a counter that is incremented each time a delta is joined with the local state. When a node sends a delta interval to another the receiving node replies with an acknowledgment when it has merged the interval into its local state. In practice the delta interval would be every delta merged into the sending node's local state after the last acknowledgment from the receiving node. This acknowledgment is used to update the entry in $A$ corresponding to the receiving node. A delta that has been acknowledged by all of a nodes neighbors is then garbage collected and removed from the map $D$.

The previous blog post showed that the space complexity for storing the metadata necessary for $N$ nodes is $O(N^2)$. In the case of a delta CRDT we see that the metadata cost at each node for $|A|$ neighbors and $|D|$ stored deltas is $O(A + D)$. So instead of the state scaling quadratically with more replicas we see the state grow linearly depending on how many neighbors each node is keeping track of and how many deltas have been sent. Even though the delta CRDT metadata is only described as a way for garbage collection of deltas cached on each node, they can also be used to kill two birds with one stone. Providing both a means to perform garbage collection on deltas and tombstones due to the fact they both rely on determining causal relationships. When a delta that contains an operation that created a tombstone is garbage collected then we can assume that the tombstone is also garbage collected. This means that the programmer must maintain links between which tombstone applies to which delta but that can be done with a simple pointer.

In the case of our 2P-set implementation from the previous blog post we need only add the acknowledgment map, the delta map, and a counter. We can also re-use the struct Twopset to represent deltas.

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

In practice it is difficult to perform add and remove operations on the local state and then forward them to other replicas without additional metadata about each set element. An alternate approach is to treat all local operations as deltas that, although immediately merged into the local state, are persisted in the local delta map until they have been acknowledged by all neighbors. At which point they are garbage collected as normal. This creates a sort of log similar to those utilized by database systems.

Since the causally consistent delta CRDT metadata allows us to garbage collect tombstones we can now compare it to the $O(N^2)$ overhead of Shapiro et al.'s approach. If we assume that the set of neighbors is all $N$ nodes we see that the complexity is $O(N+D)$. Therefore if we keep the number of deltas in check and run local garbage collection regularly the metadata overhead is considerably decreased in comparison to the previous approach. Though the $O(N)$ overhead may still prove costly when operating at scale, only keeping track of a replicas immediate neighbors can further limit metadata size. 

There are still a few drawbacks for delta-CRDTs. First being that they do not entirely eliminate the metadata overhead problem but merely mitigate it. Secondly, they also still have certain cases where it is still necessary to transmit the entire state instead of a delta. Such as in the cases of an empty map of deltas or during crash recovery when there is a chance of data loss.

### Synchronized Garbage Collection

One of the easier ways of providing distributed garbage collection on CRDTs is through some form of stronger synchronization such as [Paxos Commit](https://lamport.azurewebsites.net/video/consensus-on-transaction-commit.pdf) and [Two-Phase Commit](https://en.wikipedia.org/wiki/Two-phase_commit_protocol). In this case the system will periodically run a garbage collection operation. The frequency of which should be tied to the rate at which tombstones are created or when the system approaches a maximum number of tombstones. In the case of Two-phase commit, each replica will vote on each tombstone and if all the replicas agree that the tombstone is no longer needed then it is garbage collected when the replicas are notified of the vote's outcome. The replicas need not vote on each tombstone individually and can submit a list of their tombstones to the coordinator which will then return a list of tombstones for the replicas to delete. The easiest way to perform this check on the coordinator would be to perform logical AND operations on the lists of tombstones. So if a tombstone corresponding to a specific set element is present in all replicas it would be safe to delete.

The major trade off between this and a garbage collection method dependent on demonstrating causal relationships is that while very little extra metadata is needed in order perform garbage collection it somewhat betrays the asynchronous nature of CRDTs. Although many implementation of Two-phase commit will require additional entities call Transaction Managers with which the replicas will register in order to perform garbage collection. These additional entities further complicate the programmer's job as they must not only account for the CRDT implementation, which has been shown in the previous post to be a non-trival task, but also separate synchronization mechanisms. In the end, whether or not to use synchronization for garbage collection depends which resources are scarce in deployment environment. If local storage space is scarce enough then it may be worth the additional network overhead and compromised availability to use something like Two-phase commit. 

### Space-Saving Optimizations

If a CRDT is not expected to have a long lifespan it is likely sufficient to simply perform some common space saving optimizations in order to minimize the effect of state explosion. As discussed in the previous blog post a tombstone can actually be rather small. In the case of a 2P-set or a ARPO the tombstone set can be represented as a bitmap with each bit corresponding to an element in a set. A bit is set when the corresponding element is deleted. Using this trick the storage space needed for tombstones become negligible. Although this does not eliminate the problem of garbage collection in its entirety as the set can still contain deleted elements after all replicas have marked them as deleted. Therefore this sort of optimization is best applied in conjunction with another garbage collection scheme.

Most programmers would consider a metadata overhead of $O(N^2)$ to be unacceptable. As shown with delta-CRDTs it is possible to abandon vector clocks and still perform distributed garbage collection. While delta-CRDTs are clearly a better solution there are other ways of achieving the same goal of $O(N)$ metadata overhead. Recall that in Shapiro et al.'s scheme the key for garbage collecting tombstones is to prove causal relationships. In a [blog post](http://www.bailis.org/blog/causality-is-expensive-and-what-to-do-about-it/) Peter Bailis discusses some work by Charron-Bost in the paper [Concerning the size of logical clocks in distributed systems](https://www.sciencedirect.com/science/article/pii/002001909190055M) where he claims that $O(N)$ is the best timestamp overhead one can achieve while providing the information necessary to show causal relationships. 

Bailis among others have described multiple [methods for reducing the space costs of vector clocks](http://www.bailis.org/blog/causality-is-expensive-and-what-to-do-about-it/). Two of the described methods involve decreasing availability and eliminating "happens-before" (causal) relations therefore necessitating synchronization. The third option of explicitly specifying relevant relationships only applies in certain cases (a message replying to another). This leaves us with restricting the number of replicas participating. Either putting a total upper bound on the number of participants or by only requiring a replica to store information about its immediate "neighbors", the definition of which can vary by implementation. This may be one of the optimizations that the authors of the delta CRDT paper allude to as "important in practice".

## Conclusion

As shown in Shapiro et al.'s paper, CRDTs often require maintaining tombstones in order to properly handle deleted elements. These tombstones can allow for a CRDT to experience unbounded growth if not garbage collected when they are no longer needed. As we have explored in these two blog posts the challenge of implementing a distributed garbage collection system for CRDTs is difficult. Whether it involves high metadata overhead or synchronization. In the case of the former option we have demonstrated a few methods with which a programmer can significantly reduce the metadata cost through either a few simple optimizations or through the use of delta-CRDTs. If a programmer wishes to use a state-based CRDT it would be prudent for them to instead utilize a delta-CRDT as it provides a relatively easy solution to implementing garbage collection among other benefits. In the case of Two-phase commit or Paxos commit there may be certain situations in which the additional overhead of performing a synchronized operation is considered acceptable. There are though a multitude of environment specific factors that can influence what methods a programmer would use to implement CRDT garbage collection. Though as stated in the previous post the easiest and perhaps best way for the programmer to tackle this problem is to rely on CRDTs that do not require tombstones or to keep the lifespan of a CRDT short as to mitigate unbounded growth.
