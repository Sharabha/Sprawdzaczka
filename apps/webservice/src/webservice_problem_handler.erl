-module(webservice_problem_handler).
-compile(export_all).

-import(json_eep, [json_to_term/1, term_to_json/1]).

init({_Any, http}, _Req, _) ->
    {upgrade, protocol, cowboy_http_rest}.

known_methods(Req, State) ->
    {['GET', 'POST'], Req, State}.

allowed_methods(Req, State) ->
    {['GET', 'POST'], Req, State}.

content_types_provided(Req, State) ->
    {[{{<<"application">>, <<"json">>, []}, json_response}],
     Req, State}.

post_is_create(Req, State) ->
    {true, Req, State}.

json_response(Req, State) ->
    {term_to_json(<<"post \"create_new\" to create a new problem">>), Req, State}.

create_path(Req, State) ->
    case cowboy_http_req:body(Req) of
        {ok, Body, Req2} ->
            case (catch json_to_term(binary_to_list(Body))) of
                <<"create_new">> ->
                    %% TODO STUB create a new problem
                    %% possible alternative: do these checks in content_types_accepted callback
                    {<<"/problem/999/">>, Req2, State};
                _ ->
                    {ok, Req3} = cowboy_http_req:reply(400, Req2),
                    {halt, Req3, State}
            end;
        {error, _} ->
            {ok, Req2} = cowboy_http_req:reply(400, Req),
            {halt, Req2, State}
    end.

content_types_accepted(Req, State) ->
    {[{{<<"application">>, <<"json">>, []}, has_been_checked_before}],
     Req, State}.

has_been_checked_before(Req, State) ->
    {true, Req, State}.

terminate(_Req, _State) ->
    ok.
