-module(paxos).
-export([start/0, proposer/4, acceptor/1, learner/0]).
-define(AcceptorsNo, 3).

% TODO logging actor that will output in format that can be shown by mermaid

 % Security flaw - spawn malicious majority + 1 nodes that sends bogus prepare, promise, etc

%   every proposer gen(N mod ProposerN) values, and increments

majority(N) -> N div 2 + 1.

proposer(ProposeNo, ProposeNoBase, PromiseCount, V) ->
  io:format("=== Node proposer listening ... ~w ~n", [self()]),

  receive
    {start, V2} ->
      io:format("=== Node proposer receive start [value ~w]~n", [V2]),
      PN =   ProposeNo + ProposeNoBase,

      % ==== Paxos phase 1 ====
      io:format("=== Paxos phase 1 === ~n", []),
      %  send prepare(ProposalNumber) message to majority of acceptors
      %  shuffle list and pick first majority(N)
      a1 ! {prepare, PN}, % TODO loop over acceptors
      a2 ! {prepare, PN},
      proposer(PN, ProposeNoBase, PromiseCount, V2);

    {promise, Pn} ->
      io:format("=== Node proposer receive promise [promise number ~w] ~n", [Pn]),
      % ignores when Pn is from previous voting
      % TODO ignore next promise N from acceptor with this Pid - can test this?
      Pc = PromiseCount + 1, % generate increasing, unique values
      % get responses from majority of acceptors
      case Pc >= majority(?AcceptorsNo) of
        true ->
          % ==== Paxos phase 2 ====
          io:format("=== Paxos phase 2 === ~n", []),
          a1 ! {accept, Pn, V},
          a2 ! {accept, Pn, V},
          proposer(ProposeNo, ProposeNoBase, Pc, V);
        false -> proposer(ProposeNo, ProposeNoBase, Pc, V)
      end;
    {accepted, Pn, V} ->
      io:format("=== Node proposer receive accepted ~w ~w TODO~n", [Pn, V]),
      ok; % TODO handle
    done ->
      ok;
    Unhandled -> 
      io:format("!!!! Node proposer receive UNHANDLED message ~w ~n", [Unhandled])
    
  end.
    
  % TODO handle next round if consensus was not reached

acceptor(IgnorePn) ->
  io:format("=== Node acceptor listening ... [~w] ~n", [self()]),
  receive
    {prepare, Pn} when Pn =< IgnorePn ->
       io:format("=== Node proposer receive prepare - ignore ~n", []),
       acceptor(IgnorePn);
    {prepare, Pn} when Pn > IgnorePn ->
      io:format("=== Node proposer receive prepare - send promise ~n", []),
      p1 ! {promise, Pn},
      acceptor(Pn);
    {accept, Pn, _} when Pn < IgnorePn ->
       io:format("=== Node proposer receive accept - ignore ~n", []),
       acceptor(IgnorePn);
    {accept, Pn, V} when Pn >= IgnorePn ->
      io:format("=== Node proposer receive accept - send accepted ~n", []),
      % probably need to check if reached consensus
      l1 ! {accepted, Pn, V},
      l2 ! {accepted, Pn, V},
      acceptor(IgnorePn);
    done ->
      ok;
    Unhandled -> 
      io:format("!!!! Node proposer receive UNHANDLED message ~w ~n", [Unhandled])
      
  end.

learner() ->
  io:format("=== Node learner listening ... [~w] ~n", [self()]),  
  receive
    {accepted, Pn, V} ->
      io:format("=== Node learner receive accepted ~w ~w ~n", [Pn, V]),
      learner();
    done -> ok;
    Unhandled -> 
      io:format("!!!! Node proposer receive UNHANDLED message ~w ~n", [Unhandled])
  end.

start() ->
  io:format("Starting paxos ~n", []),
  IgnoreNothing = 0,
  ValueToAgree = 42,
  FirstProposeValue = 1,
  ProposeStep = 1,

  register(p1, spawn(paxos, proposer, [FirstProposeValue, ProposeStep, 0, ValueToAgree])),
  io:format("Registered proposer ~w ~n", [whereis(p1)]),
  
  register(a1, spawn(paxos, acceptor, [IgnoreNothing])), % TODO loop
  io:format("Registered acceptor ~w as ~w ~n", [a1, whereis(a1)]),
  register(a2, spawn(paxos, acceptor, [IgnoreNothing])),
  io:format("Registered acceptor ~w as ~w ~n", [a2, whereis(a2)]),
  register(a3, spawn(paxos, acceptor, [IgnoreNothing])),
  io:format("Registered acceptor ~w as ~w ~n", [a3, whereis(a3)]),

  register(l1, spawn(paxos, learner, [])), % TODO loop
  io:format("Registered lerner ~w as ~w ~n", [l1, whereis(l1)]),
  register(l2, self()),
  io:format("Registered lerner ~w as ~w ~n", [l2, whereis(l2)]),

  p1 ! {start, ValueToAgree},

  % TODO 1 more message to start voting, so system is properly started before voting  
  % shutdown
  receive
    {accepted, Pn, V} ->
      io:format("Learned at round ~w value ~w ~n", [Pn, V]),
      shutdown()
  end.
  

shutdown() ->
  io:format("=== Paxos ends - killing nodes === ~n", []),
  p1 ! done,
  
  a1 ! done,
  a2 ! done,
  a3 ! done,
  
  l1 ! done
  .

