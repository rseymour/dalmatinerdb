-module(dalmatiner_db_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    Port = case application:get_env(dalmatiner_db, tcp_port) of
               {ok, P} ->
                   P;
               _ ->
                   5555
           end,
    Listeners = case application:get_env(dalmatiner_db, tcp_listeners) of
                    {ok, L} ->
                        L;
                    _ ->
                        100
                end,
    {ok, _} = ranch:start_listener(dalmatiner_tcp, Listeners,
                                   ranch_tcp, [{port, Port}],
                                   dalmatiner_tcp, []),
    dalmatiner_db_sup:start_link().

stop(_State) ->
    ok.
