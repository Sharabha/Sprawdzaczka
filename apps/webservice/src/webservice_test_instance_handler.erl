-module(webservice_test_instance_handler).
-compile(export_all).

-import(json_eep, [json_to_term/1, term_to_json/1]).

init({_Any, http}, _Req, _) ->
    {upgrade, protocol, cowboy_http_rest}.

known_methods(Req, State) ->
    {['GET', 'DELETE'], Req, State}.

allowed_methods(Req, State) ->
    {['GET', 'DELETE'], Req, State}.

content_types_provided(Req, State) ->
    {[{{<<"application">>, <<"json">>, []}, json_response}],
     Req, State}.

json_response(Req, State) ->
    {ProblemIDBin, Req2} = cowboy_http_req:binding(problem_id, Req),
    ProblemID = list_to_integer(binary_to_list(ProblemIDBin)),
    {TestIDBin, Req3} = cowboy_http_req:binding(test_id, Req2),
    TestID = list_to_integer(binary_to_list(TestIDBin)),
    %% TODO STUB check db
    case get_test(ProblemID, TestID) of
        {ok, RespBody} ->
            {RespBody, Req3, State};
        _ ->
            {ok, Req4} = cowboy_http_req:reply(404, Req3),
            {halt, Req4, State}
    end.

get_test(_ProblemID, TestID) when (TestID==101) or (TestID==102) or (TestID==302)->
    {ok,
     term_to_json({[{id, TestID},
                    {solution_input, <<"...">>},
                    {checker_input, <<"...">>},
                    {time_limit, 1230},
                    {memory_limit, 1230}]})
    };
get_test(_ProblemID, _TestID) ->
    {error, badarg}.

delete_resource(Req, State) ->
    %% TODO begin deleting
    {true, Req, State}.

delete_completed(Req, State) ->
    %% TODO block until deleted or return false (->http 202) if it will be deleted asynchronously
    {true, Req, State}.

terminate(_Req, _State) ->
    ok.
