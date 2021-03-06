-module(metric_coverage).

-behaviour(riak_core_coverage_fsm).

-export([
         init/2,
         process_results/2,
         finish/2,
         start/1
        ]).

-ignore_xref([
         start/1
        ]).


-record(state, {replies, r, reqid, from}).

start(Request) ->
    ReqID = mk_reqid(),
    metric_coverage_sup:start_coverage(
      ?MODULE, {self(), ReqID, something_else},
      Request),
    receive
        ok ->
            ok;
        {ok, Result} ->
            {ok, Result}
    after 10000 ->
            {error, timeout}
    end.

%% The first is the vnode service used
init({From, ReqID, _}, Request) ->
    {ok, NVal} = application:get_env(dalmatiner_db, n),
    {ok, R} = application:get_env(dalmatiner_db, r),
    %% all - full coverage; allup - partial coverage
    VNodeSelector = allup,
    %% Same as R value here, TODO: Make this dynamic
    PrimaryVNodeCoverage = R,
    %% We timeout after 5s
    Timeout = 5000,
    State = #state{replies = gb_sets:new(), r = R,
                   from = From, reqid = ReqID},
    {Request, VNodeSelector, NVal, PrimaryVNodeCoverage,
     metric, metric_vnode_master, Timeout, State}.

process_results({ok, _ReqID, _IdxNode, Metrics},
                State = #state{replies = Replies}) ->
    Replies1 = gb_sets:union(Replies, Metrics),
    {done, State#state{replies = Replies1}};

process_results(Result, State) ->
    lager:error("Unknown process results call: ~p ~p", [Result, State]),
    {done, State}.

finish(clean, State = #state{replies = Replies,
                             from = From}) ->
    From ! {ok, gb_sets:to_list(Replies)},
    {stop, normal, State};

finish(How, State) ->
    lager:error("Unknown process results call: ~p ~p", [How, State]),
    {error, failed}.

%%%===================================================================
%%% Internal Functions
%%%===================================================================

mk_reqid() ->
    {MegaSecs,Secs,MicroSecs} = erlang:now(),
    (MegaSecs*1000000 + Secs)*1000000 + MicroSecs.
