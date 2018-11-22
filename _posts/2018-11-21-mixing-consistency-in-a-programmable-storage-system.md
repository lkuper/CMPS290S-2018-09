---
title: Mixing Consistency in a Programmable Storage System
author: Aldrin Montana
layout: single
classes: wide
---

by Aldrin Montana &middot; edited by Abhishek Singh and Lindsey Kuper

## Introduction

Modern distributed applications call for ways to store and access data using a range of consistency guarantees. Consider a distributed shared log, like that described in the [FuzzyLog][fuzzylog-paper] paper. A log service is useful in many contexts for applications including data management systems and storage systems. The FuzzyLog paper describes the use of log services for funneling updates for data management systems and other services (e.g., metadata and coordination services, filesystem namespaces) within data centers. The authors motivate their work by discussing the benefit of distributing the log across several servers and relaxing constraints on data consistency.

Reasoning about mixed consistency becomes especially challenging where data accessed at one level of consistency is used in the computation for data at a different level of
consistency. In FuzzyLog, for instance, updates to the log are marked with _colors_ that enable a variety of consistency choices.  FuzzyLog makes operations to a single color across regions causally consistent, while operations to a single color within a region are serializable.  Hence, FuzzyLog uses at least two levels of consistency in its implementation.

The need to use a range of consistency levels in the same application motivates the need for _language-level_ support for mixed consistency.  Recent language-level abstractions such as [QUELEA][quelea-paper], [IPA][ipa-paper], and [MixT][mixt-paper] aim to make programming in a mixed-consistency world safer and easier. QUELEA allows the developer to declaratively specify the consistency guarantees provided by a datastore and the consistency requirements for application-level operations. IPA provides types representing consistency levels that can be placed on abstract data type (ADT) instances, and policies for determining the consistency of a data type at runtime. MixT is a domain-specific language (DSL) that uses information flow analysis to prevent weakly consistent data from influencing strongly consistent data.

In this blog post, we are interested in exploring approaches for specifying a range of consistency guarantees in a _programmable storage_ system. After giving an informal overview of data consistency in distributed systems, I'll discuss what programmable storage is and how a programmable storage system might support a mixture of consistency levels.

## Data consistency

In a distributed system where data is copied between multiple servers, keeping the copies consistent with each other may not always be possible.
For instance, consider a small system where each _data object_ has two copies (Copy<sub>1</sub> and Copy<sub>2</sub>), distributed over two servers. What if you're accessing Copy<sub>1</sub> and it is somehow different from Copy<sub>2</sub>?

A _consistency model_ defines the ways in which Copy<sub>1</sub> and Copy<sub>2</sub> may disagree. Informally, _strong consistency_ means that all clients agree on the order that operations on a data object appear.  Under _eventual consistency_, on the other hand, copies of a data object may appear different at any point, but given enough time without updates, all copies will converge to the same state.  In a hybrid consistency model, such as [RedBlue consistency](https://www.usenix.org/system/files/conference/osdi12/osdi12-final-162.pdf), individual operations on data objects may be strongly consistent (red) or eventually consistent (blue). Red operations must be ordered with respect to each other, while blue operations may be in any order (and must commute).

In some contexts, such as in the [MixT][mixt-paper] and [IPA][ipa-paper] programming models, consistency is considered a property of the _data_ being operated on, rather than a property of the operations themselves. Since ADTs are defined by the operations that can be invoke on them, though, these two points of view are necessarily difficult to disentangle. 

## Programmable storage

Across all fields of computing, data storage is extremely important. In fact, even abstract 
models of computation require the concept of _tape_, as an infinite, contiguous sequence of locations that can store symbols. It likely isn't surprising that significant improvements in storage devices have huge impacts for many areas of computing. However, hardware improvements have not always come fast enough. As application requirements for storage have grown, storage systems have grown more complex. To accommodate web-scale and high-performance applications, storage systems have become distributed, and spanned many storage devices.

The performance of a storage system has significant impact on the design and implementation of applications that communicate with it -- consider HDFS and cloud services such as Amazon's S3. In the case of HDFS, knowledge of how it partitions files or caches data can help the application programmer make choices to reduce latency or increase throughput. And so, as applications increase in both complexity and concurrency, there is an increasing need to extract better performance from the storage system.  In addition to growing application needs, there are also improvements in hardware that storage systems have yet to make use of. Due to reliability needs, storage systems must be well tested and extensively exercised.  On the other hand, due to increasing application requirements and the rate at which underlying hardware is improving, it is necessary to iterate quickly, or to periodically re-design various subsystems. Finally, there are a variety of storage devices to tune for, and that can significantly affect software system design and implementation.

_Programmable storage_ is an approach to developing storage interfaces, pioneered by storage systems researchers at UC Santa Cruz, that emphasizes programmability and reusability of storage subsystems to address these challenges.  Due to the inherently high reliability expectations of storage systems, the programmable storage approach discourages rewriting storage subsystems or components, because this only invites younger, error-prone code. The intuition is that reusing subsystems of a storage system means that the community supporting these subsystems is larger, and these subsystems are exercised and improved more frequently. The [Malacology][malacology-paper] programmable storage system is an interface built on top of the [Ceph](https://ceph.com/) storage stack.  Malacology abstracts storage subsystems into building blocks that can be combined to more easily build a service on top of the storage system.

Ceph is an open source, distributed, large-scale storage system that aims to be "[completely
distributed without a single point of failure, scalable to the exabyte level, and freely-available][ceph-intro-blog]." Ceph has been part of storage systems research at UC Santa
Cruz for over a decade, from [the original Ceph paper][ceph-paper] (2006), the [CRUSH algorithm][crush-paper] (2006) and the [RADOS][rados-paper] data store (2007), to [Noah Watkins's recent dissertation][noah-dissertation] on programmable storage built on top of Ceph.

Although Ceph is a distributed, large-scale storage system, it was designed to fill the role of
reliable, durable storage. This expectation is common (and preferred) for many applications,
especially scientific applications, where the complexity of weaker consistency models is too
difficult to work with. This makes Ceph's support for only strong consistency, via
[primary-copy][ceph-replication] replication, reasonable. However, the trade-off between strong consistency and availability or performance is very important for some [Dynamo-like][dynamo-paper] applications. For Ceph to support these types of applications, it would need to offer weaker consistency as an option.  Recent work on a weak consistency model for Ceph, [PROAR][proar-paper], has been published by researchers at the Graduate School at Shenzhen, Tsinghua University.

Further building up our motivating example, we would like to consider extensions to [ZLog][noah-blog-zlog], an distributed shared log developed on top of Malacology. ZLog is an implementation of the [CORFU](https://www.usenix.org/conference/nsdi12/technical-sessions/presentation/balakrishnan) strongly-consistent shared log. If Ceph (and Malacology on top of it) supported multiple consistency levels, then ZLog could as well.  It would be interesting to compare FuzzyLog to a mixed-consistency version of ZLog built on Malacology. Using an approach in the spirit of QUELEA, MixT, or IPA for mixing consistencies would align well with the programmability aspect of programmable storage.

## Mixing consistency

For developers working in distributed systems, it can be cumbersome to think about whether the correct consistency guarantees are being satisfied, especially when building on storage systems that support a mixture of consistency levels. In the past few years, there have been a variety of language-level abstractions that support reasoning about mixtures of consistency guarantees.

### Inconsistent, Performance-bound, Approximate (IPA) programming

[IPA][ipa-paper] provides a _consistency type system_ that makes consistency models explicit in types.  Developers are able to verify that important data types are used at an appropriate consistency level. This type of support from the programming model is useful for developers to be both more efficient and more correct. IPA is motivated by taking a principled approach to the trade-off between consistency and performance.

There is [a prototype implementation of IPA][ipa-impl] in Scala on top of Cassandra. Scala's
powerful type system allows for ergonomically deconstructing consistency types. This
approach allows the developer to directly interact with the consistency type of their data, using
features such as pattern matching. IPA allows consistency guarantees to be specified as a policy on an ADT in two ways:

  1. _Static consistency policies_ allow specification of a consistency model (e.g., strong, weak, causal) that can be enforced by the data store.
  2. _Dynamic consistency policies_ allow specification of performance or correctness bounds within which to achieve the strongest consistency possible, and which require additional runtime support to enforce.

Static consistency policies can be implemented relatively straightforwardly on top of the data store. For this particular implementation, consistency levels for data store operations are determined via Cassandra's use of quorum reads and writes.

Dynamic consistency policies are specifications of performance or behavior properties, within which the strongest consistency constraints should be satisfied. More concretely, IPA provides two dynamic consistency types: rushed types and interval types. The dynamic consistency types are out of scope for this blog post, but they are a very interesting aspect of the IPA paper.

### MixT: consistency enforced with information flow

[MixT][mixt-paper] is a domain-specific language that aims to keep consistent computations "untainted" by inconsistent computations. Because the use of inconsistent data can weaken computations that are expected to be strongly consistent, MixT takes an information flow approach to preventing unsafe, or unexpected, interactions between computations running at different consistency levels.  Furthermore, MixT offers support for _mixed-consistency transactions_ that execute in separate phases depending on the consistency level of the operations therein.

### QUELEA: declarative programming over eventually consistent data stores 

[QUELEA][quelea-paper] takes a declarative programming approach that allows developers to specify constraints on a data store and on the operations that interact with it. Programmers can annotate operations with _contracts_ that enforce application-level invariants, such as preventing a negative bank account balance. An SMT-based _contract classification_ system analyzes these contracts and automatically determines the minimum consistency level at which an operation can be run, simplifying reasoning about consistency from the developer's perspective. Further, QUELEA supports transactional contracts even when the backend datastore does not.

## Mixing consistency in programmable storage

The typical IO path to Ceph's storage cluster does not support consistency models other than strong consistency. To
support weaker consistency models in our programmable storage system, we would need to build support for a range of consistency models directly in Ceph.  That, in turn, would motivate the need for a language-level abstraction to help programmers deal with the resulting "consistency zoo".

To support an IPA-like system on top of Ceph with as little modification as possible, it would be useful to add a quorum interface to Ceph. Ceph's RADOS datastore uses OSDs (object storage daemons) for data persistence. By communicating with these OSDs directly, rather than through a RADOS gateway (RGW), it may be possible to provide a quorum interface in Ceph. Understanding the details of OSD communication will be important for understanding whether Ceph can provide a similar interface to IPA as what Cassandra provides.

MixT, being built on top of Postgres, describes an alternate possible mechanism for supporting
weak consistency in a programmable storage system. To enable causal consistency on top of Postgres, Milano et al. replicated data over several Postgres servers. Clients were then partitioned to separate servers and each server was configured to use snapshot isolation for transactions. Version numbers for each row allowed operation ordering across servers, and vector clocks used microsecond-resolution wall clock time. If we encode versions and vector clocks in data stored in Ceph OSDs, it may be possible to simply treat each OSD as a replica server as MixT does with Postgres, hence enabling causal consistency in Ceph.

The implementation of QUELEA, like IPA, uses Cassandra as the backend data store.  It uses a ["bolt-on"](http://www.bailis.org/papers/bolton-sigmod2013.pdf)-style mechanism implemented in a shim layer on top of the data store to enable causal consistency on top of Cassandra. Because QUELEA requires programmers to specify contracts on operations that interact with the store and ensures that store operations happen at a consistency level that satisfies those contracts, it seems that implementing QUELEA on top of Ceph may benefit from the ability to communicate with Ceph OSDs individually, just like IPA.

## Next steps

In a follow-up blog post, I will try to explore mechanisms by which Ceph could support a range of consistency levels. The approaches to investigate will include quorum consistency, bolt-on causal consistency, and MixT’s approach to causal consistency. Once we understand how these mechanisms might fit into Ceph, we can investigate various approaches to mixing consistency.

<!-- intro links -->
[cassandra-datastore]: http://cassandra.apache.org/
[cassandra-quorum]: https://docs.datastax.com/en/cassandra/3.0/cassandra/dml/dmlConfigConsistency.html
[postgres-dbms]: https://www.postgresql.org/docs/9.4/release-9-4.html

<!-- DPS links -->
[osd-doc]: http://docs.ceph.com/docs/mimic/man/8/ceph-osd/
[pg-docs]: http://docs.ceph.com/docs/mimic/rados/operations/placement-groups/
[mds-docs]: http://docs.ceph.com/docs/master/man/8/ceph-mds/

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
[ceph-replication]: http://docs.ceph.com/docs/cuttlefish/architecture/#cluster-side-replication

[wiki-quorum]: https://en.wikipedia.org/wiki/Quorum_(distributed_computing)
[wiki-shim]: https://en.wikipedia.org/wiki/Shim_(computing)


[ceph-paper]: https://www.ssrc.ucsc.edu/Papers/weil-osdi06.pdf
[crush-paper]: https://ceph.com/wp-content/uploads/2016/08/weil-crush-sc06.pdf
[rados-paper]: https://ceph.com/wp-content/uploads/2016/08/weil-rados-pdsw07.pdf

[datamods-paper]: https://users.soe.ucsc.edu/~jayhawk/watkins-pdsw12.pdf
[invivo-paper]: https://users.soe.ucsc.edu/~jayhawk/watkins-bdmc13.pdf
[mantle-paper]: https://dl.acm.org/citation.cfm?id=2807607
[malacology-paper]: https://dl.acm.org/citation.cfm?id=3064208
[declstore-paper]: https://www.usenix.org/conference/hotstorage17/program/presentation/watkins
[noah-dissertation]: https://cloudfront.escholarship.org/dist/prd/content/qt72n6c5kq/qt72n6c5kq.pdf?t=pcfodf

[fuzzylog-paper]: https://www.usenix.org/system/files/osdi18-lockerman.pdf

[proar-paper]: http://www.cs.nthu.edu.tw/~ychung/conference/ICPADS-2016.pdf
[ipa-paper]: https://homes.cs.washington.edu/~luisceze/publications/ipa-socc16.pdf
[mixt-paper]: http://www.cs.cornell.edu/andru/papers/mixt/mixt.pdf
[quelea-paper]: http://kcsrk.info/papers/quelea_pldi15.pdf
[bolton-paper]: http://www.bailis.org/papers/bolton-sigmod2013.pdf
[dynamo-paper]: https://dl.acm.org/citation.cfm?id=1294281
[ioflow-paper]: https://www.microsoft.com/en-us/research/wp-content/uploads/2013/11/ioflow-sosp13.pdf

<!-- consistency-types links -->
[course-website]: http://composition.al/CMPS290S-2018-09/
[rdt-svo]: https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/replDataTypesPOPL13-complete.pdf
[strong-enough]: http://software.imdea.org/~gotsman/papers/logic-popl16.pdf
[ipa-impl]: https://github.com/bholt/ipa/tree/master/src/main/scala/ipa
[mixt-impl]: https://github.com/mpmilano/MixT
[quelea-impl]: https://github.com/kayceesrk/Quelea
