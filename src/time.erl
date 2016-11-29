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

-module(time).

-include("internal.hrl").
-include_lib("eunit/include/eunit.hrl").

-type time() :: #time{}.
-opaque([ time/0 ]).

-export_type([ timezone/0 ]).

%% API exports
-export([ utc/0
	, now/1
	, timezone/1
	, to_datetime/1
	, date/1
	, clock/1
	]).

%%%===================================================================
%%% API
%%%===================================================================

%% @doc
%% Return the current time as UTC.
%% @end
-spec utc() -> time().
utc() ->
    now('UTC').

%% @doc
%% Return the timezone associated with a time
%% @end
-spec timezone(time()) -> timezone().
timezone(#time{tz=Timezone}) ->
    Timezone.

%% @doc
%% Return the current time in the given timezone
%% @end
-spec now(timezone()) -> time().
now(Timezone) ->
    #time{nsec = erlang:system_time(nano_seconds), tz = Timezone}.

%% @doc
%% Return the date in which Time occurs
%% @end
-spec date(time()) -> calendar:date().
date(T) ->
    Nsec = offset_with_timezone(T),
    {Year, NsecRemaining1} = year_count(Nsec, epoch_year()),
    {Month, NsecRemaining2} = month_count(NsecRemaining1, 1, Year),
    Day = NsecRemaining2 div nanoseconds_in_day() + 1,

    {Year, Month, Day}.

year_count(Nsec, Year) ->
    NSecInYear = days_in_year(Year) * nanoseconds_in_day(),
    case Nsec >= NSecInYear of
	true  -> year_count(Nsec-NSecInYear, Year+1);
	false -> {Year, Nsec}
    end.

month_count(Nsec, Month, Year) ->
    DayNo = Nsec /  nanoseconds_in_day(),
    case DayNo >= days_in_month(Year, Month) of
	true ->
	    NextNsec = Nsec - (days_in_month(Year, Month) * nanoseconds_in_day()),
	    month_count(NextNsec, Month+1, Year);
	false ->
	    {Month, Nsec}
    end.

%% @doc
%% Return the clock for which in Time occurs
%% @end
-spec clock(time()) -> calendar:time().
clock(T) ->
    {HH, MM, SS} = clock_frac(T),
    {HH, MM, trunc(SS)}.

%% @doc
%% Return the clock for Time, where seconds is
%% fractional.
%% @end
-spec clock_frac(time()) -> {0..24, 0..60, float()}.
clock_frac(T) ->
    Nsec = offset_with_timezone(T),
    Clock = Nsec rem nanoseconds_in_day(),
    
    SS = (Clock rem nanoseconds_in_minute()) / nanoseconds_in_seconds(),
    MM = (Clock rem nanoseconds_in_hour()) div nanoseconds_in_minute(),
    HH = Clock div nanoseconds_in_hour(),
    
    {HH, MM, SS}.

%% @doc
%% Convert a timestamp(as returned from now() or utc()) into a
%% calendar:datetime(), containing the time as defined in timezone,
%% losing all sub-second precision.
%% @equiv {date(T), clock(T)}.
%% @end
-spec to_datetime(time()) -> calendar:datetime().
to_datetime(T) ->
    %% Inspired by the implementation in this SO answer:
    %% http://stackoverflow.com/a/1692210
    {date(T), clock(T)}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
epoch_year() -> 1970.

nanoseconds_in_day() -> 86400000000000.
nanoseconds_in_hour() -> 3600000000000.
nanoseconds_in_minute() -> 60000000000.
nanoseconds_in_seconds() -> 1000000000.

%% @doc
%% Return the number of days in a year
%% @end
-spec days_in_year(integer()) -> 365 | 366.
days_in_year(Year) ->
    case leap_year(Year) of
	true  -> 366;
	false -> 365
    end.

%% @doc
%% Return true if year is a leap year; false otherwise.
%% @end
-spec leap_year(Year::integer()) -> boolean().
leap_year(Year) when (Year rem 4 /= 0) -> false;
leap_year(Year) when (Year rem 100 /= 0) -> true;
leap_year(Year) when (Year rem 400 /= 0) -> false;
leap_year(_Year) -> true.

leap_year_test() ->
    ?assertEqual(true, leap_year(1600)),
    ?assertEqual(false, leap_year(1800)),
    ?assertEqual(true, leap_year(2020)).

-spec days_in_month(Year::integer(), Month::1..12) -> 1..31.
days_in_month(_, 1) -> 31;
days_in_month(Y, 2) -> 
    case leap_year(Y) of
	true -> 29;
	false -> 28
    end;
days_in_month(_, 3) -> 31;
days_in_month(_, 4) -> 30;
days_in_month(_, 5) -> 31;
days_in_month(_, 6) -> 30;
days_in_month(_, 7) -> 31;
days_in_month(_, 8) -> 31;
days_in_month(_, 9) -> 30;
days_in_month(_, 10) -> 31;    
days_in_month(_, 11) -> 30;
days_in_month(_, 12) -> 31.
	    
-spec offset_with_timezone(#time{}) -> integer().
offset_with_timezone(#time{nsec=Nsec, tz=Tz}) ->
    Nsec + offset_for_timezone(Tz).

%% @doc
%% The offset in nanoseconds from UTC.
%% @end
offset_for_timezone('UTC') -> 0;
offset_for_timezone('CET') -> 1 * nanoseconds_in_hour();
offset_for_timezone('CEST') -> 2 * nanoseconds_in_hour();
offset_for_timezone('EEST') -> 4 * nanoseconds_in_hour().

