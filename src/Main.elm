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


waveFunction : GridCoordinate -> Time -> Float
waveFunction coord time =
    let
        r =
            sqrt (coord.x ^ 2 + coord.y ^ 2)

        -- Primary ripples with amplitude decay
        primaryRipples =
            (200 / (r + 20)) * sin (r / 8 - time / 200)

        -- Secondary interference ripples
        secondaryRipples =
            8 * sin (r / 12 - time / 300) * cos (time / 2500)

        -- High frequency surface waves with decay
        surfaceWaves =
            5 * sin (r / 4 - time / 150) * (100 / (r + 50))

        -- Radial wave modulation (creates wave packets)
        wavePackets =
            10 * sin (r / 15 - time / 250) * (1 + 0.5 * sin (r / 25 - time / 500))

        -- Cross interference from multiple sources
        offset1 = sqrt ((coord.x - 50) ^ 2 + (coord.y - 30) ^ 2)
        offset2 = sqrt ((coord.x + 40) ^ 2 + (coord.y - 20) ^ 2)

        interference1 = 6 * sin (offset1 / 10 - time / 225) * (80 / (offset1 + 40))
        interference2 = 4 * sin (offset2 / 8 - time / 275) * (60 / (offset2 + 30))

        -- Combine all wave components
        z =
            primaryRipples + secondaryRipples + surfaceWaves + wavePackets + interference1 + interference2
    in
    z


gridElement : GridCoordinate -> Time -> Face
gridElement coord time =
    let
        height =
            waveFunction coord time

        -- Subtle blue-to-white gradient based on height
        lightness =
            0.3 + (height + 50) / 200  -- Maps height to lightness

        color =
            Color.hsl 0.6 0.3 lightness
                |> Color.toCssString

        createPoint : GridCoordinate -> Point3D
        createPoint c =
            Point3D c.x c.y (waveFunction c time)

        points =
            [ createPoint (GridCoordinate (coord.x - 5) (coord.y - 5))
            , createPoint (GridCoordinate coord.x (coord.y - 5))
            , createPoint coord
            , createPoint (GridCoordinate (coord.x - 5) coord.y)
            ]
    in
    Face points color


grid : Time -> List Face
grid time =
    let
        range =
            List.range -40 40 |> List.map (toFloat >> (*) 5)

        coordinates =
            range
                |> List.concatMap
                    (\x ->
                        range |> List.map (\y -> GridCoordinate x y)
                    )
    in
    coordinates
        |> List.map (\coord -> gridElement coord time)


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


svgProjection : Model -> List (Svg Msg)
svgProjection model =
    let
        -- Reduce base rotation when mouse is active
        hasMouseInput = model.mouseX /= 0 || model.mouseY /= 0
        baseScale = if hasMouseInput then 0.2 else 1.0

        baseRotX = -0.0003 * model.time * baseScale
        baseRotY = 0.0006 * model.time * baseScale

        -- Mouse influence (stronger influence, normalized to screen size)
        mouseInfluenceX = (model.mouseY - 400) / 400 * 0.8
        mouseInfluenceY = (model.mouseX - 400) / 400 * 0.8

        rot =
            Rotation (baseRotX + mouseInfluenceX) (baseRotY + mouseInfluenceY)

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
        |> grid
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
            , style "display" "flex"
            , style "justify-content" "center"
            , style "align-items" "center"
            , style "flex-wrap" "wrap"
            ]

        svgs =
            [ container (ViewBox -400 -400 400 400) (svgProjection model) ]
    in
    Html.div
        ([ Html.Events.on "mousemove" mouseDecoder
         , Html.Events.on "pointermove" mouseDecoder
         , style "touch-action" "none"
         ] ++ styles)
        svgs


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
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { time = 0, mouseX = 0, mouseY = 0 }, Cmd.none )


-- UPDATE


type Msg
    = Tick Time.Posix
    | MouseMove Float Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick newTime ->
            ( { model | time = Time.posixToMillis newTime |> toFloat }, Cmd.none )

        MouseMove x y ->
            ( { model | mouseX = x, mouseY = y }, Cmd.none )


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 33 Tick