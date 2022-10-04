# lvm-autosnap

[![CI](https://github.com/intentionally-left-nil/lvm-autosnap/actions/workflows/test.yml/badge.svg)](https://github.com/intentionally-left-nil/lvm-autosnap/actions/workflows/test.yml)

Create [lvm snapshots](https://man.archlinux.org/man/lvcreate.8#DESCRIPTION) during boot and automatically offer to restore your system if it stops booting.
Or, in fewer words, "Fixing your system without archiso"

# As a user...

I want to be able to run `pacman -Syu`, completely mess up my system, reboot, and have lvm-autosnap automatically offer to roll back to the last time my computer worked

# How it works

The main concept of lvm-autosnap is that it runs very early in the bootprocess, from your [initramfs](https://wiki.archlinux.org/title/Arch_boot_process#initramfs), in [early userspace](https://wiki.archlinux.org/title/Arch_boot_process#Early_userspace). In fact, it runs before the root filesystem is even mounted. This means:

- Snapshots should be consistent and not capture the system in-the-middle of doing something
- Snapshots can be restored even if there are major problems during boot because it runs so early
- Snapshots can be fully restored at once, because the filesystem isn't mounted yet

# Prerequisites

Before using lvm-autosnap, you should

1. Use an arch-derived OS (for now)
1. Use [LVM](https://wiki.archlinux.org/title/LVM) for your partitioning scheme
1. Have an offline backup of your data
1. Resize your LVM volumes to ensure you [have unallocated space](#leaving-free-space) in your volume group. You can perhaps try [this guide](https://linuxtechlab.com/beginners-guide-resizing-lvm/) for tips how. Note that if you need to shrink your root file system, you'll need to do this from a live-usb.

# Installation

1. Install lvm-autosnap via AUR
1. Modify [/etc/lvm-autosnap.env](./lvm-autosnap.env) to suit your needs. In particular, edit the `CONFIGS=` entry to match your partitioning layout
1. Edit the [HOOKS section](https://wiki.archlinux.org/title/Mkinitcpio#HOOKS) of /etc/mkinitcpio.conf and add `lvm-autosnap` as a hook after lvm2 (but before filesystems)
1. Run `mkinitcpio -P` to pick up your changes
1. Enable the [lvm-autosnap.timer](./lvm-autosnap.timer) with `systemctl enable lvm-autosnap.timer`

# Configuring lvm-autosnap

To configure lvm-autosnap, you simply need to edit [/etc/lvm-autosnap.env](./lvm-autosnap.env), and then run `mkinitcpio -P` to save the changes. The .env file itself is documented as well.

## CONFIGS

This is the only required field to modify. lvm-autosnap needs to know which volumes you want to create snapshots for, and how big those snapshots should be.

The format of configs is volume_group_name,logical_volume_name,size/volume_group_name,logical_volume_name,size/...

For example, if you wanted to back up two volumes, `root` and `home` in the `myvg` volume group, you could use:

`CONFIGS=myvg,root,20g/myvg,home,50g`
Which would configure lvm-autosnap to snapshot both root and home, with 20gb and 50gb snapshots respectively. See [Leaving free space](#leaving-free-space) for more details about the size.

### Primary config

One important note about CONFIGS is that the first volume listed (`root` in the above example) is considered the **primary** volume. This is what lvm-autosnap uses to determine other aspects of its operation. For example, when listing snapshots to restore, it only displays the primary snapshots. Once you pick that primary snapshot, the other volumes are grouped together. When determining the maximum number of snapshots lvm-autosnap stores, it only consideres the primany volumes. TL;DR: Make sure the first volume is the most important one (e.g. /root).

## MAX_SNAPSHOTS

Every time you boot, lvm-autosnap takes a new snapshot for each volume listed in [CONFIGS](#configs). To prevent lvm-autosnap from quickly eating all the free space in your hard drive, it uses the following algorithm when the computer starts.

- Count the number of snapshots created for the [primary config](#primary-config). If this count is less than MAX_SNAPSHOTS, create a new snapshot
- Otherwise, find the oldest snapshot for the primary config that is pending (did not successfully boot). Remove this snapshot if it exists, and then create a new snapshot
- Otherwise, find the oldest known-good snapshot for the primary config. Remove this snapshot, and then create a new snapshot.

Thus, you can control how many snapshots are kept by setting MAX_SNAPSHOTS. Note that MAX_SNAPSHOTS refers to the number of [snapshot groups](#snapshot-groups). Let's look at a concrete example:

Say you have 3 volumes: `myvg/root`, `myvg/home`, and `myvg/var`. You could configure lvm-autosnap to back all of these up with `CONFIGS=myvg,root,10g/myvg,home,80g/myvg,var,10g`

If you have `MAX_SNAPSHOTS=3`, then at most, you could have 3 [snapshot groups](#snapshot-groups). Each snapshot group contains a snapshot of `root`, `home`, and `var`, totalling 100gb combined. Thus, given MAX_SNAPSHOTS=3, this would require at least 300gb of space reserved for snapshots.

## RESTORE_AFTER

Every time the computer boots, lvm-autosnap determines if the computer started correctly. If the computer fails to start correctly a certain number of times consecutively, then it will prompt the user to restore from a snapshot instead of creating a new one. You can control the number of consecutive, failed boots required before initiating this process with RESTORE_AFTER.

**If you never want lvm-autosnap to prompt for restoring, set RESTORE_AFTER=0**

## LOG_LEVEL

lvm-autosnap writes information to the console. You can configure how much gets written with LOG_LEVEL.

- LOG_LEVEL=0 means log errors only
- LOG_LEVEL=1 means log errors and warnings
- LOG_LEVEL=2 means log errors, warnings, and info messages (default)
- LOG_LEVEL=3 means log everything including debug messages
- LOG_LEVEL=4 means log everything and run `set -x` to print out the sh commands being executed

## MODE

By default, lvm-autosnap either enters backup mode or restore mode depending on the # of previously-failed boots. You can override this behavior and explicitly force it to always backup or always restory by setting `MODE=backup` ore `MODE=restore` respectively

## Kernel command line

In addition to [/etc/lvm-autosnap.env](./lvm-autosnap.env), you can also set the same variables via the linux kernel command line arguments. Any values on the command line override all other parameters, including those set in `lvm-autosnap.env`.

All of the arguments in lvm-autosnap.env can be configured. See below for examples:

- `lvm-autosnap-configs=myvg,root,10g`
- `lvm-autosnap-max-snapshots=5`
- `lvm-autosnap-restore-after=3`
- `lvm-autosnap-mode=restore`
- `lvm-autosnap-log-level=2`

# Restoring your initramfs

Your `/efi` partition is typically not part of LVM. This presents two related challenges:

1. When you restore lvm snapshots, the initramfs kernel needs to match the one in your /root
1. How do you even begin restoring if your initramfs gets messed up somehow? (kernel panic, etc)

The tools to solve this are largely outside the scope of lvm-autosnap. **Instead, when you modify your efi partition (update the kernel, etc), you need to back it up yourself for later restoration**

If you are using [systemd-boot](https://wiki.archlinux.org/title/Systemd-boot), I've created the [systemd-boot-lifeboat](https://github.com/intentionally-left-nil/systemd-boot-lifeboat) ([AUR](https://aur.archlinux.org/packages/systemd-boot-lifeboat)) package to do this automatically

## Creating a known-good initramfs

Additionally, you can keep a known-working initramfs around to run the restore codepath of lvm-autosnap in emergency scenarios. The steps would look something like this:

1. Create a copy of your boot environment. (If you use a [unified kernel image](https://wiki.archlinux.org/title/Unified_kernel_image), that means just copy the `/efi/your_image.efi` to `/efi/lvm_autosnap_recovery.efi`
1. Create a new boot entry that points to your known-good initramfs. E.g. wyth systemd-boot, you would create a new entry.conf and set `EFI known_good.efi`
1. Modify the kernel arguments for this specific boot entry to set `lvm-autosnap-mode=restore` (see [the docs](#kernel-command-line) for more options). This will force lvm-autosnap to enter recovery mode when booted.

Then, if you end up in trouble with your initramfs, you can just go down the boot menu, choose the known_good boot entry, and restore the system

# CLI

lvm-autonsnap installs the `lvm-autosnap` binary to /usr/local/bin to assist with snapshots. The commands must be run as root

```
lvm-autosnap COMMAND OPTIONS
Available commands:
mark_good - Mark the stapshot of the current boot as known-good
list - Display a list of snapshot groups on the system
create - Create a new snapshot group
delete [snapshot_group_id] - Deletes a snapshot group by its group_id
config - Display the active configuration
```

# Local development

Writing code for lvm-autosnap is cumbersome because it has to run in early userspace. That means it's running in [busybox](https://en.wikipedia.org/wiki/BusyBox), using the ash shell. There are also a minimal number of external binaries available. As a rule, lvm-autosnap aims for all the code to be POSIX compatible, and not use any external programs. This means no fancy bash extensions, no calling `tr` or `sed`. The only external program called by the code is `lvm`.

To facilitate some semblence of actual programming, rather than one-very-large-shell script, files are broken up into pieces and then sourced together. This means:

- Files must not have circular dependencies
- Logic must live within functions() so the files can be sourced without causing side effects
- $SCRIPT_PATH must be manually set to avoid the difficulties of figuring out where the actual files live

Additionally, the codebase has adopted some other conventions to limit the potential of bugs and facilitate straightforward (if verbose) code:

- Functions which need to return data do so via a global variable named FUNCTION_NAME_RET
- Functions must copy the value to a local value if needed, since the global variables can be replaced with different values later
- Local values must have a unique suffix (e.g. my_var_22 instead of my_var) because `local` uses dynamic scoping and not lexical scoping :(
- Empty values are typically falsey, and `1` is typically truthy
- IFS needs to be manually set & reset for every function that uses it

## Running the code

It's suggested to use a vm. You can cd to the `e2e` directory and run `sudo ./setup.sh` to create the vm. Inside the vm, copy over the files, (using rsync, see the setup.sh script for an example), then run `rm *.zst; makepkg -c -C -S -i -p PKGBUILD.dev` to install the package

## Unit testing

Unit tests can be run locally by cd'ing to the project directory, and then running `./test/bats/bin/bats test/`
These tests are also run as part of github's CI workflow.

# Notes

## Leaving free space

LVM snapshots are a fixed size, which should be smaller than or equal to the size of the volume being backed up. For example, if you have a 100g volume, you could create 20g snapshots. This 20g is reserved and can only be used for the snapshot volume. This means if you want to keep snapshots for the last 5 boots, you would need at least 100g of unallocated space to store 5 \* 20 = 100g of snapshots.

It's important to leave enough room for each snapshot, because **if your main partition changes by more than the snapshot buffer size, the snapshot becomes instantly invalid, and no data can be retreived from it**. E.g. if you have a buffer of 10g and then pull down a bunch of steam games, you'll invalidate every snapshot you have on the system. **If you are space constrained, it's most likely a better idea to keep fewer snapshots but have a larger safety margin of buffer size** The LVM man pages suggest having a snapshot size of 20% but it's up to you

## Known-good snapshots

lvm-autosnap has the concept of "known-good" snapshots and "pending" snapshots. All snapshots, when initially created, are marked as pending. The system may be bootable, the system might not be. At some point (determined by you), lvm-autosnap will [mark the snapshot as known-good](#marking-a-snapshot-as-known-good). This matters for many reasons:

- When taking new snapshots, lvm-autosnap will evict old pending snapshots before evicting old known-good snapshots
- If the system fails to boot to a known-good state several times in a row (more than [$RESTORE_AFTER](#restoreafter)), it will prompt the user to restore their computer on the next boot
- When restoring the computer, lvm-autosnap will only list known-good snapshots to restore to

### Marking a snapshot as known-good

It's up to you to decide when your computer has booted successfully to your liking. Maybe that's as soon as the root filesystem gets mounted. Maybe that's after you log in. In any case, when that happens, you should run the [CLI command](#cli) `lvm-autosnap mark_good` which will configure the snapshot for the current boot.

The suggested behavior is to enable (and autostart) [lvm-autosnap.timer](./lvm-autosnap.timer). This timer simply waits 30 seconds before triggering `lvm-autosnap.service`. (which calls the CLI).

You can do this with `systemctl enable lvm-autosnap.timer`. Or, if you want to configure a different method for marking a snapshot as good, simply start `lvm-autosnap.service` or call `lvm-autosnap mark_good` at the desired time

## Snapshot groups

When [configuring](#configs) lvm-autosnap, you can list multiple volumes that should be backed up by lvm-autosnap. When lvm-autosnap creates a snapshot, it snapshots all of the volumes, and groups them together as a unit. This unit is known as a snapshot group. Backing up and restoring are done on the snapshot group level. When you backup, the entire snapshot group is backed up. Similarly, when you restore, the entire snapshot group is restored.

## Data format

All of lvm-autosnap's data lives within lvm itself, using lvm's own metadata, and storing its own in [lvm tags](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/logical_volume_manager_administration/lvm_tags).

For example, all snapshots controlled by lvm-autosnap contain the lvm tag `lvm-autosnap:true`. Similarly, the [snapshot group](#snapshot-groups) is determined by the `group_id:UUID` lvm tag

## Systemd initrd

By default, arch uses busybox to perform early initialization. You can switch to use [systemd for the initrd](<https://www.freedesktop.org/software/systemd/man/bootup.html#Bootup%20in%20the%20Initial%20RAM%20Disk%20(initrd)>) by adding the [systemd hook](https://wiki.archlinux.org/title/Mkinitcpio#Configuration) to your mkinitcpio.conf HOOKS section. To have lvm-autosnap work in this environment, you MUST also add the `base` hook so that there's a shell inside of initramfs. Otherwise you'll get "No such file or directory" errors when booting

## Debugging

To debug issues with lvm-autosnap, you can set the kernel command-line argument: `rd.log=all`

Then, after rebooting, lvm-autosnap logs will appear at `/run/initramfs/init.log`

You can see more logs by changing the [LOG_LEVEL](#loglevel) in `/etc/lvm-autosnap.env`.
