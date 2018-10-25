# Rough notes from my reading of the "Cloud Types" paper

## Key takeaways from this paper

  - the paper is specifically about *programmability* of replicated, eventually consistent data structures, and providing a programming model where nothing about the fact that we're dealing with replicated data leaks through to the programmer, *except* for calls to `yield` and `flush` here and there.  So, it's important for the programmer to understand the semantics of `yield` and `flush`, but it's not important *for the programmer* to understand the stuff about revision diagrams and join conditions and so on.
  - ...but, as the reader of this paper we should understand that revision diagrams and the join condition are the underlying mechanisms that make all this work.  Unfortunately, this paper isn't really self-contained in that regard.  The description of revision diagrams in section 3.1 (and the illustrations in Figure 1) of the [ECT paper](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/msr-tr-2011-11728229.pdf) are helpful.
  - the programming model is more flexible than programming against the API that CRDTs give you, because you can have non-commutative operations.  (Why is this OK with cloud types?  I think it's because revision diagrams, and the join condition in particular, enforce rules about how replicas can sync with each other.  So there's no free lunch -- with CRDTs, you put more constraints on what operations are, but syncs can happen any which way.  With this, you put fewer constraints on operations, but more constraints on who syncs with who and when.)
  - the "eventually consistent transactions" described here aren't exactly transactions as we typically know them.  My understanding is that it means that there are periods of local computation, interspersed with *opportunities* to communicate with the server (i.e., `yield`).  The idea is that *if* you communicate with the server during the `yield`, then all the local computation you've done since your last communication will be communicated at once, atomically.  *But*, there's no guarantee that you actually *will* communicate with the server then, unless you do a `flush`.  (Is that why we lose serializability -- because the client may never communicate with the server at all?  I'm honestly not sure about this.)

## 2.1

"all" mobile devices have a grocery list app, huh?

Why isn't the `Grocery` array also declared `global`?

heh, "global variables, literally".  I see what they did there.

The "cloud array" is actually an associative array (it looks like this is more or less JavaScript), and only the value type has to be a "cloud type", apparently.

> In particular, it offers an add operation to express a relative change, reminiscent of atomic or interlocked instructions in shared-memory programming.

Sounds like those inflationary writes on CRDTs, doesn't it?

Ooh, but you can also subtract using `add`!  So updates aren't necessarily inflationary.  This is an important difference.

> Another way to describe the effect of yield is that the absence of a yield guarantees isolation and atomicity; yield statements thus partition the execution into a form of transaction (called eventually consistent transactions in [1]). Effectively, this implies that everything is always executing inside a transaction. The resulting atomicity is important for maintaining invariants; in this example, it guarantees that the total count is always equal to the sum of all the individual counts, since all changes made to Grocery and totalCount are always applied atomically.

Wait, I'm super-confused by this.  If the *absence* of a yield guarantees isolation and atomicity, but there *is* a yield here, then why do we have any atomicity guarantee?

Maybe it's that everything that happens between two yield calls happens atomically.  I would buy that, because it's only when yield runs that information can be exchanged.  It's non-blocking, though, so it's not like a fence.

Maybe the idea is that yield is the only opportunity for things to happen, but if they don't happen right then, then you have to wait for the next yield.  Yeah, I think that's it.

But since changes between two yields are "always applied atomically", this means you can't do SOME of those things when you get to a yield.  It's all or nothing.

So let's suppose you have stuff to do and you miss your chance on the current yield.  Then you accumulate more things to do.  When you get to the next yield, do the undone things from the first missed yield happen first or does it all get bundled together?  Seems like the latter.  So it seems like there's a pretty big penalty for missing a yield.  I guess that you probably want to do frequent yields.

## 2.2

Note that "join" doesn't mean "least upper bound" here.  It's not symmetric.

## 2.3

I find the p. 289 diagrams pretty confusing:

1) Shouldn't the arrow for "ToBuy(egg,2)" touch down on the server during the "yield()" that comes afterward?
2) In the conditions, how are cases A and C distinguished?  How do you know, at any given time, whether you *should* expect a response from the server or not?

Only difference between left and right diagrams is whether "Bought(egg, 6)" made it to the server or not.

BTW, I think it's a bit odd that this paper has tons of pseudocode but that there's nevertheless lots of inelegant, warty stuff, like needing to iterate over "entries".  The pseudocode is almost JavaScript, so why not just show running code?  Also, there are a lot of weird ugly things that look like mistakes, like a stray semicolon in Fig. 3.

Also, the two-column code is hella hard to read.

"Note that since there is no yield in this function, we need not worry about the order entity becoming visible to other devices before all of its information is computed." -- OK, so what *does* make it visible when it's time?

> The function DeleteCustomer is simple, but has some interesting effects. Not suprisingly, it deletes the customer entity. But beyond that, it also clears all entries in all arrays that have the deleted customer as an index, and it even deletes all orders that have the deleted customer as a construction argument.

Huh!  That's some dataflow business going on, there.

> Upon flush, execution blocks until (1) all local updates have been applied to the main revision, and (2) the result has become visible to the local revision.

That reminds me of `quiesce` from LVars.

## 3.0

This section makes the semantics more precise.

I guess there's no such thing as a "cloud array", just an array whose values or properties are of a cloud type like CInt.  And a global cloud variable is sugar for an empty array with one "value" property of a cloud type.

## 3.1

The type system and semantics looks really standard so far; the interesting stuff is all in the fork-join automaton section later on.  The `barrier` operation is mentioned in passing near the end of section 3, and it isn't mentioned anywhere else in the paper.  I think it's a mistake.

(I'm not sure what `barrier` would be.  `flush` is already the blocking version of `yield`.

## 4.0

### Figure 9

The Eval and Spawn rules are simple.

The Yield-Nop rule shows that `yield` can always run and not do anything.  It's always OK to just skip syncing.

the "R(c) = r" bit in the Yield-Push and Yield-Pull rules ensures that if we are client c, we're only communicating with servers that have the correct round number listed for us in their round map.

In Yield-Pull, the client c is pulling from the server s.  The server state forks into `sigma'_s` and `sigma''_s`.  `sigma'_s` becomes the new server state, while `sigma''_s` gets joined with the old client state to form `sigma'_c`, the new client state.

In Yield-Push, it's the opposite: the *client* state forks into `sigma'_c` and `sigma''_c`.  `sigma''_c` becomes the new client state, while `sigma'_c` gets joined with the old server state to form `sigma'_s`, the new server state.

### Figure 10

The Create rule is simple.

The Retire rule says we can retire server t as long as it hands over all its knowledge and its round number to server s before it goes.

Now for Sync-Pull and Sync-Push.

Sync-Push is like Yield-Push but for the server s communicating with another server t: s is pushing to t.  The paper says it's "more synchronous" (i.e., more blocking?).  (It looks like servers have to have all the other servers, as well as clients, tracked in their round maps.)  The rule reads exactly like Yield-Push, but with the other server (t) instead of the client (c), and with the added condition that s's round map has to end up as the max of s and t's round maps plus one in t's entry.

Likewise, Sync-Pull is like Yield-Pull, but for servers: server s is pulling from server t.  There's a similar max operation on round maps.

I think these are described as "more synchronous" than the Yield rules because there's no "nop" option -- you can't choose to not do anything.  I guess these rules fire whenever s's round map entry for t matches what t's round number is for itself (where s is the server doing the pushing or pulling and t is the server being pushed to or pulled from).

## 4.1

### Figure 11

Now for the flush operations.

It's a bit weird to see `block` explicitly as syntax in Fig. 11.  This should've been listed earlier, even if it's not surface syntax.

Oh, maybe `block` is what `barrier` was a typo for earlier?

Looks like when the client does `flush`, Flush-Push has to run first, and then the only thing that can run is Flush-Pull.

I don't really understand the Commit rule or why we need an extra round number for flushing purposes.

Flush-Push doesn't update the client's state, just the server's state -- makes sense.

Interestingly, though, Flush-Pull updates both the client's and the server's state, not just the client's.  Why?  I guess because a state fork happens on the server side, so the server's state has to be updated to what its half of the fork is.

## 5.0

Now, finally, to "cloud types".

Fork-join automata look a bit like state-based CRDTs.  But they provide both `fork` and `join` operations, rather than `merge`.

## 5.1

It's instructive to think about how CInt is different from a state-based PN-Counter CRDT.  Notice that we *don't* have to store a version vector, just a base value and an offset.  I *think* that this optimization is possible because of the way concurrent revisions work, specifically, the "join rule" mentioned on p. 296 that "joiners must be downstream from the fork that forked the joinee" -- in other words, you need to either rejoin with whoever forked you (fork-join parallelism, or nested fork-join parallelism), or you need do do one of the other legal "join rule" options shown in figure 1(a) in [the "Eventually Consistent Transactions" paper](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/msr-tr-2011-11728229.pdf).

Actually, I don't understand why the non-series-parallel example in the ECT paper follows the rule!  OK, let's think about this more: the ECT paper states the join rule (which it calls the "join condition" or "join property"), which is a rule about  this way:

> The join condition expresses that the terminal t (the “joiner”) must be reachable from the fork vertex that started the revision that contains t' (the “joinee”).

Looking at the paper a bit more, I think I had "joiner" and "joinee" backward: the "joiner" is the one that has a STRAIGHT arrow connecting it to the join vertex, and the "joinee" is the one that has a vertical-to-horizontal curved arrow connecting it to the join vertex.

Under that description, the non-series-parallel graph is OK, as it should be.  So, that's something to watch out for: "joiner" and "joinee" in these papers is backwards from my original intuition.

Anyway, all of this is to say that I think the "join rule" stuff makes it so that we don't need to save so much state to create a counter, whereas with CRDTs, everyone can (and must!) merge with everyone else, whenever.

Perhaps it's also significant (and simplifies the implementation of cloud types) that in revision diagrams there's a "main revision", while with CRDTs there's no such thing.

## 5.3

Note: "the following table" on p. 301 is confusing.  It means the table on the top of p. 302.

Recall that "schemas" are just sequences of arrays and entities.  I think the important take-away from this section is that it's easy and general to have a FJA for an array/entity.  That means that individual cloud types can be straightforwardly composed into arrays or entities, and from there, you can implement whatever you want -- as illustrated in the next section, where they build an OR-set out of entities.
