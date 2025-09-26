module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes exposing (style)
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

        z =
            r * pi / 15 * sin (pi / 80 * r + time / 1000)
    in
    z


gridElement : GridCoordinate -> Time -> Face
gridElement coord time =
    let
        height =
            waveFunction coord time

        colorHue =
            height / 10

        color =
            Color.hsl colorHue 0.7 0.4
                |> Color.toCssString

        createPoint : GridCoordinate -> Point3D
        createPoint c =
            Point3D c.x c.y (waveFunction c time)

        points =
            [ createPoint (GridCoordinate (coord.x - 10) (coord.y - 10))
            , createPoint (GridCoordinate coord.x (coord.y - 10))
            , createPoint coord
            , createPoint (GridCoordinate (coord.x - 10) coord.y)
            ]
    in
    Face points color


grid : Time -> List Face
grid time =
    let
        range =
            List.range -12 12 |> List.map (toFloat >> (*) 10)

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


svgProjection : Time -> List (Svg Msg)
svgProjection time =
    let
        rot =
            Rotation (-0.002 * time) (0.004 * time)

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
    time
        |> grid
        |> sortByDistance
        |> List.map draw


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
            [ 0.25, -0.5, -0.25 ]
                |> List.map
                    (\speed ->
                        container (ViewBox -200 -200 200 200) (svgProjection (speed * model))
                    )
    in
    Html.div styles svgs


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
    Float


init : () -> ( Model, Cmd Msg )
init _ =
    ( 0, Cmd.none )


-- UPDATE


type Msg
    = Tick Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg _ =
    case msg of
        Tick newTime ->
            ( Time.posixToMillis newTime |> toFloat, Cmd.none )


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 33 Tick