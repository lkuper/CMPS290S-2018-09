# Mixing Consistency in a Declarative Programmable Storage System


<!-- ------------------------------>
<!-- SECTION -->
## Introduction
In general, I tend to be interested in approaches to lifting various concepts to first-class
citizens of a programming model. Of course, there is a lot of contextual important to be
considered, but when I think of an application domain and how a problem might be
addressed, I tend to wonder: is there a concept germane to the given domain such that considering
the concept early on in development would make design and implementation more natural and concise.

In the case of this blog post, consistency models are an important aspect of any distributed,
important computation. So, how can we make reasoning about consistency of data types and
computations natural during development? Distributed systems have been well studied for many years,
and there now exist logical frameworks, tools, declarative approaches, and even type systems
for bringing consistency models to the forefront of the developer's mental model. While this is the
case, there are still data management and storage systems that do not include consistency models in
their short list of design goals. Although, it may be fair to say that in this blog post, the
considered approaches for mixing consistency in computations (I just say "mixing consistency" for
conciseness hereafter), have happened in the last few years. So, "battle-hardened",
production-capable systems were likely designed and began development before mixing consistency had
been well explored. Specifically, the systems we consider in this blog post: [QUELEA][quelea-paper],
[IPA][ipa-paper], and [MixT][mixt-paper], have all been released and published in the last 3 years.

To establish a clear objective, in this blog post we explore approaches for declaring, and
enforcing, various consistency models in a **D**eclarative **P**rogrammable **S**torage system
([dps system](#dps-system)). The following sections include an overview, some definitions and
intuitions, and goals of dps systems:

* [*programmable storage* systems](#programmable-storage)
* [**D**eclarative **P**rogrammable **S**torage](#declarative-programmable-storage):

For our high-level analysis of [mixing consistency](#mixing-consistency) to be
meaningful, it is important to have _some_ understanding of what programmable storage is, and
especially what a declarative programmable storage system is. In the above sections, background
information is provided for both of these types of storage systems (really, it's just programmable
storage, and then with a declarative layer on top). Part of the background information is the
choice of backend data store for implementing a consistency type system on top of, and some of the
motivations behind various trade-offs we might be interested in.

Just to further anchor the analysis in this blog post (spoiler alert), the existing consistency
type system implementations we choose to cover were discussed as part of [CMPS
290S][course-website]. The analysis is provided in the section, [Mixing
Consistency](#mixing-consistency). Background for understanding what consistency even is, and what
consistency models are, can be found in these sections (TBD later, since this knowledge is assumed
for the class, CMPS 290S):

<!-- TODO later -->
* [Consistency](#consistency)
* [consistency models](#consistency-models)

For convenience (hopefully it's also useful), there is a [glossary](#glossary) at the end of this
blog post.

Due to time constraints (and perhaps the nature of my goal), this blog post will **only** cover the
relevant implementations of using mixed consistency computations, and not the actual implementation
of such a programming model in (or on top of) a dps system. However, the implementation is
something that will be addressed in a follow up blog post in the next 3 - 4 weeks (and I cross my
fingers for interesting results).


<!-- ------------------------------>
<!-- SECTION -->

# Programmable Storage
Programmable storage is motivated by the current state of large-scale, distributed storage systems.
Notably, one idea is to reuse components and subsystems from a storage system. Because storage
systems have inherently very high expectations of reliable data persistence, rewriting relevant
subsystems or components only invites younger, error-prone code. While this is not a hard and fast
rule, the intuition is that reusing subsystems of a storage system means that the community
supporting these subsystems is larger, and these subsystems are exercised and improved more
frequently. Without diving too deep into the details, programmable storage seems to be a domain
that will continue to grow, as described by Noah Watkins [in his dissertation][noah-dissertation].

Also described in Noah's dissertation, is the programmable storage system, [Ceph](#ceph). In his
dissertation, Noah details his implementation of a distributed, shared log on top of Ceph, which he
also described [in a blog post][noah-blog-zlog]. Since Noah has already explored programmable
storage system work on top of Ceph, it seemed like a natural choice to use for my data store
backend for this blog post.


## [Ceph][ceph-intro]
Ceph is an open source, distributed, large-scale storage system, that can be nicely summarized (I
think) by the following:

* In Noah's dissertation, "Ceph is something of a storage Swiss army knife."
* [In Ceph's introduction blog post][ceph-intro-blog], "the main goals of Ceph are to be
  completely distributed without a single point of failure, scalable to the exabyte level, and
  freely-available."

Ceph has been part of storage systems research at UC Santa Cruz for several years under Carlos
Maltzahn, including the [CRUSH algorithm][crush-paper] (2006), the [RADOS][rados-paper] data store
(2007), even up to [Noah's dissertation][noah-dissertation] earlier this year (2018). I have just
started working with Carlos Maltzahn and Peter Alvaro on [declarative programmable
storage](declarative-storage), where there is some interest in continuing to use Ceph as the
underlying storage system implementation. While I am not personally experienced with Ceph nor have
I interacted with users of Ceph, the idea of allowing the developer to mix consistency on top of a
storage system seemed interesting enough to explore. Especially, when considering that Ceph is
distributed over a cluster (and potentially replicated to remote clusters). With Noah's previous
work, an implementation of mixing consistencies over Ceph seems to have a clear path forward for
evaluating the benefit of sequential, causal, or weaker consistency for a programmable storage
system. This brings us to the variety of consistency models that Ceph supports.

For traditional storage systems, strong consistency is a must. Although Ceph is a distributed,
large-scale storage system, Ceph was designed to fill the role of reliable, durable storage. This
expectation is common (and preferred) for many applications, especially scientific applications,
where the complexity of distributed systems and consistency models weaker than linearizability is
too difficult to work with. This makes Ceph's support for only strong consistency reasonable.
However, there are many other applications with large data volumes, rich data models, but with
inherently low business risk that prefer to trade strong consistency for availability and
performance. This is especially common in social, web-based applications, but could also be
applicable in other scenarios (examples to come as I think about them? Maybe this is just an
interesting exercise for a graduate student?). To more optimally support these types of
applications, it would be ideal to provide the ability to specify weaker consistency models over
low risk, or non-essential, data types.

Ceph's architecture is designed around the [RADOS data store](#rados). This data store is a unified
system that provides storage interfaces for objects, blocks, and files. A Ceph storage cluster
consists of two types of daemons:
* [Ceph Monitor](#ceph-monitor)
* [Ceph OSD](#ceph-object-storage-daemon)

The [Ceph Monitor](#monitor) monitors the Ceph storage cluster. One or more Monitors form a Paxos
part-time parliament cluster that manage cluster membership, configuration, and state.

The [Ceph OSD](#osd) handles data persistence on a node in the Ceph storage cluster. The osd relies
upon the stability and performance of the underlying filesystem[^osd-fs-fn] when using [the
filestore backend][ceph-backend-filestore]. The file system currently recommended for production
systems is XFS, although btrfs is supported. On the other hand, the [new BlueStore
backend][ceph-backend-bluestore] allows Ceph to directly manage storage devices, bypassing the
extra layer of abstraction that comes with the use of kernel file systems (e.g. XFS, btrfs).

While understanding Ceph in general is useful, the aspect that is relevant for what we want to
explore in this blog post, is how Ceph replicates data, and what type of consistency is available
to developers and users. Well, Ceph is able to [support multiple data centers][data-center-faq],
but only provides strong consistency. When a client writes data to Ceph the primary OSD will not
acknowledge the write to the client until the secondary OSDs have written the replicas
synchronously. Ceph [achieves scalability][ceph-cuttlefish-arch] through "intelligent data
replication." For hardware deployed in different geographic locations, this will clearly lead to
additional latency in the time to receive synchronous acknowledgements. Considering the possible
(likely) latency, The Ceph community is working to ensure that OSD/monitor heartbeats and peering
processes still operate effectively. Otherwise, Ceph's current solutions are to rely on hardware
within a data center, or to configure Ceph in a way that ensures effective peering, heartbeat
acknowledgement and writes. According to [Ceph's faq][data-center-faq], there was an asynchronous
write capability in progress via the Ceph Object Gateway (RGW) which would provide an
eventually-consistent copy of data for disaster recovery purposes. However, this would only work
with reads and writes sent via the Object Gateway. There is also similar capability for Ceph Block
devices which are managed via the various cloudstacks. Unfortunately, it is not clear what the
progress is on these capabilities, and the proposed use cases sound particular to disaster recovery
and not performance. This leaves some potentially interesting work to be done by this blog post and
a follow-up blog post.


<!-- ------------------------------>
<!-- SECTION -->

# Declarative Programmable Storage
Programmable storage tends to be a difficult, low-level task that requires lots of code and
detailed knowledge of storage subsystem implementations. Even when carefully written, storage
systems built on top of reusable components can still expose dependencies that make maintenance
prohibitively expensive. The goal of declarative programmable storage is to use a declarative
language for specifying interfaces over storage systems (e.g. [Noah's ZLog example][noah-blog-zlog]
and [the work on DeclStore][declstore-paper]), such that maintainability and performance can be
addressed by a query optimizer or some other principled, automatic machinery. In general, the
purpose of DPS systems is to address maintainability and expressiveness of *programmable storage*
systems using declarative languages. DeclStore is a step towards declarative programmable storage. 

For a declarative programmable storage system ([dps system](#dps-system)), There are 2 major
features that I explore to allow developers specify consistency requirements over data types. These
are further explored in the [Mixing Consistency section](#mixing-consistency) section:
1. Mechanisms for supporting weaker consistency models in the backend storage system.
2. A way to define, and enforce, consistency requirements for data types.

There is an additional, related motive for studying mixing consistency over dps systems: exploring
the generalization of reasoning over arbitrarily complex data properties. From this perspective,
even beyond support for mixing consistency, this investigation will help guide the direction for future
work. To draw from MixT, which has a similar intuition, MixT claims that consistency is a property
of data. If this is at all true, then the storage system is a clear candidate for managing a
property such as consistency. If we minimally extend intuitions around consistency models to
general properties of data, being able to enforce, and reason over, pre- and post-conditions for
data seems useful.

<!-- ------------------------------>
<!-- SECTION -->
# Consistency

<!-- TODO: fill this in later -->
## Consistency Models
Consistency is an interesting property of data. We usually define an **A**bstract
**D**ata **T**ype (ADT) by the operations that we can invoke on them. From this
perspective, not only is consistency a property of data--does every client in
my system agree on the state of this data value--but it is inherently affected
by operations. The more complete our information about a data type is, the
easier it is to know if the relevant data value is *correct*. When we consider
this property in a distributed system, complete information becomes more
difficult to accumulate **efficiently**. So, we define correctness of our data
in a distributed system, as constraints with respect to complete, relevant
information. This definition of correctness given some set of constraints, is
what we call a *consistency model*. That is, given information about our *way
of thinking about consistency*, is a data value, or the state of a data type,
**consistent**.

In this section, we describe formal definitions of various consistency models
and intuitions for what they mean. We will also define terminology as
accessibly as possible in the [glossary](#glossary). Ultimately, formal
definitions of consistency models are necessary for distinguishing between them
and reasoning over them.

### NOTE
Since our class, [CMPS290S][course-website], has been spending a lot of time
reading about consistency models up to this point, I will fill this section in
later and assume that initial readers of this blog post are well acquainted
with the relevant consistency models.

<!--
To be added when I have more time? Otherwise this looks too incomplete.

#### Linearizabilty
#### Sequential Consistency
#### Causal Consistency
#### Eventual Consistency
#### Weak Consistency
-->

<!-- ------------------------------>
<!-- SECTION -->
## Mixing Consistency
In [CMPS 290S][course-website], we have been reading a handful of papers that discuss various tools
for understanding, analyzing, and reasoning about consistency in a distributed system. In these
readings, I have been particularly interested in two implementations of consistency type systems
for enforcing consistency requirements over data types:

* [Disciplined Inconsistency with Consistency Types][ipa-paper]
* [MixT: A Language for Mixing Consistency in Geodistributed Transactions][mixt-paper]

For brevity, I call "a type system that includes and enforces consistency" a consistency type
system. Consistency type systems try to lift consistency models to first-class citizens in
the type system of the distributed system programming model. By making consistency models explicit
in the type system, developers are able to verify that important data types are used at an
appropriate correctness level. The IPA paper claims:

    ...IPA allows the programmer to trade off performance and consistency, safe in the knowledge
    that the type system has checked the program for consistency safety.

This type of support from the programming model is necessary for developers to be both
more efficient and more correct. To further support mixing consistency, the MixT paper claims:

    ...engineers at major companies frequently find themselves writing distributed programs that
    mix accesses to data from multiple existing storage systems, each with distinct consistency
    guarantees.

There are many consistency models (see [Consistency Models](#consistency-models)) that are
meaningful for developers working in distributed systems. From the perspective of a consistency
type system, we are interested in how to verify and enforce them for associated data types. To do
this, consistency type systems associate data types with the consistency model we would like the
data types to conform to.

### IPA Consistency Type System
[IPA's implementation][ipa-impl] is in Scala and leverages Scala's powerful type system. This
approach allows the developer to directly interact with the consistency type of their data, using
features such as pattern matching. For IPA, the consistency model is specified as a policy on an
ADT in 1 of 2 ways:

1. Static consistency policies--These specify the consistency model (e.g. strong, weak, causal).
2. Dynamic consistency policies--These specify performance or correctness bounds, within which to
   achieve the strongest consistency possible.

Static consistency policies are roughly "passed-through" to the data store. IPA is implemented as a
layer on top of Cassandra because of Cassandra's quorum approach to consistency (and maybe because
it seemed easier to develop on top of?). By achieving "quorum intersection," writes to and reads
from Cassandra can be strongly consistent. Weak consistency policies can be satisfied by specifying
fewer replicas to write to (e.g. 1 or 2) or fewer replicas to read from (e.g. 1 or 2) such that
quorum intersection is **not satisfied**. The number of replicas written to, W, and the number of
replicas read from, R, only needs to be less than the total number of replicas, N, to be weakly
consistent. But, notice that Cassandra does not natively support complex consistency models, such
as causal or strong eventual.

Dynamic consistency policies are specifications of performance or behavior properties, within which
the strongest consistency constraints should be satisfied. More concretely, there are two types of
of dynamic consistency types: rushed and interval. A rushed type represents latency bounds in which
an answer is expected. For a latency bound of 2 seconds, IPA would return a value meeting the
strongest consistency constraints within 2 seconds. If strong consistency could be achieved for the
operation in 1 second, then that value would be preferred to a returned value that is only weakly
consistent. When the latency threshold is reached, it may be possible that a value only satisfying
weak consistency is available, and thus that would be returned.

Because the typical IO path to Ceph's storage cluster does not support various consistency models,
an IPA-style consistency type system would have to be modified, or a new storage interface on top
of Ceph be provided. In the quorum style of supporting various consistency models, Ceph may require
communicating with the OSDs directly. A potential problem could be if the OSD has synchronization
with other OSDs in the configured cluster built-in. If it is possible to communicate writes to OSDs
individually, it would be possible, potentially even "trivial", to enable a quorum approach to
consistency over Ceph OSDs. Understanding the details of OSD communication will be important for
understanding whether Ceph can provide a similar interface to IPA as what Cassandra provides.

### MixT Consistency Type System
In contrast to IPA's approach, [MixT's implementation][mixt-impl] is in C++ and much lower in the
development stack. Another interesting difference is that the backend data store used is
Postgres. What makes this interesting is that Postgres (to my understanding) supports strong
consistency, but various levels of *isolation*. MixT allows weaker consistencies by providing a
**D**omain **S**pecific **L**anguage (DSL) for defining computation in a *mixed-consistency
transaction*. Operations within these mixed-consistency transactions are then split into smaller
transactions to achieve weaker consistency.

Initially, I thought that building a consistency type system on top of a data store
that *already supports* weaker consistency models seemed more natural. Grouping operations (or enforcing
operation constraints) seemed easier to reason about than slicing operations into sub-groups, or
into isolated operations. Operationally, this makes MixT a very different approach to enforcing
consistency types. At a glance, this approach seems like it should be easier to build on top of
Ceph than an IPA-style consistency type system due to the lack of support for weaker consistency.
However, while the similarity between Ceph and Postgres providing strong consistency by default
seems like something that would make MixT applicable for being used on top of Ceph, it is not clear
that mixed-consistency transactions will be able to achieve weaker consistency on top of Ceph. I
suspect that support for weaker levels of isolation in Postgres enables MixT to support weaker
consistency by breaking up a transaction into smaller transactions. I may be misunderstanding
MixT's implementation, but it seems that weaker isolation is the only way to achieve weaker
consistency if the data store does not explicitly support weak consistency models. Before
attempting to architect an approach that layers MixT on top of Ceph, it will be important to
understand the effect of isolation levels on mixed-consistency transactions. It will also be
important to understand whether transaction splitting has the desired semantics over Ceph, given
that Ceph does not seem to support transactions (though they are requested? It is hard to tell when
they were requested and if they were ever completed).

### Declarative Programming over Mixed Consistencies
[QUELEA][quelea-paper] takes a declarative programming approach to allowing developers directly
reason over the consistency policies used for ADTs. [QUELEA's implementation][quelea-impl] provides
a declarative language for specifying an operational contract for an ADT to follow.

QUELEA, like IPA, uses Cassandra as the backend data store. Because QUELEA takes specifications for
an ADT and then communicates with the data store in a way that enforces the consistency
constraints, it seems that QUELEA may also require the ability to communicate with Ceph OSDs
individually, just like IPA. Once Ceph supports weaker consistency data operations, or some way of
communicating with Ceph allows weaker consistency, then QUELEA would be an ideal approach to take
for a DPS system.

<!-- ------------------------------>
<!-- SECTION -->
# Glossary
For conciseness in other areas, many definitions are provided here.

#### Monitor
The Ceph Monitor service maintains a master copy of [*the cluster map*](#cluster-map) including:
* cluster members
* state
* changes
* overall health of the storage cluster

#### RADOS
The RADOS ([**R**eliable **A**utonomous **D**istributed **O**bject **S**tore][rados-paper]) data
store is the backend subsystem of Ceph that handles distributed data storage.

#### OSD
A Ceph OSD ([**O**bject **S**torage **D**aemon][osd-doc]) is a daemon that is responsible for
storing objects on a local file system and providing access to them over the network.

#### PG
A [**P**lacement **G**roup][pg-docs] is a logical collection of objects that are replicated by the
same set of devices. An object's PG is determined by:
    * a hash of the object name
    * the level of replication
    * a bit mask, representing the total number of PGs in the system.

#### CRUSH
[**C**ontrolled **R**eplication **U**nder **S**calable **H**ashing][crush-paper] is a pseudo-random
data distribution algorithm that efficiently and robustly distributes object replicas across a
heterogenous, structured storage cluster[^crush-fn].

#### Metadata Server
The [**M**eta**d**ata **S**erver][mds-docs] (MDS) daemons maange the file system namespace.

#### Cluster Map
Set of 5 maps that represent the toplogy of the ceph storage cluster:

1. [Monitor Map](#monitor-map)
2. [OSD Map](#osd-map)
3. [PG](#pg-map)
4. [CRUSH](#crush)
5. [MDS](#metadata-service)

#### Monitor Map
A map containing [Ceph Monitor](#monitor) information for the storage cluster:
* fsid
* position
* name address
* port
* current epoch
* creation timestamp (of the map)
* timestamp of last update (of the map)

#### OSD Map
A map containing [**O**bject **S**torage **D**aemon](#osd) information for the storage cluster:
* [fsid](#fsid)
* creation timestamp (of the map)
* timestamp of the last update (of the map)
* list of pools
* replica sizes
* PG numbers
* list of OSDs and their status


#### PG Map
A map containing [**P**lacement **G**roup](#pg) information for the storage cluster:
* PG version
* PG timestamp
* last (previous?) OSD map epoch
* full ratios
* details on each placement group
* PG ID
* Up Set
* Acting Set
* PG State (e.g. active + clean)
* data usage statistics for each pool

#### fsid
A unique identifier for an OSD. The "fsid" term is used interchangeably with "uuid".

<!-- footnotes -->
[^crush-fn]: This is defined in the abstract and introduction of the [CRUSH paper][crush-paper]
[^osd-fs-fn]: This is mentioned in [recommendations for the RADOS configuration][ceph-fs-recommendation]

<!-- intro links -->
[ipa-paper]: https://homes.cs.washington.edu/~luisceze/publications/ipa-socc16.pdf
[mixt-paper]: http://www.cs.cornell.edu/andru/papers/mixt/mixt.pdf
[quelea-paper]: http://kcsrk.info/papers/quelea_pldi15.pdf
[noah-dissertation]: https://cloudfront.escholarship.org/dist/prd/content/qt72n6c5kq/qt72n6c5kq.pdf?t=pcfodf

[cassandra-datastore]: http://cassandra.apache.org/
[postgres-dbms]: https://www.postgresql.org/docs/9.4/release-9-4.html

<!-- DPS links -->
[osd-doc]: http://docs.ceph.com/docs/mimic/man/8/ceph-osd/
[crush-paper]: https://ceph.com/wp-content/uploads/2016/08/weil-crush-sc06.pdf
[pg-docs]: http://docs.ceph.com/docs/mimic/rados/operations/placement-groups/
[mds-docs]: http://docs.ceph.com/docs/master/man/8/ceph-mds/
[declstore-paper]: https://www.usenix.org/conference/hotstorage17/program/presentation/watkins

<!-- programmable storage links -->
[disorderlylabs]: https://disorderlylabs.github.io/
[maltzahn-website]: https://users.soe.ucsc.edu/~carlosm/UCSC/Home/Home.html
[programmable-storage]: http://programmability.us/
[noah-dissertation]: https://cloudfront.escholarship.org/dist/prd/content/qt72n6c5kq/qt72n6c5kq.pdf?t=pcfodf
[noah-zlog-impl]: https://github.com/cruzdb/zlog
[noah-blog-zlog]: https://nwat.xyz/blog/2014/10/26/zlog-a-distributed-shared-log-on-ceph/
[ceph-intro]: https://ceph.com/ceph-storage/
[ceph-intro-blog]: https://ceph.com/geen-categorie/ceph-storage-introduction/
[ceph-cuttlefish-arch]: http://docs.ceph.com/docs/cuttlefish/architecture/#how-ceph-scales
[ceph-fs-recommendation]: http://docs.ceph.com/docs/jewel/rados/configuration/filesystem-recommendations/#filesystems
[ceph-backend-bluestore]: http://docs.ceph.com/docs/mimic/rados/configuration/storage-devices/#osd-backends
[ceph-backend-filestore]: http://docs.ceph.com/docs/mimic/rados/configuration/storage-devices/#filestore
[data-center-faq]: http://docs.ceph.com/docs/cuttlefish/faq/#can-ceph-support-multiple-data-centers
[rados-paper]: https://ceph.com/wp-content/uploads/2016/08/weil-rados-pdsw07.pdf
[crush-paper]: https://ceph.com/wp-content/uploads/2016/08/weil-crush-sc06.pdf

<!-- consistency-types links -->
[course-website]: http://composition.al/CMPS290S-2018-09/
[rdt-svo]: https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/replDataTypesPOPL13-complete.pdf
[strong-enough]: http://software.imdea.org/~gotsman/papers/logic-popl16.pdf
[ipa-impl]: https://github.com/bholt/ipa/tree/master/src/main/scala/ipa
[mixt-impl]: https://github.com/mpmilano/MixT
[quelea-impl]: https://github.com/kayceesrk/Quelea
