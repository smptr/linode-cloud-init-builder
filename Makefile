SHELL = /bin/bash
UUID ?= $(shell uuidgen)
NAME ?= rishi
DOMAIN ?= goozbach.net
FQDN ?= $(NAME).$(DOMAIN)
USERNAME ?= goozbach
PASSWORD ?= $(shell cat .password )
RAWIMAGE ?= Fedora-Atomic-24-20160921.0.x86_64.raw
IMGURL ?= https://download.fedoraproject.org/pub/alt/atomic/stable/Fedora-Atomic-24-20160921.0/CloudImages/x86_64/images/$(RAWIMAGE).xz
CIDATADEV ?= $(shell blkid -L cidata)
RESETDEV ?= /dev/sdb

define USERDATA
#cloud-config
user: $(USERNAME)
chpasswd: {expire: False}
ssh_pwauth: False
ssh_authorized_keys:
  - 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEAQDThPJ0cSl24omxvlbb5VQW4oVHYxA2Q5ImnD3g6zydbyvT+BY7KftyxC/iXh1cvnSK3ATs2A/1uPjbcbkub5GVcmG6uxSBAOCAx3h94N3vBnk6e0P0+1OPnrIbzrzmH882YgGM/hckIWMPN0V2NQZtURO3s26+e7Mokyg29LBBE/Y5JQ/QhofIuLOhP86e/lWUY2zdrURdBYdbTwyGZ1bw2KvubYbNDBllL/R86r+Ub79tKnYk6rFDxhHs66H2hDq11EwYx+JDUUi0ws0o9SgHOgwwXwGomCqYsQbX/fArSs2ATlIuSHAXpJgycuBYNo128MKUGBdr4lw7DKmnvXdjpMgvuidFmC44ShqFhLqJyees4B/VnJBzvabJpXBsCJJyYzmZwC0fLlYt04uvk5ji7iuVZBR2zg04dsDIcn4nK4vFKNg/z3JlUFkK01d/F221Ojiz6lpWi+dEmf3P4MoNrSCFaS6Ga7RqkhM2kazZXZ0QGoxuboWSWxLJybm4U3yQQ9ntsIm+bjvmMGTECP51u3Avw9Oicfayqz6w9QqSYpk0LZVEKKJBTX2okDDAzqpioUw5aibdu14CfYfJSeWp37nzNyTYHg/O0Q3gBPeUDAGXO0jJyZUtiDZO0fNRQ/MJpu/i09TDYfh+QGRCsgOxv92GAmMbkITCU7XuZyRYmxkScVL0BXpGxsauOZYVMexxVtf638q8gySjhs2qDXZhCCGPb8VS3GX2NbtIgHNIMXtFh968c1IMS7o2U69w/e1bXFrBv9+zl0czL/kEBEHxASt23D98J3IP3bN4T6hrbtGvpMDgnVXqZyS1V+IivSLn96T08b3PXOTt4bKdMvyNXeudYlARGLRe6eSWd0fYzizsGzGVxdHYCQvaolnH/o7KJFEewuAmfBUpxqQ2nu1BvMlFbkL5UAK/wwT8zKjB7mHHsyrSJh80ni8aPhrCuRceHuYll1o4+cFLiKRwNIVWCZhAe+/Eopnu7Llp2cCuKN/snwc6v71bZ6XuWWds37EnWlptd1QysHM7wBB6stvLyAkIgHsUPmVgduGqILhdWrSRGaCXKqiBRh+Y95itS+cEZMXfvQXMVXwr04gCUKoGiU1qUetgUTn3DlJ56DBlegoWmQ/ZWeW6PsqkS4a54+pv8V0RIPaXji5ZVV2VnD/Cov64FNwH2PLudPMb66ehnHba7epme+59jJN1azUlvevdGaK0soMdayXRefcpVRJ+Ve9c8C1eXH9WturC1k5zEbKQt+Iq/H2rfHfqhYmxFLVHyp87Isb41WqVB8uJ8O35eQIQTHyQ/hHvm/xot+ioVDDzYRtYAruUJw4SX5ulPHMl72t5S9y+4yZDDnCghSfx id_dsa-friocorte'
  - 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDdbE5og2wY4cVF4hZ/n299rgm7wwVxdY6zD59R4DFyi28RPV5/QwWsIRrnuq91a7xmVORUZOQcje9Y68GHKSEKMdX3cgWCK7kUl/KylVh8sbGEKAUd8dyUbVMPjrgMSV2GVFQldjatkU+MSijo4VehcQdZ6uVEnF2cDVl3+rSpK3M34KUPrSGbCfIQ/iqL6WsmvHnw5RDMG9RWZHdzwOR8mpZWdWPEqeFgsubpU6mfC7psdVKlTV2TSLot1gCD4yOdYT4VRa5JPzzyS/w2O+6Qmb7nwyHToa1ttPxjQcbTvQyMWt4FFQAPRRKD6sTQ/AosvNKjKzWlC7GKTPhplay7 derekcarter@10-200-28-185.employee-macbook.bluehost.com'
chpasswd:
  list: |
     root:$(PASSWORD)
     goozbach:$(PASSWORD)
endef

export USERDATA

.PHONY: all clean nuke image

all: $(RAWIMAGE) $(NAME)-cidata.iso

$(RAWIMAGE):
	@echo fetching $(RAWIMAGE).xz
	@wget --quiet $(IMGURL)
	@echo extracting $(RAWIMAGE).xz
	@unxz $(RAWIMAGE).xz

$(NAME)-cidata.iso: meta-data user-data
	@echo generating $@
	@genisoimage -output $@ -quiet -volid cidata -joliet -rock user-data meta-data

meta-data: Makefile
	@echo generating meta-data
	@echo -e "instance-id: $(NAME)-$(UUID)\nlocal-hostname: $(FQDN)" > meta-data

user-data: Makefile
	@echo generating user-data
	@echo "$$USERDATA" > user-data

clean:
	rm -f meta-data user-data mnt/cidata/*

nuke: clean
	rm -f $(NAME)-cidata.iso

37: nuke
	rm -f $(RAWIMAGE)

image:
	@echo imaging cidata
	@dd if=$(NAME)-cidata.iso of=$(CIDATADEV) bs=4k &>/dev/null

reset:
	@echo resetting vm disk
	@dd if=$(RAWIMAGE) of=$(RESETDEV) bs=4k &>/dev/null
