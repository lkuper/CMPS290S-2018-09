# Supporting mixed consistency in a Declarative Programmable Storage System

<!-- ------------------------------>
<!-- SECTION -->
## Introduction
In this blog post, we explore how to enforce various consistency models in a **D**eclarative
**P**rogrammable **S**torage (DPS) system. In the following sections, we describe what we mean by
DPS systems:

* [*programmable storage* systems](#programmable-storage)
* [**D**eclarative **P**rogrammable **S**torage](#declarative-programmable-storage):

Once we know what a DPS system is, and what type of backend data store we are using, We analyze
implementations of consistency type systems (e.g. [IPA][ipa-paper], [MixT][mixt-paper]) and
declarative programming models (e.g. [QUELEA][quelea-paper]) for explicitly accommodating, and
reasoning over, a variety of consistency models. Background for understanding what consistency
means and what consistency models are, can be found in these sections (TBD later, since this
knowledge is assumed for the class):

<!-- TODO later -->
* [Consistency](#consistency)
* [consistency models](#consistency-models)

And then we explore our main topics of interest in these sections:

* [consistency type systems](#consistency-type-systems)
* [consistency as a property](#consistency-as-a-property)

And, for convenience, there is a [glossary](#glossary) at the end of this blog post.

### Overview
For a DPS system, There are 2 major features that I explore to allow developers specify
consistency requirements over data types:
1. Mechanisms for supporting weaker consistency models in the backend storage system.
2. A way to define, and enforce, consistency requirements for data types.

The IPA and QUELEA implementations used [Cassandra][cassandra-datastore] as the backend storage
system, while the MixT implementation used [PostgreSQL][postgres-dbms] as the backend storage
system. To support consistency types on top of a data store, it would be ideal to use a data store
that supports weaker consistency models, such as Cassandra, that way logic only needs to be added
on top of the data store. Cassandra provides flexible consistency by allowing writes to be sent to
any number of replicas within each datacenter or across datacenters. In contrast, a data store that
only supports strong consistency, such as PostgreSQL, requires an alternate approach to adding
support for consistency types. MixT defines its own transaction context, and breaks this
transaction down into separate PostgreSQL transactions in order to control consistency.

For my data store backend, I am interested in using Ceph, a programmable storage system. Some
[initial work on a DPS system][noah-dissertation], by Noah Watkins, uses Ceph as the backend
storage system for designing a DPS system. In general, the purpose of DPS systems is to address
maintainability and expressiveness of *programmable storage* systems using declarative languages.
For traditional storage systems, strong consistency is a must. Although Ceph is a distributed,
large-scale storage system, Ceph was designed to fill the role of traditional storage systems as
reliable, durable storage. This expectation is common (and preferred) for many applications,
especially scientific applications, where the complexity of distributed systems and consistency
models weaker than linearizability is too difficult to work with. This makes Ceph's support for
only strong consistency reasonable. However, there are many other applications with large data
volumes, rich data models, but with inherently low business risk that prefer to trade strong
consistency for availability and performance. This is especially common in social, web-based
applications. To build a storage system that can support these types of applications, it would be
ideal to provide the ability to specify weaker consistency models over low risk, or non-essential,
data types.

Even beyond the support of mixed consistency levels, this investigation will be useful for future
work, exploring the generalization of data properties. MixT claims that consistency is a property
of data. For storage systems which are designed entirely around the storage of data, being able to
enforce pre- and post-conditions and reason over general properties of data seems incredibly
useful. This is a secondary motivation of this blog post, to explore a generalization of
consistency types to data type properties.

<!-- ------------------------------>
<!-- SECTION -->

# Programmable Storage

<!-- TODO
* Describe Ceph:
    * what is Ceph?
    * Why only strong consistency?
    * Why weaker consistency (Examples, examples, examples)?
    * How weaker consistency? (Also, Object Gateway?)
        * What granularity
        * How is it tunable
        * Quorum?
-->

## [Ceph][ceph-intro]
Ceph is an open source, distributed, large-scale storage system. Some quotes that nicely summarize
Ceph:

* As described by Noah Watkins, [in his dissertation][noah-dissertation], "Ceph is something of a
  storage Swiss army knife."
* According to [Ceph's introduction blog post][ceph-intro-blog], "the main goals of Ceph are to be
  completely distributed without a single point of failure, scalable to the exabyte level, and
  freely-available."

Ceph has been part of storage systems research at UC Santa Cruz for several years under Carlos
Maltzahn, including the [CRUSH algorithm][crush-paper] (2006), the data store, [RADOS][rados-paper]
(2007), up to and including Noah's dissertation earlier this year (2018). I have just
started working with Carlos Maltzahn and Peter Alvaro on [declarative programmable
storage](declarative-storage), making Ceph a natural choice for investigating related, initial
research questions. While I am not personally experienced with Ceph, if I can provide a layer for
enforcing consistency types on top of Ceph, then Noah's [programmable storage work on top of
Ceph][noah-zlog] could benefit. Then, this carries over nicely into assessing the utility of
sequential, causal, or weaker consistency for a programmable storage system.

Ceph's architecture is designed around the [RADOS data store](#rados). This data store is a unified
system that provides storage interfaces for objects, blocks, and files. A Ceph storage cluster
consists of two types of daemons:
* [Ceph Monitor](#ceph-monitor)
* [Ceph OSD](#ceph-object-storage-daemon)

### Ceph Monitor
The [Ceph Monitor](#monitor) ... TODO.

### Ceph **O**bject **S**torage **D**aemon
The [Ceph OSD](#osd) relies upon the stability and performance of the underlying
filesystem[^osd-fs-fn] when using [the filestore
backend][ceph-backend-filestore]. The file system currently recommended for
production systems is XFS, although btrfs is supported. On the other hand, the
[new BlueStore backend][ceph-backend-bluestore] allows Ceph to directly manage
storage devices, bypassing the extra layer of abstraction that comes with the
use of kernel file systems (e.g. XFS, btrfs).

### Ceph Object Gateway and Eventual Consistency for Disaster Recovery
Ceph is able to [support multiple data centers][data-center-faq], but only
provides strong consistency. When a client writes data to Ceph the primary
OSD will not acknowledge the write to the client until the secondary OSDs have
written the replicas synchronously. Ceph [achieves
scalability][ceph-cuttlefish-arch] through "intelligent data replication."

<!-- TODO edit -->
The Ceph community is working to ensure that OSD/monitor heartbeats and peering
processes operate effectively with the additional latency that may occur when
deploying hardware in different geographic locations. See Monitor/OSD
Interaction for details.

If your data centers have dedicated bandwidth and low latency, you can
distribute your cluster across data centers easily. If you use a WAN over the
Internet, you may need to configure Ceph to ensure effective peering, heartbeat
acknowledgement and writes to ensure the cluster performs well with additional
WAN latency.

The Ceph community is working on an asynchronous write capability via the Ceph
Object Gateway (RGW) which will provide an eventually-consistent copy of data
for disaster recovery purposes. This will work with data read and written via
the Object Gateway only. Work is also starting on a similar capability for Ceph
Block devices which are managed via the various cloudstacks.

<!-- ------------------------------>
<!-- SECTION -->

<!-- TODO
* Describe Declarative Programmable Storage:
    * how does it interact with Ceph?
    * how could consistency level be specified
    * how could consistency level be enforced
-->

# Declarative Programmable Storage
Programmable storage tends to be a low-level task that requires lots of code and detailed knowledge
of storage subsystem implementations. Even when carefully written, storage systems built on top of
reusable components can still expose dependencies that make maintenance prohibitively expensive. By
using a declarative language for specifying storage systems, implementations over reusable
components can be made more tractable and flexible. [DeclStore][declstore-paper] is a step towards
declarative programmable storage. 

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

#### Linearizabilty

#### Sequential Consistency

#### Causal Consistency

#### Eventual Consistency

#### Weak Consistency

<!-- ------------------------------>
<!-- SECTION -->
## Consistency Types
As described in the [Consistency Models](#consistency-models) section, there
are many consistency models that are meaningful for developers working in
distributed systems. From the perspective of a consistency type system, we are
interested in how to verify and enforce them for associated data types.
To do this, Consistency type systems associate data types with the consistency
model we would like the data types to conform to. The consistency model is
defined by consistency constraints (or requirements), in a way that the
programming language or system can enforce. The association of data types with
consistency models allows the developer, and the system, to explicitly reason
over consistency constraints in applications.

### Related Work
In [CMPS290S][course-website], we have been reading a handful of papers that discuss various tools
for understanding, analyzing, and reasoning about consistency in a distributed system. There are a
few categories that I would group related work into:

1. Consistency type systems
2. Analysis of consistent, distributed logic

For the first category, consistency type systems, I first describe and analyze the following
existing implementations:
* [Disciplined Inconsistency with Consistency Types][disciplined-inconsistency]
* [MixT: A Language for Mixing Consistency in Geodistributed
  Transactions][mixt]

Analysis of consistent, distributed logic is analysis for understanding, proving,
and designing distributed systems with respect to the requirements of various
consistency models that abstract data types and operations satisfy. For this
category, this blog post is influenced by:
* [Replicated Data Types: Specification, Verification, Optimality][rdt-svo]
* ['Cause I'm Strong Enough: Reasoning about Consistency Choices in Distributed
  Systems][strong-enough]

## Consistency type systems

## Analysis of consistent, distributed logic

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
[noah-zlog]: https://github.com/cruzdb/zlog
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
[disciplined-inconsistency]: https://homes.cs.washington.edu/~luisceze/publications/ipa-socc16.pdf
[mixt]: http://www.cs.cornell.edu/andru/papers/mixt/mixt.pdf
[rdt-svo]: https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/replDataTypesPOPL13-complete.pdf
[strong-enough]: http://software.imdea.org/~gotsman/papers/logic-popl16.pdf
