# Debian release the ISO is built from, e.g. `make build DEBIAN=forky`, and
# whether its backports are enabled (and pinned, see config/archives).
# Default to those of the last build (.release), so `make test` reuses it.
LAST_RELEASE := $(file < .release)
DEBIAN ?= $(or $(word 1,$(LAST_RELEASE)),trixie)
BACKPORTS ?= $(or $(word 2,$(LAST_RELEASE)),true)

DOCKER_RUN = docker run --rm -it -e DEBIAN=$(DEBIAN) -e BACKPORTS=$(BACKPORTS) -v $$(pwd):/build -v desktops:/overlayfs --privileged debian-live-build:$(DEBIAN)

.PHONY: docker-build
docker-build:
	docker build --build-arg DEBIAN=$(DEBIAN) -t debian-live-build:$(DEBIAN) .

# The DEBIAN and BACKPORTS of the last build: changing them purges live-build's
# stages and cache (they would keep the old release) and rebuilds the C++
# modules. Builds made before this file existed were trixie with backports.
RELEASE = $(DEBIAN) $(BACKPORTS)
.release: docker-build FORCE
	@if [ "$$(cat $@ 2>/dev/null || echo 'trixie true')" != '$(RELEASE)' ]; then \
		$(DOCKER_RUN) lb clean --purge && echo '$(RELEASE)' > $@; \
	fi
	@[ -e $@ ] || echo '$(RELEASE)' > $@

.PHONY: FORCE
FORCE:

.PHONY: clean
clean: docker-build
	$(DOCKER_RUN) lb clean --purge
	find config/hooks -xtype l -print -delete

# A failed lb build leaves its .lock behind, and the next one stops on
# "already locked": no other build runs in this directory (docker --rm).
.PHONY: build
build: docker-build .release calamares-includes
	$(DOCKER_RUN) sh -c 'rm -f .lock && lb config && lb build'

KEEP_STAMPS := config bootstrap
.PHONY: build-cache
build-cache: docker-build .release calamares-includes
	$(DOCKER_RUN) \
		sh -c '[ -d .build ] || exit 0; \
			for s in $(KEEP_STAMPS); do [ -e ".build/$$s" ] || { echo "build-cache: .build/$$s missing - live-build internals changed, run make clean build" >&2; exit 1; }; done; \
			find .build -mindepth 1 -maxdepth 1 $(foreach s,$(KEEP_STAMPS),! -name $(s)) $(if $(REBUILD_DESKTOPS),,! -name binary_hooks) -exec rm -rf {} +; \
			rm -f .lock && lb config && lb build'

live-image-amd64.hybrid.iso:
	make build

# Calamares module written in C++
TPM2_MODULE = calamares/modules/tpm2-state/module.desc
$(TPM2_MODULE): $(shell find calamares/src -type f) config/archives/backports.pref.chroot .release
	mkdir -p $(@D)
	docker build --build-arg DEBIAN=$(DEBIAN) --build-arg BACKPORTS=$(BACKPORTS) \
		--build-context archives=config/archives --output type=local,dest=$(@D) calamares/src
	touch $@

# Copy Calamares config and modules into the live build `includes.chroot`
CALAMARES_ETC = config/includes.chroot/etc/calamares
CALAMARES_MODULES = config/includes.chroot/usr/lib/calamares/modules
.PHONY: calamares-includes
calamares-includes: $(TPM2_MODULE)
	rm -rf $(CALAMARES_ETC) $(CALAMARES_MODULES)
	mkdir -p $(dir $(CALAMARES_MODULES))
	cp -a calamares/config $(CALAMARES_ETC)
	cp -a calamares/modules $(CALAMARES_MODULES)

# The VM's TPM2 keeps its state in qemu/$(TPM)
# Remove the TPM with TPM=
TPM ?= swtpm
ifneq ($(TPM),)
QEMU_TPM = \
	-chardev socket,id=chrtpm,path=./qemu/$(TPM)/swtpm-sock \
	-tpmdev emulator,id=tpm0,chardev=chrtpm \
	-device tpm-tis,tpmdev=tpm0
endif

qemu/%/swtpm-sock:
	mkdir -p qemu/$*
	swtpm socket --tpm2 --tpmstate dir=$$(pwd)/qemu/$* \
	--ctrl type=unixio,path=$$(pwd)/qemu/$*/swtpm-sock \
	--log level=20 -d

# TPM2 states of the test-tpm-* targets: a previous OS owns the TPM2 (owner
# password, no storage root key), the disk key cannot be sealed in it. Except
# in swtpm-clear, the lockout hierarchy has a password too: tpm2_clear is refused.
TPM_OWNED = qemu/swtpm-clear qemu/swtpm-ppi qemu/swtpm-locked
$(TPM_OWNED:=/swtpm-sock): %/swtpm-sock: %/tpm2-00.permall
.DELETE_ON_ERROR: $(TPM_OWNED:=/tpm2-00.permall)
$(TPM_OWNED:=/tpm2-00.permall):
	mkdir -p $(@D)
	cd $(@D) && swtpm socket --tpm2 --tpmstate dir=$$(pwd) \
	--server type=unixio,path=setup --ctrl type=unixio,path=setup.ctrl \
	--flags not-need-init,startup-clear --pid file=$$(pwd)/setup.pid -d
	cd $(@D) && trap 'kill $$(cat setup.pid); rm -f setup setup.ctrl' EXIT && export TPM2TOOLS_TCTI=swtpm:path=setup && \
	tpm2_changeauth -c owner test $(if $(findstring clear,$@),,&& tpm2_changeauth -c lockout test)

DISK ?= disk
qemu/%.qcow2:
	mkdir -p qemu
	qemu-img create -f qcow2 $@ 20G

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
	-virtfs local,path=$$(pwd)/config/includes.chroot,mount_tag=devtree,security_model=none,readonly=on
endif

# Units of dev/ injected into the VM, started by dev/multi-user.target.conf
DEV_UNITS ?=
QEMU_DEV_UNITS = \
	$(foreach unit,$(if $(DEVTREE),devtree) $(DEV_UNITS),-smbios type=11,value=io.systemd.credential.binary:systemd.extra-unit.$(unit).service=$$(base64 -w0 dev/$(unit).service)) \
	-smbios type=11,value=io.systemd.credential.binary:systemd.unit-dropin.multi-user.target=$$(base64 -w0 dev/multi-user.target.conf)

# Clipboard support: a GTK display option since QEMU 11.1, older versions reject it.
QEMU_CLIPBOARD := $(shell qemu-system-x86_64 --version | awk 'NR==1 { split($$4, v, "."); if (v[1] > 11 || (v[1] == 11 && v[2] >= 1)) print ",clipboard=on" }')

.PHONY: test
test:live-image-amd64.hybrid.iso calamares-includes $(if $(TPM),qemu/$(TPM)/swtpm-sock) qemu/$(DISK).qcow2 qemu/OVMF_VARS_4M.ms.fd
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
	-drive if=virtio,format=qcow2,file=./qemu/$(DISK).qcow2,cache=none,aio=io_uring,discard=unmap \
	$(QEMU_TPM) \
	-netdev user,id=net0,hostfwd=tcp::2222-:22 \
	-device virtio-net-pci,netdev=net0 \
	$(QEMU_DEVTREE) $(QEMU_DEV_UNITS)

# The cases of the page of Calamares' tpm2-state module (see its Config.h), on a disk of their own.
# Start a case over by removing its qemu/swtpm-* directory.
.PHONY: test-tpm-absent test-tpm-clear test-tpm-ppi test-tpm-locked
test-tpm-absent:
	$(MAKE) test DISK=disk-tpm TPM=
test-tpm-clear:
	$(MAKE) test DISK=disk-tpm TPM=swtpm-clear
test-tpm-ppi:
	$(MAKE) test DISK=disk-tpm TPM=swtpm-ppi
test-tpm-locked:
	$(MAKE) test DISK=disk-tpm TPM=swtpm-locked DEV_UNITS=tpm2-no-ppi
