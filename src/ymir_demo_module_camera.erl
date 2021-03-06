-module(ymir_demo_module_camera).

-behaviour(ymir_demo_module).

-include("event_state.hrl").

-export([title/0, description/0, actions/0, start/0, stop/0]).

title() -> "Camera Demo".
description() -> "Free motion camera demo.".
actions() -> [{frameStarted, fun(S) -> move(S) end}].
start() ->
     %%Generate some objects
    
     
    Light = { "Light", "light", [{"position", {20.0, 80.0, 0.0}},
                                 {"source", "point"} ]},
    Head = {"Head", "static_entity", [{"mesh", "ogrehead.mesh"}]},
    Camera = { "Camera", "camera", [{"type", "free"},
                                    {"position", {0.0, 0.0, 80.0}},
                                    {"moveSpeed", 20.0},
                                    {"rotateSpeed", 50.00},
                                    {"lookAt", {0.0, 0.0, -300.0}},
                                    {"nearClip", 5.0},
                                    {"fixYaw", true}] },

    Scene = {title(), "scene", [{"ambient", {0.5, 0.5, 0.5, 1.0}},
                                {"viewport", "Camera"},
                                {"objects", [Light, Head, Camera]}]},
    
    io:format("Loading objects!!~n"),

    ymir_demo:core_call({create, [Scene]}).

stop() ->
    ymir_demo:core_call({destroy, [{title(), "scene", []}]}).

%%%%%% Action Definitions
position_offset(?KC_W, true, {DX,DY,DZ}) -> {DX, DY, DZ + 1.0}; 
position_offset(?KC_S, true, {DX,DY,DZ}) -> {DX, DY, DZ - 1.0};
position_offset(?KC_A, true, {DX,DY,DZ}) -> {DX - 1.0, DY, DZ};
position_offset(?KC_D, true, {DX,DY,DZ}) -> {DX + 1.0, DY, DZ};
position_offset(_Key, _Val, Offset) -> Offset.

position(State) when is_record(State, eventState) ->
    Default = {0.0, 0.0, 0.0},   
    F = fun( Key, Val, In ) -> position_offset(Key, Val, In) end,
    Offset = dict:fold(F, Default, State#eventState.keyboard),
    if
        Offset /= Default ->
            [{"move", Offset}];  

        true ->
            []
    end.

rotation(State) when is_record(State, eventState) ->

    case dict:fetch( moved, State#eventState.mouse ) of
        true -> 
            {{_Ax, Rx}, {_Ay, Ry}, {_Az, _Rz}} = dict:fetch(current, State#eventState.mouse),
            Res = {Rx * 1.0, Ry * 1.0, 0},
            case Res of
                {0.0, 0.0, 0.0} -> 
                    [];

                {Yaw, Pitch, _Roll} ->
                    [{"rotate", {Yaw, Pitch, 0.0}}]
            end;     

        false -> 
            []
     end.
        
move(State) when is_record(State, eventState) ->
    
        case position(State) ++ rotation(State) of

            Updates when Updates /= []->

                %io:format("Updates: ~p~n", [Updates]),
                %%{atomic, Camera}  = update_camera( "Camera", Updates ),

                %%Tell OgreManager about the updated object
                gen_server:call(ymir_demo, {core, { update,
                                                    [{"Camera", 
                                                      "camera",
                                                      Updates
                                                     }]}} );
            _Else ->
                ok

        end,

        State.
