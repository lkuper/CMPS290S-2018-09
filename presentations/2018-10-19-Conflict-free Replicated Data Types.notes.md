1-4:

* Conflict-free vs commutative vs convergent
* Commutative as the important property that leads to everything else
* Every version of these commute, every version of them converges, every version is
  conflict-free

5:

* Standard operation model
* Eventuality assumptions
* Termination assumptions

6:

* Eventual convergence is a property on _quiescence_
* Processes that have the same operations will eventually, after delivery has finished,
  have the same state
* Eventual consistency = eventual delivery + termination + eventual convergence

7:

* Strong eventual consistency: basically eventual convergence without quiescence
* Immediately upon receiving the same updates, processes have the same state
* Just focusing on this example: this requires processes that received two operations in a
  different order to _not care_ about that order

8:

* Mathematically, this means operations need to commute.
* Everything else falls out of this requirement
* You build a datatype that commutes, and it will converge and be conflict-free

9:

* Lattices (actually, semi-lattices)
* This structure is build on top of a partial order
* If you can assure that every pair of elements has a least upper bound on that partial
  order

10:

* That is, for every pair of elements (here, {x} and {z})
* There is a unique element (here, {x,z})
* Such that every element that is _both_ greater in the partial order of the originals
  (here, the elements {x,z} and {x,y,z}, i.e., the intersection of the red set and the
  blue set)
* is greater-than-or-equal-to on the partial order than the unique element specified
* Least. Upper. Bound. Every word means something :p
* This is a commutative operation on data structures.
* The least-upper-bound of any two elements is unique, no matter which order you see them
  in.

11:

* Another lattice!
* Go ahead, pick any two elements and convince yourself there's a lub

12:

* Turns out there's two different-but-equivalent ways to specify these data structures
* You can store the state, or you can store the set of operations that led to that state
* Either has differing advantages and disadvantages; they're both prone to state explosion
  issues but one can often be less prone than the other on a given domain
