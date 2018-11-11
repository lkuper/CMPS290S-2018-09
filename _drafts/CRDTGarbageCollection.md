# Implementing a Garbage Collected Graph CRDT (part 1 of 2)

Author: Austen Barker
Editors: Natasha Mittal and Linsey Kuper 

## Introduction

Conflict Free Replicated Data Types (CRDTs) are a class of specialized data structures designed to be replicated across a distributed system while providing eventual consistency and high availability. These can be modified concurrently without coordination while providing a means to reconcile conflicts between replicas. While CRDTs are a promising solution to the problem of building an eventually consistent distributed system, numerous practical implementation challenges remain. To deal with issues such as conflicting additions and removals that arise when processing concurrent operations, many CRDT specifications rely on simply marking items deleted with the use of something called a tombstone. These tombstones can accumulate over time and necessitate the use of a garbage collection system in order to avoid unacceptably costly growth of underlying data structures. These garbage collection systems can prove to be difficult to implement in practice. This blog post chronicles my brief research, reasoning about, and attempts to implement a CRDT with garbage collection from the specifications provided in [Shapiro et al.'s _A Comprehensive Study of Convergent and Commutative Replicated Data Types_ ](https://hal.inria.fr/inria-00555588/document).

## Background

As presented by Shapiro et al. CRDTs come in two major varieties, state based (CvRDTs) and operation based (CmRDTs). The difference comes from how the replicas propagate updates to one another. In the state based model the entire local state is transmitted to other replicas which then reconcile inconsistencies through a commutative, associative, and idempotent operation. As seen later in this blog post a merge operation between two states can often be represent by a union between two sets. Operation based CRDTs transmit their state by sending only the update operations performed to other replicas. So each operation is individually replayed on the recipient replica. In this model the operations must be commutative but not necessarily idempotent. CmRDTs are more particular about the messaging protocol between replicas but offer a lower bandwidth overhead than a CvRDT which must transmit the entire local state instead of small operations. CvRDTs on the other hand provides an associative merge operation.

The paper presents a multitude of different CRDT examples along with formal specifications and operation semantics for each. Among these are basic constructs for sets, counters, registers, and graphs. This blog post is primarily concerned with the implementation of sets and graphs. The two simplest sets specified are the Growth Only Set (G-Set) and the badly named Two Phase Set (2P-Set). The G-Set is simply a set of elements that is monotonically increasing with no removal operation. In the case of a state based 2P-Set conflicts between add and remove operations during a merge necessitates some record of which elements have been removed from the set. In order to add the ability to remove elements we must add an additional G-Set that maintains markers or tombstones denoting removed elements. 2P-Sets and G-Sets can then be used to construct sets of vertices and edges in a directed graph. The Montonic Directed Acyclic Graph (Monotonic DAG) is simply two G-Sets, one for the vertices and one for the edges. In this data structure there is no operation for removing vertices and its contents are monotonically increasing.

Shapiro et al. introduce Add-Remove Partial Order (ARPO) graph CRDT as a solution to the mess that arises when one attempts to include vertex removals in their Operation based Monotonic DAG specification. They define the ARPO as a combination of two other CRDTs: a 2P-Set to represent vertices and a G-Set to represent edges. An example of a situation in which garbage collection is useful is when an update to an Add-Remove Partial Order is applied and considered stable. At that point, one can discard the set of removed vertices.

For any CRDT that maintains tombstones, such as the state-based 2P-Set and the ARPO, the tombstones could potentially pile up and cause unnecessary bloat. The difficulty with adding garbage collection is that it will often require some degree of synchronisation. The paper presents two challenges related to garbage collection, _stability_ and _commitment_.

The purpose of tombstones is to help resolve conflicts between concurrent operations by having a record of removed elements. Eventually a tombstone is no longer required when all concurrent updates have been "delivered" and an update can be considered stable.  The paper applies a modified form of [Wuu and Bernstein's stability algorithm](http://dx.doi.org/10.1145/800222.806750), which requires each replica to maintain a set of all the other replicas and for there to be some mechanism to detect when a replica crashes. The algorithm uses vector clocks to determine concurrency of updates.

Commitment issues arise when one needs to perform an operation with a need for greater synchronization, such as removing tombstones from a 2P-Set or resetting all the replica payloads. Shapiro et al's conclusion is to require some atomic agreement between all replicas concerning the application of the desired operation.

CRDTs may seem simple on paper, but any real implementation has to account for message (un)reliability, replica failure, performance, and memory usage.

## Implementation Language Considerations

Initially I decided to attempt an implementation of the ARPO design in Python to reduce development time. I realized that in Python any garbage collection thread running would impact performance by competing with the normal CRDT operations on a single CPU core, which could interfere with the results when comparing ARPOs with and without garbage collection. Therefore I re-implemented the system in Go so I could easily run garbage collection on its own thread and core, and would not compete with the actual CRDT for CPU resources.

## ARPO Building Blocks

In order to implement the ARPO specification (or any of the graphs) it became necessary to first implement both 2P-Sets and G-Sets as state based CRDTs rather easily from specifications 11 and 12. A G-Set was implemented as a simple key/value mapping with a merge operation being a union between the two maps. The G-Set had only trivial operation rules and only required basic single set operations such as add and union. The 2P-Set implementation is then built with two G-Sets. One for added elements and one for removed elements. I used maps of key-value pairs to represent sets. Where the key is of type interface and the value is another 'interface'. The interface construct in is an easy way to achieve polymorphism and allows the implementation to use practically anything as a key or value. The drawback is that it is up to the programmer to make sure data from the interface is processed properly. 
```go
//map interfaces (key) to interfaces (value) in our set
type baseSet map[interface{}]interface{}

//all our G-Set has to contain is a single set that grows monotonically
type Gset struct {
        BaseSet baseSet
}

func NewGset() *Gset {
        return &Gset{BaseSet: baseSet{}}
}

func (g *Gset) Add(element, contents interface{}){
        g.BaseSet[element] = contents
}

func (g *Gset) Fetch(element interface{}) interface{}{
        contents := g.BaseSet[element]
        return contents
}

//Checks if a given element exists
func (g *Gset) Query(element interface{}) bool{
        _, isThere := g.BaseSet[element]
        return isThere
}

//Lists the contents of a Gset
func (g *Gset) List()  ([]interface{}){
        elements := make([]interface{}, 0, len(g.BaseSet))
        for element := range g.BaseSet{
                elements = append(elements, element)
        }
        return elements
}

//merge two sets (perform a union)
func Merge(s, t *Gset) (*Gset){
        newGset := NewGset()
        for k, v := range s.BaseSet{
                newG-Set.BaseSet[k] = v
        }
        for k, v := range t.BaseSet{
                newG-Set.BaseSet[k] = v
        }
        return newGset
}
```
One interesting thing to note is that most of the implementation of the G-Set is the same regardless of whether it is a state or operation based CRDT. The only thing that I added to the implementation was an *ApplyOps* function that will apply a list of operations in order to the G-Set (although these are only add's). The same was not true with the 2P-Set, where the biggest difference existed when removing elements. As concurrent add and remove operations are commutative the tombstone set is really only necessary when implementing a state based 2P-Set with the trade off being a few additional checks. We can also re-use the function from the G-Set implementation to handle applying operations to another 2P-Set, as the op-based 2P-Set is simply a G-Set with a removal function. 

A naive implementation of the state-based 2P-Set is not very space-efficient, as it can in the worst case require double the space of a G-Set with the same number of elements. This bloat could be curtailed by maintaining the removal set as a bitmap. Each entry in the bitmap would correspond to an entry in the add set. The merge function for a 2P-Set with a bitmap would use a bitwise OR operation between the bitmaps. This technique could also be applicable to other CRDTs that utilize tombstones.   

The tombstones in the state-based 2P-Set implementation make it a good candidate for experimention with CRDT garbage collection. Although it would be significantly more interesting to do so with a more complicated structure such as a Graph.

## Implementing the Add-Remove Partial Order CRDT

Shapiro et al.'s ARPO specification leaves out the `addEdge` and `removeEdge` operations.  In my implementation, I attempted to add the missing operations.  Many of the same challenges that exist for garbage collection of vertex tombstones also exist for edges.  Edge addition is necessary to maintain a connected graph and avoid partitions. Edge removal also turns out to be necessary:  in a naïve implementation, where edges are represented as a separate data structure (in my naïve ARPO implementation, for instance, edges are represented by their own  G-Set), we have to remove edges along with their vertices to avoid cluttering the data structure with unneeded objects. In an implementation where edges are represented by a list of references in each vertex, one must clean up the relevant references during a vertex removal. With removing edges proving necessary, and if we allow edge addition and removal independent of vertices, we end up requiring another set of tombstones to avoid the same problems with concurrent operations that we had with vertex removal. What we are left  with is a 2P2P-Graph as described in Shapiro’s Specification 16, but with a different initial state, a few new preconditions, and a Before function to show transitive relations.

```go
type Node struct{
	ID interface{}
}

//here we represent the element being added as an array
//0 is the element to add or remove (v)
//1 is the first element in an addbetween (u)
//2 is the last element in an addbetween (w)
type OpList struct {
	Operation string
	Element   []interface{}
	contents  struct{}
}

//an edge points from the origin to the destination
//so left to right
type Edge struct{
	left *Node
	right *Node
}

type AddRemove struct{
	vectorClock *vclock.VClock
	externalVectorClocks []vclock.VClock
	V *Twopset.Twopset
	E *Twopset.Twopset
}

func NewNode(id interface{}) *Node{
	return &Node{
		ID: id,
	}
}

func NewAddRemove() *AddRemove{
	AR := &AddRemove{
		vectorClock: vclock.New(),
		V: Twopset.Newtwopset(),
		E: Twopset.Newtwopset(),
	}
	leftSentinel := NewNode("leftSentinel")
	rightSentinel := NewNode("rightSentinel")
	AR.V.Add("leftSentinel", leftSentinel)
	AR.V.Add("rightSentinel", rightSentinel)
	AR.AddEdge("leftSentinel", "rightSentinel")
	return AR
}

func (a *AddRemove) Lookup (element interface{}) bool{
	if a.V.Query(element){
		return true
	}
	return false
}

//depth first search to establish transitive relationship
func (a *AddRemove) QueryBefore(u, v interface{}) bool{
	isBefore := false
	if a.V.Query(u) && a.V.Query(v){
		if edgeExists := a.FetchEdge(u, v); edgeExists!= nil {
			return true
		}
		if u.(*Node).ID == "leftSentinel" && v.(*Node).ID == "rightSentinel" {
			return true
		}
		edges := a.GetEdges(u)
		for k := range edges{
			isBefore = a.QueryBeforeRecurse(edges[k].(*Edge).right, v)
		}
	}
	return isBefore
}

func (a *AddRemove) QueryBeforeRecurse(u, v interface{}) bool{
	edges := a.GetEdges(u)
	isBefore := false
	//if we have hit the sentinel then we are done
	if len(edges) == 1 && edges[0].(*Edge).right.ID == "rightSentinel" {
		isBefore = false
	}
	for k := range edges{
		if edgeExists := a.FetchEdge(u, v); edgeExists != nil {
			isBefore = true
		}else{
			isBefore = a.QueryBeforeRecurse(edges[k].(*Edge).right, v)
		}
	}
	return isBefore
}

func (a *AddRemove) FetchNode(v interface{}) *Node{
	node := a.V.Fetch(v).(*Node)
	return node
}

//will return all edges in the set that contain a given node
func (a *AddRemove) FetchEdge(u interface{}, v interface{}) *Edge{
	edgeList := a.E.List()
	for k := range edgeList {
		if edgeList[k].(*Edge).left == u.(*Node) && edgeList[k].(*Edge).right == v.(*Node) {
			return edgeList[k].(*Edge)
		}
	}
	return nil
}

//get all edges originating at a node
func (a *AddRemove) GetEdges(u interface{}) []interface{}{
	edges := a.E.List()
	returnEdges := make([]interface{}, 0)
	for k := range edges{
		if edges[k].(*Edge).left == u.(*Node){
			returnEdges = append(returnEdges, edges[k])
		}
	}
	return returnEdges

}

func (a *AddRemove) AddEdge(u, v interface{}){
	if a.V.Query(u) && a.V.Query(v){
		newEdge := &Edge{
			left: a.FetchNode(u),
			right: a.FetchNode(v),
		}
		a.E.Add(newEdge, nil)
	}
}

func (a *AddRemove) AddBetween(u, v, w interface{}) {
	if !a.Lookup(v) && a.QueryBefore(u, w){
		a.V.Add(v, NewNode(v))
		a.AddEdge(u, v)
		a.AddEdge(v, w)
	}
}

//needs a check to remove dangling edges, could possibly be done during garbage collection
func (a *AddRemove) Remove(v interface{}){
	if a.Lookup(v) && (v != "left" || v != "right"){
		a.V.Remove(v)
	}
}

func (a *AddRemove) RemoveEdge(v interface{}){
	if a.LookupEdge(v){
		a.E.Remove(v)
	}
}

func (a *AddRemove) ApplyOps(opslist *list.List) error{
	for e := opslist.Front(); e != nil; e = e.Next(){
		oplistElement := e.Value.(*OpList)
		if oplistElement.Operation == "AddBetween"{
			a.AddBetween(oplistElement.Element[1], oplistElement.Element[0], oplistElement.Element[2])
		}else if oplistElement.Operation == "Remove"{
			a.Remove(oplistElement.Element[0])
		}else{
			return nil
		}
	}
	return nil
}
```

The preconditions for edge addition and removal are concerned with the existence of an edge when removing one, prevention of duplicate edges, and the existence of both endpoint vertices when adding edges. Further testing and prodding the implementation could reveal a need for more preconditions.


## Implementing Garbage Collection for a CRDT

Having implemented the ARPO specification (and then some), my next step was to investigate garbage collection Implementing garbage collection for a CRDT like this one is a challenge. First, establishing the stability of an update (whether it has been received by all replicas) as described in the paper assumes that the set of all replicas is known and that they do not crash permanently. Thus the implementation must include a way to detect crashed replicas (in practice, a timeout)  and a way to communicate the failure of a replica reliably to all other replicas.

Another issue is the metadata storage requirements for implementing garbage collection.  Assuming causal delivery of updates requires the use of vector clocks or some similar mechanism to establish causality. Vector clocks are specifically mentioned in section 4.1 for determining stability. As the definition of stability depends on causality, one can use the same vector clocks to establish both. However, the paper's scheme for determining stability requires each replica to store a copy of the last received vector clock from every other known replica. Therefore, the space complexity required to store the vector clocks locally for N replicas is O(N^2), and total space consumption across the whole set of replicas, O(N^3) -- considerably worse than the usual O(N) necessary to store a single vector clock at each replica for tracking causal relationships, and enough to make programmers uneasy. 

When adding the class of commitment problems to the already mounting pile of dilemmas, the programmer loses hope for the availability and performance of their system. The solutions discussed by Shapiro et al. include [Paxos Commit](https://lamport.azurewebsites.net/video/consensus-on-transaction-commit.pdf) and Two-Phase Commit protocols, which add considerably to the complexity of the implementation along with sacrificing availability. Shapiro et al. suggest performing operations requiring strong synchronization during periods when network partitions are rare; it may also help to limit such operations to when the availability of a system is not paramount. For example, one could run a garbage collection job during a scheduled server maintenance window.

It should be noted that the implementation provided above is as of this post not fully tested nor contains any garbage collection functionality. Further research is necessary to determine what methods for garbage collection are in use for other implementations (preferably production code) or if there are any alternative metadata schemes that lower the overhead costs.

To sum up, distributed garbage collection requires confronting some of the hardest problems in distributed systems.  Perhaps the easiest solution to the unbounded growth of a CRDT via tombstones is to use the [ostrich algorithm](https://en.wikipedia.org/wiki/Ostrich_algorithm) or just to avoid CRDTs that use tombstones entirely.

## Future Work

For a future blog post, I plan to investigate  garbage collection solutions currently in use with CRDTs. Some interesting avenues to explore include [pure operation-based CRDTs](https://arxiv.org/abs/1710.04469), , Victor Grishchenko's [causal trees](https://github.com/gritzko/ctre), and [delta-state CRDTs](https://arxiv.org/pdf/1603.01529.pdf). Also, [methods for reducing the space costs of vector clocks](http://www.bailis.org/blog/causality-is-expensive-and-what-to-do-about-it/) could prove useful in lowering garbage collection metadata overhead. After investigating the options, I'll hopefully be able to choose a garbage collection method to implement, integrate it with my existing ARPO implementation, and evaluate its performance.


## Conclusion

While it would seem simple at first glance garbage collection on CRDTs is anything but easy. Notwithstanding the difficulty of actually implementing one from a specification in an more theory focused paper. While this post does not verify the performance effects of garbage collection it does confirm that both implementing CRDTs is difficult and balancing availability with the stronger synchronization seemingly needed for garbage collection is a nontrivial task.



Attempted basic implementations are available here: https://github.com/atbarker/CRDTexperiments

Note: This implementation is a gross and horrifying abuse of the interface{} construct in Go. Those who care about proper use of the Go language probably should not read the code. I created this abomination because I want to see if I could.
