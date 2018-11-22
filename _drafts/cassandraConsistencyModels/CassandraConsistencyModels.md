---
title: Consistency in Cassandra
author: Natasha Mittal
layout: single
classes: wide
---

by Natasha Mittal ⋅ edited by Devashish Purandare and Lindsey Kuper

## Introduction

Today, all popular NoSQL databases like [Cassandra](http://cassandra.apache.org/), [MongoDB](https://www.mongodb.com/scale/apache-open-source-projects) or [HBase](https://hbase.apache.org/) claim to provide eventual consistency and offer mechanisms to tune consistency.

*__What is a consistency model?__*

A consistency model is a contract between the distributed data store and processes, in which if the processes agree to obey rules for ordering the read/write operations, the underlying data store will precisely specify the result of these operations. According to [DataStax](https://docs.datastax.com/en/archived/cassandra/2.0/cassandra/dml/dml_config_consistency_c.html), consistency refers to how up-to-date and synchronized a row of Cassandra data is on all of its replicas. 

A _strongly consistent_ system guarantees that all operations are seen in the same order by all the nodes in the cluster, i.e., global total ordering of all read and write operations. This introduces high latency, as a lot of synchronization is required which hampers availability and scalability. On the other hand, _eventual consistency_ is easier to implement and provides lower latency as there is no synchronization overhead. It guarantees that if no updates are made to a given data item, eventually all replicas will converge and return the last updated value of the data item.

[_Tunable consistency_](https://docs.datastax.com/en/archived/cassandra/2.1/cassandra/dml/dmlAboutDataConsistency.html) is where clients have the flexibility to adjust the consistency levels as per the application requirements, ranging from strong to eventual consistency. Cassandra provides different read and write consistency levels and users can fine-tune these levels by explicitly modifying Cassandra's configuration file. An operation’s consistency level specifies how many replicas in the cluster need to acknowledge the coordinator node.

In this blog post, we will go over Cassandra’s consistency levels, [Light Weight Transactions (LWT)](https://www.datastax.com/dev/blog/lightweight-transactions-in-cassandra-2-0) which provide serial consistency, [vector clocks](https://amturing.acm.org/p558-lamport.pdf), and the [Jepsen](https://aphyr.com/posts/294-call-me-maybe-cassandra) analysis of distributed concurrency [bugs in Cassandra](https://issues.apache.org/jira/projects/CASSANDRA/issues).

## Cassandra's Model of Consistency


Let's establish a [few definitions](https://docs.datastax.com/en/archived/cassandra/2.0/cassandra/dml/dmlAboutDataConsistency.html) before getting started:

  * RF (Replication Factor): the number of copies of each data item
  * R: the number of replicas that are contacted when a data object is accessed through a read operation (the _read set_)
  * W: the number of replicas that need to acknowledge the receipt of the update before the update completes (the _write set_)
  * QUORUM: sum_of_replication_factors/2 + 1, where sum_of_replication_factors = sum of all the replication factor settings for each data center


R + W > RF is a strong consistency model, where the write set and the read set always overlap.


Configuring RF, R and W in this model depend on the application for which the storage system is being used. In a write-intensive application, setting W=1 and R=RF can affect durability in as failures can result in conflicting writes. In read-intensive applications, setting W=RF and R=1 can affect the probability of the write succeeding.


So, to provide strong consistency and fault tolerance for balanced read-write requests, these two properties are appropriate:


* R + W > RF 
* R = W = QUORUM

For example, a system with configuration RF=3, W=2, and R=2 provides strong consistency.


R + W <= RF is a weaker consistency model, where there is a possibility that the read and write set will not overlap and the system is vulnerable to reading from nodes that have not yet received the updates.
  
### Read Requests in Cassandra


As mentioned in the [DataStax documentation for Cassandra](https://docs.datastax.com/en/archived/cassandra/2.0/cassandra/dml/dmlAboutDataConsistency.html), Cassandra can send three types of read requests to a replica:

1. Direct read request
2. Digest request
3. Background read repair request

The coordinator node sends one replica node with a direct read request and a digest request to a number of replicas determined by the consistency level specified by the client. These contacted nodes return the requested data and the coordinator compares the rows from each replica to ensure consistency. If all replicas are not in sync, the coordinator chooses the data with the latest timestamp and forwards the result back to the client. Meanwhile, a background read repair request is sent to out-of-date replicas to ensure that the requested data is made consistent on all replicas.

The following table shows the read consistency levels that Cassandra provides:

| Consistency Level        | Usage                                                   |
| -------------------------|------------------------------------------------------------------------------------------|
| ALL                   | highest consistency and lowest availability                          |
| QUORUM                | strong consistency with some level of failure                          |
| LOCAL_QUORUM           | strong consistency which avoids inter-datacenter communication latency              |
| ONE               | lowest consistency and highest availability                          |

### Write Requests in Cassandra

The coordinator node sends a write request to all the replicas that comprise the write set for that particular row. As long as all the replicas are available, they will get the write request regardless of the write consistency level specified by the client. The write consistency level determines how many replicas should respond with an acknowledgment in order for the write to be considered successful.

The following table shows the write consistency levels that Cassandra provides:

| Consistency Level        | Usage                                                   |
| -------------------------|------------------------------------------------------------------------------------------|
| ALL                   | highest consistency and lowest availability                          |
| EACH_QUORUM           | strong consistency but write fails when a data center is down                  |
| QUORUM                | strong consistency with some level of failure                          |
| LOCAL_QUORUM           | strong consistency which avoids inter-datacenter communication latency              |
| ONE               | low consistency and high availability                                    |
| ANY               | lowest consistency and highest availability and guarantees that write will never fail    |

## Lightweight Transactions (LWT)

Applications like banking or airline reservations require the operations to perform in sequence without any interruptions. This is [linearizable](https://cs.brown.edu/~mph/HerlihyW90/p463-herlihy.pdf) consistency, which is one of the strongest single-object consistency models. Cassandra provides linearizability via [lightweight transactions (LWT)](https://www.datastax.com/dev/blog/lightweight-transactions-in-cassandra-2-0).

LWTs are used for insert and update operations using *IF* clause:

```sql
INSERT INTO account (transaction_date, customer_id, amount) 
VALUES (2016-11-02, 356, 125.00) 
IF NOT EXISTS
```
```sql
UPDATE account SET amount = 230.00 
WHERE payment_date = 2016-11-02
AND customer_id = 356 
IF amount = 125.00
```

To synchronize replica nodes for [LWT](https://www.datastax.com/dev/blog/lightweight-transactions-in-cassandra-2-0), Cassandra uses an implementation of the [Paxos consensus protocol](https://lamport.azurewebsites.net/pubs/paxos-simple.pdf). There are four phases in this implementation of Paxos: **prepare/promise**, **read/results**, **propose/accept** and **commit/ack**. Thus, Cassandra makes four network round trips between the coordinator node and other replicas in the cluster to ensure linearizable execution, so performance is affected.
Prepare/Promise is the most time-consuming phase of the Paxos algorithm. The leader node proposes a ballot number and sends it to all the replicas in the cluster. The replicas accept the proposal if the ballot number is the highest it has seen so far and sends back a promise message which includes the most recent proposal it has already received in advance.

If a majority/quorum of the nodes promises to accept the ballot number, the leader can then move on to the next phase of the protocol. But if a majority of the nodes sent an earlier proposal with their promise message, the leader must use that value.

If a leader node interrupts a previous leader node, then it must finish the previous leader’s proposal first and then proceed with its own proposal, thereby assuring the desired linearizable behavior. After the commit phase, the value written by LWT is visible to non-LWTs.
The following is a (slightly anonymized) example of a Paxos trace in Cassandra (taken from one of my own Cassandra logs from a system I worked on): 

```
Parsing insert into users (username, password, email ) values ( ‘mick’, ’mick’, ’mick@gmail.com' ) if
not exists; [SharedPool-Worker-1] | 2013-05-12 10:32:12.112000 | 127.0.0.1 | 1125
Sending PAXOS_PREPARE message to /127.0.0.3 [MessagingService-Outgoing-/127.0.0.3] | 2016-08-22 12:38:44.141000
| 127.0.0.1 | 10414
Sending PAXOS_PREPARE message to /127.0.0.2 [MessagingService-Outgoing-/127.0.0.2] | 2013-05-12 12:38:44.144200
| 127.0.0.1 | 10908
Promising ballot fb282190-685c-11e6-71a2-e0d2d098d5d6 [SharedPool-Worker-1] | 2013-05-12 12:38:44.149000 |
127.0.0.3 | 4325
Promising ballot fb282190-685c-11e6-71a2-e0d2d098d5d6 [SharedPool-Worker-1] | 2013-05-12 12:38:52.147000 |
127.0.0.3 | 4325
Promising ballot fb282190-685c-11e6-71a2-e0d2d098d5d6 [SharedPool-Worker-3] | 2013-05-12 12:38:52.166000 |
127.0.0.1 | 35282
Accepting proposal Commit(fb282190-685c-11e6-71a2-e0d2d098d5d6, [lwts.users] key=mick columns=[[] | [email
password]]\n Row: EMPTY | email=mick@gmail.com, password=mick) [SharedPool-Worker-2] |
2013-05-12 12:38:52.199000 | 127.0.0.1 | 67804
```

There are two consistency levels associated with [LWTs](https://www.datastax.com/dev/blog/lightweight-transactions-in-cassandra-2-0):

  1. **SERIAL** : where the Paxos consensus protocol will involve all the nodes across multiple data centers.
  2. **LOCAL_SERIAL** : where the Paxos consensus protocol will run on the local datacenter.

## Vector Clocks

[Vector clocks](https://en.wikipedia.org/wiki/Vector_clock) are used to determine whether pairs of events are causally related in a distributed system. Logical timestamps are generated for each event in the distributed system, and their causality (happens-before relation) is determined by comparing those logical timestamps.

 The timestamp for an event is a vector of numbers, with each number corresponding to a process. Each process knows its position in the vector.  Each process assigns a timestamp to each event. 

For a send_message event, the entire vector associated with that event is sent along with the message/payload. When the message is received by a process, the receiving process does the following:

  1. Increments the counter for the process' position in the vector.
  2. Performs an element-by-element comparison of the received vector with the process's timestamp vector, and sets the process' timestamp vector to the higher of the values:

```
for (i=0; i < num_elements; i++) 
    if (received[i] > system[i])
        system[i] = received[i];
```

To determine if two events are concurrent, an element-by-element comparison of their vector timestamps is done. If each element of timestamp V1 is less than or equal to the corresponding element of timestamp V2 then V1 causally dominates V2 and the events are not concurrent. If each element of timestamp V2 is greater than or equal to the corresponding element of timestamp V1 then V2 causally dominates V1 and the events are not concurrent. If neither of these conditions applies and some elements in V1 is greater than while others are less than the corresponding elements in V2, then the events are concurrent.

Vector clocks are illustrated in the following image:

<img src="vector_clock_final.gif"></img>
    
## Jepsen

[Jepsen](https://github.com/jepsen-io/jepsen) is an open source Clojure library, written by Kyle Kingsbury, designed to test the partition tolerance of distributed systems by fuzzing the systems with random operations. The results of these tests are analyzed to expose failure modes and to verify if the system violates any of the consistency properties it claims to have.  The Jepsen project [did an analysis of Cassandra in 2013](https://aphyr.com/posts/294-call-me-maybe-cassandra).

As [Joel Knighton mentions in his talk about how the DataStax team uses Jepsen](https://www.youtube.com/watch?v=OnG1FCr5WTI&t=335s), a Jepsen test has three key properties:

  1. **Generative**: relies on randomized testing to explore the state space of distributed systems
  2. **Blackbox**: observes the system at client boundaries (does not need any tracing framework or apply some code patch in the distributed system to run the test)
  3. **Invariance**: checks invariance from the recorded history of operations rather than runtime

His talk also covers the Jepsen [Test Data Structure](https://www.youtube.com/watch?v=OnG1FCr5WTI&t=368s):

```
{:name                    ...| name of the results
 :os                      ...| prepares the operating system
 :db                      ...| configures/starts/stops the database being tested
 :client                  ...| client protocol to interact with database
 :generator               ...| instructs on how to interact
 :conductors{:nemesis  ...}  | interacts with the environment
 :checker              ...}  | looks at and assesses the test run
```

Finally, his talk discusses [how a Jepsen test runs](https://www.youtube.com/watch?v=OnG1FCr5WTI&t=507s).
<img src="lein_test1.png" width="500px;" />

  1.    Orchestration node has one thread for each client and a thread for nemesis (introduces straggling, data corruption, clock drifts and node crashes) conductor.
  2.    A series of generated data comprising of read/write operations for client threads and crash/corrupt/partition operations for nemesis thread.
  3.    N nodes on which Cassandra cluster is running.

<img src="lein_test2.png" width="500px;" />

  4. A concurrently recorded history that explains the chronological behavior of the test. 
  5.    Operations in the history are expressed as windows which marks the beginning and ending.
  6.    After running the tests, the attached checker is executed, which produces judgment on the validity of the test or produces some artifacts to explain the result of the tests.

### Jepsen Analysis of Cassandra

#### Vector Clocks

Cassandra uses last-write-wins (LWW) policy to resolve conflicts and does not implement vector clocks. This reduces the number of network round trips from 2 to 1. In this case, 
if a client A writes x=1, and another client B writes x=2, it is possible that the final value of x can be 1 or 2 depending upon which write wins(the one with the latest timestamp). 

In order to avoid this problem, Cassandra uses the concept of immutable data. For every update operation for a particular column, a <value,timestamp> pair is added. For example, for a particular column ‘name’, subsequent updates will be of the type:

```
name
Mick, 2017-11-23 12:11:23
Micky, 2017-11-24 17:13:45
Micky Lawson, 2017-12-02 09:34:09
```
When a client makes a read request, a client-specific merge function is applied to all the column values and the desired result is obtained.

**In case of equal timestamps, the lexicographically greater value is chosen.** 

For this to happen, two timestamps need to collide and it is a rare possibility that two writes will get an exactly same microsecond-resolution timestamp.

[The Jepsen analysis of Cassandra tested this](https://aphyr.com/posts/294-call-me-maybe-cassandra) by repeatedly changing a column value and found that 1 row is corrupted per 250 transactions. 

```
1000 total
399 acknowledged
397 survivors
4 acknowledged writes lost!         //writes lost means corrupt data
```
In Cassandra, the time-resolution is in milliseconds (three zeroes are blindly appended at the end to show microsecond precision). The probability of writes conflicting is much higher for millisecond-resolution and this results in so much corrupt data.

When a client makes a read request, the coordinator node collects the data from required nodes and compares the digest (hash) of the data. If there is a mismatch, conflict is resolved by using the latest timestamp wins policy. In the case of equal timestamps, a value which is lexicographically greater is chosen and sent to inconsistent replicas for read repair. It is possible that the corrupted value is lexically greater than the original value. As a result, the corrupted value will be returned to the user and also propagated to other correct replicas.

#### Session Consistency

Since Cassandra uses last-write-wins policy, it is tightly bound to wall-clock timestamps for ordering the writes. It provides the "Read Your Writes" and "Monotonic Reads" [session guarantees](https://dl.acm.org/citation.cfm?id=645792.668302)

The Jepsen tests of Cassandra introduce clock drifts due to which system clocks are unsynchronized, and the session guarantees no longer hold. For instance, this becomes an issue when dealing with leap seconds.  A leap second is a one-second adjustment (due to irregularities in Earth’s rotation) that is occasionally applied UTC to keep it close to the solar time at Greenwich. Linux Kernel systems handle leap seconds by taking a one-second backward jump.

Jepsen explains the following situation that can arise in Cassandra:

  1. a client writes w1 prior to leap second and 
  2. same client then writes w2 just after the leap second
  3. session consistency expects subsequent read to see w2
  4. but w2 has lower timestamp than w1, Cassandra ignores w2 

Since system clocks are not monotonic, timestamps alone cannot be used for global total ordering of operations across all the data centers.

Having worked extensively with Cassandra as a backend developer in an e-commerce firm, I can say that these issues are prominent, and occur frequently during the copious amounts of transaction processing. This has forced enterprises to introduce hacks at the application level, thereby increasing complexity and making the application code lengthy.

#### Bugs that Jepsen analysis found in Cassandra

[The analysis found numerous issues](https://issues.apache.org/jira/projects/CASSANDRA/issues) which challenged Cassandra's claim to offer linearizability via LWTs:

#### WriteTimeoutException when LWT concurrency level = QUORUM

During high contention, the coordinator node loses track of whether the value it submitted to Paxos has been applied or not. For instance:

 * Thread A: Reads version 1
 * Thread A: Transaction id=ABC, updates version 1 to 2 and sets account balance to $0+$100=$100, successfully applies the update but still receives a WTE.
 * Thread B: Reads version 2
 * Thread B: Transaction id=XYZ, updates version 2 to 3, and sets account balance to $100+500=$600, no WTE.
 * Thread A: tries again, reads version 3 this time, sees that version 3 is greater than it's previous version 2, now it checks the transaction id and finds it's also different.

In this case, thread A cannot clearly identify that whether its update failed or succeeded. A might assume that it failed and try again and add another $100 to the balance, causing more money to appear in the account that would be expected.

#### Incorrect implementation of Paxos

Paxos says that on receiving the promise messages from a majority of nodes, the leader should propose the value of the higher-number proposal accepted amongst the ones returned by the nodes, and only propose its own value if no node has sent back a previously accepted value.

But the current implementation ignores the value already accepted by some nodes if any of the nodes sends a more recent ballot than the other node but with no values. The net effect is that mistakenly the system is accepting two different values for the same round.

Since the first analysis of Cassandra by Jepsen in 2013, the DataStax team has adapted Jepsen and further extended it by incorporating new tests to break the new versions of Cassandra and this has helped to identify critical bugs in the implementation.


