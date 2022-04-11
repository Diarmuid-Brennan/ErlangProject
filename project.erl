%%%-------------------------------------------------------------------
%%% @author Diarmuid Brennan <liuxvm@liuxvm-VirtualBox>
%%% @copyright (C) 2022, liuxvm
%%% @doc
%%% Erlang project - Create a set of distributed communicating processes that communicate using the RIP protocol and compute primes
%%% @end
%%% Created :  1 Mar 2022 by liuxvm <liuxvm@liuxvm-VirtualBox>
%%%-------------------------------------------------------------------
-module(project).
-export([launchNode/1,replyServer/3,start/0,rpc/2,isPrime/1,isPrime/2,computePrime/1,start1/0,connectNodes/4,createRoutingTable/1,updateRoutingTables/1]).


% start function - contains a loop
% - creates a number of nodes(replyServer processes) passing in the process nickname and returns the PID
% - connects each node to its nearest neighbours
% - creates initial routing table for each node containing the nearest neighbours
% - begins the process of each node updating the routing table of its nearest neighbour by passsing in the first node
start()->
    A=launchNode(a),
    B=launchNode(b),
    C=launchNode(c),
    D=launchNode(d),
    E=launchNode(e),
    F=launchNode(f),
    connectNodes(a,A,b,B),
    connectNodes(a,A,c,C),
    connectNodes(b,B,d,D),
    connectNodes(b,B,e,E),
    connectNodes(c,C,e,E),
    connectNodes(e,E,f,F),
    createRoutingTable(A),
    createRoutingTable(B),
    createRoutingTable(C),
    createRoutingTable(D),
    createRoutingTable(E),
    createRoutingTable(F),
    updateRoutingTables(A).

% start1 function - does not contain a loop
% - creates a number of nodes (replyServer processes) passing in the process nickname and returns the PID
% - connects each node to its nearest neighbours
% - creates initial routing table for each node containing the nearest neighbours
% - begins the process of each node updating the routing table of its nearest neighbour
start1()->
    A =launchNode(a),
    B= launchNode(b),
    C= launchNode(c),
    D= launchNode(d),
    connectNodes(a,A,b,B),
    connectNodes(c,C,d,D),
    connectNodes(a,A,c,C),
    createRoutingTable(A),
    createRoutingTable(B),
    createRoutingTable(C),
    createRoutingTable(D),
    updateRoutingTables(A).

% launchNode function
% creates a node process of the replyServer function
% registers the nickname of the process
% returns the PID
launchNode(Nickname)->
    Pid = spawn(fun()->replyServer([],[],Nickname) end),
    register(Nickname, Pid),
    Pid.

% createRouting function
% sends a message to PID passed to the function to create the PID's routing table
createRoutingTable(Pid)->
    Pid!{routeTable}.

% updateRouting function
% sends a message to the PID passed to the function too begin updating the PID's neighbours routing tables
updateRoutingTables(Pid)->
    Pid!{updateRouting}.

% updateRTfromneighbourlist function
% takes in
% - the receiving processes routing table
% - the sending processes routing table
% - the receiving processes nickname
% - the sending processes nickname
%
% Checks if the sending processes routing table values are contained in the recieving processes routing table
% if a value is not already in the routing table, add the value, increment the number of hops and that it can be accessed through the sending process nickname
% if the value is contained in the routing table, call the updateNUmberofhops function
updateRTfromNeighbourList(RT,[],_,_)->
    RT;
updateRTfromNeighbourList(RT,[[Nickname,_,_]|Tail],Nickname,Sender) ->
    updateRTfromNeighbourList(RT,Tail,Nickname,Sender);
updateRTfromNeighbourList(RT,[[Name,Hops,_]|Tail],Nickname,Sender) ->
    case member(Name,RT) of
        true ->
            io:format("PROCESS ~p Original ~p~n", [Nickname,RT]),
            ChangedRT = updateNumberOfHops(RT,RT,[Name,Hops,Name],Sender),
            io:format("PROCESS ~p Update ~p~n", [Nickname,ChangedRT]),
            updateRTfromNeighbourList(ChangedRT,Tail,Nickname,Sender);
        _ ->
            IntRT = [[Name,Hops+1,Sender]|RT],
            updateRTfromNeighbourList(IntRT,Tail,Nickname,Sender)
    end.


%updateNUmberofhops function
% takes in
% - the receiving processes routing table
% - a second receiving processes routing table
% - the sending processes routing table value that was contained in the receiving processses rt already
% - the sending processes nickname
%
% check if the number of hops are less than what is contained originally
% - if less update the value to contained with the new number of hops and that it can be accessed though the sending process nickname
% - else do nothing
updateNumberOfHops(RT,[],_,_)->
    RT;
updateNumberOfHops(RT,[[Name,Hops,Send]|_], [Name,NeighbourHops,_],Nickname) when NeighbourHops < Hops-1 ->
    NewRT = lists:delete([Name,Hops,Send],RT),
    NewerRT=[[Name,NeighbourHops+1,Nickname]|NewRT],
    NewerRT;
updateNumberOfHops(RT,[_|Tail], List,Nickname) ->
    updateNumberOfHops(RT, Tail,List,Nickname).


% member function
% takes in
% - a process nickname
% - a process routing table
%
% returns true if the routing table contains the process nickname
% false if it des not
member(_,[])->
    false;
member(X,[[X,_,_]|_]) ->
    true;
member(X,[_|Tail]) ->
    member(X,Tail).

% isNN function
% takes in
% - a process nickname
% - a process nearest neighbour table
%
% returns true if the nearest neighbour table contains the process nickname
% false if it des not
isNN(_,[])->
    false;
isNN(X,[{X,_}|_]) ->
    true;
isNN(X,[_|Tail]) ->
    isNN(X,Tail).


% connectNodes function
% takes in
% - a process nickname and its PID
% - a second process nickname and PID
%
% sends a message to both processes to add the other process to their nearest neighbout table
connectNodes(NicknameOne,PidOne,NicknameTwo,PidTwo)->
    PidOne!{nn,NicknameTwo,PidTwo},
    PidTwo!{nn,NicknameOne,PidOne},
    true.

% replyServer process
% takes in
% - the processes nearest neighbour table
% - the processes routing table
% - the processes nickname
% - these values hold the state of the process
%
% - handles the messages being passed to and from each of the processes
replyServer(S,RT,NicknameOfPid)->
    receive
        % updates a processes routing table from its neighbours routing tables
        {updateNNRT,NRT,SenderNickname}->
            io:format("PROCESS ~p. Sending Neighbour List ~p~n", [SenderNickname,NRT]),
            io:format("PROCESS ~p Routing table before update ~p.~n", [NicknameOfPid,RT]),
            URT=updateRTfromNeighbourList(RT,NRT,NicknameOfPid,SenderNickname),
            io:format("PROCESS ~p Routing table after update ~p~n.", [NicknameOfPid,URT]),
            if
                URT =/= RT ->
                    io:format("PROCESS ~p the RTs dont match, sending message~n", [NicknameOfPid]),
                    updateRT(S,URT,NicknameOfPid),
                    replyServer(S,URT,NicknameOfPid);
                URT =:= RT->
                    io:format("PROCESS ~p the RTs do match, do nothing~n", [NicknameOfPid]),
                    replyServer(S,URT,NicknameOfPid)

            end;
        % initialises update routing tables process
        {updateRouting}->
            updateRT(S,RT,NicknameOfPid);
        % creates a processes initial routing table
        {routeTable}->
            NewRT= createRouting(S,RT),
            replyServer(S,NewRT,NicknameOfPid);
        % displays a processes routing table
        {displayRT}->
            io:format("Routing table list ~p~n", [RT]);
        % updates a processes nearest neighbour table
        {nn,Nickname,Pid}->
            T=[{Nickname,Pid}|S],
            replyServer(T,RT,NicknameOfPid);
        % displays a processes nearest neighbour table
        {displayNeighbours}->
            io:format("Neighbour list ~p~n", [S]);
        % computeNthPrime message when number of hops gets to 15
        {computeNthPrime,_,_,_,15} ->
            io:format("Message has exceeded the number of allowed hops~n");
        % computeNthPrime when this process is the destination
        % computes the result and sends the receive message back through the apprropriate route
        {computeNthPrime,N,DestinationNickname,SenderNickname,_} when DestinationNickname =:= NicknameOfPid ->
            P=computePrime(N),
            case isNN(SenderNickname,S) of
                true ->
                    io:format("Result is ~p. Calculated by ~p. Sending result to NN ~p~n", [P,DestinationNickname,SenderNickname]),
                    SenderNickname!{receiveAnswer,N,P,SenderNickname,NicknameOfPid,0};
                _ ->
                    Neighbour = getNeighbour(RT,SenderNickname),
                    io:format("Result is ~p. Calculated by ~p. Sending result to ~p~n", [P,DestinationNickname,Neighbour]),
                    Neighbour!{receiveAnswer,N,P,SenderNickname,NicknameOfPid,0}
            end;
        % computeNthPrime when this process is not the destination
        % finds the next neighbour to pass the message onto from its routing table and sends the message on through a nearest neighbour
        {computeNthPrime,N,DestinationNickname,SenderNickname,Hops}->
            case isNN(DestinationNickname,S) of
                true ->
                    io:format("Message is passed on from  ~p ~n", [NicknameOfPid]),
                   DestinationNickname!{computeNthPrime,N,DestinationNickname,SenderNickname,Hops+1};
                _ ->
                    Neighbour = getNeighbour(RT,DestinationNickname),
                    io:format("Message is passed on from  ~p ~n", [NicknameOfPid]),
                    Neighbour!{computeNthPrime,N,DestinationNickname,SenderNickname,Hops+1}
            end;
        % receiveAnswer message when the number of hops gets to 15
        {receiveAnswer,_,_,_,15} ->
            io:format("Message has exceeded the number of allowed hops~n");
        % receiveAnswer when this process is the destination
        % displays the result sent back to the process
        {receiveAnswer,N,P,DestinationNickname,SenderNickname,_} when DestinationNickname =:= NicknameOfPid->
            io:format("hello the answer to ~p  is ~p. Sent to ~p from ~p~n",[N,P,DestinationNickname, SenderNickname]);
        % receiceAnswer when this process is not the destination
        % finds the next neighbour to pass the message onto from its routing table and sends the message on through a nearest neighbour
        {receiveAnswer,N,P,DestinationNickname,SenderNickname,Hops}->
            case isNN(DestinationNickname,S) of
                true ->
                    io:format("Received by ~p. Sending result to NN  ~p~n", [NicknameOfPid,DestinationNickname]),
                    DestinationNickname!{receiveAnswer,N,P,DestinationNickname,SenderNickname,Hops+1};
                _ ->
                    Neighbour = getNeighbour(RT,DestinationNickname),
                    io:format("Received by ~p. Sending result to  ~p~n", [NicknameOfPid,Neighbour]),
                    Neighbour!{receiveAnswer,N,P,DestinationNickname,SenderNickname,Hops+1}
            end;
         _ ->
            io:format("Wrong message sent ~n")
    end,
    replyServer(S,RT,NicknameOfPid).

% getNeighbour function
% takes in
% - a processes routing table
% - a sending processes nickname
%
% returns the process nickname of the process that is needed to connect to in order to pass the meassage to the sending processes nickname
getNeighbour([],_)->
    null;
getNeighbour([[Name,_,Neighbour]|_],Name)->
    Neighbour;
getNeighbour([_|Tail],Name) ->
    getNeighbour(Tail,Name).


% createRouting function
% takes in
% - a processes initial empty routing table
% - a processes nearest neighbour table
%
% adds the values form the nearest neighbour table to the routing table
% sets the number of hops to 1 and routes it via the nearest neighbour
createRouting([{Name,_}|[]],RT)->
    NewRT=[[Name,1,Name]|RT],
    NewRT;
createRouting([{Name,_}|Tail],RT)->
    IntRT=[[Name,1,Name]|RT],
    createRouting(Tail,IntRT).


%updateRT function
% takes in
% - a processes nearest neighbour table
% - the processes routing table
% - the processes nickname
%
% Goes though each of the processes nearest neighbours and sends a message containing the processes Routing table and the processses nickname
updateRT([{Name,_}|[]],RT,Sender) ->
    Name!{updateNNRT,RT,Sender};
updateRT([{Name,_}|Tail],RT,Sender) ->
    Name!{updateNNRT,RT,Sender},
    updateRT(Tail,RT,Sender).


% computePrime function
% takes in
% the position of the prime number to be computed
%
% Calls the computeNthPrime function
computePrime(N)->
    computeNthPrime(N,2,4).


% computeNthPrime function
% takes in
% - the position of the prime to be computed
% - the count of the number of primes gone through so far
% - the current number that is being looked at
%
% Returns the number contained at the position the prime number to be computed is contained at
% iterates through each number, incrementing the number each time, incrementing the prime number count when the number is a prime number
computeNthPrime(1,_,_)->
    io:format("1st prime number is 2~n"),
    2;
computeNthPrime(2,_,_) ->
    io:format("2nd prime number is 3 ~n"),
    3;
computeNthPrime(N,Count,CurrentNum) when N==Count ->
    io:format("the prime number at position ~p is ~p~n", [N,CurrentNum-1]),
    CurrentNum-1;
computeNthPrime(N,Count,CurrentNum) ->
    case isPrime(CurrentNum) of
        true ->
            computeNthPrime(N,Count+1,CurrentNum+1);
        _ ->
            computeNthPrime(N,Count,CurrentNum+1)
                end.

% isPrime function
% takes in
% the number to be checked if it is  prime
% calls isPrime(N,M)
isPrime(N) -> isPrime(N,2).

% takes in
% - the number to be checked if it is a prime
% - the number to check if divides evenly into the first number
%
% returns true if the number is a prime
%false otherwise
isPrime(N,N) -> true;
isPrime(N,M)->
    ChPrime = N rem M,
    if
        ChPrime == 0 -> false;
        true -> isPrime(N,M+1)
    end.

%Add RPC functionality
rpc(Pid,Message)->
    Pid!{self(),Message},
    receive
        {Pid,Reply}->
            Reply
    end.
