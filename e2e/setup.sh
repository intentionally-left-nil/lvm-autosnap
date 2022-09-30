#!/usr/bin/env bash

# inspired from https://blog.stefan-koch.name/2020/05/31/automation-archlinux-qemu-installation

set -eufx

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

archive="${SCRIPT_DIR}/archlinux-bootstrap-2022.09.03-x86_64.tar.gz"
image="${SCRIPT_DIR}/vm.img"

qemu-img create -f raw "$image" 20G
loop=$(losetup --show -f -P "$image")

cleanup () {
  umount "$SCRIPT_DIR/vm_mnt/home"
  umount "$SCRIPT_DIR/vm_mnt"
  lvchange -an testvg || true
  losetup -d "$loop"
}
trap cleanup EXIT

if [ -z "$loop" ] ; then
  echo "could not create the loop"
  exit 1
fi

parted -s "$loop" mklabel msdos
parted -s -a optimal "$loop" mkpart primary 0% 100%
parted -s "$loop" set 1 boot on
parted -s "$loop" set 1 lvm on

pvcreate "${loop}p1"
vgcreate testvg "${loop}p1"
lvcreate -L 5G testvg -n root
lvcreate -L 5G testvg -n home

mkfs.ext4 /dev/testvg/root
mkfs.ext4 /dev/testvg/home

mkdir -p "${SCRIPT_DIR}/vm_mnt"
mount /dev/testvg/root "${SCRIPT_DIR}/vm_mnt"
mkdir -p "${SCRIPT_DIR}/vm_mnt/home"
mkdir -p "${SCRIPT_DIR}/vm_mnt/etc"
mount /dev/testvg/home "${SCRIPT_DIR}/vm_mnt/home"

tar xf "$archive" -C "$SCRIPT_DIR/vm_mnt" --strip-components 1

"$SCRIPT_DIR/vm_mnt/bin/arch-chroot" "$SCRIPT_DIR/vm_mnt" /bin/bash <<'EOF'
set -eufx

ln -sf /usr/share/zoneinfo/US/Pacific /etc/localtime
hwclock --systohc
echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo archvm > /etc/hostname
echo -e '127.0.0.1  localhost\n::1  localhost' >> /etc/hosts

echo '/dev/mapper/testvg-root / ext4 defaults 0 0' >> /etc/fstab
echo '/dev/mapper/testvg-home /home ext4 defaults 0 0' >> /etc/fstab

pacman-key --init
pacman-key --populate archlinux
echo 'Server = https://america.mirror.pkgbuild.com/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
pacman -Sy --noconfirm archlinux-keyring
pacman -Syu --noconfirm

pacman -Syu --noconfirm base linux linux-firmware mkinitcpio dhcpcd lvm2 vim grub openssh rsync sudo base-devel cpio
sed -i 's/^HOOKS=.*/HOOKS=(base udev modconf block lvm2 filesystems keyboard fsck)/' /etc/mkinitcpio.conf
echo 'COMPRESSION="cat"' >> /etc/mkinitcpio.conf
linux_version="$(ls /lib/modules/ | sort -V | tail -n 1)"
mkinitcpio -k "$linux_version" -P

grub-install --target=i386-pc /dev/loop0
sed -i 's/^GRUB_PRELOAD_MODULES=.*/GRUB_PRELOAD_MODULES="part_gpt part_msdos lvm"/' /etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="rd.log=all"/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo root:root | chpasswd
useradd -m me
echo me:me | chpasswd


echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "me ALL=(ALL) ALL" >> /etc/sudoers

systemctl enable dhcpcd.service
systemctl enable sshd.service
EOF
# qemu-system-x86_64 -m 2G -enable-kvm -cpu host -nic user,hostfwd=tcp::60022-:22 -smp 4 -drive file=vm.img,format=raw &
# rsync -av --filter=':- .gitignore' --rsh='ssh -p60022' "$PWD/../" me@127.0.0.1:/home/me/lvm-autosnap
