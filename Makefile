SHELL = /bin/bash
UUID ?= $(shell uuidgen)
NAME ?= atm
DOMAIN ?= smptr
FQDN ?= $(NAME).$(DOMAIN)
USERNAME ?= mats
PASSWORD ?= $(shell cat .password )
ROOTPASSWORD ?= $(shell cat .password.root )
RAWIMAGE ?= Fedora-Atomic-27-20180326.1
IMGURL ?= https://download.fedoraproject.org/pub/alt/atomic/stable/$(RAWIMAGE)/CloudImages/x86_64/images/$(RAWIMAGE).x86_64.raw.xz
CIDATADEV ?= $(shell blkid -L cidata -o device)
RESETDEV ?= $(shell blkid -t TYPE=LVM2_member -o device | cut -c 1-8)

define USERDATA
#cloud-config
user: $(USERNAME)
ssh_pwauth: False
ssh_authorized_keys:
  - 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzHTIFi6J9sstuGmk1jfUIYOcmZ6pf5+IYm4R1Jirn4XUK6qwIjqZZwKi+AA32gZGkc7fevgOoOQBzR/Z4FJ2tNUvwg2mIxtx/4RFYBAevbnCX9GZBz1D30LX9qOQxlXGr+pGWLSTrV36CGMXjVXDA+91Gz2uE1ce7f/mDt9UyT+TJt8mRi1p981i6R+YSc6DeVkH0aXShi184U8lreP68kzoTdJXTnkm3kcKsfasaxumXdMjv1qaXJy/yaMgy20gkfyFlYowLddNuVQeM5thejfbUXp7ySKlc8XQu1daFcpvIohA15CG/GunDXRt9DkIXnf4er2amwlfVDsntxWrX'
  - 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDrQ68VtkRVzTxy9ikhL2Jt3RVYhW8MWlERZoli5gpWbuItkDoLj6i/xoxVtPLFbxRQXpzpUU0aKtZzzSPgiP7xqEn5nWvFI5I2hLuvdU9wcoHfGXGWomaBPyv9al6XN6cDgy2lcvojfigcxpQyO4ztUTRhp9hgRnsSyI/l3iwb62AGoVvE1OGBoHegnbizcNaTCW0GAg3TeJkVGZ+WoyJ2EDZGBPYGEj1+jqtbhUVOgs3zppGT2m7lEIAOjuNhuazKEudkCXiWHA2kWktmFPZN5EugZaHLIvR2F9cvLkkD9ogjs20hd+QQPQOGymUAbZD6BJuL8CXFXLVo3wV0jiLr'
chpasswd:
  list: |
    root:$(PASSWORD)
    mats:$(ROOTPASSWORD)
  expire: False
endef

export USERDATA

.PHONY: all clean nuke image fetch

all: $(RAWIMAGE) $(NAME)-cidata.iso

fetch: $(RAWIMAGE)

$(RAWIMAGE):
	@echo fetching $(RAWIMAGE).x86_64.raw.xz
	@wget --quiet $(IMGURL)
	@echo extracting $(RAWIMAGE).x86_64.raw.xz
	@unxz $(RAWIMAGE).x86_64.raw.xz

$(NAME)-cidata.iso: meta-data user-data
	@echo generating $@
	@genisoimage -output $@ -quiet -volid cidata -joliet -rock user-data meta-data

meta-data: Makefile
	@echo generating meta-data
	@echo -e "instance-id: $(NAME)-$(UUID)\nlocal-hostname: $(FQDN)" > meta-data

user-data: Makefile
	@echo generating user-data
	@echo "$$USERDATA" > user-data
	@cat ssh-keys >> user-data

clean:
	rm -f meta-data user-data mnt/cidata/*

nuke: clean
	rm -f $(NAME)-cidata.iso
	rm -f *.raw

image: $(NAME)-cidata.iso
	@echo imaging cidata
	dd if=$(NAME)-cidata.iso of=$(CIDATADEV) bs=4k &>/dev/null

reset:
	@echo resetting vm disk
	dd if=$(RAWIMAGE).x86_64.raw of=$(RESETDEV) bs=4k &>/dev/null
