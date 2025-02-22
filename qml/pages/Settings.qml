import QtQuick 2.0
import QtMultimedia 5.4
import Nemo.Configuration 1.0
import Sailfish.Silica 1.0

Item {
    property alias global: globalSettings
    property alias mode: modeSettings

    ConfigurationGroup {
        id: globalSettings
        path: "/uk/co/piggz/harbour-advanced-camera"
        property int cameraIndex: 0
        property string captureMode: "image"
        property bool swapZoomControl: false
        property string gridMode: "none"
        property int videoBitrate: 12800000
        property int audioBitrate: 128000
        property string storagePath: StandardPaths.home

        ConfigurationGroup {
            id: modeSettings
            path: globalSettings.cameraIndex + "/" + globalSettings.captureMode

            property int effect: CameraImageProcessing.ColorFilterNone
            property int exposure: Camera.ExposureManual
            property int flash: Camera.FlashOff
            property int focus: CameraFocus.FocusAuto
            property int iso: 0
            property string resolution: ""
            property int whiteBalance: CameraImageProcessing.WhiteBalanceAuto
        }
    }

    function strToSize(siz) {
        var w = parseInt(siz.substring(0, siz.indexOf("x")))
        var h = parseInt(siz.substring(siz.indexOf("x") + 1))
        return Qt.size(w, h)
    }

    function sizeToStr(siz) {
        return siz.width + "x" + siz.height
    }

    //Return either the current mode resolution or default resolution for that mode
    function resolution(mode) {
        if (settings.global.captureMode === mode
                && settings.mode.resolution !== "") {
            var res = strToSize(settings.mode.resolution)
            if (modelResolution.isValidResolution(res, mode)) {
                return res
            }
        }
        return modelResolution.defaultResolution(mode)
    }
}
