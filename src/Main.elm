module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes exposing (style, class)
import Html.Events
import Json.Decode as Decode
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Time
import Color


type alias Time =
    Float


type alias Point3D =
    { x : Float
    , y : Float
    , z : Float
    }


type alias Point2D =
    { x : Float
    , y : Float
    }


type alias GridCoordinate =
    { x : Float
    , y : Float
    }


type alias Face =
    { points : List Point3D
    , color : String
    }


waveFunction : Int -> GridCoordinate -> Time -> Float
waveFunction variant coord time =
    let
        r =
            sqrt (coord.x ^ 2 + coord.y ^ 2)
    in
    case variant of
        1 ->
            -- Classic expanding ripples
            20 * sin (r / 12 - time / 300) * (100 / (r + 30))

        2 ->
            -- X-Y grid waves
            15 * sin (coord.x / 20 - time / 250) * sin (coord.y / 20 - time / 200)

        3 ->
            -- Spiral waves
            let
                angle = atan2 coord.y coord.x
            in
            20 * sin (r / 15 - time / 200 + angle * 3)

        _ ->
            -- Complex interference (original sophisticated pattern)
            let
                -- Primary ripples with amplitude decay
                primaryRipples =
                    (200 / (r + 20)) * sin (r / 8 - time / 320)

                -- Secondary interference ripples
                secondaryRipples =
                    8 * sin (r / 12 - time / 480) * cos (time / 4000)

                -- Cross interference from multiple sources
                offset1 = sqrt ((coord.x - 50) ^ 2 + (coord.y - 30) ^ 2)
                offset2 = sqrt ((coord.x + 40) ^ 2 + (coord.y - 20) ^ 2)

                interference1 = 6 * sin (offset1 / 10 - time / 360) * (80 / (offset1 + 40))
                interference2 = 4 * sin (offset2 / 8 - time / 440) * (60 / (offset2 + 30))
            in
            primaryRipples + secondaryRipples + interference1 + interference2


gridElement : Int -> GridCoordinate -> Time -> Face
gridElement variant coord time =
    let
        height =
            waveFunction variant coord time

        -- Animated color offset that cycles through full spectrum over time
        colorOffset = (time / 5000) - toFloat (floor (time / 5000))

        -- Map height to a larger portion of spectrum (about 2/3)
        hueFromHeight = (height / 90) * 0.67  -- Use 2/3 of spectrum

        -- Add time-based offset to cycle through full spectrum
        baseHue = hueFromHeight + colorOffset

        -- Ensure hue stays in 0-1 range
        hue = baseHue - toFloat (floor baseHue)

        -- Height-based lightness for depth perception
        lightness =
            0.3 + (height + 50) / 200

        color =
            Color.hsl hue 0.7 lightness
                |> Color.toCssString

        createPoint : GridCoordinate -> Point3D
        createPoint c =
            Point3D c.x c.y (waveFunction variant c time)

        points =
            [ createPoint (GridCoordinate (coord.x - 8) (coord.y - 8))
            , createPoint (GridCoordinate coord.x (coord.y - 8))
            , createPoint coord
            , createPoint (GridCoordinate (coord.x - 8) coord.y)
            ]
    in
    Face points color


grid : Int -> Time -> List Face
grid variant time =
    let
        range =
            List.range -20 20 |> List.map (toFloat >> (*) 8)

        coordinates =
            range
                |> List.concatMap
                    (\x ->
                        range |> List.map (\y -> GridCoordinate x y)
                    )
    in
    coordinates
        |> List.map (\coord -> gridElement variant coord time)


type alias Rotation =
    { x : Float
    , y : Float
    }


project3DTo2D : Point3D -> Rotation -> Point2D
project3DTo2D point rot =
    let
        -- Apply rotation around X axis
        cosX =
            cos rot.x

        sinX =
            sin rot.x

        y1 =
            point.y * cosX - point.z * sinX

        z1 =
            point.y * sinX + point.z * cosX

        -- Apply rotation around Y axis
        cosY =
            cos rot.y

        sinY =
            sin rot.y

        x2 =
            point.x * cosY + z1 * sinY

        z2 =
            -point.x * sinY + z1 * cosY

        -- Simple perspective projection
        perspective =
            300 / (300 + z2)
    in
    Point2D (x2 * perspective) (y1 * perspective)


sortByDistance : List Face -> List Face
sortByDistance faces =
    let
        averageZ face =
            face.points
                |> List.map (\p -> p.z)
                |> List.sum
                |> (\sum -> sum / toFloat (List.length face.points))
    in
    faces
        |> List.sortBy averageZ


svgProjection : Int -> Model -> List (Svg Msg)
svgProjection variant model =
    let
        -- Reduce base rotation when mouse is active
        hasMouseInput = model.mouseX /= 0 || model.mouseY /= 0
        baseScale = if hasMouseInput then 0.1 else 1.0

        baseRotX = -0.0003 * model.time * baseScale
        baseRotY = 0.0006 * model.time * baseScale

        -- Use smoothed current rotation values
        rot =
            Rotation (baseRotX + model.currentRotX) (baseRotY + model.currentRotY)

        draw face =
            let
                projectedPoints =
                    face.points
                        |> List.map (\p -> project3DTo2D p rot)

                pointsString =
                    projectedPoints
                        |> List.map (\p -> String.fromFloat p.x ++ "," ++ String.fromFloat p.y)
                        |> String.join " "
            in
            Svg.polygon
                [ SvgAttr.stroke "white"
                , SvgAttr.strokeWidth "0.5"
                , SvgAttr.strokeOpacity "0.5"
                , SvgAttr.fill face.color
                , SvgAttr.fillOpacity "0.5"
                , SvgAttr.points pointsString
                ]
                []
    in
    model.time
        |> grid variant
        |> sortByDistance
        |> List.map draw


mouseDecoder : Decode.Decoder Msg
mouseDecoder =
    Decode.map2 MouseMove
        (Decode.field "clientX" Decode.float)
        (Decode.field "clientY" Decode.float)


type alias ViewBox =
    { minX : Float
    , minY : Float
    , maxX : Float
    , maxY : Float
    }


container : ViewBox -> List (Svg Msg) -> Html Msg
container vb svgs =
    let
        width =
            vb.maxX - vb.minX

        height =
            vb.maxY - vb.minY
    in
    Html.div []
        [ Svg.svg
            [ SvgAttr.width (String.fromFloat width)
            , SvgAttr.height (String.fromFloat height)
            , SvgAttr.viewBox (String.fromFloat vb.minX ++ " " ++ String.fromFloat vb.minY ++ " " ++ String.fromFloat width ++ " " ++ String.fromFloat height)
            ]
            svgs
        ]


view : Model -> Html Msg
view model =
    let
        styles =
            [ style "backgroundColor" "#000000"
            , style "height" "100vh"
            , style "width" "100vw"
            , style "display" "grid"
            , style "grid-template-columns" "repeat(auto-fit, minmax(400px, 1fr))"
            , style "grid-template-rows" "repeat(auto-fit, minmax(350px, 1fr))"
            , style "gap" "0"
            , style "overflow" "hidden"
            ]

        gridContainerStyle =
            [ style "width" "100%"
            , style "height" "100%"
            , style "display" "flex"
            , style "justify-content" "center"
            , style "align-items" "center"
            , style "min-height" "350px"
            ]

        responsiveCSS =
            Html.node "style" []
                [ Html.text """
                @media (max-width: 768px) {
                    .grid-container {
                        grid-template-columns: 1fr !important;
                        grid-template-rows: repeat(4, minmax(300px, 1fr)) !important;
                    }
                }
                @media (min-width: 769px) and (max-width: 1024px) {
                    .grid-container {
                        grid-template-columns: 1fr 1fr !important;
                        grid-template-rows: 1fr 1fr !important;
                    }
                }
                @media (min-width: 1025px) {
                    .grid-container {
                        grid-template-columns: 1fr 1fr !important;
                        grid-template-rows: 1fr 1fr !important;
                    }
                }
                """
                ]

        svgs =
            [ Html.div gridContainerStyle [ container (ViewBox -400 -400 400 400) (svgProjection 1 model) ]
            , Html.div gridContainerStyle [ container (ViewBox -400 -400 400 400) (svgProjection 2 { model | time = model.time * 0.7 }) ]
            , Html.div gridContainerStyle [ container (ViewBox -400 -400 400 400) (svgProjection 3 { model | time = model.time * 1.3 }) ]
            , Html.div gridContainerStyle [ container (ViewBox -400 -400 400 400) (svgProjection 4 { model | time = model.time * 1.6 }) ]
            ]
    in
    Html.div []
        [ responsiveCSS
        , Html.div
            ([ Html.Events.on "mousemove" mouseDecoder
             , Html.Events.on "pointermove" mouseDecoder
             , style "touch-action" "none"
             , class "grid-container"
             ] ++ styles)
            svgs
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


-- MODEL


type alias Model =
    { time : Float
    , mouseX : Float
    , mouseY : Float
    , targetRotX : Float
    , targetRotY : Float
    , currentRotX : Float
    , currentRotY : Float
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { time = 0
      , mouseX = 0
      , mouseY = 0
      , targetRotX = 0
      , targetRotY = 0
      , currentRotX = 0
      , currentRotY = 0
      }
    , Cmd.none )


-- UPDATE


type Msg
    = Tick Time.Posix
    | MouseMove Float Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick newTime ->
            let
                newTimeValue = Time.posixToMillis newTime |> toFloat

                -- Smooth interpolation towards target rotation
                smoothing = 0.05  -- Lower = smoother, higher = more responsive

                newCurrentRotX = model.currentRotX + (model.targetRotX - model.currentRotX) * smoothing
                newCurrentRotY = model.currentRotY + (model.targetRotY - model.currentRotY) * smoothing
            in
            ( { model
              | time = newTimeValue
              , currentRotX = newCurrentRotX
              , currentRotY = newCurrentRotY
              }
            , Cmd.none )

        MouseMove x y ->
            let
                -- Calculate target rotation based on mouse position
                targetRotX = (y - 400) / 400 * 0.8
                targetRotY = (x - 400) / 400 * 0.8
            in
            ( { model
              | mouseX = x
              , mouseY = y
              , targetRotX = targetRotX
              , targetRotY = targetRotY
              }
            , Cmd.none )


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 33 Tick