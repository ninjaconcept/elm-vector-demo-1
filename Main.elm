module Main exposing (..)

import Html exposing (Html)
import Html.Attributes exposing (style)
import Svg exposing (Svg)
import Svg.Attributes as Attributes
import OpenSolid.Svg as Svg
import OpenSolid.Geometry.Types exposing (..)
import OpenSolid.Point2d as Point2d
import OpenSolid.Point3d as Point3d
import OpenSolid.Direction2d as Direction2d
import OpenSolid.Axis3d as Axis3d
import OpenSolid.SketchPlane3d as SketchPlane3d
import Time exposing (Time, millisecond)


type alias Face =
    { points : List Point3d
    , color : String
    }


cube : List Face
cube =
    [ -- top
      Face
        [ Point3d ( -50, -50, -50 )
        , Point3d ( 50, -50, -50 )
        , Point3d ( 50, -50, 50 )
        , Point3d ( -50, -50, 50 )
        ]
        "#9CD253"
      -- bottom
    , Face
        [ Point3d ( -50, 50, -50 )
        , Point3d ( 50, 50, -50 )
        , Point3d ( 50, 50, 50 )
        , Point3d ( -50, 50, 50 )
        ]
        "#60B5CC"
      -- back
    , Face
        [ Point3d ( -50, -50, -50 )
        , Point3d ( 50, -50, -50 )
        , Point3d ( 50, 50, -50 )
        , Point3d ( -50, 50, -50 )
        ]
        "#34495E"
      -- front
    , Face
        [ Point3d ( -50, -50, 50 )
        , Point3d ( 50, -50, 50 )
        , Point3d ( 50, 50, 50 )
        , Point3d ( -50, 50, 50 )
        ]
        "#5A6275"
      --left
    , Face
        [ Point3d ( -50, -50, -50 )
        , Point3d ( -50, 50, -50 )
        , Point3d ( -50, 50, 50 )
        , Point3d ( -50, -50, 50 )
        ]
        "#E5A63A"
      --right
    , Face
        [ Point3d ( 50, -50, -50 )
        , Point3d ( 50, 50, -50 )
        , Point3d ( 50, 50, 50 )
        , Point3d ( 50, -50, 50 )
        ]
        "#A63AE5"
    ]


sketchPlane : Time -> SketchPlane3d
sketchPlane time =
    SketchPlane3d.xy
        |> SketchPlane3d.rotateAround Axis3d.x (degrees -0.025 * time)
        |> SketchPlane3d.rotateAround Axis3d.y (degrees 0.1 * time)


svgProjection : Model -> List (Svg Msg)
svgProjection model =
    let
        draw face =
            Svg.polygon2d
                [ Attributes.stroke "black"
                , Attributes.strokeWidth "1"
                , Attributes.fill face.color
                , Attributes.fillOpacity "0.9"
                ]
                (Polygon2d face.points)

        plane =
            sketchPlane model
    in
        cube
            |> sortByDistanceToPlane (SketchPlane3d.plane plane)
            |> List.map
                (\face ->
                    { points =
                        (face.points
                            |> List.map
                                (\p ->
                                    Point3d.projectInto plane p
                                )
                        )
                    , color = face.color
                    }
                        |> draw
                )


sortByDistanceToPlane : Plane3d -> List Face -> List Face
sortByDistanceToPlane plane faces =
    faces
        |> List.sortWith (compareDistanceToPlane plane)


compareDistanceToPlane : Plane3d -> Face -> Face -> Order
compareDistanceToPlane plane face1 face2 =
    let
        minDistance face =
            face.points
                |> List.map (Point3d.signedDistanceFrom plane)
                |> List.minimum
                |> Maybe.withDefault 0

        d1 =
            face1 |> minDistance

        d2 =
            face2 |> minDistance
    in
        compare d1 d2


container : ( Float, Float ) -> ( Float, Float ) -> List (Svg Msg) -> Html Msg
container ( minX, minY ) ( maxX, maxY ) svgs =
    let
        width =
            maxX - minX

        height =
            maxY - minY

        topLeftFrame =
            Frame2d
                { originPoint = Point2d ( minX, maxY )
                , xDirection = Direction2d.x
                , yDirection = Direction2d.flip Direction2d.y
                }

        outline =
            Polygon2d
                [ Point2d.origin
                , Point2d ( 0, height )
                , Point2d ( width, height )
                , Point2d ( width, 0 )
                ]
    in
        Html.div [ style [ ( "flex", "1" ) ] ]
            [ Svg.svg
                [ Attributes.height (toString height)
                ]
                (svgs
                    |> List.map
                        (\svg ->
                            (Svg.relativeTo topLeftFrame svg)
                        )
                )
            ]


view : Model -> Html Msg
view model =
    let
        styles =
            [ ( "backgroundColor", "#212121" )
            , ( "height", "-1%" )
            , ( "display", "flex" )
            ]

        svgs =
            [ 1, 0.5, -1, -0.5 ]
                |> List.map
                    (\speed ->
                        container ( -150, -150 ) ( 150, 150 ) (svgProjection (speed * model))
                    )
    in
        Html.div [ style styles ] svgs


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    Time


init : ( Model, Cmd Msg )
init =
    ( 0, Cmd.none )



-- UPDATE


type Msg
    = Tick Time


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick newTime ->
            ( newTime, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every (-1 * millisecond) Tick
