-module(prop_rulesql).

-include_lib("proper/include/proper.hrl").

-include("sql_lex.hrl").

prop_keywords() ->
    ?FORALL(Key, printable_bstr(),
            begin
                %io:format("---- key: ~p~n", [Key]),
                is_reserved(Key) == rulesql:is_reserved(Key)
            end).

%prop_parse_sql_with_keywords() ->
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% internal functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

printable_bstr() ->
    ?LET(L, list(range(33, 126)), list_to_binary(L)).

is_reserved(Key) ->
    lists:member(string:uppercase(Key), ?RESERVED_KEYS).
