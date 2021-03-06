module Game.Update exposing (update)

import Json.Decode exposing (decodeString)
import Result
import Models.Room as Room
import Models.Player as Player
import Models.Guess as Guess
import Game.Messages exposing (Msg(..))
import Game.Models exposing (Model, Error(..), setOwnGuess, getOwnGuess, isRoundJustOver)
import Game.Commands exposing (sendPlayerStatusUpdate, requestRoundRandom, requestNewRound)
import Game.Constants exposing (tickDuration, roundDuration)


augmentCommand : Model -> Model -> Cmd Msg -> Cmd Msg
augmentCommand model newModel cmd =
    let
        shouldCloseRound =
            (isRoundJustOver model newModel) && (Just model.playerId == Maybe.map (.hostId) model.room)
    in
        Cmd.batch
            [ cmd
            , if shouldCloseRound then
                requestNewRound (newModel.room |> Maybe.map Room.setNewRound |> Maybe.withDefault (Room.getDummy ""))
              else
                Cmd.none
            ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveRoomState roomState ->
            let
                newRoom =
                    decodeString Room.itemDecoder roomState
                        |> Result.toMaybe

                didRoundChange =
                    (Maybe.map (.round) model.room) /= (Maybe.map (.round) newRoom)

                newTime =
                    if didRoundChange then
                        0
                    else
                        model.currentRoundTime

                newModel =
                    { model
                        | room = newRoom
                        , error =
                            if newRoom == Nothing then
                                (Just WrongPath)
                            else
                                Nothing
                        , currentRoundTime = newTime
                    }

                cmd =
                    if (didRoundChange || (model.room == Nothing)) then
                        requestRoundRandom ()
                    else
                        Cmd.none

                cmd_ =
                    augmentCommand model newModel cmd
            in
                newModel
                    ! [ cmd_ ]

        ReceiveRoundRandom roundRandom ->
            { model
                | currentRoundRandom = roundRandom
            }
                ! [ Cmd.none ]

        MakeGuess guessValue ->
            let
                canMakeGuess =
                    model.room
                        |> Maybe.map (Room.canGuess model.playerId)
                        |> Maybe.withDefault False

                newModel =
                    if canMakeGuess then
                        setOwnGuess guessValue model
                    else
                        model

                cmd =
                    (if canMakeGuess then
                        sendPlayerStatusUpdate newModel
                     else
                        Cmd.none
                    )
                        |> augmentCommand model newModel
            in
                newModel
                    ! [ cmd ]

        Tick tick ->
            let
                newRoundTime =
                    model.currentRoundTime + tickDuration

                didRoundTimeJustRunOut =
                    (newRoundTime >= roundDuration)
                        && (model.currentRoundTime < roundDuration)

                isPlayerGuessPending =
                    getOwnGuess model
                        |> Maybe.map .status
                        |> (==) (Just Guess.Pending)

                ( newRoom, shouldSendStatusUpdate ) =
                    if didRoundTimeJustRunOut && isPlayerGuessPending then
                        ( model.room
                            |> Maybe.map (Room.setGuess { time = newRoundTime, status = Guess.Idle } model.playerId)
                        , True
                        )
                    else
                        ( model.room
                        , False
                        )

                newModel =
                    { model
                        | currentRoundTime = newRoundTime
                        , room = newRoom
                    }

                cmd =
                    (if shouldSendStatusUpdate then
                        sendPlayerStatusUpdate newModel
                     else
                        Cmd.none
                    )
                        |> augmentCommand model newModel
            in
                newModel
                    ! [ cmd ]

        SetReady ->
            let
                newRoom =
                    model.room
                        |> Maybe.map (Room.setReady model.playerId)

                newModel =
                    { model
                        | room = newRoom
                        , currentRoundTime = 0
                    }

                command =
                    sendPlayerStatusUpdate newModel
            in
                newModel
                    ! [ command ]

        LeaveRoom _ ->
            let
                newRoom =
                    model.room
                        |> Maybe.map
                            (\r ->
                                Just
                                    { r
                                        | players =
                                            Player.update
                                                (\p -> { p | isReady = False })
                                                model.playerId
                                                r.players
                                    }
                            )
                        |> Maybe.withDefault model.room

                newModel =
                    { model | room = newRoom }

                command =
                    sendPlayerStatusUpdate newModel
            in
                newModel
                    ! [ command ]

        Navigate newUrl ->
            model
                ! []
