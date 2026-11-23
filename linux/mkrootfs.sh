#!/usr/bin/env sh
# Makes the Alpine Linux root file system for the PYNQ-Z2 (linux/README.md). It runs an armv7 Alpine
# container: the host must run ARM binaries through qemu-user binfmt with the F flag, and docker must
# be available. Inside the container, apk installs the packages into an empty directory as root, and
# mkfs.f2fs and sload.f2fs make the image from it, so the owners and modes come from apk and not from the host.
#
#   [WORK=dir] [ALPINE=3.24.4] sh mkrootfs.sh key.pub /path/to/modules
#
# key.pub is the SSH public key for root. /path/to/modules is the INSTALL_MOD_PATH of the kernel build
# (build-kernel.sh writes WORK/modules). Writes WORK/rootfs.f2fs, ./pynq-rootfs in the current
# directory by default: Alpine (OpenRC, busybox, sshd, chrony, DHCP on eth0) on F2FS, 1 GiB, label rootfs.
# Root has no password on the console (ttyPS0); SSH accepts only the key.
set -eu
[ $# -eq 2 ] && [ -f "$1" ] && [ -d "$2/lib/modules" ] || { echo "usage: sh mkrootfs.sh key.pub /path/to/modules" >&2; exit 2; }
key="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
modules="$(cd "$2" && pwd)"
alpine="${ALPINE:-3.24.4}"
mkdir -p "${WORK:-pynq-rootfs}"
work="$(cd "${WORK:-pynq-rootfs}" && pwd)"
rm -f "$work/rootfs.f2fs"

docker run --rm --platform linux/arm/v7 \
    -v "$work:/work" -v "$key:/in/key.pub:ro" -v "$modules:/in/modules:ro" -e HOST_IDS="$(id -u):$(id -g)" \
    "alpine:$alpine" sh -euxc '
branch="v$(cut -d. -f1,2 /etc/alpine-release)"
r=/tmp/rootfs
mkdir -p "$r/etc/apk"
printf "https://dl-cdn.alpinelinux.org/alpine/%s/main\nhttps://dl-cdn.alpinelinux.org/alpine/%s/community\n" "$branch" "$branch" > "$r/etc/apk/repositories"
apk add --root "$r" --initdb --keys-dir /etc/apk/keys --repositories-file "$r/etc/apk/repositories" \
    alpine-base openssh-server chrony f2fs-tools dosfstools i2c-tools mtd-utils-flash ethtool htop
cp -a /etc/apk/keys "$r/etc/apk/"
echo pynq-z2 > "$r/etc/hostname"
printf "127.0.0.1 localhost\n127.0.1.1 pynq-z2\n" > "$r/etc/hosts"
printf "auto lo\niface lo inet loopback\n\nauto eth0\niface eth0 inet dhcp\n" > "$r/etc/network/interfaces"
printf "/dev/mmcblk0p2 / f2fs defaults,noatime 0 0\n/dev/mmcblk0p1 /boot vfat defaults,noatime 0 2\n" > "$r/etc/fstab"
# The console is the PS UART (docs/jtag-uart.md); no getty on the virtual terminals.
sed -i -e "s/^tty[0-9]/#&/" "$r/etc/inittab"
echo "ttyPS0::respawn:/sbin/getty -L 115200 ttyPS0 vt100" >> "$r/etc/inittab"
echo ttyPS0 >> "$r/etc/securetty"
sed -i "s/^root:[^:]*:/root::/" "$r/etc/shadow"
install -d -m 700 "$r/root/.ssh"
install -m 600 /in/key.pub "$r/root/.ssh/authorized_keys"
sed -i "s/^#\?PasswordAuthentication .*/PasswordAuthentication no/" "$r/etc/ssh/sshd_config"
for s in devfs dmesg mdev hwdrivers; do ln -sf /etc/init.d/$s "$r/etc/runlevels/sysinit/$s"; done
for s in bootmisc hostname modules sysctl syslog swclock networking urandom; do ln -sf /etc/init.d/$s "$r/etc/runlevels/boot/$s"; done
for s in sshd chronyd; do ln -sf /etc/init.d/$s "$r/etc/runlevels/default/$s"; done
for s in mount-ro killprocs savecache; do ln -sf /etc/init.d/$s "$r/etc/runlevels/shutdown/$s"; done
mkdir -p "$r/lib/modules"
cp -r /in/modules/lib/modules/. "$r/lib/modules/"
chown -R 0:0 "$r/lib/modules"
find "$r/lib/modules" -type d -exec chmod 755 {} +
find "$r/lib/modules" -type f -exec chmod 644 {} +
: > "$r/etc/motd"
apk add f2fs-tools
truncate -s 1G /work/rootfs.f2fs
mkfs.f2fs -q -l rootfs /work/rootfs.f2fs
# -P keeps the owners and modes of the directory, which apk set as root.
sload.f2fs -f "$r" -t / -P /work/rootfs.f2fs >/dev/null
fsck.f2fs /work/rootfs.f2fs >/dev/null
chown "$HOST_IDS" /work/rootfs.f2fs
du -sh "$r"
'
ls -la "$work/rootfs.f2fs"
