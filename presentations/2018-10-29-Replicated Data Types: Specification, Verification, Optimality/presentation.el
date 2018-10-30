(require 'demo-it)
(require 'package-demo)
;; requires rust-mode for step0/syntax highlighting
;; makes a flycheck-mode call too, to turn it off — this is not at all valid rust code, so
;; we don't want flychecking

(package-demo-define-action call-noninteractively (fn &rest args)
  (apply fn args))

(package-demo-define-action save (pt)
  (funcall 'point-to-register pt))

(package-demo-define-action load (pt)
  (funcall 'jump-to-register pt))

(defun step0 ()
  (interactive)
  (let ((buffer (generate-new-buffer "svo-presentation")))
    (switch-to-buffer buffer)
    (rust-mode)
    (flycheck-mode 0)
  ))

(package-demo-define-demo step1
  (typewriter
   "struct ReplicaId(i32);
struct ObjectId(i32);
struct Timestamp(i32);
")
  (save ?a)
  (pause 3)
  (typewriter
   "
trait RDT {
    type Value;
    type Operation;
    type Message;

    fn initial_state(replica: ReplicaId) -> Self;

    fn do_(&mut self, op: Self::Operation, ts: Timestamp) -> Self::Value;
    fn send(&mut self) -> Self::Message;
    fn recv(&mut self, msg: Self::Message);

")
  (save ?r)
  (typewriter "}"))

(package-demo-define-demo step2
  (typewriter "

struct Counter {
    replica: ReplicaId,
    last_known_counts: Map<ReplicaId, i32>
}"))

(package-demo-define-demo step3
  (typewriter "

")
  (save ?b)
  (typewriter "
impl RDT for Counter {
    type Value = i32;
    type Operation = ")
  (save ?c)
  (pause 1)
  (load ?b)
  (typewriter "enum CounterOp {
    Read,
    Inc
}
")
  (load ?c)
  (typewriter "CounterOp;
    type Message = Map<ReplicaId, i32>;

    fn initial_state(replica: ReplicaId) -> Counter {
        let last_known_counts = Map::new();
        Counter { replica, last_known_counts }
    }")
  )

(package-demo-define-demo step4
  (typewriter "

    fn do_(&mut self, op: CounterOp, _ts: Timestamp) -> i32 {
        match op {
            Read => self.last_known_counts.values().sum(),
            Inc  => {
                let local_count = self.last_known_counts.entry(self.replica).or_insert(0);
                *local_count += 1;
            }
        }
    }" :speed 30))

(package-demo-define-demo step5
  (typewriter "

    fn send(&mut self) -> Map<ReplicaId, i32> {
        self.last_known_counts.clone()
    }" :speed 30))

(package-demo-define-demo step6
  (typewriter "

    fn recv(&mut self, msg: Map<ReplicaId, i32>) {
        for (replica, count) in msg {
            let local_count = self.last_known_counts.entry(replica).or_insert(0);
            *local_count = max(*local_count, count);
        }
    }

" :speed 30)
  (save ?d)
  (typewriter "
}" :speed 30)
  (save ?e))

(package-demo-define-demo step7
  (load ?r)
  (kbd "C-l")
  (typewriter "

")
  (load ?r)
  (typewriter "

    fn spec(op: Self::Operation, history: Set<Self::Event>,
            visibility: Relation<Self::Event>,
            arbitration: Relation<Self::Event>) -> Self::Value;")
  (load ?r)
  (typewriter
   "    struct Event {
        replica: ReplicaId,
        object: ObjectId,
        operation: Operation,
        return_value: Value
    }"))

(package-demo-define-demo step8
  (load ?d)
  (typewriter
   "    fn spec(op: CounterOp, history: Set<Self::Event>,
            _visibility: Relation<…>,
            _arbitration: Relation<…>) -> i32 {
        match op {
            Read => history.filter(|&ev| ev.operation == Inc).len()
        }
    }
" :speed 33))

(package-demo-define-demo step9
  (load ?e)
  (typewriter
   "

struct Register {
    data: i32,
    timestamp: Option<Timestamp>
}

enum RegisterOp {
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
" :speed 40) (save ?f) (typewriter "}" :speed 40))

(package-demo-define-demo step10
  (load ?f)
  (typewriter "

")
  (load ?f)
  (typewriter
   "

    fn spec(_op: RegisterOp, history: Set<Self::Event>,
            _visibility: impl Relation<…>,
            arbitration: impl Relation<Self::Event>) -> i32 {
        let writes = history.filter(|&a| a.operation == Write);
        let last_write_event = writes.max_by(|&a,&b| arbitration.cmp(a, b));
        let Write(last_write) = last_write_event.operation
        last_write
    }" :speed 40))

(demo-it-create step0 step1 step2 step3 step4 step5 step6 step7 step8 step9 step10)
(demo-it-start)
