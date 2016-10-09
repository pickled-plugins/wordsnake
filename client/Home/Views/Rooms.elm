module Views.Rooms exposing (view)

import Html exposing (Html, div, text ,h2, p, button, nav)
import Html.Attributes exposing (class, classList)

view : Html a
view =
  div
    [ class "app__page"
    ]
    [ h2 [] [ text "Create a room" ]
    ]
