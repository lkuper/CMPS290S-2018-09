# "Hands off my code!" OR conflict resolution algorithms in collaborative work tools (Part 1 of 2)

## Introduction

The main idea I would like to discuss in this blogpost is "how do we resolve conflicts in collaborative work". Although they are interesting, I'm _not_ referring to psychological issues here. There are plenty of people better qualified than me to discuss those. I will, rather, look into collaborative work environments  such as version control systems, collaborative text editors, etc., and try to understand the conflicts that such environments have to deal with when multiple individuals are working on a text or source code and ultimately, ways of resolving these conflicts.

Anyone who has used a version control system or worked in a collaborative setting knows all too well the problems which arise when there are conflicts in a document or code people have been editing.

"But what are these conflicts?", you ask. Well it all starts very innocuously when - the protagonists of recurring CS tales - Alice and Bob decide to collaboratively work on writing a document. They decide to use a new collaborative document editing tool called Frugal Docs. Alice creates a document, shares it with Bob. Alice starts editing the document. The document at Bob's end synchronizes with Alice's copy and when Bob edits his copy of the document, Alice gets to see the changes. And both of them continue editing their documents happily ever after. "I still don't see it!", you say. Patience young Padawan. The problem comes when we encounter network partitions. You see, everything is alright as long as Alice communicates with Bob and Bob with Alice, and both are aware of changes the other has made. Until they can't. And when they can't communicate we say that there has arisen a partition in their "network". To make things even more sinister, let's say they don't know if they have been separated. Let's say they continue to work on their respective documents and then they make changes in sections that the other is currently editing. "Aah now I see  what you were going on about", I hear you say. Yes, but there's more. The problem isn't that Alice and Bob are continuing to work under this partition, it occurs when the network partition evaporates and they can again communicate with each other. Now how do we synchronize their changes into the single document? That's the name of the game! Alice and Bob will have to sit and sort out each other's changes and create a document where no conflicts remain. And here we leave Alice and Bob to continue working on their document. _Fin_.

[Network Partitions](https://en.wikipedia.org/wiki/Network_partition) are unavoidable in distributed systems. The collaborative document editing software that Alice and Bob used is just one kind of distributed application. One of the most extensive forms of collaborative work is building software.


## What's a Partition?

One way to define a “Partition” or more specifically a “Network Partition” is when communicating systems are unable to contact each other. This can be experienced most  often during a network outage. Another way to define network partition comes from the world of offline applications. Here the network is always assumed to parted until the user wishes to connect with other applications, servers or whatnots. Chances are that if you’re working online, you’ll be working on applications that allow offline work. And if they allow offline work, they must handle the case of what happens when the application which has been offline for some time comes back online. This is complicated by the fact that there may be inconsistencies in the  data when there are many collaborators and the data may not be the same for all users. The problem then begins to take shape: How do we synchronize inconsistent data across all users so that everyone’s change is assimilated into the final document?

This problem is “The Problem” in connected systems. How do we make sure that once a partition is removed (all users/applications are connected once again) all user data is in sync? Is human intervention required?  Can this synchronization of data be done automatically? If not, what is stopping us from doing this? These are the questions that the rest of this blog post deals with.

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

There are a few merge strategies which we will go over to understand how conflicts are resolved in existing software systems.

### Operational Transformation

[Operational Transformation](https://en.wikipedia.org/wiki/Operational_transformation) is a technique that was made popular by Google in its [Google Wave project](http://web.archive.org/web/20090923095705/http://www.waveprotocol.org/whitepapers/operational-transform). Much of the original papers and documentation has been removed from Google since Google Wave was discontinued but some documents are available via the [Wayback Machine.](https://web.archive.org/web/20111126052203/http://wave-protocol.googlecode.com/hg/whitepapers/operational-transform/operational-transform.html) Operational Transformation has also made into Google's other products such as [Google Drive and Google Docs](https://drive.googleblog.com/2010/09/whats-different-about-new-google-docs_22.html). Operational Transformation is an algorithm where users keep track of operations performed on shared data as a means of keeping track of changes in the data. The original paper on Operational Transformation was published by [Sun and Ellis](http://dx.doi.org/10.1145/289444.289469).

To describe operational transformation in its most basic form, let’s say we have a document which is being edited by two users *A* and *B*. Each has a local copy of the document and a common data in the document. Let’s say the data string in the document is “*ABCDEFGH*”. Let’s call this initial string `T`, where `T = “ABCDEFGH”`. Users *A* and *B* have their own copies of the text `Ta` and `Tb` respectively. *A* makes a change to `Ta` where it now reads: `Ta=“ABCMDEFGH”`. This is done by the user *A* performing an `insert` operation at index  `3` of character `"M"` on the string `Ta`. Let's call this operation `OPa1 = Ta.insert(3,'M')`. Concurrently, *B* deletes a character in his copy of the text. Keeping similar notation, the operation *B* performs is `OPb1 = Tb.delete(2)` which results in the text `Tb = “ABDEFGH”`. Now in order to synchronize copies of the text from users *A* and *B*, the users share the operations that were performed by them on the text.

But merely sharing operations performed by both users and applying those operations at their ends is not sufficient for the text to by synchronized. If *A* received `OPb1` and decided to delete index `2` at its end, the text would read `ABMDEFGH`. If *B* received `OPa1` and inserted `"M"` at `3`, the text `Tb` would read `ABDMEFGH`. Clearly, this is a problem. The solution is arrived at when both *A* and *B* take cognisance of the operations performed at their end and not just apply new operations on the results of previous operations. 

#### Implementation of Operational Transformation

A rudimentary implementation of Operational Transformation was done for the blog and is available [here](https://bitbucket.org/alfredd/collabalgos). The following is an explanation of the implementation of Operational Transformation via Test cases. First we look at the test cases.

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

_NOTE_: A word on terminology before we begin the discussion. The word 'local' is used below to denote where the above program is executing: the 'local' machine or system. The word 'remote' is used to denote a remote machine where a 'remote' user may be working and making changes to their own copy of the data.

Each test case shown above adds an operation performed either locally on the data or by another user on their own copy of the data and sent over as part of the synchronization process. At the end of each synchronization step the data must be the same data on both local and remote users' ends. Each test case moves the editing process forward via a set of operations that are performed on the data. The following operations are performed on the data:

1. Initially the data is `abcd` inserted locally and is sent over to the remote machine (not shown). The idea is that we start with a system where both local and remote users have the same data and are in a consistent state.
2. A `y` is inserted next locally and the data becomes `yabcd`. This information is then sent to the remote server as well (code not shown).
3. Concurrently the remote user adds `x` at index `2` to it's copy which is `abcd` and sends this operation to be synced with the local copy. The local data is modified to `yabxcd`.
4. At this point the remote user should also have seen the insert from step `2` and updated its copy of the data. So both user and remote data should be `yabxcd`.
5. The remote user then deletes the character at index `1` from its copy of the data which was `yabxcd`. The data becomes `ybxcd`. When this operation is received by the local system, data is updated to `ybxcd`.
6. The local user then inserts `f` at index `1` to its local copy of data which is `ybxcd`. The data is now `yfbxcd`.
7. The remote user concurrently deletes the character at index `3` of its local data which is `ybxcd`. The remote user's data becomes `ybxd`. This operation is received by the local system which deletes the character `c` from its index `4` with the data finally becoming `yfbxd`.
8. The remote system will also update its data when it receives the insert operation of character `f` at index `1` from the local system. When the operation is applied by the remote system its data will be modified from `ybxd` to `yfbxd`. Thus both local and remote users will converge to the same state.
9. It should be noted the index used in the remote operation need not always correspond to the same index in the local data. This is where Operational Transformation is used. The main idea behind Operational Transformation is, therefore, to understand in what cases transformation will have to be applied to convert indices to correct values.

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

Test 4. delete char at index 3
2018/11/12 15:15:46 Existing Data: {yfbxcd [{1 abcd 0 0} {1 y 0 0} {1 x 3 1} {2  1 1} {1 f 1 0}]}
2018/11/12 15:15:46 New Operation received: {2 '' 3 1}
2018/11/12 15:15:46 Executing new operation: {2 '' 3 1}, current data: yfbxcd
2018/11/12 15:15:46 Current value of data: {yfbxd [{1 abcd 0 0} {1 y 0 0} {1 x 3 1} {2 '' 1 1} {1 f 1 0} {2 '' 4 1}]}

```

The important thing to note here is that each modification to the data is performed as a series of operations. There are a few assumptions made in the test cases shown above which are important to point out:

1. There is no way to know if operation in #1 _happened before_ #2. It is assumed that LOCAL and REMOTE operations happen concurrently.
2. Ordering of the operations is implicit in the test cases. (Testcase #1 is processed before testcase #2.) Operations are processed in the order in which they are seen. This imposes a partial order on the set of events occurring in the system.

Now that expectations are set, we implement a simplified Operational Transformation Editor.

```go
type Operation string

const (
    INSERT Operation = "1"
    DELETE Operation = "2"
    APPEND Operation = "3"
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

func NewCollab() *OTEditor {
    collab := &OTEditor{
        Data: "",
        Ops:  make([]Op, 10), // Keeps list of operations executed on the data.
    }
    return collab
}

func (c *OTEditor) AppendOperation(op Operation, data string, index int, optype OpType) {
    operation := Op{Op: op, Data: data, Index: index, Type: optype}
    log.Printf("Existing Data: %v\n", *c)
    log.Printf("New Operation received: %v\n", operation)
    c.exec(operation)
}

func (c *OTEditor) exec(operation Op) {
    log.Printf("Executing new operation: %v, current data: %s\n", operation, c.Data)

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
    case APPEND:
        b2 := []byte(operation.Data)
        finalData := append(b, b2...)
        c.Data = string(finalData)
        status = true

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

The program above implements a simplified version of Operational Transformation. Here the `AppendOperation` method is called whenever a new operation is performed by the user (either remote or local). All operations are added to the `OTEditor.ops` slice (think of it as an array). The data is stored in `OTEditor.Data` field. When the `AppendOperation` is called the `OTEditor` performs a transformation as previously discussed to compute the new value of the index where the data has to be inserted or deleted. This transformation is performed in the `performTransformation` method.

### Two-way, Three-way and k-way merge

### Patch Theory

### Semantic Merge

## References

[1] Hagit Attiya, Sebastian Burckhardt, Alexey Gotsman, Adam Morrison, Hongseok Yang, and Marek Zawirski. 2016. Specification and Complexity of Collaborative Text Editing. In Proceedings of the 2016 ACM Symposium on Principles of Distributed Computing (PODC '16). ACM, New York, NY, USA, 259-268. DOI: https://doi.org/10.1145/2933057.2933090

[2] http://darcs.net/ , http://darcs.net/Theory/Questions

[3] Andres Loh, Wouter Swierstra, and Daan Leijen. A Principled Approach to Version Control. https://www.andres-loeh.de/fase2007.pdf

[5] Ernst Lippe and Norbert van Oosterom. 1992. Operation-based merging. In Proceedings of the fifth ACM SIGSOFT symposium on Software development environments (SDE 5). ACM, New York, NY, USA, 78-87. DOI=http://dx.doi.org/10.1145/142868.143753

[6] Marcelo Sousa, Isil Dillig, and Shuvendu K. Lahiri. 2018. Verified three-way program merge. Proc. ACM Program. Lang. 2, OOPSLA, Article 165 (October 2018), 29 pages. DOI: https://doi.org/10.1145/3276535

[7] Why care about patch theory? Pijul distributed version control system.  https://pijul.org/model/#why-care-about-patch-theory

[9] Merge strategies in Git. https://git-scm.com/docs/merge-strategies

[10] Samuel Mimram, Cinzia Di Giusto. A Categorical Theory of Patches. Electronic Notes in Theoretical Computer Science, Volume 298, 2013, Pages 283-307,ISSN 1571-0661, https://doi.org/10.1016/j.entcs.2013.09.018.

[11] https://jneem.github.io/merging/
