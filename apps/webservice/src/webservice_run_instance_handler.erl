-module(webservice_run_instance_handler).
-compile(export_all).

-import(json_eep, [json_to_term/1, term_to_json/1]).

init({_Any, http}, _Req, _) ->
    {upgrade, protocol, cowboy_http_rest}.

known_methods(Req, State) ->
    {['GET', 'POST', 'DELETE'], Req, State}.

allowed_methods(Req, State) ->
    {['GET', 'POST', 'DELETE'], Req, State}.

content_types_provided(Req, State) ->
    {[{{<<"application">>, <<"json">>, []}, json_response}],
     Req, State}.

json_response(Req, State) ->
    {ProblemIDBin, Req2} = cowboy_http_req:binding(problem_id, Req),
    ProblemID = list_to_integer(binary_to_list(ProblemIDBin)),
    {RunIDBin, Req3} = cowboy_http_req:binding(run_id, Req2),
    RunID = list_to_integer(binary_to_list(RunIDBin)),
    case get_run(ProblemID, RunID) of
        {ok, RespBody} ->
            {RespBody, Req3, State};
        _ ->
            {ok, Req4} = cowboy_http_req:reply(404, Req3),
            {halt, Req4, State}
    end.

get_run(_ProblemID, RunID) when (RunID==302) ->
    {ok,
     term_to_json({[{id, RunID},
                    {tests, [{[{id, 102}, {status, <<"OK">>}]},
                             {[{id, 103}, {status, <<"ME">>}]}
                            ]}]})};
get_run(_ProblemID, RunID) ->
    {error, badarg}.

post_is_create(Req, State) ->
    {false, Req, State}.

process_post(Req, State) ->
    case cowboy_http_req:body(Req) of
        {ok, Body, Req2} ->
            case (catch json_to_term(binary_to_list(Body))) of
                {[{<<"recheck">>, {[{<<"notify">>, NotifyURL}]}}]} ->
                    process_recheck(NotifyURL, Req, State);
                _ ->
                    {ok, Req3} = cowboy_http_req:reply(400, Req2),
                    {halt, Req3, State}
            end;
        {error, _} ->
            {ok, Req2} = cowboy_http_req:reply(400, Req),
            {halt, Req2, State}
    end.

process_recheck(_NotifyURL, Req, State) ->
    {ProblemIDBin, Req2} = cowboy_http_req:binding(problem_id, Req),
    {RunIDBin, Req3} = cowboy_http_req:binding(run_id, Req2),
    ProblemID = list_to_integer(binary_to_list(ProblemIDBin)),
    RunID = list_to_integer(binary_to_list(RunIDBin)),
    %% TODO STUB db stuff etc
    {ok, JSONRun} = webservice_run_instance_handler:get_run(ProblemID, RunID),
    {ok, Req4}= cowboy_http_req:set_resp_body(JSONRun, Req3),
    {ok, Req5} = cowboy_http_req:reply(202, Req4),
    {halt, Req5, State}.

delete_resource(Req, State) ->
    %% TODO begin deleting
    {true, Req, State}.

delete_completed(Req, State) ->
    %% TODO block until deleted or return false (->http 202) if it will be deleted asynchronously
    {true, Req, State}.

terminate(_Req, _State) ->
    ok.
