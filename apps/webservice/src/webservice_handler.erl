-module(webservice_handler).
-export([init/3, handle/2, terminate/2]).

init({_Any, http}, Req, _) ->
    {ok, Req, []}.
%% {upgrade, protocol, cowboy_http_rest}.

handle(Req, State) ->
    {ok, Req2} = cowboy_http_req:reply(200, [], <<"HELLO WORLD!">>, Req),
    {ok, Req2, State}.

terminate(_Req, _State) ->
    ok.
