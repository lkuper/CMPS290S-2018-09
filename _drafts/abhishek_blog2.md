---
title: "Conflict resolution in collaborative text editing with operational transformation (Part 2 of 2)"
author: Abhishek Singh
layout: single
classes: wide
---

by Abhishek Singh


## Introduction

In this post we continue our discussion on collaborative text editors. The goal of [part 1](http://composition.al/CMPS290S-2018-09/2018/11/20/conflict-resolution-in-collaborative-text-editing-with-operational-transformation-part-1-of-2.html) of the post was to provide an overview of the problems encountered in collaborative text editing. We looked at the problem of consistency through a narrow set of assumptions. In this post we remove some of those assumptions to arrive at a more generalized solution to the problem of maintaining  consistency in a collaborative text editor.

Here's a list of the assumptions:
>  1. Operation messages from either sites are received exactly once.
>  2. There are exactly two editors in the system: one at Alice's end and the other at Bob's end.
>  3. My implementation does not use clocks to timestamp operations, so the _happens before_ relationship is established based on message delivery. It is assumed that LOCAL and REMOTE operations happen concurrently.
>  4. Operations are processed in the order in which they are seen and executed at a particular site. In our implementation the executed operations are stored in a list `OTEditor.Ops`.
>  5. Unlike the implementation in the [paper](http://doi.acm.org/10.1145/67544.66963), we do not assign priorities to an operation. Every operation has equal priority.
>  6. An operation is sent to others immediately after it was executed at one particular site. There is no out-of-order delivery of messages.


<figure>
  <img src="test_operations.png" height="600" width="450" />
  <figcaption>Figure 1. Operations received by Alice and Bob are transformed before being applied to local data.</figcaption>
</figure> 


Let's understand what would happen when some of these assumptions are removed from our original design. Primarily, there is a problem of ascertaining [causality](https://en.wikipedia.org/wiki/Causality) of messages in the design. Consider the second and third operations exchanged between Alice and Bob in Figure 1. There is no way for Alice to know if the third operation (INSERT ("x", 2)) sent by Bob happened before or after Bob received the second operation from Alice (INSERT("y", 0)). That's because we ignored causality in the last blog post. This is a major problem. Even with only two users in the system, there is enough uncertainty in the system when we don't consider the history of how changes happened in the system. This is just one of the problems I wish to address in this post.

The text editor in the first post consisted of only 2 users Alice and Bob. It was designed with only 2 users in mind. It is easy to understand how operation messages are exchanged when only two users exist in the system. With increase in the number of users in the system, the number of messages needed to share changes with other users grows linearly. Since each user has a replica of the document state, each change in the document state must be informed to the other users. If there are `n` users in the system, every state change at one user must be communicated with `n-1` users. With each user making changes to their document state the design of the two-user collaborative text editor developed in the last post cannot be used as there was no notion to find out the exact state on which the operation was executed.

The problem of receiving out-of-order messages or duplicate messages is another issue in the design. If the same message is received multiple times we will not be able to differentiate between duplicates or out of order messages and would execute the operation on the replica. This would aggravate the problem of data inconsistency among the users. This problem is resolved in the dOPT algorithm in the paper by [Ellis and Gibbs](http://doi.acm.org/10.1145/67544.66963) by using a vector clock.


### The Distributed Operational Transformation (dOPT)

The essence of the problem from one user's perspective is that we cannot trace the history of how a particular change was made and how it relates to that particular user's local replica history. This is the main problem. We now look at the algorithm proposed by [Ellis and Gibbs](http://doi.acm.org/10.1145/67544.66963) in the __dOPT__ algorithm more deeply to understand a possible solution to this problem. The route proposed in the dOPT algorithm involves the use of a vector clock to order the operations generated on different sites (each site is associated with a unique user). The paper defines a _convergence property_ and a _precedence property_ and a notion of _quiescence_ to describe the correctness of the algorithm. The authors define the properties as follows:

> The _Precedence Property_ states that if one operation, 0, precedes another, p, then at each site the execution of o happens before the execution of p.

> A groupware session is _quiescent_ iff all generated operations have been executed at all sites, that is, there are no requests in transit or waiting to be executed by a site process.

> The _Convergence Property_ states that site objects are identical at all sites at quiescence.

The dOPT algorithm in essence an attempt at making sure that the transformations involved would allow the system to remain consistent. The dOPT algorithm described in the paper assumes constant number of sites. For every change that a site makes to its replica, a request is generated and sent to other sites. To achieve the two properties the design uses a Request Queue Q<sub>i</sub> and a Request Log L<sub>i</sub>, where the subscript 'i' is the site identifier. Throughout the rest of the discussion site 'i' would be the location where the request is being processed and site 'j' will be the site which sent the request. The request queue contains operation requests either sent by remote sites (j) or from the user of the current site 'i'. These are requests that are waiting to be processed and the queue acts as a buffer where all incoming requests are stored for further processing. The request log on the other hand is a log of requests that have been executed by the site. The log is a list of requests ordered by the order in which the requests were executed.

Each request has the following form:

`<i, s, o, p>`

Here, `i` represents the site identifier. `s` represents the state vector of the site `i`. The "state vector" as referred to in the paper is essentially a vector clock maintained by each site. `o` represents the operation to be performed (insert or delete). `p` specifies a priority of the operation. Additionally, the operations must commute as discussed. The additional property compared to the previous implementation is that the operation requests contain vector clocks that specify when an operation was executed on site 'j' and its relation to the operations in the request queue in site 'i'.

Given two state vectors _s_<sub>_i_</sub> and _s_<sub>_j_</sub> the following relations are defined:

> 1. _s_<sub>_i_</sub> = _s_<sub>_j_</sub> ; if each component of _s_<sub>_i_</sub> is equal to the corresponding component of _s_<sub>_j_</sub>.
> 2. _s_<sub>_i_</sub> &lt; _s_<sub>_j_</sub> ; if each component of _s_<sub>_i_</sub> is less than or equal to the corresponding component of _s_<sub>_j_</sub> and at least one component of  _s_<sub>_i_</sub> is less than the corresponding component in  _s_<sub>_j_</sub>.
> 3. _s_<sub>_i_</sub> &gt; _s_<sub>_j_</sub> ; if at least one component of  _s_<sub>_i_</sub> is greater than the corresponding component in  _s_<sub>_j_</sub>.

Consider the following cases:

```text
Case 1:
    si = [ 1 2 3 4 ] 
    sj = [ 1 2 3 4 ]
    si = sj => True
```
```text
Case 2:
    si = [ 1 2 3 3 ] 
    sj = [ 1 2 3 4 ]
    si < sj => True
```
```text
Case 3:
    si = [ 4 3 2 1 ] 
    sj = [ 1 2 3 4 ]
    si > sj => True
```

The three cases shown above describe state vector comparisons as specified by dOPT. 

During initialization the following operations are done:

1. Set Q<sub>i</sub> to empty
2. Set L<sub>i</sub> to empty
3. Set s<sub>i</sub> to < 0, 0, ..., 0>


The algorithm defines three possible execution states:

1. Operation request generation,
2. Operation request reception, and
3. Operation execution,

During "operation request generation" the site 'i' generates an operation (either insert or delete). The operation is not executed immediately; the local data is not modified during operation request generation. Once the request is generated it is appended to the site's request queue Q<sub>i</sub> and broadcast to all other sites.

>  Generate operation <i ,s<sub>i</sub> , o, p>

>  Q<sub>i</sub>  :=  Q<sub>i</sub>  +  <i ,s<sub>i</sub> , o, p>

A request generated on a site 'j', is eventually received by site 'i' which then moves to the "operation request reception" state. In this state, the received operations are appended to the site's request queue.  

> Receive operation request from remote site j: <j ,s<sub>j</sub> , o<sub>j</sub>, p<sub>j</sub> >

> Q<sub>i</sub>  :=  Q<sub>i</sub>  +  <j ,s<sub>j</sub> , o<sub>j</sub>, p<sub>j</sub> >

During "operation execution", requests from the request queue are processed. The order of execution of requests in the request queue is determined by the total order of events in the request queue as determined by the comparison of the state vectors. Briefly, in this step the operation from the request queue is chosen based on the executed operations in the request log. We locate the operation older than the current state vector at site 'i'. Transformation is performed based on the operation logs in the request log. Comparison of the state vector follows the conditions stated previously. 

1. If the state vector of incoming request s<sub>j</sub> &gt; s<sub>j</sub>, this means that the site 'j' has executed operations which site 'i' has not seen yet. So this operation will have to stay in the queue till all operations between i and j have been executed. 
2. If s<sub>j</sub> = s<sub>j</sub>, the two state vectors are identical and operation o<sub>j</sub> can be executed without transformation.
3. If s<sub>j</sub> &lt; s<sub>j</sub>, site 'i' has executed operations not seen by site 'j'. The operation can be applied immediately but require operations to be transformed because other changes not visible to site 'j' have already been executed by site 'i'.

The principles behind transformations were discussed in the first post. The main idea is that the transformations must commute. This allows the operations to be executed in any order. The idea of commutative operations is vital to any operational transformation technique. In fact, the idea of commutative operations is used in distributed systems very frequently for synchronization free convergence algorithms. The idea was also proposed by [Attiya et al](http://doi.acm.org/10.1145/2933057.2933090) in their RGA protocol to tackle the problem of collaborative text editing. 

## A retrospective

Over the years there have been other solutions proposed to solve the problem of collaborative text editing. The [Jupiter collaboration system](https://dl.acm.org/citation.cfm?doid=215585.215706) proposed by resolving the architecture of the interactions between the sites. Instead of a peer-to-peer system as we have been discussing till now, the Jupiter system used a centralised architecture where a server maintains a single copy and all operation requests are handled via the server. This system became the basis of Google Wave and Google Docs projects as mentioned in the previous posts. In recent years, the operation transformation algorithm originally proposed by Ellis and Gibbs developed into a compendium of technologies. The problem of collaborative text editing has been tackled more recently by [Attiya et al](http://doi.acm.org/10.1145/2933057.2933090) in their algorithm which doesn't use operational transformation but does attempt to improve on the dOPT algorithm by proposing the RGA algorithm. The RGA algorithm shares operation history instead of vector clocks to allow the operations to be executed on remote systems. [CRDT](https://link.springer.com/chapter/10.1007%2F978-3-642-24550-3_29)s are another class of algorithms that allow data types to be created which allow state convergence.
