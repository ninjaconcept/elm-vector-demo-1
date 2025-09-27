module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes exposing (style)
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

        -- Target range: -25 to +25 for consistent color mapping
        targetRange = 25.0

        rawHeight =
            case variant of
                1 ->
                    -- Classic expanding ripples
                    0.75 * sin (r / 12 - time / 500) * (100 / (r + 30))

                2 ->
                    -- X-Y grid waves
                    sin (coord.x / 20 - time / 400) * sin (coord.y / 20 - time / 350)

                3 ->
                    -- Spiral waves
                    let
                        angle = atan2 coord.y coord.x
                    in
                    0.75 * sin (r / 15 - time / 700 + angle * 3)

                _ ->
                    -- Complex interference (original sophisticated pattern)
                    let
                        -- Primary ripples with amplitude decay
                        primaryRipples =
                            (15 / (r + 20)) * sin (r / 8 - time / 550)

                        -- Secondary interference ripples
                        secondaryRipples =
                            0.5 * sin (r / 12 - time / 800) * cos (time / 6000)

                        -- Cross interference from multiple sources
                        offset1 = sqrt ((coord.x - 50) ^ 2 + (coord.y - 30) ^ 2)
                        offset2 = sqrt ((coord.x + 40) ^ 2 + (coord.y - 20) ^ 2)

                        interference1 = 0.3 * sin (offset1 / 10 - time / 600) * (5 / (offset1 + 40))
                        interference2 = 0.25 * sin (offset2 / 8 - time / 700) * (4 / (offset2 + 30))
                    in
                    primaryRipples + secondaryRipples + interference1 + interference2
    in
    rawHeight * targetRange


gridElement : Int -> GridCoordinate -> Time -> Face
gridElement variant coord time =
    let
        height =
            waveFunction variant coord time

        -- Map height directly to full spectrum (0-1 hue range)
        -- Normalize height from consistent wave range (-25 to +25) to 0-1
        normalizedHeight = (height + 25) / 50

        -- Clamp to 0-1 range and map to full spectrum
        hue = max 0 (min 1 normalizedHeight)

        -- Height-based lightness for depth perception
        lightness =
            0.35 + (height + 25) / 280

        color =
            Color.hsl hue 0.7 lightness
                |> Color.toCssString

        createPoint : GridCoordinate -> Point3D
        createPoint c =
            Point3D c.x c.y (waveFunction variant c time)

        points =
            [ createPoint (GridCoordinate (coord.x - 7) (coord.y - 7))
            , createPoint (GridCoordinate coord.x (coord.y - 7))
            , createPoint coord
            , createPoint (GridCoordinate (coord.x - 7) coord.y)
            ]
    in
    Face points color


grid : Int -> Time -> List Face
grid variant time =
    let
        range =
            List.range -18 18 |> List.map (toFloat >> (*) 7)

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
                [ SvgAttr.stroke "#000000"
                , SvgAttr.strokeWidth "0.7"
                , SvgAttr.strokeOpacity "0.4"
                , SvgAttr.fill face.color
                , SvgAttr.fillOpacity "0.8"
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
            , style "display" "flex"
            , style "justify-content" "center"
            , style "align-items" "center"
            , style "overflow" "hidden"
            ]

        gridStyles =
            [ style "display" "grid"
            , style "grid-template-columns" "1fr 1fr"
            , style "grid-template-rows" "1fr 1fr"
            , style "gap" "2px"
            , style "padding" "2px"
            , style "box-sizing" "border-box"
            , style "max-width" "1200px"
            , style "width" "100%"
            , style "height" "min(100vh, 800px)"
            , style "aspect-ratio" "1.5"
            ]

        gridContainerStyle =
            [ style "width" "100%"
            , style "height" "100%"
            , style "display" "flex"
            , style "justify-content" "center"
            , style "align-items" "center"
            , style "overflow" "hidden"
            ]


        svgs =
            [ Html.div gridContainerStyle [ container (ViewBox -400 -400 400 400) (svgProjection 1 model) ]
            , Html.div gridContainerStyle [ container (ViewBox -400 -400 400 400) (svgProjection 2 { model | time = model.time * 0.7 }) ]
            , Html.div gridContainerStyle [ container (ViewBox -400 -400 400 400) (svgProjection 3 { model | time = model.time * 1.3 }) ]
            , Html.div gridContainerStyle [ container (ViewBox -400 -400 400 400) (svgProjection 4 { model | time = model.time * 1.6 }) ]
            ]

    in
    Html.div
        ([ Html.Events.on "mousemove" mouseDecoder
         , Html.Events.on "pointermove" mouseDecoder
         , style "touch-action" "none"
         ] ++ styles)
        [ Html.div gridStyles svgs ]


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