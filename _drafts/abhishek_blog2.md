---
title: "Conflict resolution in collaborative text editing with operational transformation (Part 2 of 2)"
author: Abhishek Singh
layout: single
classes: wide
---

by Abhishek Singh ⋅ edited by Devashish Purandare and Lindsey Kuper


## Introduction

In this post we continue our discussion on collaborative text editors. The goal of [part 1](http://composition.al/CMPS290S-2018-09/2018/11/20/conflict-resolution-in-collaborative-text-editing-with-operational-transformation-part-1-of-2.html) of the post was to provide an overview of the [dOPT](http://doi.acm.org/10.1145/67544.66963) operational transformation algorithm and how it addresses the problem of conflict resolution in collaborative text editing. We looked at the problem through a toy example under a set of assumptions that limited the scope of the problem. In this post we remove some of those assumptions and discuss the details of the dOPT algorithm as discussed in the paper.

Here's the list of the assumptions I made in my previous post:
>  1. Operation messages from either site are received exactly once.
>  2. There are exactly two editors in the system: one at Alice's end and the other at Bob's end.
>  3. My implementation does not use clocks to timestamp operations, so the _happens before_ relationship is established based on message delivery. It is assumed that LOCAL and REMOTE operations happen concurrently.
>  4. Operations are processed in the order in which they are seen and executed at a particular site. In our implementation the executed operations are stored in a list `OTEditor.Ops`.
>  5. Unlike the implementation in the [“Concurrency control in groupware systems” paper](http://doi.acm.org/10.1145/67544.66963), we do not assign priorities to an operation. Every operation has equal priority.
>  6. An operation is sent to others immediately after it was executed at one particular site. There is no out-of-order delivery of messages.


<figure>
  <img src="test_operations.png" height="600" width="450" />
  <figcaption>Figure 1. Operations received by Alice and Bob are transformed before being applied to local data.</figcaption>
</figure> 


Let us consider the consequences of removing these assumptions in the original implementation discussed in [part 1](http://composition.al/CMPS290S-2018-09/2018/11/20/conflict-resolution-in-collaborative-text-editing-with-operational-transformation-part-1-of-2.html). Primarily, there is a problem of ascertaining [causality](https://dl.acm.org/citation.cfm?id=359563) of messages in the design. Consider the second and third operations exchanged between Alice and Bob in Figure 1. There is no way for Alice to know if the operation `INSERT ("x", 2)` sent by Bob happened before or after Bob received the `INSERT("y", 0)` operation from Alice (even though we can see the figure and know that the operations were concurrent). This is more obvious in Figure 2. Alice cannot know the causal relationship because we did not address causality in part 1. Total order on the messages was enforced only by the order in which the messages were delivered to a user. Figure 2, shows that even with just two editors causality can break the best laid algorithms (which, in the case of my previous post, was far from being the best algorithm).

<figure>
  <img src="test_operations.png" height="600" width="450" />
  <figcaption>Figure 2. Alice does not know how Bob executed the operations at his end and therefore cannot know how received operations should be applied at her end.</figcaption>
</figure> 

It is easy to understand how operation messages are exchanged when only two users exist in the system. With increase in the number of users in the system, the number of messages needed to share changes with other users grows linearly. Since each user has a replica of the document, each change in the document state must be shared with the other users. If there are `n` users in the system, every state change at one user must be communicated with `n-1` users. With each user making changes to their document replica, the version of dOPT developed for the two-user collaborative text editor developed in part 1 cannot be used as there was no way knowing of the exact state of a replica when an operation was executed.

The possibility of receiving out-of-order messages is another issue that the design must address. The algorithm in post 1, executes messages on the replica in the order in which they are received without exception. This aggravates the problem of data inconsistency among the replicas if messages were delayed in transit and were not received in the same order in which they were generated. Suppose the operation  `INSERT ("x", 2)` in Figure 1 was delayed and received by Alice after the `DELETE (3)` operation from Bob.  This would lead to the operation being executed in different orders by Alice than at Bob’s end leading to data inconsistencies among the replicas. 


### The Distributed Operational Transformation (dOPT) algorithm

The crux of the data consistency problem discussed until now is that a site does not know the historical trace of an operation when it receives the operation request. We now look at the __dOPT__ algorithm proposed by [Ellis and Gibbs.](http://doi.acm.org/10.1145/67544.66963). The route proposed in the dOPT algorithm involves the use of a  [vector clock](https://en.wikipedia.org/wiki/Vector_clock) to order the operations generated on different sites (each site or user is associated with a single document replica. the document replica being an artifact on which the site executes an operation). The paper defines a _Convergence Property_ and a _Precedence Property_ and a notion of _quiescence_ to describe the correctness of the algorithm. The authors define the properties as follows:

> The _Precedence Property_ states that if one operation, _o_, precedes another, _p_, then at each site the execution of _o_ happens before the execution of _p_.

> A groupware session is _quiescent_ iff all generated operations have been executed at all sites, that is, there are no requests in transit or waiting to be executed by a site process.

> The _Convergence Property_ states that site objects are identical at all sites at quiescence.

The _Precedence Property_ mentioned above is stronger form of the [“happens before”](https://dl.acm.org/citation.cfm?id=359563) relationship. The “happens before” relationship defines a partial order between two events either as seen within a process or between the generation of a message and reception of that message. The _Precedence Property_ establishes a stronger connection between operation messages by establishing a relation between messages without any consideration of how the messages are received by a site: if an operation _o_ _happened before_ _p_, then the _Precedence Property_ ensures that regardless of the order in which other sites see operations _o_ and _p_, the _happened before_ relationship is enforced by _all_ sites. 

The _Convergence Property_ combined with the notion of quiescence is nearly identical to the Strong Convergence property defined in [CRDTs](https://link.springer.com/chapter/10.1007%2F978-3-642-24550-3_29). In the Ellis and Gibbs paper, however, quiescence is enforced periodically. The detection of quiescence is done via a distributed consensus algorithm, which is not discussed in the paper.

The dOPT algorithm is in essence an attempt at making sure that the transformations involved would allow the system to remain consistent. The dOPT algorithm described in the paper assumes a constant number of sites. For every change that a site makes to its replica, a request is generated and sent to other sites. To achieve the two properties the design uses a _request queue_ _Q<sub>i</sub>_ and a _request log_ _L<sub>i</sub>_, where the subscript _i_ is the site identifier. Throughout the rest of the discussion, site _i_ will be the location where the request is being processed and site _j_ will be the site which sent the request. The request queue contains operation requests either sent by remote sites (_j_) or from the user of the current site (_i_). These are requests that are waiting to be processed, and the queue acts as a buffer where all incoming requests are stored for further processing. The request log, on the other hand, is a log of requests that have been executed by the site. The log is a list of requests ordered by the order in which the requests were executed.

Each request has the form `<i, s, o, p>`, where, `i` represents the site identifier and `s` represents the state vector of the site `i`. The "state vector" as referred to in the  [Ellis and Gibbs paper](http://doi.acm.org/10.1145/67544.66963) is essentially a vector clock maintained by each site. `o` represents the operation to be performed (insert or delete). `p` specifies the priority of the operation. Additionally, the operations must commute, as discussed in my previous post. The additional property compared to my previous implementation is that the operation requests contain vector clocks that specify when an operation was executed on site _j_ and its relation to the operations in the request queue in site _i_.

Given two state vectors _s_<sub>_i_</sub> and _s_<sub>_j_</sub>, Ellis and Gibbs define the following relations:

> 1. _s_<sub>_i_</sub> = _s_<sub>_j_</sub> ; if each component of _s_<sub>_i_</sub> is equal to the corresponding component of _s_<sub>_j_</sub>.
> 2. _s_<sub>_i_</sub> &lt; _s_<sub>_j_</sub> ; if each component of _s_<sub>_i_</sub> is less than or equal to the corresponding component of _s_<sub>_j_</sub> and at least one component of  _s_<sub>_i_</sub> is less than the corresponding component in  _s_<sub>_j_</sub>.
> 3. _s_<sub>_i_</sub> &gt; _s_<sub>_j_</sub> ; if at least one component of  _s_<sub>_i_</sub> is greater than the corresponding component in  _s_<sub>_j_</sub>.

For example, if _s_<sub>_i_</sub> = `[ 1 2 3 3 ]` and _s_<sub>_j_</sub> = `[ 1 2 3 4 ]`, we have _s_<sub>_i_</sub> < _s_<sub>_j_</sub>.  However, if For example, if _s_<sub>_i_</sub> = `[ 4 3 2 1 ]` and _s_<sub>_j_</sub> = `[ 1 2 3 4 ]`, we have _s_<sub>_i_</sub> > _s_<sub>_j_</sub>. 





During initialization the following operations are done:

1. Set Q<sub>i</sub> to empty
2. Set L<sub>i</sub> to empty
3. Set s<sub>i</sub> to [0, 0, ..., 0]


The algorithm defines three possible execution states:

1. Operation request generation,
2. Operation request reception, and
3. Operation execution.

During "operation request generation" the site _i_ generates an operation (either insert or delete). The operation is not executed immediately; the local data is not modified during operation request generation. Once the request is generated it is appended to the site's request queue Q<sub>i</sub> and broadcast to all other sites.

>  Generate operation <i ,s<sub>i</sub> , o, p>

>  Q<sub>i</sub>  :=  Q<sub>i</sub>  +  <i ,s<sub>i</sub> , o, p>

A request generated on a site _j_ is eventually received by site _i_ which then moves to the "operation request reception" state. In this state, the received operations are appended to the site's request queue.  

> Receive operation request from remote site j: <j ,s<sub>j</sub> , o<sub>j</sub>, p<sub>j</sub> >

> Q<sub>i</sub>  :=  Q<sub>i</sub>  +  <j ,s<sub>j</sub> , o<sub>j</sub>, p<sub>j</sub> >

During "operation execution", requests from the request queue are processed. The order of execution of requests in the request queue is determined by the total order of events in the request queue as determined by the comparison of the state vectors. Briefly, in this step the operation from the request queue is chosen based on the executed operations in the request log. We locate the operation older than the current state vector at site _i_. Transformation is performed based on the operation logs in the request log. Comparison of the state vector follows the conditions stated previously. 

1. If the state vector of incoming request s<sub>j</sub> &gt; s<sub>j</sub>, this means that the site _j_ has executed operations which site _i_ has not seen yet. So this operation will have to stay in the queue till all operations between _i_ and _j_ have been executed. 
2. If s<sub>j</sub> = s<sub>j</sub>, the two state vectors are identical and operation o<sub>j</sub> can be executed without transformation.
3. If s<sub>j</sub> &lt; s<sub>j</sub>, site _i_ has executed operations not seen by site _j_. The operation can be applied immediately, but requires operations to be transformed because other changes not visible to site _j_ have already been executed by site _i_.

The principles behind transformations were discussed in my previous post. The main idea is that the transformations must commute. This allows the operations to be executed in any order. The idea of commutative operations is vital to any operational transformation technique. In fact, the idea of commutative operations is used in distributed systems very frequently for synchronization-free convergence algorithms. The idea was also proposed by [Attiya et al](http://doi.acm.org/10.1145/2933057.2933090) in their RGA protocol to tackle the problem of collaborative text editing. 

## A retrospective

Over the years there have been other solutions proposed to solve the problem of collaborative text editing. The [Jupiter collaboration system](https://dl.acm.org/citation.cfm?doid=215585.215706) looked at the problem from an architectural point-of-view. Instead of a peer-to-peer system as we have been discussing till now, the Jupiter system used a centralised architecture where a server maintains a single copy and all operation requests are handled via the server. This system became the basis of the Google Wave and Google Docs projects, as mentioned in my previous post.

In recent years, the operation transformation algorithm originally proposed by Ellis and Gibbs developed into a compendium of technologies. The problem of collaborative text editing has been tackled more recently by [Attiya et al](http://doi.acm.org/10.1145/2933057.2933090) in their algorithm which doesn't use operational transformation but does attempt to improve on the dOPT algorithm by proposing the RGA algorithm. The RGA algorithm shares operation history instead of vector clocks to allow the operations to be executed on remote systems. [CRDT](https://link.springer.com/chapter/10.1007%2F978-3-642-24550-3_29)s are another class of data structures that provide state convergence.

Over the course of the two blog posts I have aimed to understand the key ideas behind early specification of operational transformation and convey it with some clarity. When picking a topic for these blogs, I was interested studying in tools that enable cooperative work in software systems. Although the topic of cooperative text editing has been a topic of research since the 1980s, writing these blogs allowed me to study the problem in some detail. Working on these blogs has roused my interest in building systems where multiple agents can work together towards a common goal. Building useful abstractions for cooperative computing agents is something that will keep me busy for sometime.

