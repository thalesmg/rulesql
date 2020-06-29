-module(rulesql_tests).

-include_lib("eunit/include/eunit.hrl").

-include("sql_lex.hrl").

-compile(export_all).
-compile(nowarn_export_all).

keyword_1_test() ->
    [?assert(rulesql:is_reserved(Key)) || Key <- ?RESERVED_KEYS].

select_test_() ->
    [
        %% basic select
        ?_assertMatch(
            {ok,{select,
                    [{fields,['*']},
                     {from,[<<"abc">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT * FROM \"abc\"">>)),

        %% select caluse with a single variable
        ?_assertMatch(
            {ok,{select,
                    [{fields,[{var, <<"x">>}]},
                     {from,[<<"abc">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT x FROM abc">>)),

        %% select caluse with a single const
        ?_assertMatch(
            {ok,{select,
                    [{fields,[{const, <<"x">>}]},
                     {from,[<<"abc">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT 'x' FROM abc">>)),

        %% select caluse with some variables
        ?_assertMatch(
            {ok,{select,
                    [{fields,[{var, <<"x">>}, {var, <<"y">>}]},
                     {from,[<<"abc">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT x,y FROM abc">>)),

        %% select caluse with both '*' and variables
        ?_assertMatch(
            {ok,{select,
                    [{fields,[{var, <<"x">>}, {var, <<"y">>}, '*']},
                     {from,[<<"abc">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT x,y,* FROM abc">>)),

        %% multiple variables will keep the order
        ?_assertMatch(
            {ok,{select,
                    [{fields,[{var, <<"x">>}, '*', {var, <<"y">>}]},
                     {from,[<<"abc">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT x,*,y FROM abc">>))
    ].

vars_and_consts_test_() ->
    [
        %% identifiers without single quotes are vars
        ?_assertMatch(
            {ok,{select,
                    [{fields,[{'=', {var, <<"a">>}, {var, <<"b">>}}]},
                     {from,[<<"abc">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT a = b FROM abc">>)),

        %% identifiers wrapped by single quotes are consts
        ?_assertMatch(
            {ok,{select,
                    [{fields,[{'=', {var, <<"a">>}, {const, <<"b">>}}]},
                     {from,[<<"abc">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT a = 'b' FROM abc">>)),

        %% numbers without single quotes are consts
        ?_assertMatch(
            {ok,{select,
                    [{fields,[{'=', {const, 1}, {const, 1.1}}]},
                     {from,[<<"abc">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT 1 = 1.1 FROM abc">>)),

        %% numbers wrapped by single quotes are strings
        ?_assertMatch(
            {ok,{select,
                    [{fields,[{'=', {const, <<"1">>}, {const, <<"1.1">>}}]},
                     {from,[<<"abc">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT '1' = '1.1' FROM abc">>))
    ].

maps_get_test_() ->
    [].

maps_put_test_() ->
    [].

array_index_get_() ->
    [].

array_index_put_() ->
    [].

as_test_() ->
    [
        %% basic as
        ?_assertMatch(
            {ok,{select,
                    [{fields,[{as, {var, <<"a">>}, {var, <<"b">>}}]},
                     {from,[<<"abc">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT a as b FROM \"abc\"">>)),

        %% as clause can be used along with the ordinary varibales
        ?_assertMatch(
            {ok,{select,
                    [{fields,[{as, {var, <<"a">>}, {var, <<"b">>}}, {var, <<"x">>, '*'}]},
                     {from,[<<"abc">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT a as b, x, * FROM \"abc\"">>))
    ].

from_test_() ->
    [
        %% from clause without double quotes is allowed
        ?_assertMatch(
            {ok,{select,
                    [{fields,['*']},
                     {from,[<<"abc">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT * FROM abc">>)),

        %% from clause with single quotes is not allowed
        ?_assertMatch(
            {parse_error, _},
            rulesql:parsetree(<<"SELECT * FROM 'abc'">>)),

        %% from clause with more than one event is allowed
        ?_assertMatch(
            {ok,{select,
                    [{fields,['*']},
                     {from,[<<"abc">>,<<"e">>,<<"f">>,<<"g">>]},
                     {where,{}}]}},
            rulesql:parsetree(<<"SELECT * FROM abc, e, f, g">>)),

        %% from clause events should be separated by commas.
        ?_assertMatch(
            {parse_error, _},
            rulesql:parsetree(<<"SELECT * FROM abc ec">>))
    ].

where_test_() ->
    [
        %% basic where
        ?_assertMatch(
            {ok,{select,
                    [{fields,['*']},
                     {from,[<<"abc">>]},
                     {where,{'=', {const, 1}, {const, 1}}}]}},
            rulesql:parsetree(<<"SELECT * FROM \"abc\" WHERE 1 = 1">>)),

        %% where clause with conditions
        ?_assertMatch(
            {ok,{select,
                    [{fields,['*']},
                     {from,[<<"abc">>]},
                     {where,
                        {'and', {'=', {const, 1}, {const, 1}},
                                {'<', {var, a}, {const, 2}}}}
                    ]}},
            rulesql:parsetree(<<"SELECT * FROM \"abc\" "
                                "WHERE 1 = 1 and a < 2"
                              >>)),

        %% where clause with multiple conditions has associativity
        ?_assertMatch(
            {ok,{select,
                    [{fields,['*']},
                     {from,[<<"abc">>]},
                     {where,
                        {'or',
                            {'and', {'=', {const, 1}, {const, 1}},
                                    {'<', {var, a}, {const, 2}}},
                            {'!=', {const, 3}, {const, 3}}}}
                    ]}},
            rulesql:parsetree(<<"SELECT * FROM \"abc\" "
                                "WHERE 1 = 1 and a < 2 or 3 != 3"
                              >>)),

        %% force conditions priority using '()'
        ?_assertMatch(
            {ok,{select,
                    [{fields,['*']},
                     {from,[<<"abc">>]},
                     {where,
                        {'and',
                            {'=', {const, 1}, {const, 1}},
                            {'or', {'<', {var, a}, {const, 2}},
                                   {'!=', {const, 3}, {const, 3} }}
                        }}
                    ]}},
            rulesql:parsetree(<<"SELECT * FROM \"abc\" "
                                "WHERE 1 = 1 and (a < 2 or 3 != 3)"
                              >>))
    ].

case_when_test_() ->
    [].

foreach_test_() ->
    [].

foreach_do_test_() ->
    [].

foreach_do_incase_test_() ->
    [].
