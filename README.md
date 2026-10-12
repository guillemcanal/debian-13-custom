
# Custom Debian 13 Live CD

This project aims to provide an opinionated custom Debian live CD with:

- Offline installation with a Calamares installer or a script
- Debian 13 (Trixie), or Debian 14 (Forky)
- Backports and non-free repositories enabled
- Most firmwares installed
- Installation on BTRFS subvolumes
- Full disk encryption, unlocked by TPM
- Dracut instead of initramfs-tools
- systemd-boot instead of GRUB
- A choice of desktop environment: GNOME, KDE, XFCE or [DankMaterialShell](https://danklinux.com) on niri (packaged as squashfs)

This project is based on the Debian Standard [Live Image](https://salsa.debian.org/live-team/live-images/-/tree/debian/images/standard?ref_type=heads) maintained by the [Debian Salsa Team](https://salsa.debian.org/explore/projects/active)

More information about `live-build` and the Live Systems project can be found on
its homepage at <https://wiki.debian.org/DebianLive> and in the manual at
<https://live-team.pages.debian.net/live-manual/>.

## Prerequisites

### Building the ISO (`make build`)

- `make`
- `docker` (prefer [Docker's packages](https://docs.docker.com/engine/install/))

### Testing the ISO (`make test`)

On a Debian based distro

```shell
sudo apt install qemu-system-x86 qemu-system-gui qemu-utils ovmf swtpm
```

- `qemu-system-x86`: the emulator
- `qemu-system-gui`: its GTK window and OpenGL acceleration
- `qemu-utils`: `qemu-img`, to create the VM disk
- `ovmf`: the UEFI Secure Boot firmware
- `swtpm`: the software TPM 2.0

## Build the image

`make build`

The Debian release and its backports are set by two `make` variables:

| Variable    | Default  | Example                           |
|-------------|----------|-----------------------------------|
| `DEBIAN`    | `trixie` | `make build DEBIAN=forky`         |
| `BACKPORTS` | `true`   | `make build BACKPORTS=false`      |

They apply to the ISO, to the APT sources of the installed system and to the
Calamares modules built from `calamares/src`. Changing either of them purges
live-build's state (`lb clean --purge`), so the next build starts over.

Once set, they are remembered (in `.release`): `make test`, `make build-cache`
and later builds reuse them. Pass both again to go back, e.g.
`make build DEBIAN=trixie BACKPORTS=true`.

## Create a bootable USB key from the live image

```shell
# replace sdX with the correct disk, be careful, all data on this disk will be lost
dd if=live-image-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## Copy-paste between the host and the `make test` VM

QEMU's GTK display can share the clipboard with the guest since QEMU 11.1.

`make test` turns it on (`-display gtk,clipboard=on`) when the host's QEMU is
recent enough, and leaves it off otherwise.

If trixie-backports already ships QEMU 11.1 or later for your architecture, a
plain `sudo apt upgrade` is all you need. Until then, build the packages from
the backports sources. The build runs in Docker and installs nothing on the
host:

```shell
# builds trixie-backports' QEMU into qemu/debs/
make qemu-clipboard
# upgrade the QEMU packages already installed, and only those
sudo dpkg --install --selected-only qemu/debs/*.deb
```
