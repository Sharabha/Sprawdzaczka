-module(webservice).
-behaviour(application).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-export([start/0, stop/0, start/2, stop/1]).

start() ->
    application:start(cowboy),
    ok = application:start(webservice).

stop() ->
    ok = application:stop(webservice).

start(_Type, _Args) ->
    Dispatch = [
                {'_', [{[<<"problem">>], webservice_problem_handler, []},
                       {[<<"problem">>, problem_id], webservice_problem_instance_handler, []},
                       {[<<"problem">>, problem_id, <<"test">>, test_id], webservice_test_instance_handler, []},
                       {[<<"problem">>, problem_id, <<"run">>, run_id], webservice_run_instance_handler, []}
                      ]}
               ],

    cowboy:start_listener(my_http_listener, 100,
                          cowboy_tcp_transport, [{port, 8080}],
                          cowboy_http_protocol, [{dispatch, Dispatch}]
                         ),
    
    webservice_sup:start_link().

stop(_State) ->
    ok.

-ifdef(TEST).
application_start_test_() ->
    {setup,
     fun () -> ok end,
     fun (_) -> stop() end,
     ?_assert(ok =:= ?MODULE:start())}.

application_stop_test_() ->
    {setup,
     fun () -> start() end,
     {inorder, [?_assert(ok =:= stop()),
                ?_assertError({badmatch, _}, stop())]}}.

-endif.
