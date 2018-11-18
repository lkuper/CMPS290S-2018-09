# "Hey! Watch it!" OR conflict resolution collaborative editors (Part 1 of 2)

## Introduction

The main idea I would like to discuss in this blog post is: what are conflicts in collaborative work and how do we resolve these conflicts. We will look into collaborative work tools such as collaborative text editors, version control systems, etc., and try to understand the features that such tools provide their users. We will focus mainly on problems that such tools have to solve to allow multiple users using these tools to build stuff collaboratively.

Anyone who has used a version control system or worked in a collaborative setting knows all too well the problems which arise when there are conflicts between replicas of a document people have been editing.

What are these conflicts? Well it all starts very innocuously when - the protagonists of recurring CS tales - Alice and Bob decide to collaboratively work on writing a document. They decide to use a new collaborative document editing tool called Frugal Docs. Alice creates a document, shares it with Bob. Alice starts editing the document. The document at Bob's end synchronizes with Alice's copy and when Bob edits his copy of the document, Alice gets to see the changes. Both continue editing their documents happily ever after. The problem begins when we encounter [network partitions](https://en.wikipedia.org/wiki/Network_partition).

Everything is alright as long as Alice communicates with Bob and Bob with Alice, and both are aware of changes the other has made. Until they can't. And when they can't communicate we say that there has arisen a partition in their "network". To make things even more sinister, let's say they don't know if they have been separated. Let's say they continue to work on their respective documents and then they make changes in sections that the other is currently editing. The problem isn't that Alice and Bob are continuing to work under this partition. It is not a problem because both can continue to work under partition and have a local copy that might be different from the others. The problem that the collaborative tool needs to address is: when the network partition is healed and Alice and Bob can communicate with each other, how does it synchronize their copies of the document? If it were an offline world where each was writing on a piece of paper independently, Alice and Bob will have to sit and sort out each other's changes and create a unified document where both their changes are merged. The automation of this process is what any collaborative tool aims to do. We will look into possible solutions to this problem and how this problem is solved in practice.

## Examples of collaborative document editing

Some examples of [collaborative software](https://en.wikipedia.org/wiki/Collaborative_software) which most of the readers of this blog may have used are:

* Real-time collaboration and live editing: Online docs (Google/Microsoft docs)
* Version control software (git, mercurial, subversion)

There may be others but for this but for the purposes of this blog these applications are prototypical of the vast majority of collaborative tools available.

### Conflicts in live-editing applications

The example of the Alice-Bob tale of collaborative editing mentioned earlier falls into this category. An example of this type of application is Google Docs[14]. Users can share documents and multiple users can edit the document simultaneously. I mentioned the kinds of conflicts that arise in such applications but it basically boils down to this: edits from _user 1_ made to sections edited by _user 2_ must be resolved when the documents sync.

### Conflicts in version control systems

Version control systems or VCS are one of the most important programs used by developers and engineers. On a side note: version control software can be (and is) used by anyone who wants to maintain different versions of any kind of document. In most cases these documents are source code for programs and are being worked on by lots of users simultaneously.

Some VCS maintain a central repository which users can replicate locally and work on. Such VCS allow users to work offline and only sync with the main repository when they want to. Subversion is one example of such VCS. Most new version control systems are distributed: this means that there is no single location where the files are located. We will not discuss details of these VCS further. However, I will mention that the central problem of conflict resolution still exists in such software but is amplified to large extent mainly due to the nature of the application and the number of users that affect change in the data.

## Merge strategies and algorithms in use

In part 1 of this post we will look at Operational Transformation: an algorithm which was design for systems to perform tasks collaboratively.

### Operational Transformation

[Operational Transformation](https://en.wikipedia.org/wiki/Operational_transformation) is a technique which was first discussed in a 1989 paper called ["Concurrency control in groupware systems" by Ellis and Gibbs](http://doi.acm.org/10.1145/67544.66963). The technique described in the paper was intended to allow systems to collaboratively perform a common task. An important consideration when trying to understand collaborative work in general is the notion of what an operation is and what does it mean when we say operation _x_ happened before operation _y_. Additionally, it is one thing to say that _x_ happened before _y_ and another to say that _x caused y_. One of the aims of operational transformation is to recognize these cases and differentiate between them.

Operational Transformation was made popular by Google in its [Google Wave project](http://web.archive.org/web/20090923095705/http://www.waveprotocol.org/whitepapers/operational-transform). Much of the original papers and documentation has been removed from Google since Google Wave was discontinued but some documents are available via the [Wayback Machine.](https://web.archive.org/web/20111126052203/http://wave-protocol.googlecode.com/hg/whitepapers/operational-transform/operational-transform.html) Operational Transformation has also made into Google's [other products](https://developers.google.com/realtime/conflict-resolution) such as [Google Drive and Google Docs](https://drive.googleblog.com/2010/09/whats-different-about-new-google-docs_22.html). Operational Transformation is an algorithm where users keep track of operations performed on shared data as a means of keeping track of changes in the data. A more elaborate discussion of Operational Transformation was published by [Sun and Ellis](http://dx.doi.org/10.1145/289444.289469).

To describe operational transformation in its most basic form, let’s say we have a document which is being edited by two users **A** and **B**. Each has a local copy of the document and a common data in the document. Let’s say the data string in the document is “*ABCDEFGH*”. Let’s call this initial string `T`, where `T = “ABCDEFGH”`. Users **A** and **B** have their own copies of the text `Ta` and `Tb` respectively. **A** makes a change to `Ta` where it now reads: `Ta=“ABCMDEFGH”`. This is done by the user **A** performing an `insert` operation at index  `3` of character `"M"` on the string `Ta`. Let's call this operation `OPa1 = Ta.insert(3,'M')`. Concurrently, **B** deletes a character in his copy of the text. Keeping similar notation, the operation **B** performs is `OPb1 = Tb.delete(2)` which results in the text `Tb = “ABDEFGH”`. Now in order to synchronize copies of the text from users **A** and **B**, the users share the operations that were performed by them on the text.

But merely sharing operations performed by both users and applying those operations at their ends is not sufficient for the text to by synchronized. If **A** received `OPb1` and decided to delete index `2` at its end, the text would read `ABMDEFGH`. If **B** received `OPa1` and inserted `"M"` at `3`, the text `Tb` would read `ABDMEFGH`. Clearly, this is a problem. The solution is arrived at when both **A** and **B** take cognisance of the operations performed at their end and not just apply new operations on the results of previous operations.

The key insight from the above discussion is this: in order to correctly apply the the operations that happened on **B** to data on **A** there should be some function which can transform indices received from **B** to the exact index of data on **A** where the operation should be applied. Next, we will discuss a rudimentary implementation of such a transformation.

#### Implementation of Operational Transformation

_NOTE_: A word on terminology before we begin the discussion. The word 'local' is used below to denote where a program is executing: the 'local' machine or system. The word 'remote' is used to denote a remote machine where a 'remote' user may be working and making changes to their own copy of the data.

The following implementation of Operational Transformation is available [here](https://bitbucket.org/alfredd/collabalgos). The implementation follows the algorithm roughly as stated in the [1989 paper by Ellis and Gibbs](http://doi.acm.org/10.1145/67544.66963).

What follows is an explanation of the implementation of Operational Transformation via a few test scenarios. Each test case shown below adds an operation performed either locally on the data or by another user on their own copy of the data and sent over as part of the synchronization process. At the end of each synchronization step the data must be the same data on both local and remote users' ends. Each test case moves the editing process forward via a set of operations that are performed on the data. The following operations are performed on the data:

1. Initially the data is `abcd` inserted locally and is sent over to the remote machine. The idea is that we start with a system where both local and remote users have the same data and are in a consistent state.
2. A `y` is inserted next locally and the data becomes `yabcd`. This information is then sent to the remote server as well.
3. Concurrently the remote user adds `x` at index `2` to it's copy which is `abcd` and sends this operation to be synced with the local copy. The local data is modified to `yabxcd`.
4. At this point the remote user should also have seen the insert from step `2` and updated its copy of the data. So both user and remote data should be `yabxcd`.
5. The remote user then deletes the character at index `1` from its copy of the data which was `yabxcd`. The data becomes `ybxcd`. When this operation is received by the local system, data is updated to `ybxcd`.
6. The local user then inserts `f` at index `1` to its local copy of data which is `ybxcd`. The data is now `yfbxcd`.
7. The remote user concurrently deletes the character at index `3` of its local data which is `ybxcd`. The remote user's data becomes `ybxd`. This operation is received by the local system which deletes the character `c` from its index `4` with the data finally becoming `yfbxd`.
8. The remote system will also update its data when it receives the insert operation of character `f` at index `1` from the local system. When the operation is applied by the remote system its data will be modified from `ybxd` to `yfbxd`. Thus both local and remote users will converge to the same state.
9. It should be noted the index used in the remote operation need not always correspond to the same index in the local data. This is where Operational Transformation is used. The main idea behind Operational Transformation is, therefore, to understand in what cases transformation will have to be applied to convert indices to correct values.

The important thing to note here is that each modification to the data is performed as a series of operations. There are a few assumptions made in this implementation which are important to point out:

1. Operation messages from 'remote' sites are received exactly once.
2. There are exactly 2 editors in the system: one 'local' and the other 'remote'.
3. The implementation does not use clocks to timestamp operations. So there is no way to know if an operation **O1** _happened before_ **O2**. It is assumed that LOCAL and REMOTE operations happen concurrently.
4. Ordering of the operations is implicit in the test cases. (Testcase #1 is processed before testcase #2.) Operations are processed in the order in which they are executed at the 'local' site. In our implementation the executed operations are stored in a list `OTEditor.Ops`. This imposes a partial order on the set of events occurring in the system.
5. Unlike the implementation in the [paper](http://doi.acm.org/10.1145/67544.66963), we do not assign priorities to an operation before the operation is sent to other editors. We assume that an operation is sent to others immediately after it was executed at one particular site.

This implementation of Operational Transformation is not without issues and one of the main issues is visible from the discussion so far: this implementation cannot guarantee convergence to a consistent state across replicas during a long enough network partition. One factor that we overlook in this implementation is that of establishing causality between a set of operations. There is an implicit _happens before_ relationship established by the order in which operations are stored in the `OTEditor.Ops` list. This can easily be broken by packets that arrive out of order leading to data inconsistency. The implementation, therefore, relies on the order on which the operations are received to establish consistency in the system. We will explore how these issues affect systems and how these are resolved in the next blog post.

```go
func TestOTEditor_Transformation(t *testing.T) {
	ot := OTEditor { Data: "yabcd", Ops: []Op{
		{Data: "abcd", Index: 0, Type: LOCAL, Op: INSERT},
		{Data: "y", Index: 0, Type: LOCAL, Op: INSERT},
		},
	}

	// Testcase #1
	fmt.Println("Test 1. remote insert 'x' at index 2")
	ot.AppendOperation(INSERT, "x", 2, REMOTE)
	assertEquals(ot.Data, "yaxbcd")

	// Testcase #2
	fmt.Println("Test 2. remote delete char at index 1")
	ot.AppendOperation(DELETE, "", 1, REMOTE)
	assertEquals(ot.Data, "yxbcd")

	// Testcase #3
	fmt.Println("Test 3. insert 'f' at index 1")
	ot.AppendOperation(INSERT, "f", 1, LOCAL)
	assertEquals(ot.Data, "yfxbcd")

	// Testcase #4
	fmt.Println("Test 4. delete char at index 3")
	ot.AppendOperation(DELETE, "", 3, REMOTE)
	assertEquals(ot.Data, "yfxcd")
}
```

Based on the above test cases and discussion, the following outputs is seen:

```go
Test 1. remote insert 'x' at index 2
2018/11/12 15:15:46 Existing Data: {yabcd [{1 abcd 0 0} {1 y 0 0}]}
2018/11/12 15:15:46 New Operation received: {1 x 2 1}
2018/11/12 15:15:46 Executing new operation: {1 x 2 1}, current data: yabcd
2018/11/12 15:15:46 Current value of data: {yabxcd [{1 abcd 0 0} {1 y 0 0} {1 x 3 1}]}

Test 2. remote delete char at index 1
2018/11/12 15:15:46 Existing Data: {yabxcd [{1 abcd 0 0} {1 y 0 0} {1 x 3 1}]}
2018/11/12 15:15:46 New Operation received: {2 '' 1 1}
2018/11/12 15:15:46 Executing new operation: {2 '' 1 1}, current data: yabxcd
2018/11/12 15:15:46 Current value of data: {ybxcd [{1 abcd 0 0} {1 y 0 0} {1 x 3 1} {2 '' 1 1}]}

Test 3. insert 'f' at index 1
2018/11/12 15:15:46 Existing Data: {ybxcd [{1 abcd 0 0} {1 y 0 0} {1 x 3 1} {2  1 1}]}
2018/11/12 15:15:46 New Operation received: {1 f 1 0}
2018/11/12 15:15:46 Executing new operation: {1 f 1 0}, current data: ybxcd
2018/11/12 15:15:46 Current value of data: {yfbxcd [{1 abcd 0 0} {1 y 0 0} {1 x 3 1} {2  1 1} {1 f 1 0}]}

Test 4. remote delete char at index 3
2018/11/12 15:15:46 Existing Data: {yfbxcd [{1 abcd 0 0} {1 y 0 0} {1 x 3 1} {2  1 1} {1 f 1 0}]}
2018/11/12 15:15:46 New Operation received: {2 '' 3 1}
2018/11/12 15:15:46 Executing new operation: {2 '' 3 1}, current data: yfbxcd
2018/11/12 15:15:46 Current value of data: {yfbxd [{1 abcd 0 0} {1 y 0 0} {1 x 3 1} {2 '' 1 1} {1 f 1 0} {2 '' 4 1}]}

```

In the [paper](http://doi.acm.org/10.1145/67544.66963) a necessary condition (but not sufficient) to ensure that the transformation function works is to ensure commutativity of the operations. Additionally, in this implementation, we need to understand if transformation is required. Transformation in the paper is a technique to resolve conflicts. If there are no conflicts, we do not apply any transformations.

First, we understand when is a transformation required. In the above test cases we have two cases where transformation is not required. The first is seen when the `insert` operation inserts `abcd` and `y`. These are 'local' operations. Data consistency is ensured because the 'local' editor is ["_reading your writes_"](https://en.wikipedia.org/wiki/Consistency_model#Read-your-writes_Consistency). Similarly, test case #2 does not require any transformation because the last operation was also a 'remote' edit. Since there were no other edits performed locally the data is consistent with the previous write. This is a weak spot in this implementation. Since there are only two editors ('local' and 'remote') if the 'remote' made two edits (test case #1 and #2), the data is consistent at the remote system and once the edits are applied locally at the 'local' system as well. In both these cases there are no conflicts where a transformation function is needed.

Second, we discuss what commutativity is and how it applies to our test cases. Given two operations _Oi_ and _Oj_ the transformation **T** generates the following transformations
* _Oj'_ := **T** (_Oj_, _Oi_)
* _Oi'_ := **T** (_Oi_, _Oj_)

The transformation **T** is implemented such that **_Oj'_ `x` _Oi_ `=` _Oi'_ `x` _Oj_**. 


Now that expectations are set, we implement a simplified Operational Transformation Editor. The first part of the implementation deals with setting up data structures. We have two main operations: `INSERT` and `DELETE`. These operations can be done either locally or could be sent as part of a synchronization message from a remote user. Operations are tagged `LOCAL` if they are performed at on the "local" machine and tagged `REMOTE` if they are sent from a remote user. The operation is described by the struct `Op` which defines the structure of the operations which the editor (`OTEditor`) can process. The editor `OTEditor` itself has two fields: `Data`, which stores application data and `Ops`, which keeps a record of operations that have been processed by the `OTEditor`. `OTEditor.Ops` imposes a partial order on the operations.

```go
type Operation string

const (
    INSERT Operation = "1"
    DELETE Operation = "2"
    PRINT  Operation = "4"
)

type OpType int

const (
    LOCAL  OpType = 0
    REMOTE OpType = 1
)

type Op struct {
    Op    Operation
    Data  string
    Index int
    Type  OpType
}

type OTEditor struct {
    Data string
    Ops  []Op
}

```


The `OTEditor` has several methods that help implement Operational Transformation. The `AppendOperation` method is called whenever a new operation is performed by the user (either remote or local). All operations are added to the `OTEditor.ops` slice (think of it as an array). The data is stored in `OTEditor.Data` field. When the `AppendOperation` is called the `OTEditor` performs a transformation as previously discussed to compute the new value of the index where the data has to be inserted or deleted. This transformation is performed in the `performTransformation` method.

The `AppendOperation` and `exec` methods are straightforward and we will not spend too much time on them except to note that the `exec` modifies the `OTEditor.Data` according to the operation that needs to be performed. Before modifying the data a call is made from `exec` to `performTransformation`.

```go

func (c *OTEditor) AppendOperation(op Operation, data string, index int, optype OpType) {
    operation := Op{Op: op, Data: data, Index: index, Type: optype}
    log.Printf("Existing Data: %v\n", *c)
    log.Printf("New Operation received: %v\n", operation)
    c.exec(operation)
}

func (c *OTEditor) exec(operation Op) {
    log.Printf("Executing new operation: %v, current data: %s\n", operation, c.Data)

    // Recompute indices for the operation
    c.performTransformation(&operation)

    b := []byte(c.Data)
    status := false
    switch operation.Op {
    case INSERT:
        if len(b) <= operation.Index {
            log.Printf("Cannot perform operation %v, index out of bounds.", operation)
        } else {
            b1 := b[0:operation.Index]
            b2 := []byte(operation.Data)
            b3 := b[operation.Index:]
            var b0 []byte
            finalData := append(b0, b1...)
            finalData = append(finalData, b2...)
            finalData = append(finalData, b3...)
            c.Data = string(finalData)
            status = true
        }

    case DELETE:
        if len(b) <= operation.Index {
            log.Printf("Cannot perform operation %v, index out of bounds.", operation)
        } else {

            b1 := b[0:operation.Index]
            b3 := b[operation.Index:]
            var b0 []byte
            finalData := append(b0, b1...)
            finalData = append(finalData, b3[1:]...)
            c.Data = string(finalData)
            status = true
        }
    }
    if status {
        ops := append(c.Ops, operation)
        c.Ops = ops
        log.Printf("Current value of data: %v", *c)
    }

}
```

The `performTransformation` is the heart of the application. Here we make the decision of how the indices need to be computed. The following are a set of guidelines that are used to make the decision:
1. If the current operation and last operation are of the same type (either both are `REMOTE` or both are `LOCAL`), indices need not be recomputed. This is because the data is synchronized.
2. Although the editor program may be running on two or more machines and can have concurrent operations, within the program there are no concurrent threads.
3. Deletion is performed on a _one-character-at-a-time_ basis.

```go

func (c *OTEditor) performTransformation(op *Op) {
    l := len(c.Ops)
    lastOp := c.Ops[l-1]

    // Transformation required only when synchronizing user changes.
    if lastOp.Type == LOCAL && lastOp.Type != op.Type {
        if op.Index > lastOp.Index {
            if lastOp.Op == DELETE {
                op.Index -= 1
            } else if lastOp.Op == INSERT {
                op.Index += len(lastOp.Data)
            }
        }
    }
}
```

### What's in Part 2?

In the next blog we will discuss more ways of resolving conflicts especially as dealt with in version control systems such as [Git](https://git-scm.com/docs/merge-strategies). We will discuss Two-way, [Three-way](https://doi.org/10.1145/3276535) and the generalized k-way merge. We will also look at some [new kinds](https://pijul.org/model/#why-care-about-patch-theory) of version control systems which use [Patch theory](https://doi.org/10.1016/j.entcs.2013.09.018) and [semantic merge](https://daedtech.com/merging-done-right-semantic-merge/).