SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=$(shell jq -r .variables.version ubuntu.json)

help:
	@echo type make build-libvirt, make build-uefi-libvirt, make build-virtualbox, make build-hyperv or make build-vsphere

build-libvirt: ubuntu-${VERSION}-amd64-libvirt.box
build-uefi-libvirt: ubuntu-${VERSION}-uefi-amd64-libvirt.box
build-virtualbox: ubuntu-${VERSION}-amd64-virtualbox.box
build-hyperv: ubuntu-${VERSION}-amd64-hyperv.box
build-vsphere: ubuntu-${VERSION}-amd64-vsphere.box

ubuntu-${VERSION}-amd64-libvirt.box: autoinstall-cloud-init-data/* provision.sh ubuntu.json Vagrantfile.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=ubuntu-${VERSION}-amd64-libvirt -on-error=abort -timestamp-ui ubuntu.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f ubuntu-${VERSION}-amd64 ubuntu-${VERSION}-amd64-libvirt.box

ubuntu-${VERSION}-uefi-amd64-libvirt.box: tmp/libvirt-uefi-autoinstall-cloud-init-data/user-data autoinstall-cloud-init-data/* provision.sh ubuntu.json Vagrantfile-uefi.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=ubuntu-${VERSION}-uefi-amd64-libvirt -on-error=abort -timestamp-ui ubuntu.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f ubuntu-${VERSION}-uefi-amd64 ubuntu-${VERSION}-uefi-amd64-libvirt.box

tmp/libvirt-uefi-autoinstall-cloud-init-data/user-data: autoinstall-cloud-init-data/user-data
	mkdir -p $(shell dirname $@)
	sed -E 's,\*storage-config-msdos,*storage-config-gpt,g' $< >$@

ubuntu-${VERSION}-amd64-virtualbox.box: autoinstall-cloud-init-data/* provision.sh ubuntu.json Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=ubuntu-${VERSION}-amd64-virtualbox -on-error=abort -timestamp-ui ubuntu.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f ubuntu-${VERSION}-amd64 ubuntu-${VERSION}-amd64-virtualbox.box

ubuntu-${VERSION}-amd64-hyperv.box: tmp/hyperv-autoinstall-cloud-init-data/user-data autoinstall-cloud-init-data/* provision.sh ubuntu.json Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=ubuntu-${VERSION}-amd64-hyperv -on-error=abort -timestamp-ui ubuntu.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f ubuntu-${VERSION}-amd64 ubuntu-${VERSION}-amd64-hyperv.box

# see https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-ubuntu-virtual-machines-on-hyper-v
tmp/hyperv-autoinstall-cloud-init-data/user-data: autoinstall-cloud-init-data/user-data
	mkdir -p $(shell dirname $@)
	cp -f $< $@
	sed -i -E 's,\*storage-config-msdos,*storage-config-gpt,g' $@
	sed -i -E 's,((.+)- openssh-server.*),\1\n\2- linux-image-virtual\n\2- linux-tools-virtual\n\2- linux-cloud-tools-virtual,g' $@

ubuntu-${VERSION}-amd64-vsphere.box: tmp/vsphere-autoinstall-cloud-init-data/user-data autoinstall-cloud-init-data/* provision.sh ubuntu-vsphere.json Vagrantfile.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=ubuntu-${VERSION}-amd64-vsphere -timestamp-ui ubuntu-vsphere.json
	rm -rf tmp/$@-contents
	mkdir -p tmp/$@-contents
	echo '{"provider":"vsphere"}' >tmp/$@-contents/metadata.json
	cp Vagrantfile.template tmp/$@-contents/Vagrantfile
	tar cvf $@ -C tmp/$@-contents .
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f ubuntu-${VERSION}-amd64 ubuntu-${VERSION}-amd64-vsphere.box

tmp/vsphere-autoinstall-cloud-init-data/user-data: autoinstall-cloud-init-data/user-data
	mkdir -p $(shell dirname $@)
	sed -E 's,((.+)- openssh-server.*),\1\n\2- open-vm-tools,g' $< >$@

.PHONY: help buid-libvirt build-uefi-libvirt build-virtualbox build-hyperv build-vsphere
