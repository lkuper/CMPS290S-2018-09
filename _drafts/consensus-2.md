---
title: "Simplifying Agreement : Language Support for Consensus"
author: Devashish Purandare
layout: single
classes: wide
---

by Devashish Purandare &middot; edited by Aldrin Montana and Lindsey Kuper

In the last post we explored consensus mechanisms and why is it so hard to get
them right. Implementing consensus results in high code complexity. This makes it
hard to verify whether the implemented protocol is true to its formal version.
The ["Paxos Made Moderately Complex" implementation](https://github.com/denizalti/paxosmmc)
may be only 451 lines of python code, but implementations used in state of the art
systems are much more complex. Popular Paxos and Raft implementations run into
thousands of lines of code, with a lot of supporting components outside of the
core algorithm, such as back-off protocols, test suites, garbage collection,
and supporting libraries.

General purpose programming languages often lack the expressibility for the
components of a distributed system. This adds to the complexity of the code,
and causes the implemented protocol to be constrained by the limitations of the
programming language.

In this blog post I plan to explore a special class of Domain Specific Languages
(DSLs) that have been designed for distributed systems and how they implement
consensus protocols.

## Domain Specific Languages for Distributed Systems

Distributed systems encompass complex mechanisms that require semantics for
the notion of time, synchronization conditions, support for message reordering
and histories, logical operations and other distributed systems specific support.
In traditional programming languages, it is hard to allow this expression, while
maintaining simplicity.

The sample implementations we see online are often done in high level languages
like Scala, Python, or Java. While it is easy to reason about these languages
and understand the code, they limit the scalability of the program by limitations
such as the interpreter lock and garbage collection.

This leaves us in a situation where Distributed protocols are expressed in
very high level pseudocode which is extremely hard to implement as apparent from
the ["Paxos Made Moderately Complex" sample implementation.](https://github.com/denizalti/paxosmmc)
Which is still pretty high level. Or we can read the code from low level optimized
implementations such as Cassandra which are specific and stripped down to ensure
maximum performance. The understandable code is hard to implement, and the implemented
code is hard to understand.

Over the next few sections, we will go over recent work in distributed systems
domain specific languages, and how they simplify implementing, and optimizing
consensus protocols.

## DistAlgo

You might remember the infamous abstract from ["Paxos Made Simple"](),
> "The Paxos algorithm, when presented in plain English, is very simple.".

Yet as we saw in the last post,
implementing Paxos practically is extremely complex and hard to reason about.
We often end up with thousands of lines of code for Paxos, which can be buggy
and not according to specifications, as we have layers of abstractions to
implement and deal with.

The difficulty arises because we have been trying to convert English into a high
level programming language, which is difficult due to all the limitations imposed
as our expressibility is limited by what is offered by the imperative programming
paradigm. We get no help from our programming language, and in fact we have to
fight its linear tendencies to implement a linear system.

#### A new Hope

What if our programming language helped us enforce variants? What if
we could express our protocols as simply as stating in English?

This is where [DistAlgo](https://dl.acm.org/citation.cfm?id=2384645)
comes in! DistAlgo a framework that allows implementation of distributed algorithms
in a domain specific language. DistAlgo was prototyped in Python,
built specifically to address the lack of the ability of traditional programming
languages to express conditions required for distributed algorithms.

The DistAlgo team has implemented a [variety of distributed algorithms](https://github.com/DistAlgo/distalgo/tree/master/da/examples)
to showcase their language's ability to easily translate pseudocode into code,
which can then be optimized, tested, and even formally verified. We will discuss
their Paxos and Raft implementations in this post.

### Paxos in DistAlgo

In [this paper](https://arxiv.org/pdf/1704.00082.pdf) the DistAlgo authors
discuss implementation of Paxos in DistAlgo.

The paper is an excellent read, not only for the implementation of Paxos that
they walk the reader through but also the insight they offer on what makes
Paxos so hard to understand and implement.

> "Indeed, this is the hardest part for understanding Paxos,
> because understanding an earlier phase requires understanding a later phase,
> which requires understanding the earlier phases."

The cyclic nature of the definition of the Paxos protocol is the cause of a lot
of the confusion surrounding it, and that's where Raft diverges in its effort to
simplify consensus. (Although as mentioned earlier, it is an [open question](https://twitter.com/copyconstruct/status/1061818753925578753)
whether Raft succeeds in doing that).


#### DistAlgo's Superpowers!

DistAlgo implements the notion of `P` process, which presents interfaces for
`setup`, code execution `run`, and handling of received messages `receive`.
`yeild` makes the process allow handling of unhandled messages, and `await`
allows timeouts. Queries are divided into comprehensions, aggregations, and
quantifications over sets.

This allows an easy implementation of simple Paxos, using just 72 lines of code,
an implementation which can be compiled to Python or run directly, allowing
verification in [TLA+](https://lamport.azurewebsites.net/tla/tla.html)


### Moderately Complex Paxos Made Simple

The authors implement the Paxos instance we observed in [Paxos Made Moderately
Complex](), the version with slots and scouts and commanders! They also implement
Unlike the original Google
paper, they encapsulate the functionality of commanders and scouts back into the
leader to allow simpler code. The split in the original paper seemed unnecessary
from a correctness point of view this assigns their actions to the leader.

The implementation ends up being about 100 lines of code in DistAlgo, and 300 in
Python. While this is smaller than the 450 line implementation of the original,
it also reduces or repackages some functionality. The paper gives an insightful
perspective into implementing Paxos, but in the end is hamstrung by limitation
of the language and runs into some issues with the protocol implementation.

**Optimizations** : Because of this simplified interface, it is trivial to
implement optimization which keeps just the maximum numbered ballot for each
slot. The paper shows how this can be achieved by changing just 1 line of the code :

```python
accepted := {(b,s,c): received (’2a’,b,s,c)}
```
to

```python
accepted := {(b,s,c): received (’2a’,b,s,c), b = max {b: received (’2a’,b,=s,_)}}
```
this will pick the maximum ballot for each slot instead of keeping every ballot.

They implement leader leases with timeout, similar optimization to the Google paper
to prevent unnecessary contention because of multiple readers.

The paper also formally verifies the implementation of Paxos made moderately
complex, discovering and correcting a safety violation which may cause
`preempt` messages to
never be delivered to the leaders and fixes it.

Although initially enticed by this idea, I am not sure DistAlgo achieves what it
sets out to do. It doesn't save a lot on the size of the code, and while the code
complexity is greatly reduced, the original code for Paxos Made Moderately Complex,
was not very hard to begin with. What is somewhat disappointing is that both
resort to Python in the end, in a prototype which is not practical or useful to
the system's community and is limited by Python's limited support for multi-core
processing. As for now, it offers us a simple to write, verified version of
Multi-Paxos, but at least for the current stage of the prototype, it fails to
deliver on some of its promises.


### Raft in DistAlgo

Unlike their Paxos implementation which is detailed in the arxiv, Raft receives
no such love from the authors. Ignored in the OOPSLA and TOPLAS and other papers,
the only evidence of Raft in DistAlgo is the [specification file](https://github.com/DistAlgo/distalgo/blob/master/da/examples/raft/orig.da)
under examples.
This makes it unclear if the committed example is indeed complete or correct,
nevertheless I dived into the specification code, so we can check for ourselves.
Testing the implementation was harder than expected. The pip module fails
installation and the `setup.py` stops with an error. Whatever is working for the
author doesn't seem to work for me. I checked with a fresh uncorrupted Python
`virtualenv` just to make sure, but it fails with similar issues. Thankfully,
the authors also provide binaries with the distribution, which seem to work.

Executing the raft code spits out a wall of text that is the sample
implementation

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

![Instrumenting Raft](raft.png)

The process spawns 3 threads (Processes in an instance of raft) and tries the
leader election protocol between them. In the execution, we can see the distribution
of work between threads, with more weight associated with more work, the particular
leader of that round. The raft process updates state machine with the committed
entries.

Sadly, the comments do not tell us anything about the code and the execution. At
best it seems to be a proof of concept that raft could be implemented, but seems
to lack depth and rigor beyond that. One interesting thing is that the specification
ends up being ~240 lines of code, with the expanded Python being around 360. This
is in contrast to the much smaller ~100 line implementations of the Paxos protocols.
It is not completely clear, but based on my interpretation of the code, the
term limits and changes increase the length of code.



While DistAlgo is the example that stands out the most, there have been other
attempts at simplifying implementation of distributed systems. Let's see other
popular simplifications of Paxos and Raft :

## PlusCal ( +CAL )

Leslie Lamport describes the motivation behind him developing PlusCal in his usual
straightforward and blunt manner :

> Algorithms are different from programs and should not be described with 
> programming languages. The only simple alternative to programming languages
> has been pseudo-code.

[PlusCal](https://lamport.azurewebsites.net/pubs/pluscal.pdf)
was specifically designed to express algorithms using the [TLA+]() specification,
allowing transpilation into TLA+ and formal checking using the TLA checker. Lamport
notes that while pseudo-code is commonly used to express algorithms, it has no
standardized format and can cause a lot of ambiguities. PlusCal is designed
specifically to express pseudo-code of algorithms, keeping the programming aspects
aside.

```
--algorithm HelloWorld
    begin print “Hello, world.”
    end algorithm
```
is an example of a simple hello world program from the paper.

### Byzantizing Paxos by Refinement

In ["Byzantizing Paxos by Refinement"](), Lamport discuses how modifications to the
requirements of the algorithm could make it tolerate [Byzantine faults]() (along
with the fact that any noun can be turned into a verb).

In a follow up paper, ["The PlusCal Code for Byzantizing Paxos by Refinement"]()
Lamport writes about how the approaches from the paper
can be implemented in PlusCal. The paper describes implementation of Paxos
in PlusCal, and this quote about the termination is my favorite paper:

> Technically, the algorithm deadlocks after executing a _Choose()_ action
> because control is at a statement whose execution is never enabled.
> **Formally, termination is simply deadlock that we want to happen.**

PlusCal allows us to turn the pseudo-code for _byzantized_ Paxos into a TLA+
specification and formally verify the implementation. PlusCal however, can only
capture safety properties of algorithms, and the liveness conditions need to be
additionally specified in the transpiled TLA+. The extensively documented
specification is [available online.](https://lamport.azurewebsites.net/tla/byzpaxos.html)

While PlusCal allows expressibility and verification, it is hard to turn it into
a practical interoperable program, as the language is used to describe algorithms,
not programs.

A similar implementation of the Paxos specification using Input/Output Automata
(IOA) compiler can be found [here](https://github.com/jonhoo/simio/blob/master/examples/specs/paxos.ioa).

## Overlog and Bloom

In ["I Do Declare: Consensus in a Logic Language"](http://db.cs.berkeley.edu/jmh/tmp/idodeclare.pdf), the authors demonstrate that, while consensus is hard to capture
in imperative languages, it lends itself really well to declarative logic programming.
Constructs such as aggregation and set operations can be naturally expressed in
Overlog, an extended version of [Datalog.](https://docs.racket-lang.org/datalog/)
Overlog starts with two tuples, and derives new tuples from them depending on
the base rules. This repeats
until we reach a stage called _fixpoint_ where no new tuples can be derived.
The rules still apply to transitive relations and can allow us to specify invariants.

The authors first implement [2-Phase-Commit]() protocol using Overlog and then
extend it to Paxos. As we saw in DistAlgo, operations such as aggregation, selection,
can be easily expressed in Overlog, making it simpler to express distributed
algorithms.

### Bloom

[BUD (Bloom Under Development)](https://github.com/bloom-lang/bud/) is a domain
specific language implemented on top of Ruby to allow [_disorderly programming,_]()
where your program is no longer constrained by coordination, which in many cases
can be eliminated, and in others can be consolidated into a critical region. This
allows replica to execute without the need for synchronization or consensus until
the critical region is encountered. This has the potential to massively improve
scalability and performance.

[The bloom implementation of Paxos](https://github.com/bloom-lang/bud-sandbox/tree/master/paxos)
is partial and incomplete according to the description. It hasn't been updated in
quite some time.

## Closing Thoughts

When I started writing this post, the area of DSLs for distributed systems seemed
very promising. However, as I explored each of the implementations, it was a bit
demoralizing. All the languages discussed in this post are revolutionary ideas that
could change how we program distributed systems. But following up on them years
later, you end up with buggy incomplete prototypes in an abandoned wasteland of
code.

Going through the implementations presented in this post, none of them are beyond
the stage of "Proof of Concept" or prototype. If you wanted to use consensus in
your system, it would be better to go with [battle tested implementations](https://github.com/etcd-io/etcd), as verbose and complex they might be.

We need more researchers to look into the space of performance and scalability
oriented DSLs which allow distributes systems expressibility, and I hope projects
discussed in this post mature beyond the prototype stage and become strong contenders.
