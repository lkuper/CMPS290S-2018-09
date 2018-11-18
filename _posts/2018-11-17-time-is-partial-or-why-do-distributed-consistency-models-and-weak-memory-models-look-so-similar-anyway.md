---
title: "Time is Partial, or: why do distributed consistency models and weak memory models look so similar, anyway?"
author: Sohum Banerjea
layout: single
classes: wide
---

by Sohum Banerjea ⋅ edited by Aldrin Montana and Lindsey Kuper

> There's only one hard problem in computer science: recognising that cache invalidation
> errors are misnamed. They're just off-by-one errors in the time domain.

> -- Unknown

Time is weird.

Time is weird, because we really, really want to pretend it's totally ordered. Everything
at 3pm happens (we'd like to say) before everything at 4pm, no exceptions, arguments, or
compromises.

But there are so many cases in computer science where we have to loosen this
requirement. This shows up in processors, in compilers, in nodes on the network—again and
again in computing, at various levels of the stack, we find ourselves in situations where
we look at two events and don't know what order they happened in. Time is no longer total;
it's a partial order.

Why? The reason we don't _know_ is because the abstraction layer below us doesn't
_say_. Whether deliberately or not, our computing abstractions often refuse to give us
guarantees about order. The freedom to reorder events often enables much higher
performance, or availability.

A processor may have a _[memory-ordering](https://www.cl.cam.ac.uk/~pes20/weakmemory/)
[model](https://preshing.com/20120930/weak-vs-strong-memory-models/)_; this captures what
guarantees your CPU doesn't want to give you, when executing assembly, as to which
instruction happened before which other instruction. It uses this freedom to pipeline
instructions and execute them out of order, so it can use its silicon more efficiently
than I would know how to.

A language may have a _memory consistency model_ ("memory model" for short); this captures
what guarantees that language doesn't want to give you, while _generating_ assembly, as to
ordering instructions across multiple threads. The reorderings inherent in the hardware
memory model are a large part of why the compiler provides this weak notion of time. This
language-level memory model is what you code to when writing lock-free systems code.

A prominent example of a language-level memory model is [the C++11 weak and strong memory
models](https://en.cppreference.com/w/cpp/atomic/memory_order). By default, C++ provides
atomic operations with synchronisation; but provides the ability to weaken memory accesses
for higher performance. The behaviour it provides is intended to be an abstraction over
the major processor architectures today (x86, POWER, and ARM).

Finally, a distributed system may have a _consistency model_; this captures what
guarantees your system doesn't want to give you as to the ordering of events across
clients and replicas in a wide-area network. The reorderings inherent in communication
lags and the presence or absence of synchronisation are a large part of why a distributed
system is forced to provide you this weak notion of time. This consistency model is what
you code to when writing a distributed application.

In practice, there's a vast [zoo](http://www.vukolic.com/consistency-survey.pdf) of
consistency models you could be using when writing a distributed system. In all these
cases, these models describe the (desired) observable behaviour of the system, from
outside the system. If I, a single client, or a single thread, write to a value, then
immediately read from it, am I guaranteed to see a write at least as new as mine? If time
weren't partial, if we always had a clear idea about the ordering of operations in our
systems, the answer to this question would be yes, of course. It'd be weird to even _ask_.

But time _is_ partial, and so we have to ask.

## Consistency Models -- I Mean, Memory Models

Reasoning about this partial ordering is often difficult and always annoying. At all
layers of the stack, we've always wanted to pretend time is total—whether it's ACID or
atomic operations/locks, coding to stronger guarantees is, well, easier!

But we all need speed. Whether we're talking about distributed systems that sacrifice
strong consistency to gain availability, or lock-free programming under weak memory to
avoid the synchronisation penalty, programmers at every layer of the stack have found it
useful to do this difficult reasoning.

Shared-memory consistency models and distributed-memory consistency models are both
_abstract_ models: they describe the _interface_ of the system to the programmer using
it. They describe what sorts of weaker behaviours we _can_ rely on from time, now that the
default total ordering properties we tend to assume no longer apply. It would seem that
the two kinds of memory models are analogous, and yet, each community has developed its
own language for discussing them, with different-but-overlapping meanings.

You can see how this would get confusing.  What can we do about it?

## Describing Time With Anywhere Between Two And Eight Partial Orders

In [his 2014
book(https://www.microsoft.com/en-us/research/publication/principles-of-eventual-consistency/),
Sebastian Burckhardt attempts to comprehensively characterise the behaviour of the many
kinds of consistency models.  The framework they develop describes, among other
mathematical structures, two logical orderings of events, “visibility" and
“arbitration"—which also appeared previously in Burckhardt and his co-authors' [2014 POPL
paper on specifying and verifying replicated data
types](https://www.microsoft.com/en-us/research/publication/replicated-data-types-specification-verification-optimality/).

“Visibility" is a partial order of potential causality; it tracks what events (possibly on
other replicas) are visible to what other events. It isn't constrained, beyond needing to
be acyclic; events on one object can be visible to events on another object, and whether
the event is a read or write doesn't determine whether it's visible to other events or
not.

“Arbitration" is a total order that tracks how the distributed system, when asked to make
a choice, will adjudicate which event happened before which other event.

Since distributed consistency models are analogous to memory models, it turns out these
notions of visibility and arbitration are also useful for discussing and reasoning about
memory models. In particular, in appendix D.4 of [their POPL '14
paper](https://www.microsoft.com/en-us/research/publication/replicated-data-types-specification-verification-optimality/),
Burckhardt et al. show how the C++11 weak memory model is "very close" to per-object
causal consistency, with some interesting deviations.  This is what we'll be diving into
for the rest of this post.

The first step is to specialise visibility and arbitration into "reads-from" and
"modification order". "Reads-from" no longer tracks visibility between anything but writes
to reads on the same object, and only ever allows a read to have visibility of exactly
zero or one writes.

This corresponds to the fact that there only ever a single actual memory cell being
written to in a shared memory processor, for any given object, even if threads may access
it at different points in causality. In a distributed system, a logical object can be
written to at many separate replicas.

"Modification order" takes the same step in specialising arbitration, by being per-object
and only ordering writes. This is, again, a specialisation borne from the fact that the
weak memory specification only makes strong guarantees per-object.

The next step is to consider the consistency axioms that Burckhardt et al. define, and see
how they apply to the weak memory model. They define these axioms in the context of
distributed systems first, so they need specialisation for the shared memory case. Note
that even though they're named "axioms", they are properties that different consistency
models may or may not provide—the paper focuses on the properties that define cross-object
causal consistency.

### EVENTUAL

For any particular event, there cannot be infinitely many events that do not have
visibility of it. That is, every event is _eventually_ visible to "the system".

This needs to be somewhat more complicated to make sense under weak memory: you have to
state that any particular _write_ cannot have infinitely many reads that don't read from
it or read from an earlier write (by modification order).

The C++11 specification does not guarantee this axiom, though practically it's difficult
to find a counterexample.

### THINAIR

When you trace "potential causality" across thread/client operations and
visibility/reads-from, you cannot go back in time. This is defined by requiring the
closure of thread orderings with reads-from to be acyclic. We can typically rely on this
property holding in distributed systems, but it would prohibit certain kinds of
speculative execution from being visible to the user in weak memory systems.

Burckhardt et al. point out that the
C++11 specification "does not validate" this axiom, and it's unclear whether the resulting
"satisfaction cycles" [are observable in
practice](https://dl.acm.org/citation.cfm?id=2429099).

### Causality Axioms

To pin down what causality actually refers to under weak memory, we need to precisely
define what events can impact the results from what other events. This starts by staring
at our standard causality axioms: the [session
guarantees](https://dl.acm.org/citation.cfm?id=645792.668302). These are four related
properties that capture coherence properties of reads and writes across different threads,
and we need to specialise them to the per-object case (see [Figure 23 of Burckhardt et
al.](https://www.microsoft.com/en-us/research/publication/replicated-data-types-specification-verification-optimality/)).

* RYW (Read Your Writes): A read that follows a write, to the same cell, within the same
  thread/replica/session, must read data that is at least as new as the write. The
  distributed systems version of this property is specified entirely in terms of
  visibility, whereas the weak memory version has to appeal to both reads-from and
  modification order.
* MR (Monotonic Reads): Subsequent reads (within the same thread, to the same cell) must
  continue to see data that is at least as new.
* WFR (Writes Follow Reads): If a write follows a read within a thread, to the same cell,
  then it has to be later in modification order than the write that read read-from.
* MW (Monotonic Writes): Later writes (within a thread, to the same cell) have to be later
  in modification order.

The original versions of WFR and MW have two variants, for arbitration and visibility; but
this only matters for more complex data cells than integer registers.

These properties capture common-sense notions of causality; it's what they leave out
that's interesting. In particular, under the weak memory analysis, these definitions of
causality are scoped to be within a thread/replica/session and a particular cell/object
being written to; [the Burckhardt et
al. paper](https://www.microsoft.com/en-us/research/publication/replicated-data-types-specification-verification-optimality/)
calls them "per-object causal visibility" and "per-object causal arbitration", again in
Figure 23.  They do not at all restrict the behaviour of the system when separate threads are writing
to separate cells.

The cross-object causality axioms then capture the impact of causal influence across
different objects/memory cells.

* COCV (Cross-Object Causal Visibility): This is RYW, without the restriction that the
  final read has to be in the same thread/replica/session. Reads from an object that are
  causally later than a write to that object, via visibility/reads-from or thread order,
  must read data that is at least as new as the write.

The C++11 specification captures these properties. Note that they have been defined such
that the restriction of visibility to reads-from and arbitration to modification order
don't affect their definitions much.

That is not true for the last property.

* COCA (Cross-Object Causal Arbitration): This is Monotonic Writes, but across different
  threads, in the same way as COCV is RYW across different threads. However, since
  modification order only orders writes per object, the weak memory version allows the
  system to inconsistently order writes to different objects across reads-from and
  within-thread order.

Concretely, COCA being a much weaker property under weak memory is why this classic weak
memory case can return `{x := 0, y := 0}`.

> Thread A: y := 0; x := 1; return x
> Thread B: x := 0; y := 1; return y

The thread order within each thread is allowed to be inconsistent with the per-object
ordering and modification order. Note that by RYW, it cannot be the case that `x := 0 →x
:= 1` in modification order, and similarity for `y`, and so modification order must
contain `x := 1 → x := 0` and `y := 1 → y := 0`. Thus, modification order clearly forms a
cycle with thread order.

This cycle is allowed by weak-memory COCA. It's not that thread order/reads-from
contradict modification order; each thread sees a coherent history of writes. It's just
that those histories only agree with other threads' histories when you scope them
per-object.

## What Does This All Mean?

Time is partial.

Even though time naturally feels like a total order, studying distributed systems or weak
memory exposes you, head on, to how it isn't. And that's precisely _because_ these are
both cases where our standard over-approximation of time being total limits
performance—which we obviously can't have.

Then, after we accept that time is partial, there are many small but important
distinctions between the various ways it can be partial. Even these two fields, which
_look_ so much alike at first glance, have careful, subtle differences in what kinds of
events they treat as impacting each other. We needed to dig into the technical definitions
of various properties, _after_ someone else has already done the work of translating one
field into another's language already.

Time is partial. Maybe it's time we got used to it.
