# Rough notes from my reading of the "Disciplined Inconsistency" paper

## Key takeaways from this paper

This paper combines a lot of different ideas: approximate computing, consistency-based SLAs, information flow.  My main takeaways:

  - since I'd read the [MixT](http://www.cs.cornell.edu/andru/papers/mixt/) paper more recently than this one, the "static consistency levels" part of the paper reminds me of how MixT applies information-flow reasoning to consistency levels.  However, it's not clear what static consistency levels are possible in this paper other than "strong" and "weak".  I don't see how you can enforce just causal consistency, for instance, using only the R and W quorum settings, which are the underlying mechanism that IPA uses.  It's also not clear to me whether this paper does anything to guard against *implicit* information flows from one piece of inconsistent data to another, although maybe this just somehow falls out of the Scala type system.  In any case, the treatment of this topic in the MixT paper seems more principled.
  - having said that, I think the really interesting part of this paper is the *dynamic* consistency levels stuff, and particularly the error tolerance bounds, which were inspired by approximate computing (which isn't surprising, considering that Luis was involved).  This really took a lot of implementation effort.  And they didn't take the shortcut here of saying "counters can be off by up to N" (which still would have required something like a reservation system); instead, they said "counters can be off by up to N *percent*", which is harder to implement because there's a constantly shifting number of reservations.
  - to me, the most interesting thing in the evaluation is that under an error tolerance bound, the *mean* error is *worse* than it is under weak consistency, but *max* error is a lot lower.  For instance, in Figure 6(b), under "error: 1%" there *is* an error more often than there is under weak consistency, but of course under weak consistency the error can be unboundedly large.  If I'm understanding this right, it almost seems like when you have a certain error tolerance, replicas are making an effort *not* to synchronize at times when their differences wouldn't matter! -- which reminds me of an old Simon Peyton Jones quip about how lazy languages have to go to a great deal of effort to figure out what they *don't* need to compute.  In any case, I wonder if things could be tuned to do anti-entropy during periods of light load, so that the mean error is no worse than it is under weak consistency *and* the max error is also less!

## Section 3

We're dealing with ADTs like Counter, Set, List, etc.

Consistency _policies_ apply to ADT _operations_ such as `read`, `size`, `contains`, `range`, etc.

I think that "Consistency(Strong)" and "Consistency(Weak)" are examples of consistency policies on ADT operations.

Consistent[Int] and Inconsistent[Int] are examples of consistency types.

How is the constraint that the ticket account can't go below 0 implemented?  Are refunds strongly consistent while purchases are more weakly consistent?

"The IPA programming model provides a set of consistency policies that can be placed on ADT instances to specify consistency properties for the lifetime of the object." -- Oh, I thought that y'all just said that policies apply to operations, not to ADT instances themselves.  This sounds a lot like the MixT approach of having consistency levels attached to different pieces of data.  (Indeed, MixT cites IPA.)  I really forgot how similar MixT was to all this!

Really curious how you go about enforcing the LatencyBound and ErrorTolerance policies.

"Static and dynamic policies can apply to an entire ADT instance or on individual methods." Aha, okay.

"enforcing type safety directly enforces consistency safety" -- is there a proof that type safety implies consistency safety?  Is there a proof of type safety?

"Forcing developers to explicitly endorse inconsistent values prevents them from accidentally using inconsistent data where they did not determine it was acceptable, essentially
inverting the behavior of current systems where inconsistent data is always treated as if it was safe to use anywhere. However, endorsing values blindly in this way is not the intended
use case; the key productivity benefit of the IPA type system comes from the other consistency types which correspond to the dynamic consistency policies in §3.3 which allow developers to handle dynamic variations in consistency, which we describe next." -- OK, so when *do* you do the endorsing?  Endorsing feels to me like Mickens' "The God Label" (https://www.usenix.org/system/files/1401_08-12_mickens.pdf) which I definitely give all my variables.

So, this idea -- the idea that you can do what you want, but you have to write "endorse" in some places -- means that you have to think about where inconsistency comes from.

"Rushed[T] is a sum (or union) type ,with one variant per consistency level available to the implementation of LatencyBound. Each variant is itself a consistency type..." -- I'm a bit confused here.  In the example, one branch is `Inconsistent(x)`, which would seem to have type `Inconsistent[T]`, but we go ahead and print `x` without having to "endorse" it first.  Why is that okay?

On to accuracy policies (ErrorTolerance(x%)).

>  However, if size is annotated with ErrorTolerance(5%), then it could return any interval that includes 101, such as [ 95 , 105 ] or [ 100 , 107 ], so the client cannot tell if the recent add was included in the size.

Wait a second -- what does the "5%" mean, then?  If it's "within 5% of the value of the linearizable answer", then is 107 okay?

## Section 4

OK.  So, the static consistency policies (Strong, etc.) are just enforced by picking the appropriate Cassandra quorum numbers for all operations done by an ADT.  So it's just a thin layer over the top of Cassandra's R and W values.  But this means that you can't specify that you want Causal consistency.  What options are there besides "Strong" (and "Weak"?) for the static policies?

The dynamic policies (LatencyBound and ErrorTolerance) are more interesting because they require an additional runtime mechanism to enforce.

> Because overall consistency is dependent on both the strength of reads and writes, it really does not make sense to specify consistency policies on individual operations in isolation. Declaring consistency policies on an entire ADT, however, allows the implementer of the ADT to ensure that all combinations of reads and writes achieve the specified consistency.

Don't you want to support both weakly and strongly consistent reads of the same ADT instance?

> the designer of each ADT must choose consistency levels for its operations which together enforce strong consistency.

I guess IPA doesn't give you any guidance in this, then?

Implementation of latency-bound types:

> If no responses are available at the time limit, it waits for the first to return.

So the latency bound isn't actually a guarantee, then.  Well, in that case you could always fake a "first response" with type Inconsistent[T] that's just some garbage, right?]

> Some designs may permit more efficient implementations: for example, in a Dynamo-style storage system we could send read requests to all replicas, then compute the most consistent result from all responses received within the latency limit.

I'm confused by this -- what is "the most consistent result"?  Isn't consistency a global property?

The monitoring thing (to predict what kind of consistency will likely be possible within a given time bound) is kinda cool.

The "escrow" error bounds technique in 4.3 was mentioned in the "comprehensive study of CRDTs" TR as a way to enforce global properties like a PN-counter never going below zero.  But using this technique to enforce error tolerance bounds is something new.

The tricky thing is that as the value changes, what a tolerance like "10%" means changes.  What if it's an integer counter and its value is 1, and there's an error tolerance of 10%?  Then, the only writes that are possible are strong writes, because any increment or decrement to one replica would cause it to be more than 10% different than other replicas.  Did they consider just having "off by at most N" tolerances, where N is, say, the value of a counter or the size of a set?

The token allocation thing seems pretty involved.  I imagine a lot of the implementation work of the paper went into that.

## Section 5

The cultural difference between PL and systems papers is interesting.  I feel like a PL paper wouldn't feel the need to provide justification for its use of Scala, whereas this paper is like, "Established companies use it!!!"

"client-side library except for a custom middleware layer" -- the "custom middleware layer" bit needs to run on every replica (to implement the reservations stuff), though.  Isn't this hard to deploy?

The main thing I'm left wondering about after reading this section and the one before it is the IFC stuff.  What was the mechanism for enforcing that?  What about implicit flows -- what prevents leaking?  (Does MixT do better than IPA here?)

## Section 6

I don't understand the difference between "uniform" and "high load" in the microbenchmark experiment.

OK, so the first microbenchmark randomly increments and reads 100 counters and measures.  The interesting result in fig. 5 is that the "latency: 50ms" spec for the "Slow replica" case still give you strong consistency 83% of the time.  What would have been a latency bound that would have resulted in an interesting number in that ballpart for the "Geodistributed" case?

This also makes me think that specs like "95% of reads should happen in under 50ms" should be possible!

The fig. 6a results for "Slow replica" and "Geodistributed" are interesting, too.  You do pretty well with 1% error.

fig. 6b: looks like mean % error is worse under "error: 1%" than it is under weak consistency, but max % error is a lot lower.  In other words, under "error: 1%" there *is* an error more often than there is under weak consistency, but the error never gets too far out of hand.  I wonder if things could be tuned to do anti-entropy during slow load times...

What does "the ticket Pool is safe even when weakly consistent" mean (comment in fig. 8/caption on fig. 9)?  What does "safe" mean?

## Section 7

Hmm, Quelea's visibility and ordering constraints sound like the visibility and arbitration relations from Burckhardt's stuff.  (Quelea = the "Declarative Programming over EC Data Stores" paper.)

Indigo = the "Putting Consistency back in EC" paper.

Inspired by Pileus, yay.

"CRDTs [...] are still only eventually (or causally) consistent" -- the "or causally" is an interesting aside here.  Causal consistency doesn't have anything to say about preventing replica divergence; you can have replicas diverging without violating causality.

"Information flow tracking systems [23, 41, 52], also use static type checking and dynamic analysis to enforce non-interference between sensitive data and untrusted channels, but, to the best of our knowledge, those techniques have not been applied to enforce consistency safety by separating weakly and strongly consistent data." I want to talk to Brandon about MixT and what he thinks is new in it.  I think the MixT people would say that what's new is support for transactions, but even aside from that, this paper doesn't say much about how it does IFC; the MixT paper seemed more...principled in that regard.
