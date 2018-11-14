# Manufacturing Consensus : How Consensus is Achieved in the Real World

### Author : [Devashish Purandare](https://twitter.com/dev14e)

### Reviewers : Sohum Banerjea, and Lindsey Kuper

---

## Introduction

*With its comprehensive coverage of consistency, this course had limited
time to go over consensus. I wrote this post to serve two objectives,
it covers the basics of consensus, which would be a helpful read for all of us
and it explores how systems program and implement it in the real world
with some detail on languages, keeping with the theme of the course.*

---

## Consensus

Consensus, as the name suggests, are a class of algorithms that resolve
conflicting values and get different replicas in a replicated data store
to agree on the values and orders of operations. Consensus algorithms are
some of the most complex operations in distributed systems, so how do we
get replicas to agree?

### Don't do it!

The first rule of Consensus is : [_"avoid using it wherever possible"_](https://github.com/aphyr/distsys-class#avoid-consensus-wherever-possible)
Consensus is expensive in terms of performance, it is notoriously hard to reason
about and implement, and if you can avoid it, you should. There are a several
ways to avoid consensus :

- **Skip coordination!** : [The CALM conjecture](http://bloom-lang.net/calm/) shows
us that if we can make our program as add only and monotonically increasing, we
can reliably guarantee eventual consistency as long as all the updates are sent
to each replica at least once. _(It was tempting to include bloom in this post,
but we shall focus on implementations of consensus, as otherwise this post would
be at the risk of increasing monotonically without bounds)._

- **Set math!** : Utilize properties such as commutativity and idempotence to
grow toward the same eventual goal. [CRDTs](https://hal.inria.fr/inria-00555588/en/)
or Convergent and Commutative Replicated Data Types are built around the ideas
of sets. If you maintain a set of data that can only grow with unions, you
ensure that any replicas getting the same data would eventually converge at the
same values. In a similar fashion to CALM, it doesn't require coordination, and
there is no true replica, each replica will eventually get all data. There are
several issues with implementations of CRDTs, including "state explosion" (the
state maintained for each replica grows exponentially, to the detriment of
storage and performance), complexity, and garbage collection. [Austen's blog
post goes more in-depth about the specifics](http://LINKAUSTENBLOGHERE.COM).

- **Talk is Cheap! : When in doubt, ask around!** Gossip or Epidemic protocols are
widely used to heal disparities between replicas. Introduced in the [1987 Xerox
paper](http://bitsavers.trailing-edge.com/pdf/xerox/parc/techReports/CSL-89-1_Epidemic_Algorithms_for_Replicated_Database_Maintenance.pdf)
Gossip protocols proceed by : sharing update information between replicas,
contacting a random replica and comparing contents, the differences in which
are fixed by anti-entropy and conflict resolution algorithms, and rumormongering
: maintaining hot data changes as special values, until a certain number of
replicas reflect them. All these actions can take us toward eventual
consistency.

### Why coordination and consensus is a bad idea

- **It is slow** : Consensus requires a significant overhead of message passing,
locking, voting and other meta operations until all replicas agree. This is
time and resource intensive, and can be complicated by failures and delays in
the underlying network.

- **It is impossible!!** : The Dijkstra award winning paper [Impossibility of
Distributed Consensus with One Faulty Process](https://groups.csail.mit.edu/tds/papers/Lynch/jacm85.pdf)
proves that in an asynchronous network environment, it is impossible to ensure
that distributed consensus algorithms will succeed. A failure at a particular
moment can void the correctness of any consensus algorithm. As disheartening as
this seems, there's a way around that. FLP assumes deterministic process, and by
making our algorithms non deterministic as in [Another Advantage of Free Choice:
Completely Asynchronous Agreement Protocols,](https://allquantor.at/blockchainbib/pdf/ben1983another.pdf)
a probabilistic approach that can guarantee that a solution is generated "as
long as a majority of the processes continue to operate."

### Then why do we need consensus?

If consensus is so terrible, why are we still using complex techniques to
achieve it?

Maybe, eventually consistent isn't good enough! Stronger consistency conditions
such as [Linearizability and Serializability](http://www.bailis.org/blog/linearizability-versus-serializability/)
require that replicas agree not only on the content of the final set, but the
state flow required to make it that way. It is not possible to guarantee these
conditions in eventually consistent growth only systems or by just using gossip
protocols. These systems often need transactional changes and coordination and
consensus protocols.

### How do consensus algorithms work?

It is really hard! [Ask the experts!](https://twitter.com/palvaro/status/1059609961360064512)
The abstract of [Paxos Made Simple](https://lamport.azurewebsites.net/pubs/paxos-simple.pdf)
(rather infamously) states :

> The Paxos algorithm, when presented in plain English, is very simple.

seems easy, right? Let's dive right in!

**Listen and Learn :** Most consensus algorithms follow the these base
techniques :

- Some processes propose values that they think are correct.
- These values are broadcast to Listeners, who select a correct value based on
some heuristics, such as a minimum quorum.
- The rest of the replicas do not play part in picking a winner, they are told
the winning values and update themselves to reflect it.
- Eventually, with a guaranteed delivery mechanism, all the replicas can agree
on the order.

There are some really popular Consensus algorithms that we will go over before
discussing their implementations. [Paxos](#Paxos), [Raft](#Raft) remain the two
most popular consensus algorithms. This blog post will analyze their
implementations and language support in depth. We will briefly go over other
consensus protocols, such as Zookeeper, and Viewstamped replication, however
in-depth discussion could cause this blog post to be much longer than the class
requirement :P.

_Note : You may notice the lack of discussion about consenus problems related to
the "Blockchain" technology in this blog post. The author wants to clarify that
it is an intentional omission._

## Implementing Paxos

[The part time parliament](https://lamport.azurewebsites.net/pubs/lamport-paxos.pdf)
introduced the world to the Paxos algorithm, or _it would have, had it been
published._ Lamport followed up with [Paxos made simple](https://lamport.azurewebsites.net/pubs/lamport-paxos.pdf)
after realizing that the original paper was a little too _greek_ for the target
audience. Since then, there have been numerous implementations of Paxos,
including optimizations, DSLs, and revisions. We will go over most of them in
this section.

### Paxos Made Simple

To understand the Paxos algorithm (to the extent we can), we will go over
Lamport's original paper, titled [Paxos Made Simple](https://lamport.azurewebsites.net/pubs/lamport-paxos.pdf) which introduced us to Paxos.

Paxos made simple states 3 invariants for correctness :

> - Only a value that has been proposed may be chosen,
> - Only a single value is chosen, and
> - A process never learns that a value has been chosen unless it actually has been.

The algorithm breaks down processes into Proposers (P), Acceptors (A), and
Learners (L). Paxos is simpler when there is a single, P, issues arise when
there are multiple proposers. Paxos made simple adds some restrictions on
how acceptors accept proposals :

- Each acceptor must accept the first value _v_ that it gets
- After that, the acceptor can only accept any proposal _n_ as long as it has
value _v_
- Acceptors in the majority with the highest proposal number are picked winners.

This gives us a _prepare_ request with number _n_. An accepted prepare request
means that the acceptor will never accept any other request with value less than
_n_. The latest accepted value is communicated along with this response to the
proposer. Once a majority has accepted a value, it can be communicated as an
accept request to the acceptors as well as the Learners.

Unfortunately the paper becomes rather sparse in details on the implementation
part. The described system has a distinguished proposer and Listener elected by
the processes from among themselves.

### Paxos Made Live

[Paxos made live](https://www.cs.utexas.edu/users/lorenzo/corsi/cs380d/papers/paper2-1.pdf)
by Google, offers us an insight into Google's Chubby system, which offers
distributed locking over the filesystem using Paxos. Google implements
Multi-Paxos which repeatedly runs instances of Paxos so that a sequence of
values such as a log can be agreed upon. Their implementation is similar to the
one we just discussed, elect a coordinator, broadcast an accept message and if
accepted, broadcast a commit message. Coordinators have ordering, and
restriction on values, to ensure that everybody settles on a single value.

The system spins up a new instance of Paxos for each value in the log, resulting
in the multipaxos system. Because this can leave behind some replicas (say in a
network partition), they design a _catch up_ mechanism. This is achieved using a
technique not too different from [write-ahead-logging](https://en.wikipedia.org/wiki/Write-ahead_logging)

**Optimizations** :

- If you have smooth communication, the authors suggest
chaining updates across the multipaxos instances as there's only a small chance
of a change between subsequent transfers. This can eliminate doing the propose
action for every paxos instance, saving a lot of time.

- You can add bias to the coordinator picking process to prefer a single
coordinator, and skip the election process or avoid having competing
coordinators in a majority of cases, saving time.

**Engineering Challenges** :

My favorite part of this paper is the engineering challenges they discuss while
implementing paxos on a real system with Chubby.

- Hard disk failures : Can be addressed by converting the coordinator into a non
voter and utilizing the logging mechanism to track everything until the next
instance of Paxos picks up.

- Who's the boss? : The replicas can elect a new coordinator without notifying
the present coordinator, causing issues. They solve the problem by adding leases
on each coordinators duration, during which other coordinators cannot be
elected.

- The Google paper glosses over the group membership problem using the words,

> While group membership with the core Paxos algorithm is straightforward,
> the exact details are non-trivial when we introduce Multi-Paxos, disk
> corruptions, etc. Unfortunately the literature does not spell this out, nor
> does it contain a proof of correctness for algorithms related to group
> membership changes using Paxos. We had to fill in these gaps to make group
> membership work in our system. The details – though relatively minor – are
> subtle and beyond the scope of this paper.

how do they solve this, perhaps we may never know.

### Paxos Made Moderately Complex

Much like Paxos made simple, [Paxos made moderately complex](http://www.cs.cornell.edu/courses/cs7412/2011sp/paxos.pdf)
implements a much more complex system than what the name implies. In this
attempt the authors implement multi-decree paxos (multipaxos) and go over in
great depths about their implementations, and optimizations, both as pseudocode
and as C++/Python code. The authors introduce a new term _slots_ to reason about
paxos implementation. Slots are commands for each replica to drive its state
towards the right direction. In case different operations end up in the same
slot across different replicas, paxos can be used to pick a winner. The slots
are not dissimilar to a write ahead log discussed in other approaches. Confirmed
operations in slots can then be put in slot\_out to be communicated to other
replicas. The system then describes several invariants over the slots and
replicas to ensure the multipaxos remains safe and live.

They introduce the notions of commanders and scouts, commanders being analogous
to coordinators. The implementation of scouts is interesting, scouts just act
during the prepare phase, ensuring enough responses before passing the data back
to their leaders. Leaders spawn scouts and wait for _adopted_ message from them,
entering a passive mode loop while scouts try to get majority response. Once in
the active mode, the leaders get consensus to decide which commands are agreed
upon in which slot (only 1 per slot) and use the commanders to dispatch the
commands in the second phase to all the replicas.

This paper goes in-depth discussing the original Synod protocol and how it is
limited by practical considerations.

#### Paxos Made Pragmatic

The author's note that in order to satisfy the invariants, the state would grow
rapidly in the above discussed implementation, and provide a few ways to
optimize the implementation and actually make it practical.

- Reduce state : The system can reduce state maintained by keeping only the
accepted value for each slot. This can cause issue in case of competing leaders
and crashes, agreed upon values may be different for the same slot.

- Garbage Collection : Once values are agreed upon by a majority of replicas, it
is not necessary to keep the old values of applied slots. However, just deleting
them might cause an impression that they are empty and can be filled. The
authors address this by adding a variable to the acceptor state to track which
slots have been garbage collected.

- Flushing to disk : Periodically log can be truncated and flushed to disk, as
keeping the entire state in memory is expensive and can be lost in a power
failure.

- Read only operations do not change the state, yet need to get data from a
particular state, treating such operations differently can help us avoid
expensive operations.

The code is available in the appendix.

The authors discuss several Paxos variants, concluding that Paxos is more like a
family of algorithms rather than a single implementation.

### riak-ensembles : Implementing vertical Paxos in Erlang

[riak-ensembles](https://github.com/basho/riak_ensemble/tree/develop/doc#overview)
implement [vertical Paxos](https://www.microsoft.com/en-us/research/wp-content/uploads/2009/05/podc09v6.pdf)
in Erlang to create their consensus ensembles on top
of K/V stores. riak borrows from other implementations, such as the leader
leases from Paxos made live, and allows leadership changes tracking metadata
with the clever use of [Merkle Trees](https://en.wikipedia.org/wiki/Merkle_tree)
(remember Blockchain?). This allows creation of ensembles : consensus groups
that implement multipaxos on a cluster. The authors discuss their implementation
in [this video](https://www.youtube.com/watch?v=ITstwAQYYag).

### Moderately Complex Paxos Made Simple

If you are still following along at this point, you might remember the infamous,
"The Paxos algorithm, when presented in plain English, is very simple." from the
Paxos made simple paper. Yet as we go over each of the practical
implementations, we observe that implementing it practically is extremely
complex and hard to reason about.

But maybe, it has been hard, because we have been trying to convert English to
C++, which is extremely difficult due to all the intricacies required by the
algorithm. What if, our programming language helped us enforce variants? What if
we could express it as simply as stating in English? This is where [DistAlgo](https://github.com/DistAlgo/distalgo)
comes in! It is a framework that allows us to implement distributed algorithms
in a domain specific language, prototyped in Python, built specifically for
us! In [their paper](https://arxiv.org/pdf/1704.00082.pdf) they discuss
implementation of Paxos in DistAlgo.

As they discuss Lamport's Paxos made simple, they explain why Paxos is hard to
understand and implement very beautifully :
> "Indeed, this is the hardest part for understanding Paxos,
> because understanding an earlier phase requires understanding a later phase,
> which requires understanding the earlier phases."

The authors implement the Paxos implementation we saw in Paxos made Moderately
complex : the one with slots and scouts and commanders! Unlike the original
paper, they fold the functionality of commanders and scouts back into the leader
to allow simpler code. The separation in the original paper seemed arbitrary to
me and this makes it so that the leader performs their actions.

**Optimizations** : Because of this simplified interface, it is trivial to
implement optimization which keeps just the maximum numbered ballot for each
slot changing just 1 line of implementation :

```python
accepted := {(b,s,c): received (’2a’,b,s,c)}
```
to

```python
accepted := {(b,s,c): received (’2a’,b,s,c), b = max {b: received (’2a’,b,=s,_)}}
```
this will pick the maximum ballot for each slot instead of keeping every ballot.

They implement leader leases with timeout, similar optimization to the original
to prevent unnecessary contention because of multiple readers.

The paper also formally verifies the implementation of Paxos made moderately
complex and discovers a safety violation which may cause `preempt` messages to
never be delivered to the leaders and fixes it.

Perhaps the most important contribution of this is that it implements Paxos
made moderately complex with much less complexity as you have programming
language support now.

## Raft

[Raft](https://raft.github.io) is often touted as a simpler alternative to
Paxos. Winner of the best paper award at Usenix ATC 2014, Raft offers you a
_raft_ to wade through the dangerous and scary waters of consenus protocols. It
is designed to be _simple_. The [original paper,](https://www.usenix.org/system/files/conference/atc14/atc14-paper-ongaro.pdf)
in fact has an in-depth user Study at Stanford to show that Raft is much easier
to understand as well as explain over Paxos. The authors present a world where
the treacherous waters of Greece are past us and it is smooth sailing from now
on to understand and implement consensus. So let's see how Raft works!

### Base Implementation

Raft performs leader elections to pick leaders for each round. The condition for
leadership is stronger in raft as leaders are the only nodes that handle reads
and writes to the log as well as log replication to all the replicas.
Conflicting entries in followers logs can be overwritten to reflect the leader.
The leader election protocol works with the help of a timeout mechanism for
sending heartbeats to collect votes. The election phase itself comes with a
timeout to reduce conflicts.

**Is raft really simpler to understand an implement than Paxos?**
To understand, yes, as the paper shows it with a study that it is indeed easier
to understand and explain for most students. However for implementing it, that's
a big maybe.

In a recent tweet by [Cindy Sridharan](https://twitter.com/copyconstruct/status/1061818753925578753)
:
> "Paxos is known to be notoriously difficult to implement. Here's a little
> secret for you - Raft is difficult to implement too. As I know a lot more
> about this now, there's really not much difference between Raft and Paxos."
>
> \- Peter Mattis, of CockroachDB, the OSS Spanner clone.

The quorum reads discussed in Raft are never implemented by CockroachDB as it is
simply too expensive to perform them.

Over the next few sections, we will analyze different implementations of Raft.

### Formal verification and implementation of Raft with `vard` and `etcd`

[`etcd`](https://github.com/etcd-io/etcd) is a lightweight Key-Value store
implemented using Go. It uses the raft protocol for distributed consensus to
manage its replicated log. It uses a verified and widely used [Raft Library](https://github.com/etcd-io/etcd/tree/master/raft)
which is shared by other big projects like _"Kubernetes, Docker Swarm, Cloud
Foundry Diego, CockroachDB, TiDB, Project Calico, Flannel, and more."_ The
linked implementation is feature complete implementation of Raft in Go,
including some optional enhancements such as :

> Optimistic pipelining to reduce log replication latency
>
> Flow control for log replication
>
> Batching Raft messages to reduce synchronized network I/O calls
>
> Batching log entries to reduce disk synchronized I/O
>
> Writing to leader's disk in parallel
>
> Internal proposal redirection from followers to leader
>
> Automatic stepping down when the leader loses quorum
>
> Protection against unbounded log growth when quorum is lost

The verification project [Verdi](http://verdi.uwplse.org) base their own KV
store `vard` on this implementation of Raft. They implement the Raft protocol
in the Verdi framework and verify it using [Coq](https://coq.inria.fr) a popular
formal verification tool. This has now been exported to OCaml and is [available
to use](https://github.com/uwplse/verdi-raft).

### CockroachDB

[CockroachDB](https://www.cockroachlabs.com/docs/stable/) is an open source
alternative to [Google's Spanner](https://storage.googleapis.com/pub-tools-public-publication-data/pdf/65b514eda12d025585183a641b5a9e096a3c4be5.pdf),
a highly available distributed store which uses atomic clock timestamps to
allow ACID properties on top of a distributed data store. The big advantage of
these stores is that despite being scalable across continents, they allow SQL
and relational properties. Raft is used extensively in CockroachDB to ensure
that replicas remain consistent.

CockroachDB implements [Multi-Raft](https://www.cockroachlabs.com/blog/scaling-raft/)
on top of the raft protocol to allow better
scalability. This involves certain changes to how raft works. It divides
replicas into ranges, which locally implement raft. Each range performs leader
elections and other raft protocol operations. Ranges can have overlapping
memberships. MultiRaft converts each node's associated ranges into a group
for raft, limiting the hearbeat exchange to once per tick,

### Other Raft implementations

The `etcd` implementation of raft is the gold standard, and widely used in
projects that use raft. It is a feature-complete implementation true to the
paper. Raft is rather easy to [implement in DistAlgo](https://github.com/DistAlgo/distalgo/blob/master/da/examples/raft/orig.da)
the framework we discussed in "Moderately Complex Paxos Made Simple." Although
interestingly, it involves much more code than their implementations of Paxos.
The DistAlgo specification for

- Lamport Paxos is **72 loc**,
- the moderately complex paxos at **173 loc**,
- Raft clocks in at **213 loc**.

You can check out the [various implementations here.](https://github.com/DistAlgo/distalgo/tree/master/da/examples)

(For reference, the C++/Python/Go implementations are thousands of loc).

## Closing note

I intended to write down this blog post as _"Programming Language Support for
Consensus"_, however, thrown off by the possible implementations and
complications, it ended up being more about the different implementations of
Consensus class algorithms, and what they offer. The topic for language support
and why DistAlgo achieves the same in a shorter span will have to wait. Perhaps
it can be a separate post down the line, or someone else can pick it up. Hazy
after reading dozens of papers, blogs, and manuals on achieving consensus, I
plan to do something more implementation focused my next blog post.


## References and Resources

I have linked all the references in the relevant sections. For general readings
I would recommend these resources that I looked at.

- [An introduction to distributed systems by Kyle Kingsbury](https://github.com/aphyr/distsys-class)
- [CMPS 232 by Peter Alvaro](https://github.com/devashishp/CMPS232-Fall16/blob/master/readings.md)
- [CMPS 290S by Lindsey Kuper : current class!](http://composition.al/CMPS290S-2018-09/readings.html)
