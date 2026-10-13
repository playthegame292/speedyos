import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: presentation
    color: "#1a1816"

    property int currentSlide: 0

    Timer {
        interval: 6000
        running: true
        repeat: true
        onTriggered: {
            currentSlide = (currentSlide + 1) % 4
        }
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: currentSlide
        interactive: false

        // Slide 1: Welcome
        Item {
            Column {
                anchors.centerIn: parent
                spacing: 16
                width: parent.width * 0.85

                Image {
                    source: "speedyos-logo.png"
                    width: 128
                    height: 128
                    smooth: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "🐾 Welcome to SpeedyOS"
                    font.pixelSize: 26
                    font.bold: true
                    color: "#f5ead7"
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
                Text {
                    text: "Fast Paws. Arch Power."
                    font.pixelSize: 18
                    color: "#c97d3e"
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
                Text {
                    text: "SpeedyOS is setting up your system. Sit back and relax while the files are unpacked and configured for your machine."
                    font.pixelSize: 14
                    color: "#d1c5b8"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
            }
        }

        // Slide 2: KDE Plasma 6
        Item {
            Column {
                anchors.centerIn: parent
                spacing: 16
                width: parent.width * 0.85

                Text {
                    text: "⚡ Modern KDE Plasma 6 Desktop"
                    font.pixelSize: 24
                    font.bold: true
                    color: "#f5ead7"
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
                Text {
                    text: "Wayland by default, a familiar panel and launcher, PipeWire sound and NetworkManager. Everything is configurable in System Settings."
                    font.pixelSize: 14
                    color: "#d1c5b8"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
            }
        }

        // Slide 3: Speedy CLI
        Item {
            Column {
                anchors.centerIn: parent
                spacing: 16
                width: parent.width * 0.85

                Text {
                    text: "🐾 Speedy Command Line Companion"
                    font.pixelSize: 24
                    font.bold: true
                    color: "#f5ead7"
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
                Text {
                    text: "Try speedy update, speedy install firefox and speedy doctor in a terminal. Each one shows the exact pacman or systemctl command it runs."
                    font.pixelSize: 14
                    color: "#d1c5b8"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
            }
        }

        // Slide 4: Arch Power
        Item {
            Column {
                anchors.centerIn: parent
                spacing: 16
                width: parent.width * 0.85

                Text {
                    text: "🏔️ The Power of Arch Linux"
                    font.pixelSize: 24
                    font.bold: true
                    color: "#f5ead7"
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
                Text {
                    text: "Enjoy rolling-release access to the latest packages, cutting-edge Linux kernels, and the vast Arch user community. Always up-to-date, always yours."
                    font.pixelSize: 14
                    color: "#d1c5b8"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
            }
        }
    }

    PageIndicator {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        count: swipeView.count
        currentIndex: swipeView.currentIndex
    }
}
