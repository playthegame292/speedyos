#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="speedyos"
iso_label="SPEEDY_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="SpeedyOS <https://github.com/playthegame292/speedyos>"
iso_application="SpeedyOS Live/Install DVD"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="speedyos"
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/sudoers.d/10-speedyos-live"]="0:0:440"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/speedyos-installer"]="0:0:755"
  ["/usr/local/bin/speedyos-try-install"]="0:0:755"
  ["/usr/local/lib/speedyos/finalize-install"]="0:0:755"
  ["/etc/skel/Desktop/speedyos-welcome.desktop"]="0:0:755"
  ["/home/speedyuser"]="1000:1000:755"
  ["/home/speedyuser/Desktop"]="1000:1000:755"
  ["/home/speedyuser/.config"]="1000:1000:755"
  ["/home/speedyuser/.config/powerdevilrc"]="1000:1000:644"
  ["/home/speedyuser/.config/kscreenlockerrc"]="1000:1000:644"
  ["/home/speedyuser/Desktop/speedyos-welcome.desktop"]="1000:1000:755"
  ["/home/speedyuser/Desktop/speedyos-installer.desktop"]="1000:1000:755"
)
