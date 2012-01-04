-module(ymir_demo_event_manager).

-behaviour(gen_event).

-export([init/1, handle_event/2, handle_info/2, handle_call/2, terminate/2]).

-record( eventState, { keyboard=dict:new(), 
                       mouse= dict:from_list( [{current, {0,0,0}},
                                               {previous, {0,0,0}}] ), 
                       gui = dict:new(),
                       actions = []} ).

init(Actions) when is_list(Actions) ->
    {ok, #eventState{actions = Actions} }.

%Events
%{keyPressed, X}
%{keyReleased, X}
%{mousePressed, X}
%{mouseReleased, X}
%{mouseMoved, Pos}

%%Actions

%{Event, Action}
%{Prereq, Action}%

%Pre = fun( Keyboard, Mouse ) -> true / false. 
%Action = fun( Keyboard, Mouse ) -> ok.  

gui_action(ID, Val, Action, State) ->
    Gui = State#eventState.gui,
    NotVal = not Val,

    case dict:find(ID, Gui) of
        {ok, Val} ->
            Action(State#eventState.keyboard, 
                   State#eventState.mouse);
        
        {ok, NotVal} ->
           ok; 

        _Undef when Val == false ->
            Action(State#eventState.keyboard, 
                   State#eventState.mouse);

        _Undef ->
           ok 
    end.

keyboard_action(ID, Val, Action, State) ->
    Keyboard = State#eventState.keyboard,
    Mouse = State#eventState.mouse,
    NotVal = not Val,

    case dict:find(ID, Keyboard) of
        {ok, Val} ->
            Action(Keyboard, Mouse);
        
        {ok, NotVal} ->
           ok; 

        _Undef when Val == false ->
           Action(Keyboard, Mouse);

        _Undef ->
           ok 
    end.

mouse_action(ID, Val, Action, State) ->
    Keyboard = State#eventState.keyboard,
    Mouse = State#eventState.mouse,
    NotVal = not Val,

    case dict:find(ID, Mouse) of
        {ok, Val} ->
            Action(Keyboard, Mouse);
        
        {ok, NotVal} ->
           ok; 

        _Undef when Val == false ->
           Action(Keyboard, Mouse);

        _Undef ->
            ok
    end.

process_action({{keyUp, ID}, Action}, State) when is_integer(ID),
                                                 is_function(Action, 2) ->

    keyboard_action(ID, false, Action, State),                                                 
    State;

process_action({{keyDown, ID}, Action}, State) when is_integer(ID),
                                                    is_function(Action, 2) ->
    keyboard_action(ID, true, Action, State),                                                       
    State;

process_action({{mouseUp, ID}, Action}, State) when is_integer(ID),
                                                    is_function(Action, 2) ->
    mouse_action(ID, false, Action, State),
    State;

process_action({{mouseDown, ID}, Action}, State) when is_integer(ID), 
                                                      is_function(Action, 2) ->
    mouse_action(ID, true, Action, State),
    State;                                                      

process_action({{guiMouseDown, {Name, Button}}, Action}, State) when is_list(Name),
                                                                     is_integer(Button) ->
    gui_action({Name, Button}, true, Action, State),
    State;

process_action({{guiMouseUp, {Name, Button}}, Action}, State) when is_list(Name),
                                                                   is_integer(Button) ->
    gui_action({Name, Button}, false, Action, State),
    State;

process_action({{guiMouseButtonClick, Name}, Action}, State) ->
    gui_action(Name, true, Action, State),

    %%Process each click only once, clear the true flag
    State#eventState{ gui = dict:store( Name,
                                        false,
                                        State#eventState.gui) };

process_action({Prereq, Action}, State) when is_function(Prereq, 2),
                                             is_function(Prereq, 2) ->
     Keyboard = State#eventState.keyboard,
     Mouse = State#eventState.mouse,

     case Prereq(Keyboard, Mouse) of
        true -> Action(Keyboard, Mouse)
     end,
     
     State;

process_action(Something, State) ->
    io:format("What?  ~p~n", [Something]),
    State.
        

handle_event(frameStarted, State) ->
    F = fun(E, A) -> process_action(E, A) end,

    %%Process the list of actions, calling every
    %%action whose prerequisites have been met.
    {ok, lists:foldl(F, State, State#eventState.actions)};

handle_event({keyPressed, Key}, State) when is_record(State, eventState) ->
    Keyboard = State#eventState.keyboard,
    Mouse = State#eventState.mouse,

    {ok, State#eventState{ keyboard = dict:store(Key, true, Keyboard), 
                      mouse = Mouse }};

handle_event({keyReleased, Key}, State) when is_record(State, eventState) ->
    Keyboard = State#eventState.keyboard,
    Mouse = State#eventState.mouse,

    {ok, State#eventState{ keyboard = dict:store(Key, false, Keyboard), 
                           mouse = Mouse }};

handle_event({mousePressed,{Key, _Pos}}, State) when is_record(State, eventState) ->
    Keyboard = State#eventState.keyboard,
    Mouse = State#eventState.mouse,

    io:format("MousePressed! Key = ~p~n", [Key]),

    {ok, State#eventState{ keyboard = Keyboard, 
                           mouse = dict:store(Key, true, Mouse) }};

handle_event({mouseReleased, {Key, _Pos}}, State) when is_record(State, eventState) ->
    Keyboard = State#eventState.keyboard,
    Mouse = State#eventState.mouse,

    io:format("MouseReleased! Key = ~p~n", [Key]),

    {ok, State#eventState{ keyboard = Keyboard, 
                           mouse = dict:store(Key, false, Mouse) }};

handle_event({mouseMoved, Pos}, State) when is_record(State, eventState) ->
    Keyboard = State#eventState.keyboard,
    Mouse = State#eventState.mouse,
    {_ID, [{Ax,_Rx},{Ay, _Ry}, {Az, _Rz}]} = Pos,

    %%Update current mouse position
    {ok, State#eventState{ keyboard = Keyboard,
                           mouse = dict:store(current, {Ax, Ay, Az}, Mouse) }};


handle_event({guiMousePressed, {ID, Button}}, State) when is_list(ID), 
                                                          is_integer(Button),
                                                          is_record(State, eventState) ->
    
    io:format("guiMousePressed! Key = ~p~n", [Button]),
    
    {ok, State#eventState{ gui = dict:store({ID, Button},
                                            true,
                                            State#eventState.gui) }};

handle_event({guiMouseReleased, {ID, Button}}, State) when is_list(ID),
                                                          is_integer(Button),
                                                          is_record(State, eventState) ->
    
    io:format("guiMouseReleased! Key = ~p~n", [Button]),
    {ok, State#eventState{ gui = dict:store({ID, Button},
                                            false,
                                            State#eventState.gui) }};

handle_event({guiMouseButtonClick, ID}, State ) ->
    io:format("guiMouseButtonClick! ID = ~p~n", [ID]),

    {ok, State#eventState{ gui = dict:store(ID,
                                            true,
                                            State#eventState.gui) }};

handle_event( Event, State )->
    io:format("Got Event! ~p~n", [Event]),
    {ok, State}.

%%Add/remove actions
handle_call({add_actions, Actions}, State) when is_list(Actions) ->

    NewActions = State#eventState.actions ++ Actions,

    {ok, ok, State#eventState{ actions = NewActions }};

handle_call(clear_actions, State) ->
    {ok, ok, State#eventState{ actions = [] }};

handle_call( _Call, State ) ->
    {ok, ok, State}.

handle_info( _Info, State )->
    {ok, State}.

terminate( _Args, _State ) ->
    stop.
