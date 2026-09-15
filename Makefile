DOCKER_RUN = docker run --rm -it -v $$(pwd):/build -v desktops:/overlayfs --privileged debian-live-build:trixie

.PHONY: docker-build
docker-build:
	docker build -t debian-live-build:trixie .

.PHONY: clean
clean: docker-build
	$(DOCKER_RUN) lb clean --purge
	find config/hooks -xtype l -print -delete

.PHONY: build
build: docker-build
	$(DOCKER_RUN) sh -c 'lb config && lb build'

KEEP_STAMPS := config bootstrap
.PHONY: build-cache
build-cache: docker-build
	$(DOCKER_RUN) \
		sh -c '[ -d .build ] || exit 0; \
			for s in $(KEEP_STAMPS); do [ -e ".build/$$s" ] || { echo "build-cache: .build/$$s missing - live-build internals changed, run make clean build" >&2; exit 1; }; done; \
			find .build -mindepth 1 -maxdepth 1 $(foreach s,$(KEEP_STAMPS),! -name $(s)) $(if $(REBUILD_DESKTOPS),,! -name binary_hooks) -exec rm -rf {} +; \
			lb config && lb build'

live-image-amd64.hybrid.iso:
	make build

qemu/swtpm/swtpm-sock:
	mkdir -p qemu/swtpm
	swtpm socket --tpm2 --tpmstate dir=$$(pwd)/qemu/swtpm \
	--ctrl type=unixio,path=$$(pwd)/qemu/swtpm/swtpm-sock \
	--log level=20 -d

qemu/disk.qcow2:
	mkdir -p qemu
	qemu-img create -f qcow2 qemu/disk.qcow2 20G

qemu/OVMF_VARS_4M.ms.fd:
	mkdir -p qemu
	cp /usr/share/OVMF/OVMF_VARS_4M.ms.fd ./qemu/

# Debian's QEMU built from the trixie-backports sources
.PHONY: qemu-clipboard
qemu-clipboard:
	docker build --output type=local,dest=qemu/debs - < dev/qemu-clipboard.Dockerfile

# Share config/includes.chroot with the VM over 9p
# Disable with DEVTREE=
DEVTREE ?= 1
ifneq ($(DEVTREE),)
QEMU_DEVTREE = \
	-virtfs local,path=$$(pwd)/config/includes.chroot,mount_tag=devtree,security_model=none,readonly=on \
	-smbios type=11,value=io.systemd.credential.binary:systemd.extra-unit.devtree.service=$$(base64 -w0 dev/devtree.service) \
	-smbios type=11,value=io.systemd.credential.binary:systemd.unit-dropin.multi-user.target=$$(base64 -w0 dev/multi-user.target.conf)
endif

# Clipboard support: a GTK display option since QEMU 11.1, older versions reject it.
QEMU_CLIPBOARD := $(shell qemu-system-x86_64 --version | awk 'NR==1 { split($$4, v, "."); if (v[1] > 11 || (v[1] == 11 && v[2] >= 1)) print ",clipboard=on" }')

.PHONY: test
test:live-image-amd64.hybrid.iso qemu/swtpm/swtpm-sock qemu/disk.qcow2 qemu/OVMF_VARS_4M.ms.fd
	qemu-system-x86_64 -machine q35 \
	-m 4096 -enable-kvm -smp 4 -cpu host \
	-boot menu=on \
	-vga none -device virtio-vga-gl -display gtk,gl=on$(QEMU_CLIPBOARD) \
	-device virtio-serial-pci \
	-chardev qemu-vdagent,id=vdagent,name=vdagent,clipboard=on \
	-device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
	-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd \
	-drive if=pflash,format=raw,file=./qemu/OVMF_VARS_4M.ms.fd \
	-drive format=raw,media=cdrom,file=./live-image-amd64.hybrid.iso \
	-drive if=virtio,format=qcow2,file=./qemu/disk.qcow2,cache=none,aio=io_uring,discard=unmap \
	-chardev socket,id=chrtpm,path=./qemu/swtpm/swtpm-sock \
	-tpmdev emulator,id=tpm0,chardev=chrtpm \
	-device tpm-tis,tpmdev=tpm0 \
	-netdev user,id=net0,hostfwd=tcp::2222-:22 \
	-device virtio-net-pci,netdev=net0 \
	$(QEMU_DEVTREE)
