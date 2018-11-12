# TODO:
* Link Declarative programmable storage and consistency back to IPA and
  MixT

# Introduction
In this blog post, I explore how to enforce various consistency models in a **D**eclarative
**P**rogrammable **S**torage (DPS) system. I analyze implementations of consistency type systems
(e.g. [IPA][ipa-paper], [MixT][mixt-paper]) and declarative programming models (e.g.  [Declarative
Programming over ECDS][quelea-paper]) for explicitly accommodating, and reasoning over, a variety
of consistency models.

Necessary background information can be found in the following sections:
* [**D**eclarative **P**rogrammable **S**torage](declarative-programmable-storage/index.md):
    * [*programmable storage* systems](declarative-programmable-storage/programmable-storage.md)
    * [glossary of DPS system terminology](declarative-programmable-storage/glossary.md)
* [Consistency](consistency/index.md)
    * [consistency models](consistency/consistency-models.md)
    * [consistency type systems](consistency/consistency-type-systems.md)
    * [consistency as a property](consistency/consistency-as-a-property.md)

For a DPS system, I imagine there are 2 major features to allow developers to specify consistency
requirements over data types:
1. Mechanisms for supporting weaker consistency models in the backend storage system.
2. A way to define, and enforce, consistency requirements for data types.

The IPA and QUELEA implementations used [Cassandra][cassandra-datastore] as the backend storage
system, while the MixT implementation used [PostgreSQL][postgres-dbms] as the backend storage
system.

<!--TODO-->
Cassandra is an eventually consistent data store.

I am interested in using Ceph, a programmable storage system as
the backend. Some [initial work on a DPS system][noah-dissertation], by Noah Watkins, uses Ceph as
the backend storage system for designing a DPS system. In general, the purpose of DPS systems is to
address maintainability and expressiveness of *programmable storage* systems using declarative
languages.

For distributed storage systems, strong consistency is a must. While many data management systems
sacrifice strong consistency for availability and performance, a storage system that provides file
and object storage interfaces is expected to be durable. However, it is common for applications
with large data volumes and rich data models to prefer the storage system over a data management
system for ad-hoc data processing. This is especially common in social, web-based applications. For
applications that use the storage system for non-essential data persistence, trading weaker
consistency for availability and lower latency can be preferable.

Even beyond the use of declarative reasoning over mixed consistency levels,
this investigation will be useful for future work, exploring the generalization
of data properties enforceable with pre and post conditions, and how to reason
over them.

The meat of what this blog post then investigates, can be found in the
[Consistency as a Property](consistency/consistency-property.md)
subsection of the [Consistency](consistency/intro.md) section. The
Investigation section, overall, describes how consistency as a property may be
implemented and reasoned over in a declarative programmable storage system.

## Short Term Objective
To design and implement a DPS system that is able to optimize over, and generate an "execution
plan," for a storage application *that can accommodate several consistency models*.

## Long Term Objective
 (and similar
properties) 

[ipa-paper]: https://homes.cs.washington.edu/~luisceze/publications/ipa-socc16.pdf
[mixt-paper]: http://www.cs.cornell.edu/andru/papers/mixt/mixt.pdf
[quelea-paper]: http://kcsrk.info/papers/quelea_pldi15.pdf
[noah-dissertation]: https://cloudfront.escholarship.org/dist/prd/content/qt72n6c5kq/qt72n6c5kq.pdf?t=pcfodf

[cassandra-datastore]: http://cassandra.apache.org/
[postgres-dbms]: https://www.postgresql.org/docs/9.4/release-9-4.html

[hacky-comment-1]: reason_about_consistency_from_a_dataflow_perspective.
# TODO:
* Describe Declarative Programmable Storage:
    * how does it interact with Ceph?
    * how could consistency level be specified
    * how could consistency level be enforced

# Declarative Programmable Storage

# Glossary
For conciseness in other areas, many definitions are provided here.

## Programmable Storage

### Ceph

##### OSD
[**O**bject **S**torage **D**aemon][osd-doc] is a daemon that is responsible for storing objects on
a local file system and providing access to them over the network.

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

1. Monitor
2. [OSD](#osd)
3. [PG](#pg)
4. [CRUSH](#crush)
5. [MDS](#metadata-service)

#### fsid
A unique identifier for an OSD. The "fsid" term is used interchangeably with "uuid".

## Declarative Programmable Storage

[osd-doc]: http://docs.ceph.com/docs/mimic/man/8/ceph-osd/
[crush-paper]: https://ceph.com/wp-content/uploads/2016/08/weil-crush-sc06.pdf
[pg-docs]: http://docs.ceph.com/docs/mimic/rados/operations/placement-groups/
[mds-docs]: http://docs.ceph.com/docs/master/man/8/ceph-mds/
[^crush-fn]: This is defined in the abstract and introduction of the [CRUSH paper][crush-paper]
# TODO
* Describe Ceph:
    * what is Ceph?
    * Why only strong consistency?
    * Why weaker consistency (Examples, examples, examples)?
    * How weaker consistency? (Also, Object Gateway?)
        * What granularity
        * How is it tunable
        * Quorum?

# Programmable Storage

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

Ceph's architecture is designed around the
[**R**eliable **A**utonomous **D**istributed **O**bject **S**tore (RADOS)][rados-paper].
This data store is a unified system that provides storage interfaces for objects,
blocks, and files. A Ceph storage cluster consists of two types of daemons:

* Ceph Monitor
* Ceph **O**bject **S**torage **D**aemon (OSD)

The Monitor daemon maintains a master copy of [*the cluster map*](glossary.md#cluster-map)
including:

* cluster members
* state
* changes
* overall health of the storage cluster

*The cluster map* is a set of 5 maps that altogether represent the storage
cluster topology:

1. [Monitor Map](#monitor-map)
2. [OSD Map](#object-storage-daemon-map)
3. [**P**lacement **G**roup Map](#placement-group-map)
4. [**C**ontrolled **R**eplication **U**nder **S**calable **H**ashing Map](#controlled-replication-under-scalable-hashing-map)
5. [**M**eta **D**ata **S**oftware Map](#meta-data-software-map)

#### Monitor Map
A map of Ceph Monitor daemons to their:
* fsid
* position
* name address
* port
* current epoch
* creation timestamp (of the map)
* timestamp of last update (of the map)

#### **Object** **S**torage **D**aemon Map
A map of OSD damones to their:
* fsid
* creation timestamp (of the map)
* timestamp of the last update (of the map)
* list of pools
* replica sizes
* PG numbers
* list of OSDs and their status


#### **P**lacement **G**roup Map
A map containing:
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

#### **C**ontrolled **R**eplication **U**nder **S**calable **H**ashing Map
TODO



#### **M**eta **D**ata **S**oftware Map
TODO



### Ceph **O**bject **S**torage **D**aemon
The Ceph OSD relies upon the stability and performance of the underlying
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

[^osd-fs-fn]: This is mentioned in [recommendations for the RADOS configuration][ceph-fs-recommendation]

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
# Background
This blog post groups background information into three subsections:
1. [Consistency Models](consistency-models.md)
2. [Consistency Types](consistency-type-systems.md)
3. [Declarative Programmable Storage](declarative-programmable-storage.md)

Subsections 1 and 2 provide background information necessary to talk about what
a consistency model is and the various models of consistency that have been
defined and studied. Subsection 3 then describes and defines declarative
programmable storage and then details how consistency models and consistency
types are relevant to declarative programmable storage.
# Consistency Models
This subsection defines the various consistency models as well as terminology
for distinguishing between them and understanding relevant constraints.

## Linearizabilty

## Sequential Consistency

## Causal Consistency

## Eventual Consistency

## Weak Consistency
# Consistency Types
As described in the [Consistency Models](consistency-models.md) section, a consistency model is a
framework for defining what consistency is. Because there are many consistency models, it is useful
to understand how to compare them, but especially how to verify and enforce them. Consistency type
systems associate data types with the consistency model we would like the data types to conform to.
The consistency model is defined by consistency constraints (or requirements), in a way that the
programming language or system can enforce. The association of data types with consistency models
allows the developer, and the system, to explicitly reason over consistency constraints in
applications.

## Related Work
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

[course-website]: http://composition.al/CMPS290S-2018-09/
[disciplined-inconsistency]: https://homes.cs.washington.edu/~luisceze/publications/ipa-socc16.pdf
[mixt]: http://www.cs.cornell.edu/andru/papers/mixt/mixt.pdf
[rdt-svo]: https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/replDataTypesPOPL13-complete.pdf
[strong-enough]: http://software.imdea.org/~gotsman/papers/logic-popl16.pdf
