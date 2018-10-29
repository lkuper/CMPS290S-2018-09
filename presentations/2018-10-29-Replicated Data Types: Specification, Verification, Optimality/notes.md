1.

* Specification
* Verification
* (Optimality)

2.

```rust
pub struct ReplicaId(i32);
pub struct ObjectId(i32);
pub struct Timestamp(i32);

pub trait RDT {
    type Value;
    type Operation;
    type Message;

    fn initial_state(replica: ReplicaId) -> Self;

    fn do_(&mut self, op: Self::Operation, ts: Timestamp) -> Self::Value;
    fn send(&mut self) -> Self::Message;
    fn recv(&mut self, msg: Self::Message);
}

```
* Basic specifications
* Three associated types, three methods
* Note that all the methods are allowed to change local state,
  * though only do and recv are really expected to


3.

``` rust
pub struct Counter {
    replica: ReplicaId,
    last_known_counts: Map<ReplicaId, i32>
}
```

* State-based counter
* Sort-of a vector clock

4.

``` rust
pub enum CounterOp {
    Read,
    Inc
}

impl RDT for Counter {
    type Value = i32;
    type Operation = CounterOp;
    type Message = Map<ReplicaId, i32>;

    fn initial_state(replica: ReplicaId) -> Counter {
        let last_known_counts = Map::new();
        Counter { replica, last_known_counts }
    }

    fn do_(&mut self, op: CounterOp, _ts: Timestamp) -> i32 {
        match op {
            CounterOp::Read => self.last_known_counts.values().sum(),
            CounterOp::Inc  => {
                let local_count = self.last_known_counts.entry(self.replica).or_insert(0);
                *local_count += 1;
            }
        }
    }

    fn send(&mut self) -> Map<ReplicaId, i32> {
        self.last_known_counts.clone()
    }

    fn recv(&mut self, msg: Map<ReplicaId, i32>) {
        for (replica, count) in msg {
            let local_count = self.last_known_counts.entry(replica).or_insert(0);
            *local_count = max(*local_count, count);
        }
    }
}
```

* Nothing surprising, standard distributed counter
* Note how it's defined _just_ by defining the types and methods we stated

5.

``` rust
pub struct Event<Op,Val> {
    replica: ReplicaId,
    object: ObjectId,
    operation: Op,
    return_value: Val
}

pub trait RDT {
    type Event = Event<Self::Operation, Self::Value>

    fn spec(op: Self::Operation, history: Set<Self::Event>,
            visibility: impl Relation<Self::Event>,
            arbitration: impl Relation<Self::Event>) -> Self::Value;
}
```

* So how do we spec this?
* We describe a spec as just a condition it has to meet on an operation,
  * given a history
  * a visibility relation
  * and an arbitration relation

6.

``` rust
impl RDT for Counter {
    fn spec(op: CounterOp, history: Set<Event<CounterOp, i32>>,
            _visibility: impl Relation<…>,
            _arbitration: impl Relation<…>) -> i32 {
        match op {
            Read => {
                history.iter()
                    .filter(|&ev| ev.operation == CounterOp::Inc)
                    .collect().len()
            }
        }
    }
}
```

* The history is already implicitly just the history that's visible to this operation
* (That's what a large chunk of the “abstract execution” machinery is buying us)
* So it might end up that you don't need to appeal to visibility/arbitration at all
* That said, they're important, because you still need them to make the specs _deterministic_

7.

``` rust
pub struct Register {
    data: i32,
    timestamp: Option<Timestamp>
}

pub enum RegisterOp {
    Read,
    Write(i32)
}

impl RDT for Register {
    type Value = i32;
    type Operation = RegisterOp;
    type Message = Register;

    fn initial_state(_replica: ReplicaId) -> Register {
        Register { data: 0, timestamp: None }
    }

    fn do_(&mut self, op: RegisterOp, ts: Timestamp) -> i32 {
        match op {
            Write(new_data) if self.timestamp < Some(ts) => {
                self.data = new_data;
                self.timestamp = Some(ts);
            }
        }
        self.data
    }

    fn send(&mut self) -> Register {
        self.clone()
    }

    fn recv(&mut self, msg: Register) {
        if self.timestamp < msg.timestamp {
            self.data = msg.data;
            self.timestamp = msg.timestamp;
        }
    }
}

```

* LWW register.
* Not especially surprising.

8.

``` rust
impl RDT for Register {
    fn spec(_op: RegisterOp, history: Set<Event<RegisterOp, i32>>,
            _visibility: impl Relation<…>,
            arbitration: impl Relation<Event<RegisterOp, i32>>) -> i32 {
        let writes = history.iter().filter(|&a| a.operation != Read);
        let last_write_event = writes.max_by(|&a,&b| arbitration.cmp(a, b));
        let Write(last_write) = last_write_event.operation
        last_write
}

```

* Need arbitration relation to make this spec deterministic
* All events that have happened in our history
  * ordered by how we're meant to break ties
    * with the timestamps, in this case
* Without the arbitration relation, there'd be no deterministic spec here

9.

* This lets you specify local properties
* Global properties need to be specified too
* They essentially reduce them all to broad network-level properties and prove them separately
