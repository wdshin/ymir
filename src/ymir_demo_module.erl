-module(ymir_demo_module).

-export([behaviour_info/1]).

behaviour_info(callbacks)->
    [ {title, 0},
      {description, 0},
      {handler, 0},
      {start, 0} ];

behaviour_info(_other) -> undefined.