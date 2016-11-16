module Game.Views.Word exposing (view)

import Html
import Html.Lazy exposing (lazy)
import Dict
import Game.Models exposing (Model, getOwnGuess)
import Models.Room as Room
import Models.Guess as Guess
import Game.Messages exposing (Msg(..))
import UiKit.Word


view : Model -> Room.Room -> Html.Html Msg
view model room =
    let
        guessIndex =
            getOwnGuess model
                |> Maybe.map Guess.toMaybe
                |> Maybe.withDefault (Just 0)

        startAngle =
            (toFloat model.currentRoundRandom) / 1000 * 2 * pi

        isRoundOver =
            Room.isRoundOver room

        highlights =
            guessIndex
                |> Maybe.map (\i -> [ ( i, "highlighted" ) ])
                |> Maybe.map
                    ((++)
                        (if isRoundOver then
                            [ ( 0, "marked" ) ]
                         else
                            []
                        )
                    )
                |> Maybe.map Dict.fromList
                |> Maybe.withDefault Dict.empty
    in
        lazy UiKit.Word.view
            { word = room.roundData.word
            , startAngle = startAngle
            , highlights = highlights
            , isDisabled = isRoundOver
            , onLetterClick = MakeGuess
            }
