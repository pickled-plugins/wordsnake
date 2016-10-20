module UiKit.LabeledInput exposing (view)

import Html exposing (Html, Attribute, div, text ,h1, h2, p, a, button, form, label, input, fieldset)
import Html.Attributes exposing (class, type', id, name, for, required, autofocus, placeholder, href)
import Html.Events exposing (onInput, onClick)

type alias Options a =
  { id : String
  , label : String
  , type' : String
  , autofocus : Bool
  , placeholder : String
  , onInput : String -> a
  }

view : Options a -> Html a
view options =
  fieldset []
    [ label
        [ for options.id
        ]
        [ text options.label
        ]
    , input
        [ type' "text"
        , id options.id
        , name options.id
        , onInput options.onInput
        , autofocus options.autofocus
        , placeholder options.placeholder
        ] []
    ]