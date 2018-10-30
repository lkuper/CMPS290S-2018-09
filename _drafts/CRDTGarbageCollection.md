Attempted basic implementations are available here: https://github.com/atbarker/CRDTexperiments

# Background

## The Add-Remove Partial Order

The Add-Remove partial order CRDT presented in the paper is introduced as a solution to the mess that arises when one attempts to include vertex removals in their Operation based Monotonic Directed Acyclic Graph specification. A partial order is built using one Two Phase Set and one Growth Only Set. Oddly the authors decided to ignore the *addEdge* and *removeEdge* operations as "it was not clear what semantics would be reasonable". The absence of these operations do not hinder the reasoning about Garbage Collection presented in section four of the paper but it does prove to be a major problem when implementing the CRDT from the specification. Also problematic is the absence of any distinction about the implementation being operation or state based. Therefore there is no easy way to accurately reason about *Merge* or *Compare* operations that are described in the paper's earlier specifications.

The example of a situation in which garbage collection is useful is when an update to an Add-Remove Partial Order is applied and considered stable then one can discard the set of removed vertices.

## Garbage Collection

In section 4 the authors bring up the necessity of garbage collection when using a CRDT that maintains tombstones. Such as the state based two phase set and the Add-Remove Partial Order. These tombstones could potentially pile up and cause considerable unnecessary bloat. The difficulty with adding some form of garbage collection is that it will often require some degree of synchronisation. The paper presents two challenges related to garbage collection that are described as stability and commitment.

The purpose of the tombstone is to help resolve conflicts between concurrent operations by having a record of removed elements. Eventually this tombstone is no longer required when all concurrent updates have been "delivered" and an update can be considered stable. (insert formal definition reference here).  The paper applies a modified form of Wuu and Bernstein's stability algorithm (cite) that requires the replicas to maintain a set of all the other replicas and for there to be some mechanism to detect when a replica crashes. Concurrency of updates is determined via the use of vector clocks.

The commitment problems are described in a more vague and lackluster manner than stability problems but provide a much more interesting challenge for implementation. Commitment issues arise when one needs to perform an operation with a need for greater synchronization. Examples given by the authors are removing tombstones from a 2P-set or resetting all the replica payloads. The obvious conclusion is to require some atomic agreement between all replicas concerning the application of the desired operation.

# Implementation

CRDT's may seem simple on paper but they are most definitely not simple to implement as an actual computer program once one starts to worry about messaging reliability, replica failure, performance, and space concerns. It is my goal to explore the realistic implementation of a CRDT while still paying attention to performance, memory consumption, metadata size, and code complexity.

## Garbage Collection Considerations

Overall the goal of this post was to implement and test a CRDT with garbage collection that could be used to both test the usefulness of the paper's specifications and the behavior of Garbage Collection in a CRDT. To this end I decided to implement the ARPO structure used as an example in section four. The goal was to 

Initially I decided to attempt an implementation of the Add-Remove Partial Order (ARPO) design in Python to reduce development time. I realized that due to how Python handles multithreading (which is a lie, it doesn't) then any garbage collection thread running would impact performance by competing with the normal CRDT operations on a single CPU core. This would, in my opinion, negatively impact the results when comparing ARPOs with and without garbage collection. Therefore I re-implemented the system in Golang so I could easily run Garbage collection on its own thread and core. Therefore the garbage collection thread should not compete with the actual CRDT for CPU resources.

## Two Phase and Growth Only Sets

In order to implement the ARPO specification (or any of the graphs) it became necessary to first implement both Two Phase (2Pset) and Growth only (Gset) sets. Both were implemented as state based CRDTs rather easily from specifications 11 and 12. The Gset had only trivial operation rules with only basic single set operations needed for each function in the implementation. The 2Pset implementation is then built with two Gsets. One for added elements and one for removed elements. In these implementations basic sets are respresented as maps of key-value pairs. Where the key is of type interface and the value is another interface. The interface construct in Golang is an easy way to achieve polymorphism and allows the implementation to use practically anything as a key or value. The drawback is that it is up to the programmer to make sure data from the interface is processes properly. 

One interesting thing to note is that most of the implementation of the Gset is the same regardless of whether it is state or operation based. The only thing that I added to the implementation was an *ApplyOps* function that will apply a list of operations in order to the Gset (although these are only add's). The same was not true with the 2Pset where the biggest difference existed when removing elements. As concurrent add and remove operations are commutative the tombstone set is really only necessary when implementing a state based two phase set with the trade off being a few additional checks. We can also re-use the function from the Gset implementation to handle applying operations to another 2Pset as the operational 2Pset is simply a Gset with a removal function. 

One interesting observation is that a naive implementation of the 2Pset is not very space efficient as it can in the worst case require double the space of a Gset with the same number of elements. This bloat can be curtailed by maintaining the removal set as a bitmap. Each entry in the bitmap would correspond to an entry in the add set. The merge function for a 2Pset with a bitmap would use a bitwise OR operation between the bitmaps. This technique should also be applicable to other CRDT's that utilize tombstones.   

Due to the presence of tombstones in the state based 2Pset implementation it is sufficient for experimention with CRDT garbage collection. Although it would be significantly more interesting to do so with a more complicated structure.

## Implementing Specification 18: Add-Remove Partial Order

Due to the incomplete nature of the ARPO specification I decided to complete what the authors erroneously left unfinished. This meant that two issues had to be addressed. First being the absence of operations for *addEdge* and *removeEdge* as well as "reasonable" semantics and second being the absence of any information about whether the specification was operation or state based. The second distinction being necessary as that logically leads to how one would construct *Merge* and *Compare* operations. It follows that since the Add-Only Monotonic DAG (specification 17) is operation based then the ARPO is also operation based as at its core it is a minimal DAG. Also supporting this is the fact that no other operation based CRDT in the paper possesses *Merge* or *Compare* functions. To summarize this rant, the fact that a programmer must infer properties and construct their own operations shows how inadequate specification 18 is for actually writing code. It lends some credance to the claims of Burkhardt et al. that existing replicated data type specifications are lacking. Similarly to a the 2Pset CRDT it is possible to represent the removal set with a simple bitmap in order to save space.

## Implementing Garbage Collection on a CRDT

At a passing glance implementing garbage collection on a CRDT seems rather easy from reading section 4 from Shapiro et al. but once one starts exploring all that needs to be done to meet the guarantees and assumptions discussed the effort becomes rather daunting. It also becomes rather difficult to generalize the situation for CRDT garbage collection as it is very use case specific. For instance how often one must run garbage collection can greatly impact availability.

First off establishing the stability of an update as described in the paper assumes that the set of all replicas is known and that they do not crash permenantly. Thus the implementation must include some form of time out or crash detection and a way to communicate the failure of a given replica reliably to all other replicas. Assuming causal delivery of updates requires the use of vector clocks or some similar mechanism to establish causality. Vector clocks are specifically mentioned in section 4.1 for the purposes of determining stability. As the given definition of stability is dependent on causality one can use the same vector clocks to establish both. Although the presented scheme for determining stability requires each replica to store a copy of the last recieved vector clock from every other known replica. Therefore the space complexity required to locally store the vector clocks for N replicas is O(N^2). Considerably more than the normal O(N) necessary to determine causal relationships. As should be abundantly clear the metadata costs balloon to levels that would likely be uncomfortable for most programmers. There are some methods that can be used to manage the size of vector clocks (citation of bailis post) that could be applied to reduce the size of the vector clocks. 

When adding the class of commitment problems to the already mounting pile of dilmenas the programmer starts to lose a bit of hope for the availability and performance of their system. The solutions discussed by Shapiro et al. include Paxos commit and Two Phase commit protocols which are not trivial to implement and add considerably to the complexity of the implementation along with sacrificing availability. Shapiro's introduction brings up the idea of performing operations requiring strong synchronisation during periods when network partitions are rare. To add to this it is probably also beneficial to limit such operations to when the availability of a system is not paramount. For example one could run a garbage collection job during a scheduled server maintenance window.

All of this said if the programmer does not wish to delve headlong into some of the hardest problems in distributed systems the easiest solution to the unbounded growth of a CRDT is to use the Ostrich Algorithm.

# Conclusion





# Citations (need to finish adding these and format them correctly)
Burkhardt, Replicated Data Types: Specification, Verification, Optimality

http://www.bailis.org/blog/causality-is-expensive-and-what-to-do-about-it/

https://en.wikipedia.org/wiki/Ostrich_algorithm


