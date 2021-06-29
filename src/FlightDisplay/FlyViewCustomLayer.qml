/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.12
import QtQuick.Controls         2.4
import QtQuick.Dialogs          1.3
import QtQuick.Layouts          1.12

import QtLocation               5.3
import QtPositioning            5.3
import QtQuick.Window           2.2
import QtQml.Models             2.1

import QGroundControl               1.0
import QGroundControl.Airspace      1.0
import QGroundControl.Airmap        1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

Item {
    id: _root

    property var parentToolInsets               // These insets tell you what screen real estate is available for positioning the controls in your overlay
    property var totalToolInsets:   _toolInsets // These are the insets for your custom overlay additions
    property var mapControl

    // Property of Tools
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property color  _baseBGColor:           qgcPal.window

    // Property of Active Vehicle
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property real   _heading:               _activeVehicle   ? _activeVehicle.heading.rawValue : 0
    property bool   _available:             !isNaN(_activeVehicle.vibration.xAxis.rawValue)
    property real   _xValue:                _activeVehicle.vibration.xAxis.rawValue
    property real   _yValue:                _activeVehicle.vibration.yAxis.rawValue
    property real   _zValue:                _activeVehicle.vibration.zAxis.rawValue

    property real   _barWidth:              ScreenTools.defaultFontPixelWidth * 3
    property real   _barHeight:             ScreenTools.defaultFontPixelHeight * 10

    readonly property real _barMinimum:     0.0
    readonly property real _barMaximum:     90.0
    readonly property real _barBadValue:    60.0

    // Property of Vibration visible
    property var _vibeStatusVisible:        false

    // QGC Map Center Position
    property var _mapCoordinate:            QGroundControl.flightMapPosition

    // Property OpenWeather API Key
    property string   _openWeatherAPIkey:   QGroundControl.settingsManager ? QGroundControl.settingsManager.appSettings.openWeatherApiKey.value : null

    // Weather Function
    function getWeatherJSON() {
        if(!_openWeatherAPIkey) {
            weatherBackground.visible = false
            return
        }

        var requestUrl = "http://api.openweathermap.org/data/2.5/weather?lat=" + QGroundControl.flightMapPosition.latitude + "&lon="
                         + QGroundControl.flightMapPosition.longitude + "&appid=" + _openWeatherAPIkey + "&lang=kr&units=metric"

        var openWeatherRequest = new XMLHttpRequest()
        openWeatherRequest.open('GET', requestUrl, true);
        openWeatherRequest.onreadystatechange = function() {
            if (openWeatherRequest.readyState === XMLHttpRequest.DONE) {
                if (openWeatherRequest.status && openWeatherRequest.status === 200) {
                    var openWeatherText = JSON.parse(openWeatherRequest.responseText)

                    // Debug
                    //console.log(openWeatherRequest.responseText)

                    // Weather Tab
                    cityText.text       = openWeatherText.name
                    weatherText.text    = openWeatherText.weather[0].main
                    windDegreeText.text = getDirection(openWeatherText.wind.deg)
                    windSpeedText.text  = openWeatherText.wind.speed

                } else {
                    if(!openWeatherRequest.status) {
                        // Not Internet
                        mainWindow.showMessageDialog(qsTr("Internet Not Connect."), qsTr("Check Your Internet Connection."))
                    }
                    else if(openWeatherRequest.status === 401) {
                        // Key error
                        mainWindow.showMessageDialog(qsTr("OpenWeather Key Error"), qsTr("OpenWeather Key Error. Check Your API Key."))
                    }
                    else if(openWeatherRequest.status === 429) {
                        // Key use excess
                        mainWindow.showMessageDialog(qsTr("OpenWeather API Use Excess."), qsTr("OpenWeather API Use Excess. Make your request a little bit slower."))
                    }
                }
            }
        }
        openWeatherRequest.send()
    }

    // Degree Convert
    function getDirection(angle) {
        var directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
        var index = Math.round(((angle %= 360) < 0 ? angle + 360 : angle) / 45) % 8;
        return directions[index];
    }

    QGCToolInsets {
        id:                         _toolInsets
        leftEdgeCenterInset:        0
        leftEdgeTopInset:           0
        leftEdgeBottomInset:        0
        rightEdgeCenterInset:       0
        rightEdgeTopInset:          0
        rightEdgeBottomInset:       0
        topEdgeCenterInset:         0
        topEdgeLeftInset:           0
        topEdgeRightInset:          0
        bottomEdgeCenterInset:      0
        bottomEdgeLeftInset:        0
        bottomEdgeRightInset:       0
    }

    // Get Weather on Complete
    Component.onCompleted: {
        getWeatherJSON()
    }

    //-----------------------------------------------------------------------------------------------------
    //--Compass Indicator----------------------------------------------------------------------------------
    Rectangle {
        id:                     compassBackground
        anchors.bottom:         telemetryPanel.top
        anchors.bottomMargin:   ScreenTools.smallFontPointSize
        anchors.right:          attitudeIndicator.left
        anchors.rightMargin:    -attitudeIndicator.width / 2
        width:                  -anchors.rightMargin + compassBezel.width + (_toolsMargin * 2)
        height:                 attitudeIndicator.height / 1.8
        radius:                 2
        color:                  Qt.rgba(0,0,0,0)

        Rectangle {
            id:                     compassBezel
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin:     _toolsMargin
            anchors.left:           parent.left
            width:                  height
            height:                 parent.height - (northLabelBackground.height / 2) - (headingLabelBackground.height / 2)
            radius:                 height / 2
            border.color:           qgcPal.window
            border.width:           1
            color:                  Qt.rgba(0,0,0,0)
        }
        Rectangle {
            id:                         northLabelBackground
            anchors.top:                compassBezel.top
            anchors.topMargin:          -height / 2
            anchors.horizontalCenter:   compassBezel.horizontalCenter
            width:                      northLabel.contentWidth * 1.5
            height:                     northLabel.contentHeight * 1.5
            radius:                     ScreenTools.defaultFontPixelWidth  * 0.25
            color:                      qgcPal.windowShade

            QGCLabel {
                id:                 northLabel
                anchors.centerIn:   parent
                text:               "N"
                color:              qgcPal.text
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }
        Image {
            id:                 headingNeedle
            anchors.centerIn:   compassBezel
            height:             compassBezel.height * 0.75
            width:              height
            source:             "qrc:/qmlimages/compassInstrumentArrow.svg"
            fillMode:           Image.PreserveAspectFit
            sourceSize.height:  height
            transform: [
                Rotation {
                    origin.x:   headingNeedle.width  / 2
                    origin.y:   headingNeedle.height / 2
                    angle:      _heading
                }
            ]
        }
        Rectangle {
            id:                         headingLabelBackground
            anchors.top:                compassBezel.bottom
            anchors.topMargin:          -height / 2
            anchors.horizontalCenter:   compassBezel.horizontalCenter
            width:                      headingLabel.contentWidth * 1.5
            height:                     headingLabel.contentHeight * 1.5
            radius:                     ScreenTools.defaultFontPixelWidth  * 0.25
            color:                      qgcPal.windowShade

            QGCLabel {
                id:                 headingLabel
                anchors.centerIn:   parent
                text:               _heading
                color:              qgcPal.text
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }
    }

    //-----------------------------------------------------------------------------------------------------
    //--Attituede Indicator--------------------------------------------------------------------------------
    Rectangle {
        id:                     attitudeIndicator
        anchors.bottomMargin:   _toolsMargin
        anchors.rightMargin:    _toolsMargin
        anchors.bottom:         parent.bottom
        anchors.right:          parent.right
        height:                 ScreenTools.defaultFontPixelHeight * 6
        width:                  height
        radius:                 height * 0.5
        color:                  Qt.rgba(0,0,0,0.9)

        PeachAttitudeWidget {
            size:               parent.height * 0.9
            vehicle:            _activeVehicle
            showHeading:        true
            anchors.centerIn:   parent
        }
    }

    //-----------------------------------------------------------------------------------------------------
    //--Custom Telemetry Values Bar------------------------------------------------------------------------
    TelemetryValuesBar {
        id:                 telemetryPanel
        anchors.margins:    _toolsMargin
        anchors.right:      attitudeIndicator.left
        anchors.bottom:     parent.bottom
    }

    //-----------------------------------------------------------------------------------------------------
    //--MapScale Bar---------------------------------------------------------------------------------------
    MapScale {
        id:                 mapScale
        anchors.margins:    _toolsMargin
        anchors.right:       telemetryPanel.left
        anchors.bottom:     parent.bottom
        mapControl:         _mapControl
        buttonsOnLeft:      false
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && mapControl.pipState.state === mapControl.pipState.fullState

        property real centerInset: visible ? parent.height - y : 0
    }

    //-----------------------------------------------------------------------------------------------------
    //--Vibration Widget-----------------------------------------------------------------------------------
    Rectangle {
        id:                     vibrationBackground
        anchors.bottom:         telemetryPanel.top
        anchors.bottomMargin:   ScreenTools.smallFontPointSize * 2
        anchors.right:          compassBackground.left
        width:                  compassBezel.width
        height:                 compassBezel.height
        radius:                 height / 2
        color:                  Qt.rgba(0,0,0,1)

        MouseArea {
            anchors.fill: parent
            onClicked:    _vibeStatusVisible = !_vibeStatusVisible
        }

        QGCLabel {
            anchors.centerIn:   parent
            font.pointSize:     ScreenTools.largeFontPointSize
            Layout.alignment:   Qt.AlignHCenter
            color:              "white"
            text:               qsTr("Vibe")
        }
    }

    //-----------------------------------------------------------------------------------------------------
    //--Vibration Status-----------------------------------------------------------------------------------
    Rectangle {
        id:                     vibrationStatus
        anchors.left:           parent.left
        anchors.leftMargin:     _toolsMargin * 13
        anchors.top:            weatherBackground.bottom
        anchors.topMargin:      _toolsMargin
        width:                  -anchors.rightMargin + compassBezel.width + (_toolsMargin * 20)
        height:                 attitudeIndicator.height * 2.0
        radius:                 2
        color:                  qgcPal.window
        visible:                _vibeStatusVisible

        RowLayout {
            id:               barRow
            spacing:          ScreenTools.defaultFontPixelWidth * 2
            anchors.centerIn: parent

            ColumnLayout {
                Rectangle {
                    id:                 xBar
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _xValue) / (_barMaximum - _barMinimum))
                        color:          qgcPal.text
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("X")
                }
            }

            ColumnLayout {
                Rectangle {
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _yValue) / (_barMaximum - _barMinimum))
                        color:          qgcPal.text
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Y")
                }
            }

            ColumnLayout {
                Rectangle {
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _zValue) / (_barMaximum - _barMinimum))
                        color:          qgcPal.text
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Z")
                }
            }
        }

        // Max vibe indication line at 60
        Rectangle {
            anchors.topMargin:      xBar.height * (1.0 - ((_barBadValue - _barMinimum) / (_barMaximum - _barMinimum)))
            anchors.top:            barRow.top
            anchors.left:           barRow.left
            anchors.right:          barRow.right
            width:                  barRow.width
            height:                 1
            color:                  "red"
        }
    }

    //-----------------------------------------------------------------------------------------------------
    //--Weather Widget------------------------------------------------------==-----------------------------
    Rectangle {
        id:                     weatherBackground
        anchors.left:           parent.left
        anchors.leftMargin:     _toolsMargin * 13
        anchors.top:            parent.top
        anchors.topMargin:      _toolsMargin
        width:                  -anchors.rightMargin + compassBezel.width + (_toolsMargin * 20)
        height:                 attitudeIndicator.height * 1.7
        radius:                 2
        color:                  qgcPal.window

        MouseArea {
            anchors.fill: parent
            onClicked: getWeatherJSON()
        }

        ColumnLayout {
            id:         weatherValue
            spacing:    ScreenTools.defaultFontPixelWidth
            anchors.centerIn: parent

            // City
            Row {
                QGCLabel {
                    font.pointSize:     ScreenTools.mediumFontPointSize
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("City : ")
                }

                QGCLabel {
                    id:                 cityText
                    font.pointSize:     ScreenTools.mediumFontPointSize
                    Layout.alignment:   Qt.AlignHCenter
                }
            }

            // Weather
            Row {
                QGCLabel {
                    font.pointSize:     ScreenTools.mediumFontPointSize
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Weather : ")
                }

                QGCLabel {
                    id:                 weatherText
                    font.pointSize:     ScreenTools.mediumFontPointSize
                    Layout.alignment:   Qt.AlignHCenter
                }
            }

            // Wind Degree
            Row {
                QGCLabel {
                    font.pointSize:     ScreenTools.mediumFontPointSize
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Wind Degree : ")
                }

                QGCLabel {
                    id:                 windDegreeText
                    font.pointSize:     ScreenTools.mediumFontPointSize
                    Layout.alignment:   Qt.AlignHCenter
                }
            }

            // Wind Speed
            Row {
                QGCLabel {
                    font.pointSize:     ScreenTools.mediumFontPointSize
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Wind Speed : ")
                }

                QGCLabel {
                    id:                 windSpeedText
                    font.pointSize:     ScreenTools.mediumFontPointSize
                    Layout.alignment:   Qt.AlignHCenter
                }
            }

            // Widget Footer
            QGCLabel {
                font.pointSize:     ScreenTools.smallFontPointSize
                Layout.alignment:   Qt.AlignHCenter
                text:               qsTr("Provide by openweathermap")
            }

            QGCLabel {
                font.pointSize:     ScreenTools.smallFontPointSize
                Layout.alignment:   Qt.AlignHCenter
                text:               qsTr("(Click to Refresh)")
            }
        }//ColumnLayout
    }
}
