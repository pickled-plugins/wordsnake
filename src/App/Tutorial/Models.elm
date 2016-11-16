module Tutorial.Models exposing (..)


type Stage
    = Start
    | ShowWord


type alias Model =
    { stage : Stage
    , guess : Maybe Int
    }


init : Model
init =
    { stage = Start
    , guess = Nothing
    }



-- Helpers


getDummy : String -> Model
getDummy s =
    init


getDialogContent : Model -> String
getDialogContent { stage, guess } =
    case stage of
        Start ->
            "Heyyo, ready? Just click me to get your very first word."

        ShowWord ->
            case guess of
                Nothing ->
                    "Holy moly, who writes like that? Anyways, see if you can find the first letter."

                Just i ->
                    if i == 0 then
                        "Cool, you got it - click me again to create your very own room."
                    else
                        "Not quite, not quite. Give it one more go?"
