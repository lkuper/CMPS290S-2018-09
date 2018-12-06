---
title: Erlang
author: Natasha Mittal
layout: single
classes: wide
---

by Natasha Mittal ⋅ edited by Abhishek Alfred Singh and Lindsey Kuper

## Introduction
In 1981, the Ericsson [Computer Science Laboratory(CSLab)](http://www.cs-lab.org/) had been experimenting with ways to program telephony features in Prolog, a declarative language. Telecom applications in general are parallel systems with a large number of concurrent actions taking place. The downside to Prolog was that such declarative languages did not possess error-handling facilities and also lacked the means for concurrency control across multiple systems. Thus began a series of collaborations which led to the development of Erlang.

Erlang is said to be the result of [Joe Armstrong](https://joearms.github.io/)'s [thesis]
(http://erlang.org/download/armstrong_thesis_2003.pdf) on "Making reliable distributed systems in the presence of software errors". In it, he described the approaches towards programming telecom applications and argued how Erlang fulfills the requisites to build fault tolerant systems. Since its inception in 1986, Erlang has grown popular for building reliable telecom applications. It has been used in Web Prioritizer and [Mail Robustifier](https://dl.acm.org/citation.cfm?id=338532), two Erlang products developed by [Bluetail](https://www.walerud.com/blog/bluetail-spinning-out-of-ericsson-and-selling-for-152m-in-18-months), a company founded by Joe Armstrong. [Ericsson's AXD301](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.33.5674&rep=rep1&type=pdf), a scalable ATM switching system developed using Erlang middleware, was one of the company's most successful new products in the years 1998 to mid 2000s. 

Erlang is a [concurrent programming language designed for programming large-scale distributed soft real-time control applications](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.34.5602&rep=rep1&type=pdf). It is used in conjunction with libraries called [OTP (Open Telecom Platform)](http://erlang.org/doc/system_architecture_intro/sys_arch_intro.html) which use "supervision trees" to provide descriptions of error recovery actions to take, for a given error. Erlang is process-based, in the sense that individual processes do not share memory and communicate via asynchronous message passing, hence maintaining strong isolation between concurrent processes. Since the resource threads are not shared, Erlang's programming model is able to use fail-fast processes. Consistency is provided by the language and not the underlying operating system. 

The basic idea is to perform the application logic at one layer and have another layer, say the [error trapping layer](http://delivery.acm.org/10.1145/1820000/1810910/p68-armstrong.pdf?ip=76.102.6.80&id=1810910&acc=OPEN&key=4D4702B0C3E38B35%2E4D4702B0C3E38B35%2E4D4702B0C3E38B35%2E6D218144511F3437&__acm__=1543946542_df2e5d8166b0c84f74f5000a5d4ce297) to ensure the system state is restored properly and full recovery is possible after the occurrence of any error. 

Erlang also offers support for dynamic code replacement, which aids in code updating and maintenance without stopping the system. This is essential since telecom applications are very long-lived or more often than not, aren't shut down ever.

## Concurrency Oriented Programming

COPL stands for "Concurrency Oriented Programming Languages", this term was coined by Joe Armstrong in his [thesis](http://erlang.org/download/armstrong_thesis_2003.pdf), where he argued that Erlang falls into this category of languages. The main advantage to using COPLs is the way they can easily model real-world concurrent activities and simultaneously ensure that their mapping is done 1:1  to avoid degeneration of the program. This is in contrast to the approach in non-CO languages where program is not isomorphic to the problem, and so they are subject to severe interference errors.

As described in his [thesis](http://erlang.org/download/armstrong_thesis_2003.pdf), there are three major properties of Erlang which makes it satisfy the requirements for being considered a concurrent programming language. 
These are:

1. It supports lightweight processes, as in the computation required to generate and destroy processes are very little.
2. It supports isolation of processes.
3. Every process is identified uniquely by a Pid.
4. There are no shared states between processes.
5. Message passing does not guarantee delivery, and is pure (no dangling pointers or data references).
6. Processes can detect the occurrence of and also the reason of failures in other processes.

A critical requirement in COPLs is that of isolation. There must be strong isolation between the multiple processes running on a single machine. Unless programmed, no faults in any process should affect any of the other processes on the machine. To enable isolation, all processes have "share nothing" semantics and message passing between processes is asynchronous to prevent a sender of the message from getting indefinitely blocked in case software errors occur in the receiver. Data is also immutable within individual processes.

Another requirement is unforgeability of process names so that it is impossible to guess their names. Each process can only know its own name and the name if the child processes it has created. The act of revealing names to other processes is termed as the [name distribution problem](http://erlang.org/download/armstrong_thesis_2003.pdf). Such revelations have to be limited to trusted processes only to maintain system security. 

Thirdly, message passing has "send and pray" semantics. Every message is assumed to be received in its entirety or not received at all. Messages can be sent to and received via mailboxes, which every process has. To aid the isolation agenda, there can be no pointers or references to data structures residing on other machines, once a message has been passed. Additionally, message passing is done in order, i.e messages are received in the exact order they had been sent in. The key advantage to using message passing in relevance to today's world is the scalability. Such systems are very easily scalable and can be replicated over multiple isolated machines, thereby enabling fault tolerance as well. Even though individual components may fail, the probability of all of them failing at the same time would be minimal if replication is done sufficiently. 

In addition to these features, Erlang has a safe-type system, which ensures no corrupt data structures can be written by allowing them to be typed dynamically only. Another unique feature of Erlang is its principle of fault-tolerance - let processes fail and issue other processes to detect these failures and fix them. So an individual process getting destroyed has no adverse consequences on the system.

## Fault-tolerance in Erlang

According to [Joe](http://erlang.org/download/armstrong_thesis_2003.pdf), the main strategy for implementing fault-tolerance is to try to perform a task, and if unsuccessful, try to perform a simpler task. In this manner, a hierarchy of tasks is established. This strategy helps avoid unnecessary complexity that might result in the system becoming less reliable. 

This hierarchical organization of tasks is better known as a set of supervision hierarchies. In this level-based organization, the highest level task is to run an application according to specific parameters, and if not possible, to run simpler lower level tasks. A system failure occurs if the lowest level task cannot be performed successfully. As we go down to simpler tasks, failure to perform becomes more unlikely. It is also interesting to note that on encountering more an more failures at different levels, the emphasis becomes less towards providing complete service and more towards protecting the system. Hence it becomes important to have some mechanism to log all failures and their particular reasons.

### Supervision Hierarchy
The supervision hierarchy detects and as attempts to stop errors from propagating upwards in the system. Every task is associated with a supervisor process which assigns it to a worker for achieving the goals necessary to complete the given task. 

As described in [thesis](http://erlang.org/download/armstrong_thesis_2003.pdf), supervision trees are hierarchical trees of supervisors. Each node in the tree is responsible for monitoring errors in its child nodes: 

1. Supervision trees are trees of Supervisors.
2. Supervisors monitor Workers and Supervisors.
3. Workers are instances of Behaviors.
4. Behaviors are parameterized by Well-behaved functions.
5. Well-behaved functions raise exceptions when errors occur.

A supervisor needs to have the information about how to start, stop or restart every worker under it. This data is stored in an SSRS (Start Stop and Restart Specification). In a linear hierarchy, the rule is - stop all children processes if a parent asks to stop the supervisor; and to restart a child in case it dies. 

### AND/OR Supervision Hierarchies
An AND hierarchy is used where processes are intended to be coordinated with each other, whereas the OR hierarchy is used when processes are independent. 
The supervisor acts according to the following rules:

1. If my parent stops me then I should stop all my children.
2. If any child dies and I am an AND supervisor stop all my children and restart all my children.
3. If any child dies and I am an OR supervisor restart the child that died.
 
By implementing supervisors in the OTP system in this manner, it is in effect implementing a supervision tree that can be used to monitor the behavior of the system.

It is also important to exactly define what an error means for this system. Errors are not always corresponding to exceptions. [Joe](http://erlang.org/download/armstrong_thesis_2003.pdf) defines an error as "a deviation between the observed behavior of a system and the desired behavior of a system."

## Programming Model

### Concurrency
In Erlang, *spawn(Fun)* is used to create a parallel process which executes function *Fun*. In the code, I have implemented a simple client-server model where a counter is incremented everytime when client sends a request to server.

```
-module(counter_client_server).
-author("natashamittal").

-export([start/0,counter_server/1,counter_client/1]).

counter_server(Number) ->
  receive
    {request, Pid} ->
      io:format("Server: ~w Client request received from: ~w~n",[self(),Pid]),
      NewNumber = Number + 1,
      Pid ! {hitCount, NewNumber},
      counter_server(NewNumber)
  end.

counter_client(Server_Address) ->
  Server_Address ! {request, self()},
  receive
    {hitCount, Number} ->
      io:format("Client: ~w HitCount was: ~w~n",[self(),Number]),
      if
        (Number < 100) -> counter_client(Server_Address)
      end
  end.
  
start() ->
  Server_PID = spawn(counter_client_server,counter_server,[0]),
  spawn(counter_client_server,counter_client,[Server_PID]).  
  
Execution:
7> Natashas-MacBook-Pro-2:counter natashamittal$ erl
Erlang R15B03 (erts-5.9.3.1) [source] [64-bit] [smp:8:8] [async-threads:0] [hipe] [kernel-poll:false]
Eshell V5.9.3.1  (abort with ^G)
1> c(counter_client_server).
{ok,counter_client_server}
2> counter_client_server:start().
Server: <0.38.0> Client request received from: <0.39.0>
<0.39.0>
Client: <0.39.0> HitCount was: 1
Server: <0.38.0> Client request received from: <0.39.0>
Client: <0.39.0> HitCount was: 2
Server: <0.38.0> Client request received from: <0.39.0>
Client: <0.39.0> HitCount was: 3
Server: <0.38.0> Client request received from: <0.39.0>
Client: <0.39.0> HitCount was: 4
Server: <0.38.0> Client request received from: <0.39.0>
Client: <0.39.0> HitCount was: 5
.
.
.
Client: <0.39.0> HitCount was: 99
Server: <0.38.0> Client request received from: <0.39.0>
Client: <0.39.0> HitCount was: 100
ok
```

When 'N' clients are spawn, following changes are made to the code above:

```
spawn_n_clients(N,Server_Address) ->
  if
    N > 0 ->
      spawn(counter_client_server,counter_client,[Server_Address]),
      timer:sleep(random:uniform(100)),
      spawn_n_clients(N-1,Server_Address);
    N == 0 ->
      io:format("Last client spawned.~n")
  end.

start(Num) ->
  Server_PID = spawn(counter_client_server,counter_server,[0]),
  spawn_n_clients(Num,Server_PID).
  
Execution
8> c(counter_client_server).
{ok,counter_client_server}
9> counter_client_server:start(5).
Server: <0.72.0> Client request received from: <0.73.0>
Client: <0.73.0> HitCount was: 1
Server: <0.72.0> Client request received from: <0.74.0>
Client: <0.74.0> HitCount was: 2
Server: <0.72.0> Client request received from: <0.75.0>
Client: <0.75.0> HitCount was: 3
Server: <0.72.0> Client request received from: <0.76.0>
Client: <0.76.0> HitCount was: 4
Server: <0.72.0> Client request received from: <0.77.0>
Client: <0.77.0> HitCount was: 5
Last client spawned.
ok
```

### Fault-tolerance

The linking of the processes is done via *link()* or *spawn_link()* functions. The example discussed below has been taken from [learnyousomeerlang](https://learnyousomeerlang.com/errors-and-processes) which clearly explains how linking works in Erlang.

```
-module(linking).
-export([chain/1]).

chain(0) ->
  receive
    _ -> ok
  after 2000 ->
    exit("chain dies here")
  end;

chain(N) ->
  Pid = spawn(fun() -> chain(N-1) end),
  link(Pid),
  receive
    _ -> ok
  end.

Execution:
Eshell V6.4.1.7  (abort with ^G)
1> link(spawn(linking, chain, [3])).
true
2> 2> 2> ** exception error: "chain dies here"

Explanation:
[erl shell] == [N=3] == [N=2] == [N=1] == [N=0]
[erl shell] == [N=3] == [N=2] == [N=1] == *dead*
[erl shell] == [N=3] == [N=2] == *dead*
[erl shell] == [N=3] == *dead*
[erl shell] == *dead*
*dead, error message shown*
[erl shell] <-- restarted       %% here erl also dies eventually.
```
### Client-Server: TCP Connection

The code below explains how client-server interaction is done in Erlang using TCP connection:

```
-module(socket_server).
-author("natashamittal").
-export([start_server/0]).

-define(PORT, 9000).

start_server() ->
  Pid = spawn_link(fun() ->
    {ok, ListeningSocket} = gen_tcp:listen(?PORT,[binary, {active, true}]),
    spawn(fun() -> acceptSocket(ListeningSocket) end),
    timer:sleep(infinity)
    end),
  {ok, Pid}.

acceptSocket(ListeningSocket) ->
  {ok, AcceptSocket} = gen_tcp:accept(ListeningSocket),
  spawn(fun() -> acceptSocket(ListeningSocket) end),
  handler(AcceptSocket).

handler(AcceptSocket) ->
  %%inet:setopts(AcceptSocket,{active,once}),
  receive
    {tcp, AcceptSocket, <<"quit">>} -> gen_tcp:close(AcceptSocket);
    {tcp, AcceptSocket, BinaryMessage} ->
      if
        (BinaryMessage =:= <<"Hi, How are you?">>) ->
        gen_tcp:send(AcceptSocket, "I am fine :)");

        (BinaryMessage =:= <<"What doing?">>) ->
          gen_tcp:send(AcceptSocket, "Working!!");

        (BinaryMessage =:= <<"Ok! Bye">>) ->
          gen_tcp:send(AcceptSocket, "Bye :)");

        true ->
          gen_tcp:send(AcceptSocket, "Cannot interpret")
      end,
    handler(AcceptSocket)
  end.
  
Execution:
Eshell V5.9.3.1  (abort with ^G)
1> c(socket_server).      %% server is started in one terminal
{ok,socket_server}
2> socket_server:start_server().
{ok,<0.38.0>}

Eshell V5.9.3.1  (abort with ^G)
1> {ok, Socket} = gen_tcp:connect({127,0,0,1},9000,[binary,{active,true}]).  %% client is started in another terminal
{ok,#Port<0.590>}
2> gen_tcp:send(Socket,"Hi, How are you?").
3> flush().
Shell got {tcp,#Port<0.590>,<<"I am fine :)">>}
4> gen_tcp:send(Socket,"What doing?").     
5> flush().
Shell got {tcp,#Port<0.590>,<<"Working!!">>}
6> gen_tcp:send(Socket,"Ok! Bye").    
7> flush().
Shell got {tcp,#Port<0.590>,<<"Bye :)">>}
8> gen_tcp:send(Socket,";) :)").  
9> flush().                     
Shell got {tcp,#Port<0.590>,<<"Cannot interpret">>}
10> gen_tcp:send(Socket,"quit"). 
11> flush().                    
Shell got {tcp_closed,#Port<0.590>}
```
### Mnesia

Mnesia is the distributed database written in Erlang. The code below explains how mnesia can be used for distributed environment.

Main Database Logic:

```
-module(db_logic).
-author("natashamittal").
-export([initDB/0, storeDB/2, getDBMsg/1, getDBMsgAndTime/1, deleteDB/1]).

-include_lib("stdlib/include/qlc.hrl").

-record(conversation,{nodeName,message,createdOn}).

initDB() ->
  mnesia:create_schema([node()]),
  mnesia:start(),
  mnesia:create_table(conversation, [{attributes, record_info(fields,conversation)},
    {type, bag},
    {disc_copies,[node()]}]).

storeDB(NodeName, Message) ->
  Fun = fun() ->
        {CreatedOn,_} = calendar:universal_time(),
        mnesia:write(#conversation{nodeName = NodeName, message = Message, createdOn = CreatedOn})
        end,
  mnesia:transaction(Fun).

getDBMsg(NodeName) ->
  Fun = fun() ->
    Query = qlc:q([X || X <- mnesia:table(conversation),
      X#conversation.nodeName =:= NodeName]),
    Results = qlc:e(Query),
    lists:map(fun(Item) -> Item#conversation.message end, Results)
    end,
  {atomic,Message} = mnesia:transaction(Fun),
  Message.

getDBMsgAndTime(NodeName) ->
  Fun = fun() ->
    Query = qlc:q([X || X <- mnesia:table(conversation),
      X#conversation.nodeName =:= NodeName]),
    Results = qlc:e(Query),
    lists:map(fun(Item) -> {Item#conversation.message, Item#conversation.createdOn} end, Results)
        end,
  {atomic,Message} = mnesia:transaction(Fun),
  Message.

deleteDB(NodeName) ->
  Fun = fun() ->
    Query = qlc:q([X || X <- mnesia:table(conversation),
      X#conversation.nodeName =:= NodeName]),
    Results = qlc:e(Query),
    F = fun() ->
      list:foreach(fun(Result) ->
                    mnesia:delete(Result)
                   end,Results)
        end,
    mnesia:transaction(F)
    end,

  mnesia:transaction(Fun).
```

Database Server:

```
-module(database_server).
-author("natashamittal").
-behaviour(gen_server).
-export([start_link/0]).
-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).
-export([store/2, getDBMsg/1, getDBMsgAndTime/1, delete/1]).
-record(state, {}).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

store(NodeName, Message) ->
  gen_server:call({global,?MODULE},{store,NodeName,Message}).

getDBMsg(NodeName) ->
  gen_server:call({global,?MODULE},{getDBMsg,NodeName}).

getDBMsgAndTime(NodeName) ->
  gen_server:call({global,?MODULE},{getDBMsgAndTime,NodeName}).

delete(NodeName) ->
  gen_server:call({global,?MODULE},{delete,NodeName}).

init(_Args) ->
  process_flag(trap_exit, true),
  io:format("~p (~p) starting .... ~n",[{global,?MODULE},self()]),
  db_logic:initDB(),
  {ok, #state{}}.

handle_call({store, NodeName, Message}, _From, State) ->
  db_logic:storeDB(NodeName,Message),
  io:format("Message has been saved for ~p~n",[NodeName]),
  {reply, ok, State};

handle_call({getDBMsg, NodeName}, _From, State) ->
  Messages = db_logic:getDBMsg(NodeName),
  lists:foreach(fun(M) ->
    io:format("Received: ~p~n",[M])
    end,Messages),
  {reply, ok, State};

handle_call({getDBMsgAndTime, NodeName}, _From, State) ->
  Messages = db_logic:getDBMsgAndTime(NodeName),
  lists:foreach(fun({M, CO}) ->
    io:format("Received: ~p Created on: ~p~n",[M,CO])
                end,Messages),
  {reply, ok, State};

handle_call({delete,NodeName}, _From, State) ->
  db_logic:deleteDB(NodeName),
  io:format("Data deleted for ~p~n",[NodeName]),
  {reply, ok, State};

handle_call(_Request, _From, State) ->
  {reply, ok, State}.

handle_cast(_Request, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.
```

Database Supervisor:

```
-module(database_supervisor).
-author("natashamittal").
-behaviour(supervisor).
-export([start_link/0]).
-export([init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init(_) ->
  RestartStrategy = one_for_one,
  MaxRestarts = 3,
  MaxSecondsBetweenRestarts = 30,

  SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

  Restart = permanent,
  Shutdown = infinity,
  Type = worker,

  MnesiaSpecifications = {mnesiaServerId, {database_server, start_link(), []}, Restart, Shutdown, Type, [database_server]},

  {ok, {SupFlags, [MnesiaSpecifications]}}.
```

Database Client:

```
-module(database_client).
-author("natashamittal").
-export([storeMessage/2,getMessage/1,getMessageAndTimestamp/1,deleteMessage/1]).

storeMessage(NodeName, Message) ->
  database_server:store(NodeName,Message).

getMessage(NodeName) ->
  database_server:getDBMsg(NodeName).

getMessageAndTimestamp(NodeName) ->
  database_server:getDBMsgAndTime(NodeName).

deleteMessage(NodeName) ->
  database_server:delete(NodeName).
```

Now, let's look at the execution:

```
Eshell V6.4.1.7  (abort with ^G)
1> application:which_applications().
[{stdlib,"ERTS  CXC 138 10","2.4"}, 
 {kernel,"ERTS  CXC 138 10","3.2.0.1"}]
2> database_application:start().
{global,database_supervisor} <0.37.0> starting...
{global,database_server} <0.38.0> starting....
{global,database_client} <0.39.0> starting.....
ok
3> application:which_applications().
[{database_application,"Database for storing and deleting Node Messages"},
 {mnesia,"MNESIA  CXC 138 12","4.8"},
 {stdlib,"ERTS  CXC 138 10","2.4"},
 {kernel,"ERTS  CXC 138 10","3.2.0.1"}]
 4> database_client:storeMessage(node(),"Hi, How are you?").
 Comment has been saved for nonode@nohost.
 ok
 5> database_client:storeMessage(node(),"What are you doing?").
 Comment has been saved for nonode@nohost.
 ok
 6> database_client:getMessage(node()).
 Received: "Hi, How are you?"
 Received: "What are you doing?"
 ok
 7> database_client:getMessageAndTimestamp(node()).
 Received: "Hi, How are you?" Created on: {2018,12,5}
 Received: "What are you doing?" Created on: {2018,12,5}
 ok
 8> database_client:deleteMessage(node()).
 Data deleted for: nonode@nohost
 ok
```
