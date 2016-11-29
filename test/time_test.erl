%%%-------------------------------------------------------------------
%%% @author Sölvi Páll Ásgeirsson <solvip@gmail.com>
%%% @copyright (C) 2016, Sölvi Páll Ásgeirsson
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%
%%%-------------------------------------------------------------------
-module(time_test).

-include_lib("eunit/include/eunit.hrl").
-include_lib("time/src/internal.hrl").

now_test() ->
    Now = time:utc(),
    ?assertEqual('UTC', time:timezone(Now)).

clock_test() ->
    Time = #time{nsec=1480369160677666116, tz='UTC'},
    Expected = {21, 39, 20},
    ?assertEqual(Expected, time:clock(Time)).
    

to_datetime_test() ->
    TimeUTC = #time{nsec=1480369160677666116, tz='UTC'},
    ExpectedUTC = {{2016, 11, 28}, {21, 39, 20}},
    ?assertEqual(ExpectedUTC, time:to_datetime(TimeUTC)),
    
    TimeCET = #time{nsec=1480369160677666116, tz='CET'},
    ExpectedCET = {{2016, 11, 28}, {22, 39, 20}},
    ?assertEqual(ExpectedCET, time:to_datetime(TimeCET)),
    
    TimeEEST = #time{nsec=1480369160677666116, tz='EEST'},
    ExpectedEEST = {{2016, 11, 29}, {01, 39, 20}},
    ?assertEqual(ExpectedEEST, time:to_datetime(TimeEEST)).


date_test() ->
    TimeUTC = #time{nsec=1480369160677666116, tz='UTC'},
    ?assertEqual({2016, 11, 28}, time:date(TimeUTC)).
