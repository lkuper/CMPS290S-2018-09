#![feature(associated_type_defaults)]
use std::collections::{HashSet, HashMap};
use std::hash::Hash;

#[derive(PartialEq, Eq, Hash, Copy, Clone)]
pub struct ReplicaId(i32);

#[derive(PartialEq, Eq, Hash)]
pub struct ObjectId(i32);

#[derive(PartialEq, Eq, Hash, PartialOrd, Ord, Copy, Clone)]
pub struct Timestamp(i32);

#[derive(PartialEq, Eq, Hash)]
pub struct Event<Op,Val> {
    replica: ReplicaId,
    object: ObjectId,
    operation: Op,
    return_value: Val
}

pub trait Relation<T> {
    fn are_related(&self, t1: &T, t2: &T) -> bool;
    fn cmp(&self, t1: &T, t2: &T) -> std::cmp::Ordering;
}

pub trait RDT {
    type Value: Eq + Hash;
    type Operation: Eq + Hash;
    type Message;

    fn initial_state(replica: ReplicaId) -> Self;

    fn do_(&mut self, op: Self::Operation, ts: Timestamp) -> Self::Value;
    fn send(&mut self) -> Self::Message;
    fn recv(&mut self, msg: Self::Message);

    fn spec(op: Self::Operation, history: HashSet<Event<Self::Operation, Self::Value>>,
            visibility: impl Relation<Event<Self::Operation, Self::Value>>,
            arbitration: impl Relation<Event<Self::Operation, Self::Value>>) -> Self::Value;
}

pub struct Counter {
    replica: ReplicaId,
    last_known_counts: HashMap<ReplicaId, i32>
}

#[derive(PartialEq, Eq, Hash)]
pub enum CounterOp {
    Read,
    Inc
}

impl RDT for Counter {
    type Value = i32;
    type Operation = CounterOp;
    type Message = HashMap<ReplicaId, i32>;

    fn initial_state(replica: ReplicaId) -> Counter {
        let last_known_counts = HashMap::new();
        Counter { replica, last_known_counts }
    }

    fn do_(&mut self, op: CounterOp, _ts: Timestamp) -> i32 {
        match op {
            CounterOp::Read => self.last_known_counts.values().sum(),
            CounterOp::Inc  => {
                let local_count = self.last_known_counts.entry(self.replica).or_insert(0);
                *local_count += 1;
                -1 // garbage return
            }
        }
    }

    fn send(&mut self) -> HashMap<ReplicaId, i32> {
        self.last_known_counts.clone()
    }

    fn recv(&mut self, msg: HashMap<ReplicaId, i32>) {
        for (replica, count) in msg {
            let local_count = self.last_known_counts.entry(replica).or_insert(0);
            *local_count = std::cmp::max(*local_count, count);
        }
    }


    fn spec(op: CounterOp, history: HashSet<Event<CounterOp, i32>>,
            _visibility: impl Relation<Event<CounterOp, i32>>,
            _arbitration: impl Relation<Event<CounterOp, i32>>) -> i32 {
        match op {
            CounterOp::Inc => -1,
            CounterOp::Read => {
                history.iter()
                    .filter(|&ev| ev.operation == CounterOp::Inc)
                    .collect::<Vec<_>>()
                    .len() as i32
            }
        }
    }
}

#[derive(Clone)]
pub struct Register {
    data: i32,
    timestamp: Option<Timestamp>
}

#[derive(PartialEq, Eq, Hash)]
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
            RegisterOp::Write(new_data) if self.timestamp < Some(ts) => {
                self.data = new_data;
                self.timestamp = Some(ts);
            },
            _ => {}
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

    fn spec(_op: RegisterOp, history: HashSet<Event<RegisterOp, i32>>,
            _visibility: impl Relation<Event<RegisterOp, i32>>,
            arbitration: impl Relation<Event<RegisterOp, i32>>) -> i32 {
        let writes = history.iter().filter(|&a| a.operation != RegisterOp::Read);
        let last_write_event = writes.max_by(|&a,&b| arbitration.cmp(a, b)).unwrap();
        if let RegisterOp::Write(last_write) = last_write_event.operation {
            last_write
        } else { panic!() }
    }
}
