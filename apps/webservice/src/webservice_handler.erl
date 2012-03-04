-module(webservice_handler).
-compile(export_all).

%% $ curl -H "Accept: text/plain" http://localhost:8080/ 
%% HELLO WORLD!%
%% $ curl -H "Accept: text/html" http://localhost:8080/     
%% <html><head><title>TEST TITLE</title></head><body><h1>HELLO WORLD!</h1></body></html>%

init({_Any, http}, _Req, _) ->
    {upgrade, protocol, cowboy_http_rest}.

known_methods(Req, State) ->
    {['GET'], Req, State}.

content_types_provided(Req, State) ->
    {[{{<<"text">>, <<"plain">>, []}, to_text},
      {{<<"text">>, <<"html">>, []}, to_html}], 
     Req, State}.

to_text(Req, State) ->
    {<<"HELLO WORLD!">>, Req, State}.

to_html(Req, State) ->
    {<<"<html><head><title>TEST TITLE</title></head><body><h1>HELLO WORLD!</h1></body></html>">>, Req, State}.

terminate(_Req, _State) ->
    ok.
