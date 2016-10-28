module Game.Update exposing (update)

import Json.Decode exposing (decodeString)
import Result

import Game.Messages exposing (Msg(..))
import Game.Models.Main exposing (Model, setOwnGuess, getOwnGuess, isRoundJustOver)
import Game.Models.Room as Room
import Game.Models.Guess as Guess
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
      , if shouldCloseRound then requestNewRound model else Cmd.none
      ]

update : Msg -> Model -> (Model, Cmd Msg, Maybe String)
update msg model =
  case msg of
    ReceiveRoomState roomState ->
      let
        newRoom = decodeString Room.roomDecoder roomState
          |> Result.toMaybe
        didRoundChange = (Maybe.map (.round) model.room) /= (Maybe.map (.round) newRoom)
        newTime = if didRoundChange then 0 else model.currentRoundTime
        newModel =
          { model
              | room = newRoom
              , currentRoundTime = newTime
          }
        cmd =
          if (didRoundChange || (model.room == Nothing))
            then
              requestRoundRandom ()
            else
              Cmd.none
        cmd' =
          augmentCommand model newModel cmd
      in
        ( newModel
        , cmd'
        , Nothing
        )

    ReceiveRoundRandom roundRandom ->
      ( { model
            | currentRoundRandom = roundRandom
        }
      , Cmd.none
      , Nothing
      )

    MakeGuess guessValue ->
      let
        canMakeGuess =
          model.room
            |> Maybe.map (Room.canGuess model.playerId)
            |> Maybe.withDefault False
        newModel =
          if canMakeGuess
            then
              setOwnGuess guessValue model
            else
              model
        cmd =
          if canMakeGuess
            then
              sendPlayerStatusUpdate newModel
            else
              Cmd.none
        cmd' =
          augmentCommand model newModel cmd
      in
        ( newModel
        , cmd'
        , Nothing
        )

    Tick tick ->
      let
        newRoundTime = model.currentRoundTime + tickDuration
        didRoundTimeJustRunOut =
          (newRoundTime >= roundDuration) &&
          (model.currentRoundTime < roundDuration)
        isPlayerGuessPending =
          getOwnGuess model
            |> Maybe.map .value
            |> (==) (Just Guess.Pending)
        (newRoom, shouldSendStatusUpdate) = if didRoundTimeJustRunOut && isPlayerGuessPending
          then
            ( model.room
                |> Maybe.map (Room.setGuess {time = newRoundTime, value = Guess.Idle} model.playerId)
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
          if
            shouldSendStatusUpdate
          then
            sendPlayerStatusUpdate newModel
          else
            Cmd.none
        cmd' =
          augmentCommand model newModel cmd
      in
        ( newModel
        , cmd'
        , Nothing
        )

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
        command = sendPlayerStatusUpdate newModel
      in
        ( newModel
        , command
        , Nothing
        )

    Navigate newUrl ->
      ( model
      , Cmd.none
      , Just newUrl
      )