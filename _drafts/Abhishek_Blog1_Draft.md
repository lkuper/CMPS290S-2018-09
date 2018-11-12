# Title: [Placeholder]

## Introduction

The main idea I would like to discuss in this blogpost is "how do we manage conflicts in collaborative work". We will look into collaborative work environments  such as version control systems, collaborative text editors, etc., and try to understand the issues that such environments have to deal with and ultimately, ways of resolving conflicts.

Anyone who has used a version control system and worked in a collaborative setting knows all too well the problems which arise when there are conflicts in a document or code people have been editing.

"But what are these conflicts?", you ask. Well it all starts very innocuously when - the protagonists of recurring CS tales - Alice and Bob decide to collaboratively work on writing a document. They decide to use a new collaborative document editing tool called Frugal Docs. Alice creates a document, shares it with Bob. Alice starts editing the document. The document at Bob's end synchronizes with Alice's copy and when Bob edits his copy of the document, Alice gets to see the changes. And both of them continue editing their documents happily ever after. "I still don't see it!", you say. Patience young Padawan. The problem comes when we encounter network partitions. You see, everything is alright as long as Alice communicates with Bob and Bob with Alice, and both are aware of changes the other has made. Until they can't. And when they can't communicate we say that there has arisen a partition in their "network". To make things even more sinister, let's say they don't know if they have been separated. Let's say they continue to work on their respective documents and then they make changes in sections that the other is currently editing. "Aah now I see  what you were going on about", I hear you say. Yes, but there's more. The problem isn't that Alice and Bob are continuing to work under this partition, it occurs when the network partition evaporates and they can again communicate with each other. Now how do we synchronize their changes into the single document? That's the name of the game! Alice and Bob will have to sit and sort out each other's changes and create a document where no conflicts remain. And here we leave Alice and Bob to continue working on their document. _Fin_.

Partitions[12] are unavoidable in distributed systems. The collaborative document editing software that Alice and Bob used is just one kind of distributed application. One of the most extensive forms of collaborative work is building software.


## What's a Partition?

One way to define a “Partition” or more specifically a “Network Partition” is when communicating systems are unable to contact each other. This can be experienced most  often during a network outage. Another way to define network partition comes from the world of offline applications. Here the network is always assumed to parted until the user wishes to connect with other applications, servers or whatnots. Chances are that if you’re working online, you’ll be working on applications that allow offline work. And if they allow offline work, they must handle the case of what happens when the application which has been offline for some time comes back online. This is complicated by the fact that there may be inconsistencies in the  data when there are many collaborators and the data may not be the same for all users. The problem then begins to take shape: How do we synchronize inconsistent data across all users so that everyone’s change is assimilated into the final document?

This problem is “The Problem” in connected systems. How do we make sure that once a partition is removed (all users/applications are connected once again) all user data is in sync? Is human intervention required?  Can this synchronization of data be done automatically? If not, what is stopping us from doing this? These are the questions that the rest of this blog post deals with.

## Examples of collaborative document editing

Some examples of collaborative software which most of the readers of this blog may have used are[13]:

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

Operational Transformation [4,5,8] is a technique that was made popular by Google in its Google Wave project [15,16]. Operational Transformation is an algorithm where users keep track of operations performed on shared data as a means of keeping track of changes in the data.

To describe operational transformation in its most basic form, let’s say we have a document which is being edited by two users *A* and *B*. Each has a local copy of the document and a common data in the document. Let’s say the data string in the document is “*ABCDEFGH*”. Let’s call this initial string `T`, where `T = “ABCDEFGH”`. Users *A* and *B* have their own copies of the text `Ta` and `Tb` respectively. *A* makes a change to `Ta` where it now reads: `Ta=“ABCMDEFGH”`. This is done by the user *A* performing an `insert` operation at index  `3` of character `"M"` on the string `Ta`. Let's call this operation `OPa1 = Ta.insert(3,'M')`. Concurrently, *B* deletes a character in his copy of the text. Keeping similar notation, the operation *B* performs is `OPb1 = Tb.delete(2)` which results in the text `Tb = “ABDEFGH”`. Now in order to synchronize copies of the text from users *A* and *B*, the users share the operations that were performed by them on the text.

But merely sharing operations performed by both users and applying those operations at their ends is not sufficient for the text to by synchronized. If *A* received `OPb1` and decided to delete index `2` at its end, the text would read `ABMDEFGH`. If *B* received `OPa1` and inserted `"M"` at `3`, the text `Tb` would read `ABDMEFGH`. Clearly, this is a problem. The solution is arrived at when both *A* and *B* take cognisance of the operations performed at their end and not just apply new operations on the results of previous operations. 



### Two-way, Three-way and k-way merge


## References

[1] Hagit Attiya, Sebastian Burckhardt, Alexey Gotsman, Adam Morrison, Hongseok Yang, and Marek Zawirski. 2016. Specification and Complexity of Collaborative Text Editing. In Proceedings of the 2016 ACM Symposium on Principles of Distributed Computing (PODC '16). ACM, New York, NY, USA, 259-268. DOI: https://doi.org/10.1145/2933057.2933090

[2] http://darcs.net/ , http://darcs.net/Theory/Questions

[3] Andres Loh, Wouter Swierstra, and Daan Leijen. A Principled Approach to Version Control. https://www.andres-loeh.de/fase2007.pdf

[4] Chengzheng Sun and Clarence Ellis. 1998. Operational transformation in real-time group editors: issues, algorithms, and achievements. In Proceedings of the 1998 ACM conference on Computer supported cooperative work (CSCW '98). ACM, New York, NY, USA, 59-68. DOI=http://dx.doi.org/10.1145/289444.289469

[5] Ernst Lippe and Norbert van Oosterom. 1992. Operation-based merging. In Proceedings of the fifth ACM SIGSOFT symposium on Software development environments (SDE 5). ACM, New York, NY, USA, 78-87. DOI=http://dx.doi.org/10.1145/142868.143753

[6] Marcelo Sousa, Isil Dillig, and Shuvendu K. Lahiri. 2018. Verified three-way program merge. Proc. ACM Program. Lang. 2, OOPSLA, Article 165 (October 2018), 29 pages. DOI: https://doi.org/10.1145/3276535

[7] Why care about patch theory? Pijul distributed version control system.  https://pijul.org/model/#why-care-about-patch-theory

[8] Operational Transformation. Wikipedia.org. https://en.wikipedia.org/wiki/Operational_transformation

[9] Merge strategies in Git. https://git-scm.com/docs/merge-strategies

[10] Samuel Mimram, Cinzia Di Giusto. A Categorical Theory of Patches. Electronic Notes in Theoretical Computer Science, Volume 298, 2013, Pages 283-307,ISSN 1571-0661, https://doi.org/10.1016/j.entcs.2013.09.018.

[11] https://jneem.github.io/merging/

[12] Network Partition. Wikipedia. https://en.wikipedia.org/wiki/Network_partition

[13] https://en.wikipedia.org/wiki/Collaborative_software 

[14] Conflict resolution in Google Docs. https://drive.googleblog.com/2010/09/whats-different-about-new-google-docs_22.html 

[15] http://web.archive.org/web/20090923095705/http://www.waveprotocol.org/whitepapers/operational-transform

[16] https://web.archive.org/web/20111126052203/http://wave-protocol.googlecode.com/hg/whitepapers/operational-transform/operational-transform.html



