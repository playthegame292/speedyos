// SpeedyOS default desktop: the standard Plasma panel with SpeedyOS pins.
loadTemplate("org.kde.plasma.desktop.defaultPanel")

var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
    desktopsArray[j].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktopsArray[j].writeConfig("Image", "file:///usr/share/wallpapers/SpeedyOS/");
}

// Pin useful apps on the task manager.
var allPanels = panels();
for (var i = 0; i < allPanels.length; i++) {
    var tasks = allPanels[i].widgets("org.kde.plasma.icontasks");
    for (var t = 0; t < tasks.length; t++) {
        tasks[t].currentConfigGroup = ["General"];
        tasks[t].writeConfig("launchers", [
            "applications:org.kde.dolphin.desktop",
            "applications:firefox.desktop",
            "applications:org.kde.konsole.desktop",
            "applications:speedyos-welcome.desktop",
            "applications:systemsettings.desktop"
        ]);
    }
}
