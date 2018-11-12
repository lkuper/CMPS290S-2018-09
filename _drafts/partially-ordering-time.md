# Time Is Weird
## or: why do distributed systems and weak memory models look so similar, anyway

(_Epistemic status: I'm just learning about both of these fields, and these are simply my
observations from studying them and comparing them. If you work in either field and
something looks wrong, it probably is; let me know!_)

    There's only one hard problem in computer science: recognising that cache invalidation errors
    are misnamed. They're just off-by-one errors in the time domain.
        —Unknown

Time is weird.

Time is weird, not just because we insist on trying to [measure it](#url) and [standardise
it](#url), though that field is of course amazingly horrifying. Time is weird, because
when we try to think about what it actually _implies_, that a second has passed since one
second ago.

The best we've been able to come up with about the arrow of time is that it in some way
tracks things that “happened” _before_ other things that “happened” _after_ them, in the
sense, that, uh, the later events have access to information? and entropy? from the
earlier events? Which means, um, something something flow of causality?

Of course that breaks down, at distances comparable to light speed. When you can no longer
assume that events are instantaneously knowable, time behaves _seriously_ anomalously. Can
an alien reading about memory models outside our light cone meaningfully have done so
_before_ you did?

But we ignore that, and hope that in the vast majority of cases we can just assume time
just works how we kinda normally want it to work. There's no reason to make life so much
more complicated for ourselves, right?

…if there's one thing I've understood about computer folk, it's that we _never_ pass up a
chance to make life more complicated for ourselves.

### Time, But Only Sometimes

Time is weird.

Time is weird because there are so many cases where (processors / compilers / “the
network”, pick all) look at two events that “happened” in one order and decide, nah, those
don't need to “happen” in that order.

Your hardware will have a memory ordering model; this captures what license your CPU takes
when executing assembly as to which instructions happen before which other ones. (Or is
supposed to, anyway; in practice many hardware memory models are
[underspecified](#urls[1-2]).)

Your compiler will have a memory model; this captures how your language chooses to expose
the hardware memory model to you, as well as what license your compiler takes in
reordering instructions _while generating assembly_ across multiple threads. This is what
you code to when writing lock-free systems code.

In practice, there's a single weak memory model that matters to most people—the C++11
memory model, as developed to be an abstraction over all of x86, POWER, and ARM.

And your distributed system will have a consistency model; this captures how your system
chooses to expose the synchronisation or lack thereof in the system to you, as well as
what “license” your network “takes” in reordering events across clients in a wide-area
network. This is what you code to when writing a distributed application.

In practice, there's a vast [consistency zoo](#url) of consistency models you could be
using when writing a distributed system. Good. Good. Good!

In all these cases, these models describe the (desired) observable behaviour of the
system, from outside the system. If I, a single client, or a single thread, write to a
value, and then immediately read from it, am I guaranteed to see a write at least as new
as mine? If time wasn't weird, if we didn't constantly take license to reorder operations
in all of these systems, the answer would be yes, of course.

But time is weird, and so we have to ask.

### Consistency Models—I Mean, Memory Models

Both these worlds started out by trying to ignore time being this weird for as long as
they could—distributed programmers tried to hue to ACID properties as long as possible,
and systems programmers relied on mutual exclusion / locks for a long time.

But we all need speed. Whether it's the CAP theorem and weakly/eventually consistent
models [#url], or lockfree programming with weak/relaxed memory models, both worlds ended
up relaxing this strong view of time in order to gain speed.

Weak memory models and consistency models are both _abstract_ models: they describe the
_interface_ of the system to the programmer using it. They describe what sorts of
behaviours we _can_ rely on from time, now that the default properties we tend to assume
no longer apply.

Both worlds have developed their own language for describing these models. For instance:
the phrase “data race” in systems programming refers to any pair of accesses to a memory
location that include at least one write, without a synchronisation barrier between
them. This concept doesn't have a specific phrasing in distributed programming, because
that field assumes that reads and writes participate in data races (“are concurrent”) by
default.

Thus, “data-race freedom” is a stronger condition than the distributed systems term
“sequential consistency” (“any concurrent accesses can be treated _as if_ they were
synchronised”), but if you can prove that a program on your processor is data-race free,
you can _provide_ sequential consistency to that program as your hardware or software
memory model (“SQ-DRF”, “sequential consistency for data-race free programs” [6]).

…You can see how this could get confusing.

The obvious solution is, of course, to make things more confusing!

### The Burckhardt Paper

The Burckhardt Paper. The _Burckhardt paper_.

Dr. Sebastian Burckhardt has [been trying](#urls) to formalise the specification of
consistency models for some time, in the distributed systems world. In [7], Appendix D.4,
their team lays out an analysis of the C++ weak memory model in a slight specialisation of their framework.

This gives us a convenient way to discuss the similarities and differences between the two
fields. In particular, the C++ memory model _approximates_ to per-object causal
consistency, with a few interesting differences.

We'll study them axiom by axiom, but it's first important to note that where causal
consistency is defined in (Burckhardt's) terms of a “visibility” and an “arbitration”
orderings, they define weak memory axioms in terms of a “reads-from” and “modification
order” instead, correspondingly.

“Visibility” in the distributed systems model is a partial order of potential causality;
it tracks what events (on possibly other replicas) are visible to what other events. It
can contain read→read, read→write, write→read, and write→write edges, across multiple
objects. “Reads-from” is much more specialised; it only ever contains write→read edges on
the same object, and only ever contains one edge for a given read event.

This corresponds to the fact that there only is a single actual memory cell being written
to in a shared memory processor, for any given object, even if threads may access it at
different points in causality. In a distributed system, a logical object can be written to
at many separate locations (“replicas”).

“Arbitration” is a total order that tracks how the distributed system, when asked to make
a choice, will adjudicate which event happened before which other event. It's distinct
from “modification order” in that the latter is, again, per-object, and only adjudicates
writes.

This is, again, a specialisation borne from the fact that the weak memory specification
only makes strong guarantees per-object.

Okay. With these under our belt, we can discuss each individual property and how it
differs between distributed systems' per-object causal consistency and the C++11 weak
memory model.

#### EVENTUAL

For any particular event, there cannot be infinitely many events that do not have
visibility of it. To make sense under weak memory, this is slightly more complicated: you
have to state that for any particular _write_, there cannot be infinitely many reads that
don't read from it or read from an earlier write (by modification order).

The C++11 specification does not guarantee this axiom, though practically it's difficult
to find a counterexample.

#### THINAIR

When you trace “potential causality” across thread/client operations and
visibility/reads-from, you cannot go back in time. This is just a sanity axiom in
distributed systems, but it does prohibit certain kinds of speculative execution from
being visible to the user in weak memory systems.

The C++11 specification does not guarantee this axiom, and it is violated on commodity
hardware consistently.

#### Causality Axioms

To track our notion of causality and time, we need to pin down what events can impact the
results from what other events. To start, we define per-object causality axioms: the
session guarantees. These are four related properties that capture coherence
properties of reads and writes across different threads.

* RYW (Read Your Writes): A read that follows a write, to the same cell, within the same
  thread/replica/session, must read data that is at least as new as the write. The
  distributed systems version of this property is specified entirely in terms of
  visibility, whereas the weak memory version has to appeal to both reads-from and
  modification order.
* MR (Monotonic Reads): Subsequent reads (within the same thread, to the same cell) must
  continue to see data that is at least as new.
* WFR (Writes Follow Reads): If a write follows a read within a thread, to the same
  cell, then it has to be later in arbitration order (and visibility) than the write
  that read read-from.
* MW (Monotonic Writes): Later writes (within a thread, to the same cell) have to be later
  in arbitration (and visibility) order.

WFR and MW have two variants, for arbitration and visibility; but this only matters for
more complex data cells than integer registers.

These properties capture common-sense notions of causality; it's what they leave
out that's interesting. In particular, these definitions of causality are scoped to be
within a thread/replica/session and a particular cell/object being written to; they are
summarised in the Burckhardt paper as “per-object causal visibility” and “per-object
causal arbitration”.

They do not at all restrict the behaviour of the system when separate threads are writing
to separate cells.

The cross-object causality axioms capture the impact of causal influence across different
objects/memory cells.

* COCV (Cross Object Causal Visibility): This is RYW, without the restriction that the
  final read has to be in the same thread/replica/session. Reads from an object that are
  causally later than a write to that object, via visibility/reads-from or events that are
  ordered by happening in the same thread, must read data that is at least as new as the
  write.

The C++11 specification captures these previous properties. Note that they have been
defined such that the restriction of visibility to reads-from and arbitration to
modification order don't effect their definitions much.

This is not true for the last property.

* COCA (Cross Object Causal Arbitration): This is Monotonic Writes but across different
  threads/replicas/sessions, in the same way. However, since modification order only
  orders writes per object, the weak memory version allows the system to inconsistently
  order writes to different objects to reads-from and within-thread order.

Concretely, this amounts to an analysis of why this classic weak memory testcase can
return `{x := 0, y := 0}`.

    Initial State {x := 0, y := 0}
    Thread A: x := 1; return y
    Thread B: y := 1; return x

### What Does This All Mean?

Time is weird.

Time is weird because time is ultimately our way of trying to keep track of what events
had an influence on other events. And that turns out to be a surprisingly complicated
concept!

Studying distributed systems or weak memory exposes you to this complexity head on,
precisely _because_ these are both cases where the standard overapproximating answer of
“everything that happened before it” are limiting performance. Which we obviously can't
have.

Even these two fields, which _look_ so much alike at first glance, have careful, subtle
differences in what kinds of events they treat as impacting each other. We needed to dig
into the technical definitions of various properties, _after_ someone else has already
done the work of translating one field into another's language already.

Time is weird. Maybe it's time we got used to it.


[1] https://www.cl.cam.ac.uk/~pes20/weakmemory/
[2] https://preshing.com/20120930/weak-vs-strong-memory-models/
[3] https://arxiv.org/abs/1707.05923
[4] https://arxiv.org/abs/1805.07886
[5] http://www0.cs.ucl.ac.uk/staff/j.alglave/papers/aplas11.pdf
[6] http://www.hboehm.info/c++mm/sc_proof.html
[7] https://www.microsoft.com/en-us/research/publication/replicated-data-types-specification-verification-optimality/

[?] http://www.podc.org/dijkstra/2003.html or maybe the 1991 paper directly?
