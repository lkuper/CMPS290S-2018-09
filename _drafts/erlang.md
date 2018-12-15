---
title: An overview of Erlang
author: Natasha Mittal
layout: single
classes: wide
---

by Natasha Mittal ⋅ edited by Abhishek Singh and Lindsey Kuper

## Introduction
In 1981, the Ericsson [Computer Science Laboratory (CSLab)](http://www.cs-lab.org/) had been experimenting with ways to program telephony features in Prolog, a declarative language. Telecom applications in general are distributed systems with a large number of concurrent actions taking place. The downside to Prolog was that such declarative languages did not possess error-handling facilities and also lacked the means for concurrency control across multiple systems. Thus began a series of collaborations which led to the development of Erlang.

Erlang is described in [Joe Armstrong](https://joearms.github.io/)'s [2003 PhD thesis]
(http://erlang.org/download/armstrong_thesis_2003.pdf) on "Making reliable distributed systems in the presence of software errors". In it, he describes how Erlang supports building fault-tolerant systems. Since its inception in 1986, Erlang has grown popular for building reliable telecom applications. It has been used in Web Prioritizer and [Mail Robustifier](https://dl.acm.org/citation.cfm?id=338532), two products developed by [Bluetail](https://www.walerud.com/blog/bluetail-spinning-out-of-ericsson-and-selling-for-152m-in-18-months), a company founded by Joe Armstrong. [Ericsson's AXD301](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.33.5674&rep=rep1&type=pdf), a scalable ATM switching system developed using Erlang middleware, was one of the company's most successful new products from 1998 to the mid-2000s. 

Armstrong describes Erlang as "a concurrent programming language designed for programming large-scale distributed soft real-time control applications" (http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.34.5602&rep=rep1&type=pdf). It is used in conjunction with a collection of libraries and tools called [OTP (Open Telecom Platform)](http://erlang.org/doc/system_architecture_intro/sys_arch_intro.html), which uses "supervision trees" to provide descriptions of error recovery actions to take for a given error. Erlang is [process-based](https://www.toptal.com/elixir/process-oriented-programming-elixir-and-otp), in the sense that individual processes do not share memory and communicate via asynchronous message passing, hence maintaining strong isolation between concurrent processes. Since the resource threads are not shared, processes are isolated from each other and errors occuring in one process cannot propagate to other processes, so Erlang's programming model is able to use fail-fast processes. Concurrency is provided by the language and not the underlying operating system. 

Erlang also offers support for dynamic code replacement, which aids in code updating and maintenance without stopping the system. This is essential since telecom applications are long-lived, or more often than not, aren't shut down ever.

## Concurrency Oriented Programming

In his [thesis](http://erlang.org/download/armstrong_thesis_2003.pdf), Armstrong coined the term _COPL_, which stands for "concurrency-oriented programming language", and  argued that Erlang falls into this category of languages. Armstrong says that the advantage of using COPLs is the way they can easily model real-world concurrent activities and map them onto concurrent processes in a 1:1 fashion, in contrast to non-COPLs, where one process or thread might control several independent activities.

As described in section 2.4.2 in his [thesis](http://erlang.org/download/armstrong_thesis_2003.pdf), there are six essential characteristics of a COPL:

1. It supports lightweight processes, i.e., the computation required to generate and destroy processes is minimal.
2. It supports isolation of processes.
3. Every process is identified uniquely by a Pid.
4. There is no shared state between processes.
5. Message passing does not guarantee delivery, and is pure (no dangling pointers or data references).
6. Processes can detect the occurrence of and also the reason of failures in other processes.

A critical requirement in COPLs is that of isolation. There must be strong isolation between the multiple processes running on a single machine. Unless programmed, no faults in any process should affect any of the other processes on the machine. To enable isolation, all processes have "share nothing" semantics and message passing between processes is asynchronous to prevent a sender of the message from getting indefinitely blocked in case software errors occur in the receiver. Data is also immutable within individual processes.

Another requirement is unforgeability of process names so that it is impossible to guess their names. Each process can only know its own name and the name of the child processes it has created. The act of revealing names to other processes is called the “name distribution problem”, mentioned in section 2.4.4 in Armstrong’s [thesis] (http://erlang.org/download/armstrong_thesis_2003.pdf). Such revelations have to be limited to trusted processes only to maintain system security. 

Message passing has "send and pray" semantics in Erlang. Every message is assumed to be received in its entirety or not received at all. Messages can be sent to and received via mailboxes, which every process has. To aid isolation, there can be no pointers or references to data structures residing on other machines, once a message has been passed. Additionally, messages are received in the exact order they were sent. A key advantage of message passing  is scalability: message-passing systems are relatively easy to replicate over multiple isolated machines, thereby enabling fault tolerance as well. Even though individual components may fail, the probability of all of them failing at the same time is low. 

## Fault-tolerance in Erlang

According to section 5.1 of [Armstrong’s thesis](http://erlang.org/download/armstrong_thesis_2003.pdf), the main strategy for implementing fault-tolerance is to try to perform a task, and if unsuccessful, try to perform a simpler task. In this manner, a hierarchy of tasks is established. This strategy helps avoid unnecessary complexity that might result in the system becoming less reliable. 

### Supervision Hierarchies

Armstrong refers to these hierarchical organizations of tasks as "supervision hierarchies". In this level-based organization, the highest-level task is to run an application according to specific parameters, and if not possible, to run simpler lower-level tasks. A system failure occurs if the lowest-level task cannot be performed successfully. As we go down to simpler tasks, failure to perform the task becomes more unlikely. It is also interesting to note that on encountering more and more failures at different levels, the emphasis becomes less towards providing complete service and more towards protecting the system. Hence it becomes important to have some mechanism to log all failures and their particular reasons.

The supervision hierarchy detects and attempts to stop errors from propagating upwards in the system. Every task is associated with a supervisor process which assigns it to a worker for achieving the goals necessary to complete the given task. 

A supervisor needs to have the information about how to start, stop or restart every worker under it. This data is stored in an SSRS (Start Stop and Restart Specification). In a linear hierarchy, the rule is: stop all child processes if a parent asks to stop the supervisor; and to restart a child in case it dies. 

## Programming Model

### Process Creation
Spawning is the way new processes are created. When *spawn()* is called, module name and  function within that module is passed as arguments. This newly spawned process executes this function and returns the identifier for the spawned process, i.e., the Pid. Pids can then be used for message passing between individual processes.

The syntax for doing this is as follows:

```erlang
spawn(Module, Exported_Function, List of Arguments) 
```

As an example:
```erlang
spawn(moduleA, response, [thank you])
```

The above spawn function call creates a new process which executes a function named "response" with argument ‘thank you’ defined within module ‘moduleA’.

### Message Passing
All processes abide by a message passing interface, which is same for all the concurrent processes. Message passing is the only form of data exchange between two processes, and there is no data sharing. A message can be a list, a tuple, integers, etc

Message passing takes place causally, and with a construct called "receive". It directs processes to wait for message to come from another process. 

The example mentioned below has been taken from [Message Passing Subsection of Erlang’s website](http://erlang.org/doc/getting_started/conc_prog.html#message-passing), which explains message passing syntax. In this example, two processes are created which send messages to each other a number of times.

```erlang
-module(msg_passing).
-export([start/0, ping/2, pong/0]).

ping(0, Pong_PID) ->			
  Pong_PID ! finished,					%% syntax to send message, string ‘finished is being sent to process with Pid=Pong_PID
  io:format("ping finished~n", []);		

ping(N, Pong_PID) ->
  Pong_PID ! {ping, self()},		
  Receive						%% receive block does a pattern matching
    pong ->
      io:format("Ping received pong~n", [])
  end,
  ping(N - 1, Pong_PID).				%% recursive call to itself

pong() ->
  receive
    finished ->
      io:format("Pong finished~n", []);
    {ping, Ping_PID} ->
      io:format("Pong received ping~n", []),
      Ping_PID ! pong,
      pong()
  end.

start() ->
  Pong_PID = spawn(msg_passing, pong, []),		%% a process is spawned which executes pong function
  spawn(msg_passing, ping, [3, Pong_PID]).			%% another process is spawned which executes ping message
```

```
Eshell V5.9.3.1  (abort with ^G)
1> c(msg_passing).
{ok,msg_passing}
2> msg_passing:start().
Pong received ping
<0.39.0>
Ping received pong
Pong received ping
Ping received pong
Pong received ping
Ping received pong
ping finished
Pong finished
```

### Process Linking

The linking of the processes is done via *link()* or *spawn_link()* functions. The example discussed below has been taken from [the "Errors and Processes" chapter of _Learn You Some Erlang for Great Good!_](https://learnyousomeerlang.com/errors-and-processes), which clearly explains how linking works in Erlang.

This function spawns N processes which are linked to each other.

```erlang
-module(linking).				%% a module named linking is created
-export([chain/1]).				%% export makes chain function public

chain(0) ->					%% base case when N=0 and process dies after 2000 milliseconds
  receive
    _ -> ok
  after 2000 ->
    exit("chain dies here")
  end;

chain(N) ->					%% recursive call to spawn N processes and linking them to each other
  Pid = spawn(fun() -> chain(N-1) end),	%% spawns a new process running chain(N-1) func
  link(Pid),
  receive
    _ -> ok
  end.
```

After three recursive calls to `linking:chain()`, the process running `chain(0)` dies and this error propagates to other processes running with N=1, 2, and 3 consecutively. Eventually, the error propagates to the top-level Erlang shell process, `erl shell`, which also dies, as seen in the stack trace below.

```
Execution:
Eshell V6.4.1.7  (abort with ^G)
1> link(spawn(linking, chain, [3])).		%% N = 3, so three processes are spawned
true
2> 2> 2> ** exception error: "chain dies here”
Stack Trace::
[erl shell] == [N=3] == [N=2] == [N=1] == [N=0]
[erl shell] == [N=3] == [N=2] == [N=1] == *dead*
[erl shell] == [N=3] == [N=2] == *dead*
[erl shell] == [N=3] == *dead*
[erl shell] == *dead*
*dead, error message shown*
[erl shell] <-- restarted       %% here erl also dies eventually.
```

###Conclusion

The past couple of decades have seen a growth in Erlang's popularity, as its programming techniques are being picked up by various other transactional systems owing to a growing need for concurrent service based applications. Databases like [CouchDB](http://couchdb.apache.org/), [Scalaris](http://scalaris.zib.de/) and [Amazon SimpleDB](https://aws.amazon.com/simpledb/) have been implemented using Erlang. Erlang has also become a good choice as a general purpose programming language, as in the [Nitrogen framework](http://nitrogenproject.com/) for web development, or even [Wings3D](http://www.wings3d.com/) designed for graphics modeling. In conclusion, the following quote by Armstrong in [Rackspace in 2013](https://www.youtube.com/watch?v=u41GEwIq2mE&t=3m59s) seems apt:"If [Java](https://en.wikipedia.org/wiki/Java_(programming_language)) is '[write once, run anywhere](https://en.wikipedia.org/wiki/Write_once,_run_anywhere)', then Erlang is 'write once, run forever'.
