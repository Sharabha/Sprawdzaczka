-module(webservice_problem_instance_handler).
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

json_response(Req, State) ->
    %% TODO STUB check db
    case cowboy_http_req:binding(problem_id, Req) of
        {<<"999">>, Req2} ->
            {term_to_json(
               {[{id, 999}]}
              ), Req2, State};
        {<<"777">>, Req2} ->
            {term_to_json(
               {[{id, 777},
                 {tests, [101, 102]}]}
              ), Req2, State};
        {_, Req2} ->
            {ok, Req3} = cowboy_http_req:reply(404, Req2),
            {halt, Req3, State}
    end.

post_is_create(Req, State) ->
    {false, Req, State}.

process_post(Req, State) ->
    case cowboy_http_req:body(Req) of
        {ok, Body, Req2} ->
            case (catch json_to_term(binary_to_list(Body))) of
                {[{<<"test">>, Test}]} ->
                    process_add_test(Test, Req, State);
                {[{<<"run">>, Run}]} ->
                    process_add_run(Run, Req, State);
                _ ->
                    {ok, Req3} = cowboy_http_req:reply(400, Req2),
                    {halt, Req3, State}
            end;
        {error, _} ->
            {ok, Req2} = cowboy_http_req:reply(400, Req),
            {halt, Req2, State}
    end.

process_add_test({Test}, Req, State) ->
    _SolutionInput = proplists:get_value(solution_input, Test),
    _CheckerInput  = proplists:get_value(checker_input, Test),
    _TimeLimit = proplists:get_value(time_limit, Test), 
    _MemoryLimit  = proplists:get_value(memory_limit, Test),
    {ProblemID, Req2} = cowboy_http_req:binding(problem_id, Req),
    %% TODO STUB db stuff etc
    NewTestID = 102,
    {ok, Req3} = cowboy_http_req:set_resp_header('Location', [<<"/problem/", ProblemID/binary, "/test/">>, integer_to_list(NewTestID)], Req2),
    {ok, JSONTest} = webservice_test_instance_handler:get_test(ProblemID, NewTestID),
    {ok, Req4}= cowboy_http_req:set_resp_body(JSONTest, Req3),
    {true, Req4, State}.
    
process_add_run({Run}, Req, State) ->
    _Language = proplists:get_value(language, Run),
    _Solution = proplists:get_value(solution, Run),
    _Notify   = proplists:get_value(notify, Run),
    {ProblemID, Req2} = cowboy_http_req:binding(problem_id, Req),
    %% TODO STUB db stuff etc
    NewRunID = 302,
    {ok, Req3} = cowboy_http_req:set_resp_header('Location', [<<"/problem/", ProblemID/binary, "/run/">>, integer_to_list(NewRunID)], Req2),
    {ok, JSONRun} = webservice_run_instance_handler:get_run(ProblemID, NewRunID),
    {ok, Req4}= cowboy_http_req:set_resp_body(JSONRun, Req3),
    {true, Req4, State}.

terminate(_Req, _State) ->
    ok.
