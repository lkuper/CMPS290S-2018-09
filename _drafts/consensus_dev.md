---
title: Manufacturing Consensus: Overview of Distributed Consensus Implementations
author: Devashish Purandare
layout: single
classes: wide
---


by Devashish Purandare &middot; edited by Sohum Banerjea and Lindsey Kuper


## Introduction


Consensus protocols, as the name suggests, are a class of techniques by which some number of distributed participants can agree on a single value -- for instance, to resolve
conflicting values at different replicas of a data object in a replicated data store. Consensus
protocols are some of the most complex algorithms in distributed systems.
How do we get replicas to agree?


### Don't do it!


The first rule of consensus is [_"avoid using it wherever possible"_](https://github.com/aphyr/distsys-class#avoid-consensus-wherever-possible)
Consensus is expensive in terms of performance and it is notoriously hard to reason
about and implement. If you can avoid it, you should. There are several
ways to avoid running a full-blown consensus algorithm to resolve conflicts between replicas:
- **Skip coordination!** : [The CALM principle](http://bloom-lang.net/calm/) shows
us that if we can design our program so that "adding things to the input can only increase the output", we
can reliably guarantee eventual consistency as long as all the updates are sent
to each replica at least once. The [Bloom programming language](http://bloom-lang.net/index.html) makes use of this idea.


- **Exploit commutativity and idempotence!**: [CRDTs](https://hal.inria.fr/inria-00555588/en/)
(Conflict-free Replicated Data Types) are built around the notion of monotonic growth with respect to a lattice. For instance, if you maintain a replicated set that can only grow by means of the set union operation, every replica of the set will eventually converge. There
are
several challenges with implementations of CRDTs, including "state explosion" (the
state maintained for each replica can grow exponentially, to the detriment of
storage and performance), complexity, and garbage collection. [Austen's blog
post goes more in-depth about the specifics](http://composition.al/CMPS290S-2018-09/2018/11/12/implementing-a-garbage-collected-graph-crdt-part-1-of-2.html).


- **Talk is cheap; when in doubt, ask around!** _Gossip_ or _epidemic_ protocols are
widely used to heal disparities between replicas. Introduced in a [1987 Xerox PARC 
paper](http://bitsavers.trailing-edge.com/pdf/xerox/parc/techReports/CSL-89-1_Epidemic_Algorithms_for_Replicated_Database_Maintenance.pdf), gossip protocols make progress by sharing update information between replicas.
Replicas contact other, randomly chosen replicas and compare contents. Any differences found
are fixed by comparing timestamps, or using an application-specific conflict resolution approach. Rumor-mongering
is used to maintain hot data changes as special values, until a certain number of
replicas reflect them.


### Reasons to avoid coordination and consensus when possible


- **It is slow**: Consensus requires a significant overhead of message passing,
locking, voting, and the like until all replicas agree. This is
time- and resource-intensive, and can be complicated by failures and delays in
the underlying network.


- **Partial failures**: One of the biggest issues with distributed systems is that partial failures can
happen, leading to arbitrary message drops, while the system continues to work. Partial failures are notoriously hard to detect, and can compromise the correctness property of any protocol not designed explicitly to deal with them.


- **It is impossible!!**: In their Dijkstra-Award-winning paper [Impossibility of
Distributed Consensus with One Faulty Process](https://groups.csail.mit.edu/tds/papers/Lynch/jacm85.pdf), Fischer, Lynch, and Patterson proved that in an asynchronous network environment, it is impossible to ensure
that distributed consensus protocols will succeed -- the famous _FLP result_ A failure at a particular
moment can void the correctness of any consensus algorithm. As disheartening as
this seems, there's a way around it. FLP assumes deterministic processes, and
by
making our algorithms non-deterministic as in [Another Advantage of Free Choice:
Completely Asynchronous Agreement Protocols](https://allquantor.at/blockchainbib/pdf/ben1983another.pdf) can guarantee that a solution is generated "as
long as a majority of the processes continue to operate."


### Then why do we need consensus?


If consensus is so terrible, why are we still using complex techniques to
achieve it?


Maybe, eventually consistent isn't good enough! Strong consistency conditions
such as [Linearizability](https://cs.brown.edu/~mph/HerlihyW90/p463-herlihy.pdf) and [Serializability](https://en.wikipedia.org/wiki/Serializability)
require not only that replicas' final contents agree, but that clients cannot observe different intermediate states on the way there. Ensuring that these conditions hold sometimes leaves us with no choice but to use coordination and
consensus protocols.


### How do consensus protocols work?


It is really hard! [Ask the experts!](https://twitter.com/palvaro/status/1059609961360064512)
The abstract of [Paxos Made Simple](https://lamport.azurewebsites.net/pubs/Paxos-simple.pdf)
(rather infamously) states :


> The Paxos algorithm, when presented in plain English, is very simple.


We will discuss why it can be hard to implement, yet easy to state.


**Listen and Learn :** Most consensus protocols follow the these base
techniques :


- Ideally there is a prepare phase in which replicas pick a Leader that they are going to listen to
- The Leader is picked by a majority of nodes using an election-like process
- Leaders propose values and changes.
- These values are broadcast to Listeners, who select a correct value based on
heuristics, such as a minimum quorum.
- The rest of the replicas do not play part in picking a winner, they are told
the winning values and update themselves to reflect it.


We'll discuss two popular consensus protocols, Paxos and Raft


## Implementing Paxos


Leslie Lamport's paper ["The Part-Time Parliament"](https://lamport.azurewebsites.net/pubs/lamport-Paxos.pdf)
introduced the world to the Paxos algorithm -- or it would have, had anyone understood it. Lamport followed up with ["Paxos Made Simple"](https://lamport.azurewebsites.net/pubs/lamport-Paxos.pdf)
after realizing that the original paper was a little too Greek for the target
audience. Since then, there have been numerous variations and optimizations of the original Paxos algorithm.
### Paxos Made Simple


Their ["Paxos Made Simple"](https://lamport.azurewebsites.net/pubs/lamport-Paxos.pdf) paper states three invariants for correctness:


> - Only a value that has been proposed may be chosen,
> - Only a single value is chosen, and
> - A process never learns that a value has been chosen unless it actually has been.


The algorithm breaks down processes into Proposers (P), Acceptors (A), and
Learners (L). The following rules govern 
how acceptors accept proposals :


- Each acceptor must accept the first value _v_ that it gets.
- After that, the acceptor can only accept any proposal _n_ as long as it has
value _v_ and _n_ is greater than its current proposal number.
- Acceptors in the majority with the highest proposal number are picked winners.


Proposers start with a _prepare_ request with number _n_. An accepted prepare request
means that the acceptor will never accept any other request with value less than
_n_. The latest accepted value is communicated along with this response to the
proposer. Once a majority has accepted a value, it can be communicated as an
accept request to the acceptors as well as the Learners.


The described system has a distinguished proposer and Learner elected by
the processes from among themselves. Lamport Paxos is simpler when there is a single P; issues arise when there are multiple proposers. But the paper is short on implementation details, and implementing Paxos in practice is nontrivial, as the next paper we'll look at shows.


### Paxos Made Live


["Paxos Made Live"](
https://static.googleusercontent.com/media/research.google.com/en//archive/paxos_made_live.pdf), originally an invited talk at PODC '07 from an engineering team at Google, offers us insight into Google's Chubby system, which implements
distributed locking over the GFS filesystem using Paxos. Chubby uses
Multi-Paxos, which repeatedly runs instances of the Paxos algorithm so that a sequence of
values, such as a log, can be agreed upon. Their implementation is similar to the
one we just discussed: elect a coordinator, broadcast an accept message, and if
accepted, broadcast a commit message. Coordinators have ordering, and
restrictions on values, to ensure that everybody settles on a single value.


Because Multi-Paxos can leave behind some replicas (say, in a
network partition), they design a _catch up_ mechanism,  using a
technique not too different from [write-ahead-logging](https://en.wikipedia.org/wiki/Write-ahead_logging).


#### Optimizations
- If you can ensure that the leader doesn’t crash and network doesn’t cause arbitrary delays, the authors suggest
chaining updates across the Multi-Paxos instances, as there's only a small chance
of network changes between subsequent transfers. This can eliminate doing the propose (prepare)
phase for each Paxos instance, saving a lot of time.


- You can add bias to the coordinator picking process to prefer a single
coordinator, and skip the election process or avoid having competing
coordinators in a majority of cases, saving time.


#### Engineering Challenges


My favorite part of "Paxos Made Live" is the engineering challenges the authors encountered while
implementing Paxos on a real system for Chubby.


- Hard disk failures: These can be addressed by converting the coordinator into a non-voter and using the logging mechanism to track everything until the next
instance of Paxos picks up.


- Who's the boss?: The replicas can elect a new coordinator without notifying
the present coordinator, causing issues. They solve the problem by adding leases
on each coordinator's duration, during which other coordinators cannot be
elected.


"Paxos Made Live" glosses over their handling of the group membership problem:


> While group membership with the core Paxos algorithm is straightforward,
> the exact details are non-trivial when we introduce Multi-Paxos, disk
> corruptions, etc. Unfortunately the literature does not spell this out, nor
> does it contain a proof of correctness for protocols related to group
> membership changes using Paxos. We had to fill in these gaps to make group
> membership work in our system. The details – though relatively minor – are
> subtle and beyond the scope of this paper.


How did they solve this? We may never know.


### Paxos Made Moderately Complex


Much like "Paxos Made Simple", ["Paxos Made Moderately Complex"](https://dl.acm.org/citation.cfm?id=2673577)
implements a much more complex system than what the name implies. The authors implement Multi-Paxos and go into
great depth about their implementation and optimizations to it, both as pseudocode
and as C++/Python code. The authors introduce a new term, _slots_, to reason about
Paxos implementation. Slots are commands for each replica to drive its state
towards the right direction. In case different operations end up in the same
slot across different replicas, Paxos can be used to pick a winner. The slots
are not dissimilar to a write-ahead log discussed in other approaches. Confirmed
operations in slots can then be put in `slot\_out` to be communicated to other
replicas. The system then describes several invariants over the slots and
replicas to ensure the Multi-Paxos algorithm remains safe and live.


They introduce the notions of _commanders_ and _scouts_, commanders being analogous
to coordinators. The idea of scouts is interesting: scouts just act
during the prepare phase, ensuring enough responses before passing the data back
to their leaders. Leaders spawn scouts and wait for an _adopted_ message from them,
entering a passive mode loop while scouts try to get a majority response. Once in
the active mode, the leaders get consensus to decide which commands are agreed
upon in which slot (only one per slot) and use the commanders to dispatch the
commands in the second phase to all the replicas.


This paper goes in-depth discussing the original Synod protocol --- i.e., the subprotocol of Paxos that implements consensus, as opposed to handling state machine replication --- and how it is
limited by practical considerations.


The authors of “Paxos made Moderately Complex” have a great resource which goes over in depth about Paxos : [paxos.systems](http://paxos.systems/)


#### Paxos Made Pragmatic


The authors of "Paxos Made Moderately Complex" note that in order to satisfy the aforementioned invariants, the state would grow
rapidly, as we keep all incoming messages at each slot along with the winner.
The authors provide a few ways to
optimize the implementation and actually make it practical.


- Reduce state: The system can reduce state maintained by keeping only the
accepted value for each slot. This can cause issues if there are competing leaders
or crashes, as agreed-upon values may be different for the same slot.


- Garbage collection: Once values are agreed upon by a majority of replicas, it
is not necessary to keep the old values of applied slots. However, just deleting
them might cause an impression that they are empty and can be filled. The
authors address this by adding a variable to the acceptor state to track which
slots have been garbage collected.


- Flushing to disk: Periodically, the log can be truncated and flushed to disk, as
keeping the entire state in memory is expensive and can be lost in a power
failure.


- Read-only operations do not change the state, yet need to get data from a
particular state. Treating such operations differently can help us avoid
expensive operations.
[The code is available online](http://paxos.systems/code.html)


The authors discuss several Paxos variants, concluding that Paxos is more like a
family of protocols rather than a single implementation.


### riak-ensembles: Implementing vertical Paxos in Erlang


[riak-ensembles](https://github.com/basho/riak_ensemble/tree/develop/doc#overview)
implements [Vertical Paxos](https://www.microsoft.com/en-us/research/wp-content/uploads/2009/05/podc09v6.pdf) (Paxos that allows hardware reconfiguration even if it is in the middle of agreement process)
in Erlang to create their consensus ensembles on top
of key-value stores. riak-ensembles borrows from other implementations, such as the leader
leases described in "Paxos Made Live", and allows leadership changes, tracking metadata
with the clever use of [Merkle trees](https://en.wikipedia.org/wiki/Merkle_tree). This allows creation of ensembles: consensus groups
that implement Multi-Paxos on a cluster. The authors discuss their implementation
in [this video](https://www.youtube.com/watch?v=ITstwAQYYag).






## Raft


[Raft](https://Raft.github.io) is often touted as a simpler alternative to
Paxos. Winner of the best paper award at Usenix ATC 2014, Raft offers you a
_Raft_ to wade through the dangerous and scary waters of consensus protocols. It
is intended to be _simple_. The [original paper,](https://www.usenix.org/system/files/conference/atc14/atc14-paper-ongaro.pdf)
in fact has an in-depth user study at Stanford to show that Raft is easier
to understand as well as explain over Paxos. While it is an open question whether Raft achieved its simplicity goals, it is widely used in a lot of large scale systems. In this section we will discuss the Raft protocol, its different implementations and contrast it with Paxos.


### Base Implementation


Raft performs leader elections to pick leaders for each round. The condition for
leadership is stronger in Raft than in Paxos, as leaders are the only nodes that handle reads
and writes to the log as well as log replication to all the replicas.
Conflicting entries in followers' logs can be overwritten to reflect the leader.
The leader election protocol works with the help of a timeout mechanism for
sending heartbeats to collect votes. The election phase itself comes with a
timeout to reduce conflicts.


### Implementation of Raft with `etcd` and formal verification with `vard`


[etcd](https://github.com/etcd-io/etcd) is a lightweight key-value store
implemented using Go. It uses the Raft protocol for distributed consensus to
manage its replicated log. It uses a verified [Raft library](https://github.com/etcd-io/etcd/tree/master/raft)
which is also used by other big projects like _"Kubernetes, Docker Swarm, Cloud
Foundry Diego, CockroachDB, TiDB, Project Calico, Flannel, and more."_ and is a feature-complete implementation of Raft in Go,
including some optional enhancements.


The verification project [Verdi](http://verdi.uwplse.org) base their own key-value
store `vard` on this implementation of Raft. They implement the Raft protocol
in the Verdi framework and verify it using [Coq](https://coq.inria.fr), a popular
formal verification tool; from there, it can be extracted to OCaml and is [available
to use](https://github.com/uwplse/verdi-Raft).


### CockroachDB


[CockroachDB](https://www.cockroachlabs.com/docs/stable/) is an open source
alternative to [Google's Spanner](https://storage.googleapis.com/pub-tools-public-publication-data/pdf/65b514eda12d025585183a641b5a9e096a3c4be5.pdf),
a highly available distributed store which uses TrueTime, a globally synchronized clock system, To
allow ACID properties on top of a distributed data store. The big advantage of
these stores is that despite being scalable across continents, they allow relational properties such as Linearizability and Serializability, along with referential integrity. Raft is used extensively in CockroachDB to ensure
that replicas remain consistent.


CockroachDB implements [Multi-Raft](https://www.cockroachlabs.com/blog/scaling-Raft/)
on top of the Raft protocol to allow better
scalability. This involves certain changes to how Raft works. It divides
replicas into ranges, which locally implement Raft. Each range performs leader
elections and other Raft protocol operations. Ranges can have overlapping
memberships. Multi-Raft converts each node's associated ranges into a group
for Raft, limiting the heartbeat exchange to once per tick.




## Next steps


As we've seen, consensus protocols can be hard to understand and implement.  Could programming language support for expressing these protocols help?  In my next post, we'll consider languages that are specifically designed for the task of implementing distributed protocols such as consensus protocols, and compare implementations in those languages to the general-purpose language implementations discussed here.
