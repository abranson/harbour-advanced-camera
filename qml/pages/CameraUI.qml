import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import QtSensors 5.0
import Nemo.KeepAlive 1.2
import uk.co.piggz.harbour_advanced_camera 1.0
import "../components/"

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    property alias camera: camera
    property bool _cameraReload: false
    property bool _completed: false
    property bool _focusAndSnap: false
    property bool _loadParameters: true
    property bool _recordingVideo: false
    property bool _manualModeSelected: false
    readonly property int zoomStepSize: 5
    property int controlsRotation: 0
    property int _pictureRotation: Screen.primaryOrientation == Qt.PortraitOrientation ? 0 : 90
    // Use easy device orientation values
    // 0=unknown, 1=portrait, 2=portrait inverted, 3=landscape, 4=landscape inverted
    property int _orientation: OrientationReading.TopUp

    OrientationSensor {
    id: orientationSensor
        active: true

        onReadingChanged: {
            if (reading.orientation >= OrientationReading.TopUp
                    && reading.orientation <= OrientationReading.RightUp) {
                _orientation = reading.orientation
                console.log("Orientation:", reading.orientation, _orientation);
            }

            switch (reading.orientation) {
            case OrientationReading.TopUp:
                _pictureRotation = 0; break
            case OrientationReading.TopDown:
                _pictureRotation = 180; break
            case OrientationReading.LeftUp:
                _pictureRotation = 270; break
            case OrientationReading.RightUp:
                _pictureRotation = 90; break
            default:
                // Keep device orientation at previous state
            }
        }
    }

    DisplayBlanking {
        preventBlanking: camera.videoRecorder.recorderState === CameraRecorder.RecordingState
    }

    // Orientation sensors for primary (back camera) & secondary (front camera)
    readonly property var _rotationValues: {
        "primary": [270, 270, 90, 180, 0, 270, 270],
        "secondary"//Uses orientation sensor value 0-6
        : [90, 90, 270, 180, 0, 90, 90],
        "ui": [0, 90, 0, 0, 270, 0, 0, 0, 180] //Uses enum value 1,2,4,8
    }

    readonly property int viewfinderOrientation: {
        var rotation = 0
        switch (orientation) {
        case Orientation.Landscape:
            rotation = 90
            break
        case Orientation.PortraitInverted:
            rotation = 180
            break
        case Orientation.LandscapeInverted:
            rotation = 270
            break
        }

        return (720 + camera.orientation + rotation) % 360
    }

    RotationAnimation on controlsRotation {
        running: _orientation === OrientationReading.TopUp
        to: 270
        duration: 200
        direction: RotationAnimation.Shortest
    }
    RotationAnimation on controlsRotation {
        running: _orientation === OrientationReading.TopDown
        to: 90
        duration: 200
        direction: RotationAnimation.Shortest
    }
    RotationAnimation on controlsRotation {
        running: _orientation === OrientationReading.LeftUp
        to: 180
        duration: 200
        direction: RotationAnimation.Shortest
    }
    RotationAnimation on controlsRotation {
        running: _orientation === OrientationReading.RightUp
        to: 0
        duration: 200
        direction: RotationAnimation.Shortest
    }

    focus: true

    defaultOrientationTransition: Transition {
        NumberAnimation {
        }
    }

    Camera {
        id: camera

        cameraState: page._completed
                     && !page._cameraReload ? Camera.ActiveState : Camera.UnloadedState

        imageProcessing.colorFilter: CameraImageProcessing.ColorFilterNone
        imageProcessing.denoisingLevel: 1
        imageProcessing.contrast: 1
        imageProcessing.sharpeningLevel: 1

        // Write Orientation to metadata
        metaData.orientation:  camera.position === Camera.FrontFace ? (720 + camera.orientation - _pictureRotation) % 360 : (720 + camera.orientation + _pictureRotation) % 360

        exposure {
            //exposureCompensation: -1.0
            exposureMode: Camera.ExposureAuto
        }

        flash.mode: Camera.FlashOff

        imageCapture {
            onImageCaptured: {
                photoPreview.source = preview // Show the preview in an Image
                console.log("Camera: captured", photoPreview.source)
            }
            onImageSaved: {
                console.log("Camera: image saved", path)
                galleryModel.append({
                                        "filePath": path,
                                        "isVideo": false
                                    })
            }
            onResolutionChanged: {
                console.log("Image resolution changed:",
                            camera.imageCapture.resolution)
                camera.viewfinder.resolution = getNearestViewFinderResolution()
            }
        }

        videoRecorder {
            audioSampleRate: 48000
            audioBitRate: settings.global.audioBitrate
            audioChannels: 1
            audioCodec: "audio/mpeg, mpegversion=(int)4"
            frameRate: 30
            videoCodec: "video/x-h264"
            mediaContainer: "video/quicktime, variant=(string)iso"
            videoEncodingMode: CameraRecorder.AverageBitRateEncoding
            videoBitRate: settings.global.videoBitrate

            onRecorderStateChanged: {
                if (camera.videoRecorder.recorderState === CameraRecorder.StoppedState) {
                    console.log("saved to: " + camera.videoRecorder.outputLocation)
                }
            }

            onRecorderStatusChanged: {
                if (camera.videoRecorder.recorderStatus === CameraRecorder.FinalizingStatus) {
                    var path = camera.videoRecorder.outputLocation.toString()
                    path = path.replace(/^(file:\/{2})/, "")
                    galleryModel.append({
                                            "filePath": path,
                                            "isVideo": true
                                        })
                }
            }

            onResolutionChanged: {
                console.log("Video resolution changed:",
                            settings.resolution("video"))
                camera.viewfinder.resolution = getNearestViewFinderResolution()
            }
        }

        onLockStatusChanged: {
            if (camera.lockStatus === Camera.Locked && _focusAndSnap
                    && !_recordingVideo) {
                camera.imageCapture.captureToLocation(
                            fsOperations.writableLocation(
                                "image",
                                settings.global.storagePath) + "/IMG_" + Qt.formatDateTime(
                                new Date(), "yyyyMMdd_hhmmss") + ".jpg")
                animFlash.start()
                _focusAndSnap = false
            }
        }

        onCameraStatusChanged: {
            console.log("Camera status:", cameraStatus)

            if (cameraStatus === Camera.StartingStatus) {
                settingsOverlay.setCamera(camera)
            }

            if (cameraStatus === Camera.ActiveStatus && _loadParameters) {
                if (zoomSlider.maximumValue != camera.maximumDigitalZoom) {
                    zoomSlider.maximumValue = camera.maximumDigitalZoom
                }

                if (settings.global.captureMode === "video") {
                    camera.captureMode = Camera.CaptureVideo
                    btnModeSwitch._hilighted2 = true
                } else {
                    camera.captureMode = Camera.CaptureStillImage
                    btnModeSwitch._hilighted2 = false
                }

                settingsOverlay.setMode(settings.global.captureMode)

                camera.viewfinder.resolution = getNearestViewFinderResolution()
                applySettings()

                lblResolution.forceUpdate = !lblResolution.forceUpdate
            }
        }

        onOrientationChanged: {
            console.log("Orientation:", orientation);
        }
    }

    Item {
        id: controlsContainer
        rotation: _rotationValues["ui"][page.orientation]
        width: page.orientation === Orientation.Portrait
               || page.orientation === Orientation.PortraitInverted ? parent.height : parent.width
        height: page.orientation === Orientation.Portrait
                || page.orientation === Orientation.PortraitInverted ? parent.width : parent.height
        anchors.centerIn: parent

        GridOverlay {
            aspect: settings.global.captureMode
                    === "image" ? ratio(camera.imageCapture.resolution) : ratio(
                                      camera.videoRecorder.resolution)

            function ratio(resolution) {
                return resolution.width / resolution.height
            }
        }

        Slider {
            id: zoomSlider
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: parent.width * 0.75
            minimumValue: 1
            maximumValue: camera.maximumDigitalZoom
            value: camera.digitalZoom
            stepSize: zoomStepSize
            rotation: {
                // Zoom slider should be slide up to zoom in
                if (_orientation === OrientationReading.TopUp)
                    return -180
                else if (_orientation === OrientationReading.TopDown)
                    return 0
                else if (_orientation === OrientationReading.LeftUp)
                    return 180
                else if (_orientation === OrientationReading.RightUp)
                    return 0
            }

            onValueChanged: {
                if (value != camera.digitalZoom)
                    camera.digitalZoom = value
            }

            Connections {
                target: camera

                onDigitalZoomChanged: {
                    zoomSlider.value = camera.digitalZoom
                }
            }
        }

        Image {
            id: photoPreview
            rotation: page.controlsRotation
            onStatusChanged: {
                if (photoPreview.status === Image.Ready) {
                    console.log('photoPreview ready')
                }
            }
        }

        RoundButton {
            id: btnCapture

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingMedium

            size: Theme.itemSizeLarge
            rotation: page.controlsRotation

            image: shutterIcon()
            icon.anchors.margins: Theme.paddingSmall
            onClicked: doShutter()
        }

        Rectangle {
            id: rectFlash
            anchors.fill: parent
            opacity: 0

            NumberAnimation on opacity {
                id: animFlash
                from: 1.0
                to: 0.0
                duration: 200
            }
        }

        Row {
            anchors.horizontalCenter: {
                if ((_orientation === OrientationReading.TopUp)
                        || (_orientation === OrientationReading.TopDown))
                    return parent.right
                else
                    return parent.horizontalCenter
            }

            anchors.verticalCenter: {
                if ((_orientation === OrientationReading.TopUp)
                        || (_orientation === OrientationReading.TopDown))
                    return parent.verticalCenter
                else
                    return parent.top
            }

            anchors.verticalCenterOffset: {
                if ((_orientation === OrientationReading.TopUp)
                        || (_orientation === OrientationReading.TopDown))
                    return 0
                else
                    return height
            }

            anchors.horizontalCenterOffset: {
                if ((_orientation === OrientationReading.TopUp)
                        || (_orientation === OrientationReading.TopDown))
                    return -(btnCapture.width + height)
                else
                    return 0
            }

            spacing: Theme.paddingMedium
            rotation: page.controlsRotation

            Label {
                property bool forceUpdate: false
                id: lblResolution
                color: Theme.lightPrimaryColor
                text: (forceUpdate
                       || !forceUpdate) ? settings.sizeToStr(
                                              (settings.global.captureMode === "video" ? camera.videoRecorder.resolution : camera.imageCapture.resolution)) : ""
            }

            Label {
                id: lblRecordTime
                visible: settings.global.captureMode === "video"
                color: Theme.lightPrimaryColor
                //text: Qt.formatDateTime(new Date(camera.videoRecorder.duration), "hh:mm:ss") //Doest work as return 01:00:00 for 0
                text: msToTime(camera.videoRecorder.duration)
            }
        }

        SettingsOverlay {
            id: settingsOverlay
            iconRotation: page.controlsRotation
        }

        RoundButton {
            id: btnGallery

            visible: galleryModel.count > 0
            enabled: visible

            anchors.top: btnCameraSwitch.bottom
            anchors.bottomMargin: Theme.paddingMedium
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingMedium
            icon.rotation: page.controlsRotation

            size: Theme.itemSizeSmall

            image: "image://theme/icon-m-image"

            onClicked: {
                camera.stop()
                pageStack.push(Qt.resolvedUrl("GalleryUI.qml"), {
                                   "fileList": galleryModel
                               })
            }
        }

        RoundButton {
            id: btnCameraSwitch
            icon.source: "image://theme/icon-camera-switch"
            visible: QtMultimedia.availableCameras.length > 1
            icon.rotation: page.controlsRotation
            anchors {
                top: parent.top
                topMargin: Theme.paddingMedium
                right: parent.right
                rightMargin: Theme.paddingMedium
            }
            onClicked: {
                console.log("Setting temp resolution")
                camera.imageCapture.setResolution(settings.strToSize("320x240"))
                camera.stop()
                _loadParameters = false
                if (++settings.global.cameraIndex >= QtMultimedia.availableCameras.length) {
                    settings.global.cameraIndex = 0;
                }
                tmrDelayedStart.start()
            }
        }

        IconSwitch {
            id: btnModeSwitch
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingMedium
            anchors.right: parent.right
            anchors.rightMargin: (rotation === 90
                                  || rotation === 270) ? Theme.paddingLarge
                                                         * 2 : Theme.paddingMedium
            rotation: page.controlsRotation
            width: Theme.itemSizeSmall

            icon1Source: "image://theme/icon-camera-camera-mode"
            icon2Source: "image://theme/icon-camera-video"
            button1Name: "image"
            button2Name: "video"

            onClicked: {
                console.log("selected:", name)
                camera.stop()
                settingsOverlay.setMode(name)
                if (name === button1Name) {
                    camera.captureMode = Camera.CaptureStillImage
                } else {
                    camera.captureMode = Camera.CaptureVideo
                }
                camera.start()
            }
        }
    }

    //End controlsContainer
    MouseArea {
        id: mouseFocusArea
        anchors.fill: parent
        z: -1 //Send to back
        onClicked: {

            if (settingsOverlay.panelOpen) {
                settingsOverlay.hideAllPanels()
                return
            }

            // If in auto or macro focus mode, focus on the specified point
            if (camera.focus.focusMode === Camera.FocusAuto
                    || camera.focus.focusMode === Camera.FocusMacro
                    || camera.focus.focusMode === Camera.FocusContinuous) {
                var focusPoint
                switch ((360 - viewfinderOrientation) % 360) {
                case 90:
                    focusPoint = Qt.point(mouse.y, width - mouse.x)
                    break
                case 180:
                    focusPoint = Qt.point(width - mouse.x, height - mouse.y)
                    break
                case 270:
                    focusPoint = Qt.point(height - mouse.y, mouse.x)
                    break
                default:
                    focusPoint = Qt.point(mouse.x, mouse.y)
                    break
                }

                // Normalize the focus point.
                focusPoint.x = focusPoint.x / Math.max(page.width, page.height)
                focusPoint.y = focusPoint.y / Math.min(page.width, page.height)

                camera.focus.focusPointMode = Camera.FocusPointCustom
                camera.focus.setCustomFocusPoint(focusPoint)
            }
            camera.searchAndLock()
        }
    }

    Rectangle {
        id: focusCircle
        height: (camera.lockStatus === Camera.Locked) ? Theme.itemSizeSmall : Theme.itemSizeMedium
        width: height
        radius: width / 2
        border.width: 4
        border.color: focusColor()
        color: "transparent"
        visible: camera.focus.focusPointMode === Camera.FocusPointCustom

        x: {
            var ret = 0
            switch ((360 - viewfinderOrientation) % 360) {
            case 90:
                ret = page.width - camera.focus.customFocusPoint.y * page.width
                break
            case 180:
                ret = page.width - camera.focus.customFocusPoint.x * page.width
                break
            case 270:
                ret = camera.focus.customFocusPoint.y * page.width
                break
            default:
                ret = camera.focus.customFocusPoint.x * page.width
                break
            }
        }

        y: {
            var ret = 0
            switch ((360 - viewfinderOrientation) % 360) {
            case 90:
                ret = camera.focus.customFocusPoint.x * page.height
                break
            case 180:
                ret = page.height - camera.focus.customFocusPoint.y * page.height
                break
            case 270:
                ret = page.height - camera.focus.customFocusPoint.x * page.height
                break
            default:
                ret = camera.focus.customFocusPoint.y * page.height
                break
            }
        }

        transform: Translate {
            x: -focusCircle.width / 2
            y: -focusCircle.height / 2
        }
    }

    Component.onCompleted: {
        console.log("Setting initial camera ", QtMultimedia.availableCameras[settings.global.cameraIndex].deviceId)
        camera.deviceId = QtMultimedia.availableCameras[settings.global.cameraIndex].deviceId
        _completed = true
    }

    Connections {
        target: window

        onActiveFocusChanged: {
            if (!window.activeFocus) {
                camera.stop()
            } else {
                if (pageStack.depth === 1)
                    camera.start()
            }
        }
    }

    Connections {
        target: pageStack

        onDepthChanged: {
            if (pageStack.depth === 1) {
                console.log("Calling camera.start() due to pageStack change")
                camera.start()
            }
        }
    }

    ListModel {
        id: galleryModel
    }

    ListModel {
        id: viewfinderResolutionModel
    }

    Timer {
        id: tmrDelayedStart
        repeat: false
        running: false
        interval: 200
        onTriggered: {
            var newCamera = QtMultimedia.availableCameras[settings.global.cameraIndex]
            console.log("camera delayed start", newCamera.deviceId, newCamera.displayName, newCamera.position, newCamera.orientation)
            _loadParameters = true
            camera.deviceId = newCamera.deviceId
            camera.start()
            _cameraReload = true
        }
    }

    Timer {
        id: reloadTimer
        interval: 100
        running: page._cameraReload
                 && camera.cameraStatus === Camera.UnloadedStatus
        onTriggered: {
            page._cameraReload = false
        }
    }

    Keys.onVolumeUpPressed: {
        if (settings.global.swapZoomControl) {
            zoomOut()
        } else {
            zoomIn()
        }
    }

    Keys.onVolumeDownPressed: {
        if (settings.global.swapZoomControl) {
            zoomIn()
        } else {
            zoomOut()
        }
    }

    Keys.onPressed: {
        if (event.isAutoRepeat) {
            return
        }
        if (event.key === Qt.Key_CameraFocus
                && settings.mode.focus === Camera.FocusManual) {
            camera.searchAndLock()
        } else if (event.key === Qt.Key_Camera) {
            doShutter()
        }
    }

    function applySettings() {
        console.log("Applying settings in", settings.global.captureMode,
                    "mode for", camera.deviceIndex, "camera with status",
                    camera.cameraStatus)

        camera.imageProcessing.setColorFilter(settings.mode.effect)
        camera.exposure.setExposureMode(settings.mode.exposure)
        camera.flash.setFlashMode(settings.mode.flash)
        camera.imageProcessing.setWhiteBalanceMode(settings.mode.whiteBalance)
        setFocusMode(settings.mode.focus)

        if (settings.mode.iso === 0) {
            camera.exposure.setAutoIsoSensitivity()
        } else {
            camera.exposure.setManualIsoSensitivity(settings.mode.iso)
        }

        camera.imageCapture.setResolution(settings.resolution("image"))
        camera.videoRecorder.resolution = settings.resolution("video")
    }

    function setFocusMode(focus) {
        if (focus === Camera.FocusManual) {
            if (camera.focus.focusMode !== Camera.FocusAuto) {
                camera.stop()
                camera.focus.setFocusMode(Camera.FocusAuto)
                camera.start()
            }
            _manualModeSelected = true
        } else {
            _manualModeSelected = false
            if (camera.focus.focusMode !== focus) {
                camera.stop()
                camera.focus.setFocusMode(focus)
                camera.start()
            }
        }
        settings.mode.focus = focus

        //Set the focus point back to centre
        camera.focus.setFocusPointMode(Camera.FocusPointAuto)
        camera.searchAndLock()
    }

    function getNearestViewFinderResolution() {

        /// Tries to find the most correct ViewFinder resolution
        /// for the selected camera settings
        ///
        /// In order of preference:
        ///  * Exact match to picture size in supported viewfinder resolutions
        ///  * Highest resolution of the same picture ratio in supported viewfinder resolutions
        ///  * Default to 800x600 for 4:3, and 1280x720 for everything else and hope it's valid
        var pictureResolution = settings.resolution(settings.global.captureMode)
        console.log("Target viewfinder resolution", pictureResolution.width, pictureResolution.height)
        var supportedResolutions = camera.supportedViewfinderResolutions()
        var cameraRatio = modelResolution.sizeToRatio(pictureResolution)
        if (pictureResolution.width > 0 && supportedResolutions) {
            // Check for exact match to picture size
            for (var i=0; i<supportedResolutions.length; i++) {
                var thisRes = Qt.size(supportedResolutions[i]["width"], supportedResolutions[i]["height"])
                if (pictureResolution === thisRes) {
                    console.log("Exact match!", thisRes)
                    return thisRes
                }
            }
            // Find highest ratio match
            for (var i=supportedResolutions.length-1; i>=0; i--) {
            var thisRes = Qt.size(supportedResolutions[i]["width"], supportedResolutions[i]["height"])
                console.log("Viewfinder resolution for ratio:", thisRes)
                if (cameraRatio === modelResolution.sizeToRatio(thisRes)) {
                    console.log("Ratio match!" ,thisRes)
                    return thisRes
                }
            }
        }
        console.log("Using default for ratio")
        if (cameraRatio.width == 4 && cameraRatio.height == 3)
            return Qt.size(800, 600)
        else
            return Qt.size(1280, 720)
    }

    function doShutter() {
        if (camera.captureMode === Camera.CaptureStillImage) {
            if ((camera.focus.focusMode === Camera.FocusAuto
                 && !_manualModeSelected)
                    || camera.focus.focusMode === Camera.FocusMacro
                    || camera.focus.focusMode === Camera.FocusContinuous) {
                _focusAndSnap = true
                camera.searchAndLock()
            } else {
                camera.imageCapture.captureToLocation(
                            fsOperations.writableLocation(
                                "image",
                                settings.global.storagePath) + "/IMG_" + Qt.formatDateTime(
                                new Date(), "yyyyMMdd_hhmmss") + ".jpg")
                animFlash.start()
            }
        } else {
            if (camera.videoRecorder.recorderStatus === CameraRecorder.RecordingStatus) {
                camera.videoRecorder.stop()
            } else {
                camera.videoRecorder.outputLocation = fsOperations.writableLocation(
                            "video",
                            settings.global.storagePath) + "/VID_" + Qt.formatDateTime(
                            new Date(), "yyyyMMdd_hhmmss") + ".mp4"
                camera.videoRecorder.record()
            }
        }
    }

    function zoomIn() {
        if (camera.digitalZoom < camera.maximumDigitalZoom) {
            camera.digitalZoom += zoomStepSize
        }
    }

    function zoomOut() {
        if (camera.digitalZoom > 1) {
            camera.digitalZoom -= zoomStepSize
        }
    }

    function focusColor() {
        if (camera.lockStatus === Camera.Unlocked) {
            return "white"
        } else if (camera.lockStatus === Camera.Searching) {
            return "#e3e3e3" //light grey
        } else {
            return "lightgreen"
        }
    }

    function shutterIcon() {
        if (camera.captureMode === Camera.CaptureStillImage) {
            return "image://theme/icon-camera-shutter"
        } else {
            if (camera.videoRecorder.recorderStatus === CameraRecorder.RecordingStatus) {
                return "image://theme/icon-camera-video-shutter-off"
            } else {
                return "image://theme/icon-camera-video-shutter-on"
            }
        }
    }

    function msToTime(millis) {
        return new Date(millis).toISOString().substr(11, 8)
    }
}
