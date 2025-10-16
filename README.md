erl_distrib_systems
=====

Notes on distributed systems in Erlang

Build
```sh
rebar3 compile
```

## Paxos

```shell
rebar shell
```
```erlang
paxos:start().
```

Papers:
* [The Part-Time Parliament](https://lamport.azurewebsites.net/pubs/pubs.html#lamport-paxos) by Leslie Lamport
* [Paxos Made Simple](https://lamport.azurewebsites.net/pubs/pubs.html#paxos-simple) by Leslie Lamport

```mermaid
sequenceDiagram
  participant p1 as Proposer1
  participant a1 as Acceptor1
  participant a2 as Acceptor2
  participant l1 as Learner1
  participant l2 as Learner2

  Note over p1, l2: Paxos phase 1
  
  p1->>a1: propose(5)
  p1->>a2: propose(5)
  
  a1->>p1: promise(5)
  a2->>p1: promise(5)

  Note over p1, a2: Majority(acceptors) promise - ignore msg < 5
  Note over p1, l2: Paxos phase 2 
    
  p1->>a1: accept(5,42)
  Note right of a1: Consensus reached
  p1->>a2: accept(5,42)
  Note right of a2: Consensus reached
    
  a1->>p1: accepted(5,42)
  a2->>p1: accepted(5,42)
  a1->>l1: accepted(5,42)
  a1->>l2: accepted(5,42)
  
  Note over l1, l2: Learners notified about consensus
```
