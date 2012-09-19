%%======================================================================
%%
%% Leo Manager
%%
%% Copyright (c) 2012 Rakuten, Inc.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% ---------------------------------------------------------------------
%% LeoFS Manager - JSON Formatter
%% @doc
%% @end
%%======================================================================
-module(leo_manager_formatter_json).

-author('Yosuke Hara').

-include("leo_manager.hrl").
-include_lib("leo_commons/include/leo_commons.hrl").
-include_lib("leo_redundant_manager/include/leo_redundant_manager.hrl").
-include_lib("leo_object_storage/include/leo_object_storage.hrl").
-include_lib("eunit/include/eunit.hrl").


-export([ok/0, error/1, error/2, help/0, version/1,
         bad_nodes/1, system_info_and_nodes_stat/1, node_stat/1,
         du/2, s3_keys/2, endpoints/1, buckets/1,
         whereis/1, histories/1
        ]).

-define(output_ok(),           gen_json({[{result, <<"OK">>}]})).
-define(output_error_1(Cause), gen_json({[{error, list_to_binary(Cause)}]})).


%% @doc Format 'ok'
%%
-spec(ok() ->
             string()).
ok() ->
    gen_json({[{result, <<"OK">>}]}).


%% @doc Format 'error'
%%
-spec(error(string()) ->
             string()).
error(Cause) ->
    gen_json({[{error, list_to_binary(Cause)}]}).


%% @doc Format 'error'
%%
-spec(error(atom(), string()) ->
             string()).
error(Node, Cause) ->
    gen_json({[{error,
                {[{<<"node">>,  list_to_binary(atom_to_list(Node))},
                  {<<"cause">>, list_to_binary(Cause)}]}
               }]}).


%% @doc Format 'help'
%%
-spec(help() ->
             string()).
help() ->
    [].


%% Format 'version'
%%
-spec(version(string()) ->
             string()).
version(Version) ->
    gen_json({[{result, list_to_binary(Version)}]}).


%% @doc Format 'bad nodes'
%%
-spec(bad_nodes(list()) ->
             string()).
bad_nodes(BadNodes) ->
    Cause = lists:foldl(fun(Node, [] ) ->        io_lib:format("~w",  [Node]);
                           (Node, Acc) -> Acc ++ io_lib:format(",~w", [Node])
                        end, [], BadNodes),
    ?MODULE:error(Cause).


%% @doc Format a cluster-node list
%% @private
-spec(system_info_and_nodes_stat(list()) ->
             string()).
system_info_and_nodes_stat(Props) ->
    SystemConf = leo_misc:get_value('system_config', Props),
    Version    = leo_misc:get_value('version',       Props),
    [RH0, RH1] = leo_misc:get_value('ring_hash',     Props),
    Nodes      = leo_misc:get_value('nodes',         Props),

    NodeInfo = case Nodes of
                   [] -> [];
                   _  ->
                       lists:map(
                         fun({Type, NodeName, NodeState, RingHash0, RingHash1, When}) ->
                                 NewRingHash0 = case is_integer(RingHash0) of
                                                    true  -> integer_to_list(RingHash0);
                                                    false -> RingHash0
                                                end,
                                 NewRingHash1 = case is_integer(RingHash1) of
                                                    true  -> integer_to_list(RingHash1);
                                                    false -> RingHash1
                                                end,
                                 {[{<<"type">>,      list_to_binary(Type)},
                                   {<<"node">>,      list_to_binary(NodeName)},
                                   {<<"state">>,     list_to_binary(NodeState)},
                                   {<<"ring_cur">>,  list_to_binary(NewRingHash0)},
                                   {<<"ring_prev">>, list_to_binary(NewRingHash1)},
                                   {<<"when">>,      list_to_binary(leo_date:date_format(When))}
                                  ]}
                         end, Nodes)
               end,

    gen_json({[{<<"system_info">>,
                {[{<<"version">>,        list_to_binary(Version)},
                  {<<"n">>,              list_to_binary(integer_to_list(SystemConf#system_conf.n))},
                  {<<"r">>,              list_to_binary(integer_to_list(SystemConf#system_conf.r))},
                  {<<"w">>,              list_to_binary(integer_to_list(SystemConf#system_conf.w))},
                  {<<"d">>,              list_to_binary(integer_to_list(SystemConf#system_conf.d))},
                  {<<"ring_size">>,      list_to_binary(integer_to_list(SystemConf#system_conf.bit_of_ring))},
                  {<<"ring_hash_cur">>,  list_to_binary(integer_to_list(RH0))},
                  {<<"ring_hash_prev">>, list_to_binary(integer_to_list(RH1))}
                 ]}},
               {<<"node_list">>, NodeInfo}
              ]}).


%% @doc Format a cluster node state
%% @private
-spec(node_stat(#cluster_node_status{}) ->
             string()).
node_stat(_) ->
    [].



%% @doc Format storage stats
%%
-spec(du(summary | detail, {integer(), integer()} | list()) ->
             string()).
du(summary, {FileSize, Total}) ->
    gen_json({[{<<"file_size">>, FileSize},{<<"total_of_objects">>, Total}]});

du(detail, StatsList) when is_list(StatsList) ->
    JSON = lists:map(fun({ok, #storage_stats{file_path   = FilePath,
                                             total_sizes = FileSize,
                                             total_num   = ObjTotal}}) ->
                             {[{<<"file_path">>,        list_to_binary(FilePath)},
                               {<<"file_size">>,        FileSize},
                               {<<"total_of_objects">>, ObjTotal}
                              ]};
                        (_) ->
                             []
                     end, StatsList),
    gen_json(JSON);
du(_, _) ->
    gen_json([]).


%% @TODO
%% @doc Format s3-gen-key result
%%
-spec(s3_keys(string(), string()) ->
             string()).
s3_keys(_,_) ->
    [].


%% @TODO
%% @doc Format a endpoint list
%% @private
-spec(endpoints(list(tuple())) ->
             string()).
endpoints(_) ->
    [].


%% @TODO
%% @doc Format a bucket list
%% @private
-spec(buckets(list(tuple())) ->
             string()).
buckets(_) ->
    [].


%% @TODO
%% @doc Format an assigned file
%% @private
-spec(whereis(list()) ->
             string()).
whereis(_) ->
    [].


%% @TODO
%% @doc Format a history list
%% @private
-spec(histories(list(#history{})) ->
             string()).
histories(_) ->
    [].


%%----------------------------------------------------------------------
%% Inner function(s)
%%----------------------------------------------------------------------
%% @doc Generate a JSON-format doc
%%
-spec(gen_json(list()) ->
             binary()).
gen_json(JSON) ->
    case catch jiffy:encode(JSON) of
        {'EXIT', _} ->
            [];
        Result ->
            <<Result/binary, ?CRLF>>
    end.
