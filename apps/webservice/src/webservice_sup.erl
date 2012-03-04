-module(webservice_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link(?MODULE, []).

init(_Args) ->
    {ok, {{one_for_one, 1, 60}, []}}.
