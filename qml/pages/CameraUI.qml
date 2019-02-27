import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Media 1.0
//import com.jolla.camera 1.0
import QtMultimedia 5.4
import QtQuick.Layouts 1.0
import uk.co.piggz.harbour_advanced_camera 1.0
import Nemo.Configuration 1.0
import "../components/"

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.Landscape

    property string temp_resolution_str: ""

    ConfigurationValue {
        id: effectMode
        key: "/uk/co/piggz/harbour-advanced-camera/effectMode"
        defaultValue: ""
    }

    ConfigurationValue {
        id: exposureMode
        key: "/uk/co/piggz/harbour-advanced-camera/exposureMode"
        defaultValue: ""
    }

    ConfigurationValue {
        id: focusMode
        key: "/uk/co/piggz/harbour-advanced-camera/focusMode"
        defaultValue: ""
    }

    ConfigurationValue {
        id: resolution
        key: "/uk/co/piggz/harbour-advanced-camera/resolution"
        defaultValue: ""
    }

    ConfigurationValue {
        id: whiteBalanceMode
        key: "/uk/co/piggz/harbour-advanced-camera/whiteBalanceMode"
        defaultValue: ""
    }

    ConfigurationValue {
        id: flashMode
        key: "/uk/co/piggz/harbour-advanced-camera/flashMode"
        defaultValue: ""
    }

    ConfigurationValue {
        id: isoMode
        key: "/uk/co/piggz/harbour-advanced-camera/isoMode"
        defaultValue: ""
    }


    Rectangle {
        parent: window
        anchors.fill: parent
        z: -1
        color: "black"
    }

    VideoOutput {
        id: captureView
        anchors.fill: parent
        source: camera
        rotation: 180
        orientation: camera.orientation
        onOrientationChanged: {
            console.log(orientation)
        }
    }

    Camera {
        id: camera

        imageProcessing.colorFilter: CameraImageProcessing.ColorFilterNone

        viewfinder.resolution: Qt.size(1920, 1080)
        exposure {
            //exposureCompensation: -1.0
            exposureMode: Camera.ExposureAuto
        }

        flash.mode: Camera.FlashOff

        imageCapture {
            onImageCaptured: {
                photoPreview.source = preview  // Show the preview in an Image
                console.log("Camera: captured", photoPreview.source)
            }
            onImageSaved: {
                console.log("Camera: image saved", path)
                modelData.append({ photoPath: "file://" + path })
                btnGallery.visible = true
            }
        }
    }

    Image {
        id: photoPreview

        onStatusChanged: {
            if (photoPreview.status == Image.Ready) {
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

        image: "image://theme/icon-camera-shutter"

        onClicked: {
            camera.imageCapture.capture();
            animFlash.start();
        }
    }

    Rectangle {
        id: rectFlash
        anchors.fill: parent
        opacity: 0

        NumberAnimation on opacity {id:animFlash; from: 1.0; to: 0.0; duration: 200 }
    }

    Item {
        id: buttonPanel
        visible: true
        enabled: visible

        height: parent.height
        width: 2 * Theme.itemSizeSmall + 4 * Theme.paddingMedium
        anchors.left: parent.left
        anchors.top: parent.top

        Behavior on x {
            NumberAnimation { duration: 150 }
        }

        Row {
            spacing: Theme.paddingSmall
            anchors.fill: parent
            anchors.margins: Theme.paddingSmall

            ColumnLayout {
                id: colButtons
                spacing: Theme.paddingSmall
                width: Theme.itemSizeSmall
                
                RoundButton {
                    id: btnScene
                    icon.color: Theme.primaryColor
                    image: "../pics/icon-m-effect.png"

                    onClicked: {
                        hidePanels()
                        panelEffects.show();
                    }
                }
                RoundButton {
                    id: btnExposure
                    image: "image://theme/icon-camera-exposure-compensation"

                    onClicked: {
                        hidePanels()
                        panelExposure.show();
                    }
                }
                RoundButton {
                    id: btnFocus
                    image: focusIcon()

                    onClicked: {
                        hidePanels()
                        panelFocus.show();
                    }
                }
                RoundButton {
                    id: btnResolution
                    icon.color: Theme.primaryColor
                    image: "../pics/icon-m-resolution.png"

                    onClicked: {
                        hidePanels();
                        panelResolution.show();
                    }
                }
                RoundButton {
                    id: btnWhiteBalance
                    image: whiteBalanceIcon()

                    onClicked: {
                        hidePanels();
                        panelWhiteBalance.show();
                    }
                }
                RoundButton {
                    id: btnFlash
                    image: flashIcon()

                    onClicked: {
                        hidePanels();
                        panelFlash.show();
                    }
                }
            }
            ColumnLayout {
                id: colButtons2
                spacing: Theme.paddingSmall
                width: Theme.itemSizeSmall

                RoundButton {
                    id: btnIso
                    icon.color: Theme.primaryColor
                    image: isoIcon()

                    onClicked: {
                        hidePanels()
                        panelIso.show();
                    }
                }

            }
            /*
            Item {
                id: menuButtonContainer
                height: parent.height
                width: buttonPanel.buttonSize
                
                RoundButton {
                    id: btnMenu
                    height: buttonPanel.buttonSize
                    width: buttonPanel.buttonSize
                    anchors.verticalCenter: parent.verticalCenter
                    image: buttonPanel.menuVisible ? "image://theme/icon-m-left" : "image://theme/icon-m-right"
                    onClicked: {
                        buttonPanel.menuVisible = !buttonPanel.menuVisible;
                    }
                }
                

            }
            */
        }

    }

    DockedListView {
        id: panelEffects
        model: modelEffects
        selectedItem: effectMode.value

        onClicked: {
            camera.imageProcessing.setColorFilter(value);
            effectMode.value = value;
            hidePanels();
        }
    }

    DockedListView {
        id: panelExposure
        model: modelExposure
        selectedItem: exposureMode.value


        onClicked: {
            camera.exposure.setExposureMode(value);
            exposureMode.value = value;
            hidePanels();
        }
    }

    DockedListView {
        id: panelFlash
        model: modelFlash
        selectedItem: flashMode.value


        onClicked: {
            camera.flash.setFlashMode(value);
            flashMode.value = value;
            hidePanels();
        }
    }

    DockedListView {
        id: panelWhiteBalance
        model: modelWhiteBalance
        selectedItem: whiteBalanceMode.value


        onClicked: {
            camera.imageProcessing.setWhiteBalanceMode(value);
            whiteBalanceMode.value = value;
            hidePanels();
        }
    }

    DockedListView {
        id: panelFocus
        model: modelFocus
        selectedItem: focusMode.value

        onClicked: {
            setFocusMode(value);
            hidePanels();
        }
    }

    DockedListView {
        id: panelIso
        model: modelIso
        selectedItem: isoMode.value

        onClicked: {
            if (value === 0) {
                camera.exposure.setAutoIsoSensitivity();
            } else {
                camera.exposure.setManualIsoSensitivity(value);
            }
            isoMode.value = value;
            hidePanels();
        }
    }

    DockedListView {
        id: panelResolution
        model: sortedModelResolution
        selectedItem: strToSize(temp_resolution_str)

        onClicked: {
            camera.imageCapture.setResolution(value);
            temp_resolution_str = sizeToStr(value);
            resolution.value = temp_resolution_str;
            hidePanels();
            console.log("selected resolution", value, temp_resolution_str, resolution.value);
        }
    }

    EffectsModel {
        id: modelEffects
    }

    ExposureModel {
        id: modelExposure
    }

    IsoModel {
        id: modelIso
    }

    WhiteBalanceModel {
        id: modelWhiteBalance
    }

    FocusModel {
        id: modelFocus
    }

    FlashModel {
        id: modelFlash
    }

    Rectangle {
        id: focusCircle
        height: Theme.itemSizeHuge
        width: height
        radius: width / 2
        border.width: 2
        border.color: "white"
        color: "transparent"
        x: parent.width / 2
        y: parent.height / 2
        transform: Translate {
            x: -focusCircle.width / 2
            y: -focusCircle.height / 2
        }

    }

    Label {
        id: lblResolution
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.paddingMedium
        color: Theme.lightPrimaryColor
        text: temp_resolution_str
    }

    MouseArea {
        id: mouseFocusArea
        anchors.fill: parent
        z: -1 //Send to back
        onClicked: {
            // If in auto or macro focus mode, focus on the specified point
            if (camera.focus.focusMode == Camera.FocusAuto || camera.focus.focusMode == Camera.FocusMacro || camera.focus.focusMode == Camera.FocusContinuous) {
                focusCircle.x = mouse.x;
                focusCircle.y = mouse.y;

                camera.focus.focusPointMode = Camera.FocusPointCustom;
                camera.focus.setCustomFocusPoint(Qt.point((mouse.x / page.width), (mouse.y / page.height)));
            }
            camera.searchAndLock();
        }
    }

    /*
    GStreamerVideoOutput {
        id: videoOutput
        source: camera
        orientation: camera.orientation

        onOrientationChanged: {
            console.log(orientation)
        }

        z: -1
        anchors.fill: parent

        Behavior on y {
            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
        }
    }
    */

    ListModel {
        id: modelData
    }

    Timer {
        id: delayQuery
        interval: 1000
        running: true
        repeat: false
        onTriggered: {
            modelExposure.setCamera(camera);
            modelEffects.setCamera(camera);
            modelIso.setCamera(camera);
            modelWhiteBalance.setCamera(camera);
            modelFocus.setCamera(camera);
            modelFlash.setCamera(camera);

            modelResolution.setImageCapture(camera.imageCapture);
        }
    }

    Component.onCompleted: {
        applySettings();
    }

    function applySettings() {
        camera.imageProcessing.setColorFilter(effectMode.value);
        camera.exposure.setExposureMode(exposureMode.value);
        camera.flash.setFlashMode(flashMode.value);
        camera.imageProcessing.setWhiteBalanceMode(whiteBalanceMode.value);
        setFocusMode(focusMode.value);

        if (isoMode.value === 0) {
            camera.exposure.setAutoIsoSensitivity();
        } else {
            camera.exposure.setManualIsoSensitivity(isoMode.value);
        }

        camera.imageCapture.setResolution(strToSize(resolution.value));
        temp_resolution_str = resolution.value;
    }

    function hidePanels() {
        //buttonPanel.menuVisible = false;
        panelExposure.hide();
        panelEffects.hide();
        panelWhiteBalance.hide();
        panelFlash.hide();
        panelFocus.hide();
        panelIso.hide();
        panelResolution.hide();
    }

    function flashIcon() {
        var flashIcon = "";
        switch(flashMode.value) {
        case Camera.FlashAuto:
            flashIcon = "image://theme/icon-camera-flash-automatic";
            break;
        case Camera.FlashOn:
            flashIcon = "image://theme/icon-camera-flash-on";
            break;
        case Camera.FlashOff:
            flashIcon = "image://theme/icon-camera-flash-off";
            break;
        case Camera.FlashRedEyeReduction:
            flashIcon = "image://theme/icon-camera-flash-redeye";
            break;
        default:
            flashIcon = "image://theme/icon-camera-flash-on";
            break;

        }
        return flashIcon;
    }

    function focusIcon() {
        var focusIcon = "";
        switch(focusMode.value) {
        case Camera.FocusAuto:
            focusIcon = "image://theme/icon-camera-focus-auto";
            break;
        case Camera.FocusManual:
            focusIcon = "../pics/icon-camera-focus-manual.png";
            break;
        case Camera.FocusMacro:
            focusIcon = "image://theme/icon-camera-focus-macro";
            break;
        case Camera.FocusHyperfocal:
            focusIcon = "../pics/icon-camera-focus-hyperfocal.png";
            break;
        case Camera.FocusContinuous:
            focusIcon = "../pics/icon-camera-focus-continuous.png";
            break;
        case Camera.FocusInfinity:
            focusIcon = "image://theme/icon-camera-focus-infinity";
            break;
        default:
            focusIcon = "image://theme/icon-camera-focus";
            break;

        }
        return focusIcon;
    }

    function whiteBalanceIcon() {
        var wbIcon = "";
        switch(whiteBalanceMode.value) {
        case CameraImageProcessing.WhiteBalanceAuto:
            wbIcon = "image://theme/icon-camera-wb-automatic";
            break;
        case CameraImageProcessing.WhiteBalanceSunlight:
            wbIcon = "image://theme/icon-camera-wb-sunny";
            break;
        case CameraImageProcessing.WhiteBalanceCloudy:
            wbIcon = "image://theme/icon-camera-wb-cloudy";
            break;
        case CameraImageProcessing.WhiteBalanceShade:
            wbIcon = "image://theme/icon-camera-wb-shade";
            break;
        case CameraImageProcessing.WhiteBalanceTungsten:
            wbIcon = "image://theme/icon-camera-wb-tungsten";
            break;
        case CameraImageProcessing.WhiteBalanceFluorescent:
            wbIcon = "image://theme/icon-camera-wb-fluorecent";
            break;
        case CameraImageProcessing.WhiteBalanceSunset:
            wbIcon = "image://theme/icon-camera-wb-sunset";
            break;
        case CameraImageProcessing.WhiteBalanceFlash:
            wbIcon = "image://theme/icon-camera-wb-default"; //TODO need icon
            break;
        default:
            wbIcon = "image://theme/icon-camera-wb-default";
            break;

        }
        return wbIcon;
    }

    function isoIcon() {
        var iso = "";
        if (isoMode.value === 0) {
            iso = "../pics/icon-m-iso-auto.png";
        } else if (isoMode.value === 1) {
            iso = "../pics/icon-m-iso-hjr.png";
        } else {
            iso = "../pics/icon-m-iso-" + isoMode.value + ".png";
        }

        return iso;
    }

    function strToSize(siz) {
        console.log("Converting ", siz, " to size");

        var w = parseInt(siz.substring(0, siz.indexOf("x")));
        var h = parseInt(siz.substring(siz.indexOf("x") + 1));

        return Qt.size(w,h);
    }

    function sizeToStr(siz) {
        console.log("Converting ", siz, " to string");

        return siz.width + "x" + siz.height;
    }

    function setFocusMode(focus) {
        if (camera.focus.focusMode !== focus) {
            camera.unlock();
            camera.focus.setFocusMode(focus);
            focusMode.value = focus;

            //Set the focus point pack to centre
            focusCircle.x = page.width / 2;
            focusCircle.y = page.height / 2;

            camera.focus.focusPointMode = Camera.FocusPointAuto
            camera.searchAndLock();
        }
    }

    RoundButton {
        id: btnGallery

        visible: false
        enabled: visible

        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingMedium
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingMedium

        size: Theme.itemSizeSmall

        image: "image://theme/icon-m-image"

        onClicked: {
            pageStack.push(Qt.resolvedUrl("GalleryUI.qml"), { "photoList": modelData })
        }
    }
}
