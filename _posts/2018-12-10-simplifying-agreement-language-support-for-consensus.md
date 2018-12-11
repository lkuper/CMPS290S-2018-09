---
title: "Simplifying Agreement: Language Support for Consensus"
author: Devashish Purandare
layout: single
classes: wide
---


by Devashish Purandare &middot; edited by Aldrin Montana and Lindsey Kuper


In [my last post](/CMPS290S-2018-09/2018/11/19/manufacturing-consensus-an-overview-of-distributed-consensus-implementations.html), we explored consensus mechanisms and why it is so hard to get
them right. Implementing consensus and other distributed protocols often requires implementing a lot of supporting functionality, resulting in long and complex code. This makes it
hard to verify whether the implemented protocol is true to its formal definition.
The ["Paxos Made Moderately Complex" implementation](https://github.com/denizalti/paxosmmc)
may be only 451 lines of Python code, but implementations used in state-of-the-art
systems are [much more complex](https://github.com/etcd-io/etcd/tree/master/raft). Popular Paxos and Raft implementations run into the thousands of lines of code. As the authors of [“Paxos Made Live”](https://static.googleusercontent.com/media/research.google.com/en//archive/paxos_made_live.pdf) point out:

> While Paxos can be described with a page of pseudo-code, our complete implementation contains several thousand lines of C++ code. The blow-up is not due simply to the fact that we used C++ instead of pseudo notation, nor because our code style may have been verbose. Converting the algorithm into a practical, production-ready system involved implementing many features and optimizations – some published in the literature and some not.

When using a general-purpose programming language to implement Paxos, then, we seem to have two options:

  - We can use a higher-level language like Python; such an implementation may be concise and relatively easy to understand, but not suitable for scalability and high performance.
  - Alternatively, we can use a lower-level language, such as C++, and write a scalable, high-performance implementation that is verbose and hard to understand.

Is there any way to have both high performance *and* ease of programmability?  Domain-specific languages (DSLs) [promise a way to have both programmability and performance by trading off generality](http://ppl.stanford.edu/papers/pact11-brown.pdf) -- so let's see how well that works!

In this blog post I plan to explore a special class of domain-specific languages
(DSLs) that have been designed for implementing
consensus protocols.

## Domain-Specific Languages for Distributed Systems

Programming distributed systems requires complex reasoning about the timing and order of messages sent and received, synchronization conditions, and other distributed-systems-specific concepts.  In general-purpose programming languages, it is hard to implement distributed algorithms while maintaining simplicity.

Various DSLs intended for implementing distributed algorithms -- especially consensus algorithms -- have been proposed, such as [DistAlgo](https://sites.google.com/site/distalgo/home), [Bloom](http://bloom-lang.net/), [Overlog](http://dl.acm.org/citation.cfm?id=1095818), and [PSync](https://dl.acm.org/citation.cfm?id=2837650). In this post we will do a deep dive into one of these: DistAlgo.

## DistAlgo

You might remember the infamous abstract from ["Paxos Made Simple"](https://lamport.azurewebsites.net/pubs/paxos-simple.pdf): "The Paxos algorithm, when presented in plain English, is very simple."  Yet, as we've seen,
implementing Paxos in practice is not so simple.  Some of the difficulty in trying to convert English pseudo-code into running code comes from the fact that the programming language we are using is not especially suited for expressing consensus protocols.

### A New Hope

What if
we could express distributed protocols in working code as easily as they are stated in pseudo-code?  This is where [DistAlgo](https://dl.acm.org/citation.cfm?id=2384645)
comes in! DistAlgo is a programming language that emphasizes the ability to clearly describe distributed algorithms. Prototyped in Python,
DistAlgo was built specifically to address the lack of support in general-purpose programming
languages for expressing constructs required for distributed algorithms.

The DistAlgo team has implemented a [variety of distributed algorithms](https://github.com/DistAlgo/distalgo/tree/master/da/examples)
to showcase their language's ability to express these algorithms in running code,
which can then be optimized, tested, and even formally verified.

### Paxos in DistAlgo

In ["Moderately Complex Paxos Made Simple,"](https://arxiv.org/pdf/1704.00082.pdf) the creators of DistAlgo discuss implementing a version of Paxos in DistAlgo.  The paper is an excellent read, not only for the implementation of Paxos that
they walk the reader through, but also the insight they offer on what makes
Paxos so hard to understand and implement.  For instance, Lamport's prose description of Paxos in the "Paxos Made Simple" paper involves the notion of a "promise", and the authors of "Moderately Complex Paxos Made Simple" devote some effort to making this notion precise, commenting:

> Indeed, this is the hardest part for understanding Paxos,
> because understanding an earlier phase requires understanding a later phase,
> which requires understanding the earlier phases.

The cyclic nature of the definition of the Paxos protocol is the cause of a lot
of the confusion surrounding it, and that's where [Raft](https://raft.github.io/) diverges from Paxos in its effort to
simplify consensus. (Although, as mentioned [in my previous post](/CMPS290S-2018-09/2018/11/19/manufacturing-consensus-an-overview-of-distributed-consensus-implementations.html), it is an [open question](https://twitter.com/copyconstruct/status/1061818753925578753)
whether Raft succeeds in doing that.)

#### DistAlgo's Superpowers!

DistAlgo supports the notion of a process, which presents interfaces for initialization 
(`setup`), code execution (`run`), and handling of received messages (`receive`).
`yield` makes the process allow handling of unhandled messages, and `await`
allows timeouts. Queries on message histories are divided into comprehensions, aggregations, and quantifications over sets.

This allows an easy implementation of simple Paxos, using just 72 lines of code.
The DistAlgo implementation can be compiled to Python or run directly.  The authors also argue that the high-level nature of the DistAlgo code allows easy translation to
[TLA+](https://lamport.azurewebsites.net/tla/tla.html) for subsequent verification.

### Moderately Complex Paxos Made Simple

The authors implement the version of Paxos we saw in [Paxos Made Moderately
Complex](http://dl.acm.org/citation.cfm?id=2673577), the version with slots and scouts and commanders! Unlike the original paper, though, they encapsulate the functionality of commanders and scouts back into the
leader to allow simpler code. The split in the original paper seemed unnecessary
from a correctness point of view; this assigns their actions to the leader.

The implementation ends up being about 100 lines of code in DistAlgo, and 300 in
Python. While this is smaller than the 450-line Python implementation of the original,
it also reduces or repackages some functionality.

In DistAlgo, it is trivial to
implement an optimization which keeps just the maximum numbered ballot for each
slot. The paper shows how this can be achieved by changing just one line of the code:

```python
accepted := {(b,s,c): received (’2a’,b,s,c)}
```
to
```python
accepted := {(b,s,c): received (’2a’,b,s,c), b = max {b: received (’2a’,b,=s,_)}}
```
This will pick the maximum ballot for each slot instead of keeping every ballot.

They also implement leader leases with timeout, similar optimization to the Google paper
to prevent unnecessary contention because of multiple readers.

The authors also manually translate the DistAlgo code into [TLA+](http://lamport.azurewebsites.net/tla/tla.html) and mechanically verify the TLA+ specification using [TLAPS](http://tla.msr-inria.inria.fr/tlaps/content/Home.html), discovering and correcting a safety violation in the original "Paxos Made Moderately Complex" pseudo-code which may cause `preempt` messages to never be delivered to the leaders.

Although initially enticed by the idea of implementing Paxos in DistAlgo, I am not sure DistAlgo achieves what it
sets out to do. It doesn't save a lot on the size of the code, and while the code
complexity is reduced, the original code for "Paxos Made Moderately Complex" was not very complex to begin with. What is somewhat disappointing is that both
resort to Python in the end, in a prototype which is not practical or useful to
the systems community and is limited by Python's limited support for multi-core
processing. For now, it offers us a relatively simple-to-write implementation of
Multi-Paxos that is presumably easy to manually convert to a TLA+ specification, but at least for the current stage of the prototype, it fails to
deliver on practical applicability.

### Raft in DistAlgo

Although the DistAlgo developers have an [implementation of Raft](https://github.com/DistAlgo/distalgo/blob/master/da/examples/raft/orig.da) in the "examples" directory of their [GitHub repo](https://github.com/DistAlgo/distalgo/), Raft isn't described in any of their papers.
This makes it unclear if the committed example is indeed complete or correct.  Nevertheless I dived into the specification code, so we can check for ourselves.
Testing the implementation was harder than expected. The pip module fails
installation, and the `setup.py` stops with an error. Whatever is working for the
authors doesn't seem to work for me. I checked with a fresh uncorrupted Python
`virtualenv` just to make sure, but it fails with similar issues. Thankfully,
the authors also provide binaries with the distribution, which seem to work.

Executing the Raft code spits out a wall of text that is the log messages produced by an example run of the protocol:

```
> ./dar ../da/examples/raft/orig.da
../da/examples/raft/orig.da compiled with 0 errors and 0 warnings.
[369] da.api<MainProcess>:INFO: <Node_:b2c01> initialized at 127.0.0.1:(UdpTransport=45231, TcpTransport=41250).
[369] da.api<MainProcess>:INFO: Starting program <module 'orig' from '../da/examples/raft/orig.da'>...
[370] da.api<MainProcess>:INFO: Running iteration 1 ...
[370] da.api<MainProcess>:INFO: Waiting for remaining child processes to terminate...(Press "Ctrl-C" to force kill)
[2542] orig.Server<Server:17c06>:OUTPUT: Heartbeat timeout, transitioning to Candidate state.
[2549] orig.Server<Server:17c06>:OUTPUT: Transitioning to Leader.
[3898] orig.Server<Server:17c06>:OUTPUT: LogEntry:1:<Client:17c09>:0  at index 1 applied to state machine.
[3899] orig.Client<Client:17c09>:OUTPUT: Request 1 complete.
[3899] orig.Server<Server:17c06>:OUTPUT: LogEntry:1:<Client:17c08>:0  at index 2 applied to state machine.
[3900] orig.Client<Client:17c08>:OUTPUT: Request 1 complete.
[3901] orig.Server<Server:17c05>:OUTPUT: LogEntry:1:<Client:17c09>:0  at index 1 applied to state machine.
[3901] orig.Server<Server:17c03>:OUTPUT: LogEntry:1:<Client:17c09>:0  at index 1 applied to state machine.
[3901] orig.Server<Server:17c06>:OUTPUT: LogEntry:1:<Client:17c07>:0  at index 3 applied to state machine.
[3902] orig.Client<Client:17c07>:OUTPUT: Request 1 complete.
.
.
.
.
[6923] orig.Client<Client:17c07>:OUTPUT: Request 3 complete.
[6926] orig.Server<Server:17c04>:OUTPUT: LogEntry:1:<Client:17c07>:2  at index 9 applied to state machine.
[6927] orig.Server<Server:17c02>:OUTPUT: LogEntry:1:<Client:17c07>:2  at index 9 applied to state machine.
[6926] orig.Node_<Node_:b2c01>:OUTPUT: All clients done.
[6929] orig.Server<Server:17c05>:OUTPUT: LogEntry:1:<Client:17c07>:2  at index 9 applied to state machine.
[6929] orig.Server<Server:17c03>:OUTPUT: LogEntry:1:<Client:17c07>:2  at index 9 applied to state machine.
[6929] da.api<MainProcess>:INFO: Main process terminated.


```


Curious as to what it was doing, I profiled the execution in the instruments
provided by Xcode.

<figure>
  <img src="/CMPS290S-2018-09/blog-assets/raft.png" alt="Instrumenting a DistAlgo run of Raft" />
</figure> 

The process spawns three threads (processes in an instance of Raft) and tries the
leader election protocol between them. In the execution, we can see the distribution
of work between threads, with more weight associated with more work, the particular
leader of that round. The Raft process updates state machines with the committed
entries.

Sadly, the comments do not tell us anything about the code and the execution. At
best it seems to be a proof of concept that Raft could be implemented in DistAlgo. One interesting thing is that the implementation
ends up being ~240 lines of code, with the expanded Python being around 360 lines. This
is in contrast to the much shorter ~100-line implementations of the Paxos protocols.
It is not completely clear why the Raft implementation is so much longer, but based on my interpretation of the code, the
leader election code and changes to allow support for “idle mode” increase the length of the code. The code also [combines several checks into single conditions](https://github.com/DistAlgo/distalgo/blob/master/da/examples/raft/orig.da#L96), resulting in dense code like:

```python
  if await(currentRole is not Leader):
            return
        elif some(n in range(len(log) - 1),
                  has= (n > commitIndex and
                        len(setof(i, i in matchIndex, matchIndex[i] >= n)) >
                        len(peers) / 2 and
                        log[n].term == currentTerm)):
            debug("Updating commitIndex from %d to %d" % (commitIndex, n))
            commitIndex = n
        # Idle timeout is half of normal term timeout:
        elif timeout(termTimeout/2):
            debug("Idle timeout triggered.")
            has_idled = True
```

## Closing Thoughts

When I started writing this post, the area of DSLs for distributed systems seemed
very promising. However, the state of the art turns out to be a bit
demoralizing. The DSLs mentioned in this post include fascinating ideas that
could change how we program distributed systems, but all of them are buggy and incomplete prototypes.  None of the languages mentioned at the start of this post have advanced beyond
the proof-of-concept stage.

If you want to use consensus in
your system today, it would be better to go with [battle-tested implementations](https://github.com/etcd-io/etcd) in general-purpose languages, as verbose and complex as they might be.  We need more researchers to look into the space of performance- and scalability-oriented DSLs for expressing distributed algorithms, and I hope the projects
discussed in this post mature beyond the prototype stage and become strong contenders.
