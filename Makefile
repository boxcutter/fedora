# if Makefile.local exists, include it
ifneq ("$(wildcard Makefile.local)", "")
	include Makefile.local
endif

PACKER_VERSION = $(shell packer --version | sed 's/^.* //g' | sed 's/^.//')
ifneq (0.5.0, $(word 1, $(sort 0.5.0 $(PACKER_VERSION))))
$(error Packer version less than 0.5.x, please upgrade)
endif

FEDORA21_X86_64 ?= http://mirror.cs.pitt.edu/fedora/linux/releases/test/21-Beta/Server/x86_64/iso/Fedora-Server-DVD-x86_64-21_Beta.iso
FEDORA20_X86_64 ?= http://mirrors.kernel.org/fedora/releases/20/Fedora/x86_64/iso/Fedora-20-x86_64-DVD.iso
FEDORA19_X86_64 ?= http://download.fedoraproject.org/pub/fedora/linux/releases/19/Fedora/x86_64/iso/Fedora-19-x86_64-DVD.iso
FEDORA18_X86_64 ?= http://mirrors.kernel.org/fedora/releases/18/Fedora/x86_64/iso/Fedora-18-x86_64-DVD.iso
FEDORA21_I386 ?= http://mirror.cs.pitt.edu/fedora/linux/releases/test/21-Beta/Server/i386/iso/Fedora-Server-DVD-i386-21_Beta.iso
FEDORA20_I386 ?= http://mirrors.kernel.org/fedora/releases/20/Fedora/i386/iso/Fedora-20-i386-DVD.iso
FEDORA19_I386 ?= http://mirrors.kernel.org/fedora/releases/19/Fedora/i386/iso/Fedora-19-i386-DVD.iso
FEDORA18_I386 ?= http://mirrors.kernel.org/fedora/releases/18/Fedora/i386/iso/Fedora-18-i386-DVD.iso

# Possible values for CM: (nocm | chef | chefdk | salt | puppet)
CM ?= nocm
# Possible values for CM_VERSION: (latest | x.y.z | x.y)
CM_VERSION ?=
ifndef CM_VERSION
	ifneq ($(CM),nocm)
		CM_VERSION = latest
	endif
endif
BOX_VERSION ?= $(shell cat VERSION)
ifeq ($(CM),nocm)
	BOX_SUFFIX := -$(CM)-$(BOX_VERSION).box
else
	BOX_SUFFIX := -$(CM)$(CM_VERSION)-$(BOX_VERSION).box
endif
# Packer does not allow empty variables, so only pass variables that are defined
ifdef CM_VERSION
	PACKER_VARS := -var 'cm=$(CM)' -var 'cm_version=$(CM_VERSION)' -var 'headless=$(HEADLESS)' -var 'update=$(UPDATE)' -var 'version=$(BOX_VERSION)'
else
	PACKER_VARS := -var 'cm=$(CM)' -var 'headless=$(HEADLESS)' -var 'update=$(UPDATE)' -var 'version=$(BOX_VERSION)'
endif
ifdef PACKER_DEBUG
	PACKER := PACKER_LOG=1 packer --debug
else
	PACKER := packer
endif
TEMPLATE_FILENAMES := $(wildcard *.json)
BOX_FILENAMES := $(TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
VMWARE_TEMPLATE_FILENAMES = fedora18-i386.json fedora18.json fedora19-i386.json fedora19.json fedora20-i386.json fedora20.json
VMWARE_BOX_FILENAMES := $(VMWARE_TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
VMWARE_BOX_FILES := $(foreach box_filename, $(VMWARE_BOX_FILENAMES), box/vmware/$(box_filename))
VIRTUALBOX_BOX_FILES := $(foreach box_filename, $(BOX_FILENAMES), box/virtualbox/$(box_filename))
PARALLELS_TEMPLATE_FILENAMES = fedora18-i386.json fedora18.json fedora19-i386.json fedora19.json fedora20-i386.json fedora20.json
PARALLELS_BOX_FILENAMES := $(PARALLELS_TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
PARALLELS_BOX_FILES := $(foreach box_filename, $(PARALLELS_BOX_FILENAMES), box/parallels/$(box_filename))
BOX_FILES := $(VMWARE_BOX_FILES) $(VIRTUALBOX_BOX_FILES) $(PARALLELS_BOX_FILES)
TEST_BOX_FILES := $(foreach builder, $(BUILDER_TYPES), $(foreach box_filename, $(BOX_FILENAMES), test-box/$(builder)/$(box_filename)))
VMWARE_BOX_DIR := box/vmware
VIRTUALBOX_BOX_DIR := box/virtualbox
PARALLELS_BOX_DIR := box/parallels
VMWARE_OUTPUT := output-vmware-iso
VIRTUALBOX_OUTPUT := output-virtualbox-iso
PARALLELS_OUTPUT := output-parallels-iso
VMWARE_BUILDER := vmware-iso
VIRTUALBOX_BUILDER := virtualbox-iso
PARALLELS_BUILDER := parallels-iso
CURRENT_DIR = $(shell pwd)
SOURCES := $(wildcard script/*.sh)

.PHONY: list validate

all: $(BOX_FILES)

test: $(TEST_BOX_FILES)

###############################################################################
# Target shortcuts
define SHORTCUT

$(1): vmware/$(1) virtualbox/$(1) parallels/$(1)

test-$(1): test-vmware/$(1) test-virtualbox/$(1) test-parallels/$(1)

vmware/$(1): $(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

test-vmware/$(1): test-$(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

ssh-vmware/$(1): ssh-$(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

virtualbox/$(1): $(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

test-virtualbox/$(1): test-$(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

ssh-virtualbox/$(1): ssh-$(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

parallels/$(1): $(PARALLELS_BOX_DIR)/$(1)$(BOX_SUFFIX)

test-parallels/$(1): test-$(PARALLELS_BOX_DIR)/$(1)$(BOX_SUFFIX)

ssh-parallels/$(1): ssh-$(PARALLELS_BOX_DIR)/$(1)$(BOX_SUFFIX)

endef

SHORTCUT_TARGETS := fedora21 fedora21-i386 fedora20 fedora20-i386 fedora19 fedora19-i386 fedora18 fedora18-i386
$(foreach i,$(SHORTCUT_TARGETS),$(eval $(call SHORTCUT,$(i))))
###############################################################################

# Generic rule - not used currently
#$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): %.json
#	cd $(dir $<)
#	rm -rf output-vmware-iso
#	mkdir -p $(VMWARE_BOX_DIR)
#	packer build -only=vmware-iso $(PACKER_VARS) $<

$(VMWARE_BOX_DIR)/fedora21$(BOX_SUFFIX): fedora21.json $(SOURCES) http/ks.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA21_X86_64)" $<

$(VMWARE_BOX_DIR)/fedora20$(BOX_SUFFIX): fedora20.json $(SOURCES) http/ks.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA20_X86_64)" $<

$(VMWARE_BOX_DIR)/fedora19$(BOX_SUFFIX): fedora19.json $(SOURCES) http/ks.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA19_X86_64)" $<

$(VMWARE_BOX_DIR)/fedora18$(BOX_SUFFIX): fedora18.json $(SOURCES) http/ks-fedora18.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA18_X86_64)" $<

$(VMWARE_BOX_DIR)/fedora21-i386$(BOX_SUFFIX): fedora21-i386.json $(SOURCES) http/ks.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA21_I386)" $<

$(VMWARE_BOX_DIR)/fedora20-i386$(BOX_SUFFIX): fedora20-i386.json $(SOURCES) http/ks.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA20_I386)" $<

$(VMWARE_BOX_DIR)/fedora19-i386$(BOX_SUFFIX): fedora19-i386.json $(SOURCES) http/ks.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA19_I386)" $<

$(VMWARE_BOX_DIR)/fedora18-i386$(BOX_SUFFIX): fedora18-i386.json $(SOURCES) http/ks-fedora18.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	$(PACKER) build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA18_I386)" $<

# Generic rule - not used currently
#$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): %.json
#	cd $(dir $<)
#	rm -rf output-virtualbox-iso
#	mkdir -p $(VIRTUALBOX_BOX_DIR)
#	packer build -only=virtualbox-iso $(PACKER_VARS) $<

$(VIRTUALBOX_BOX_DIR)/fedora21$(BOX_SUFFIX): fedora21.json $(SOURCES) http/ks.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA21_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/fedora20$(BOX_SUFFIX): fedora20.json $(SOURCES) http/ks.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA20_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/fedora19$(BOX_SUFFIX): fedora19.json $(SOURCES) http/ks.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA19_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/fedora18$(BOX_SUFFIX): fedora18.json $(SOURCES) http/ks-fedora18.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA18_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/fedora21-i386$(BOX_SUFFIX): fedora21-i386.json $(SOURCES) http/ks.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA21_I386)" $<

$(VIRTUALBOX_BOX_DIR)/fedora20-i386$(BOX_SUFFIX): fedora20-i386.json $(SOURCES) http/ks.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA20_I386)" $<

$(VIRTUALBOX_BOX_DIR)/fedora19-i386$(BOX_SUFFIX): fedora19-i386.json $(SOURCES) http/ks.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA19_I386)" $<

$(VIRTUALBOX_BOX_DIR)/fedora18-i386$(BOX_SUFFIX): fedora18-i386.json $(SOURCES) http/ks-fedora18.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	$(PACKER) build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA18_I386)" $<

# Generic rule - not used currently
#$(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX): %.json
#	cd $(dir $<)
#	rm -rf output-parallels-iso
#	mkdir -p $(PARALLELS_BOX_DIR)
#	packer build -only=parallels-iso $(PACKER_VARS) $<

$(PARALLELS_BOX_DIR)/fedora20$(BOX_SUFFIX): fedora20.json $(SOURCES) http/ks.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA20_X86_64)" $<

$(PARALLELS_BOX_DIR)/fedora19$(BOX_SUFFIX): fedora19.json $(SOURCES) http/ks.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA19_X86_64)" $<

$(PARALLELS_BOX_DIR)/fedora18$(BOX_SUFFIX): fedora18.json $(SOURCES) http/ks-fedora18.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA18_X86_64)" $<

$(PARALLELS_BOX_DIR)/fedora20-i386$(BOX_SUFFIX): fedora20-i386.json $(SOURCES) http/ks.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA20_I386)" $<

$(PARALLELS_BOX_DIR)/fedora19-i386$(BOX_SUFFIX): fedora19-i386.json $(SOURCES) http/ks.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA19_I386)" $<

$(PARALLELS_BOX_DIR)/fedora18-i386$(BOX_SUFFIX): fedora18-i386.json $(SOURCES) http/ks-fedora18.cfg
	rm -rf $(PARALLELS_OUTPUT)
	mkdir -p $(PARALLELS_BOX_DIR)
	packer build -only=$(PARALLELS_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA18_I386)" $<


list:
	@echo "Prepend 'vmware/', 'virtualbox/', or 'parallels/' to build only one target platform:"
	@echo "  make vmware/fedora20"
	@echo ""
	@echo "Targets:"
	@for shortcut_target in $(SHORTCUT_TARGETS) ; do \
		echo $$shortcut_target ; \
	done ;

validate:
	@for template_filename in $(TEMPLATE_FILENAMES) ; do \
		echo Checking $$template_filename ; \
		packer validate $$template_filename ; \
	done

clean: clean-builders clean-output clean-packer-cache

clean-builders:
	@for builder in $(BUILDER_TYPES) ; do \
		if test -d box/$$builder ; then \
			echo Deleting box/$$builder/*.box ; \
			find box/$$builder -maxdepth 1 -type f -name "*.box" ! -name .gitignore -exec rm '{}' \; ; \
		fi ; \
	done

clean-output:
	@for builder in $(BUILDER_TYPES) ; do \
		echo Deleting output-$$builder-iso ; \
		echo rm -rf output-$$builder-iso ; \
	done

clean-packer-cache:
	echo Deleting packer_cache
	rm -rf packer_cache

test-$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): $(VMWARE_BOX_DIR)/%$(BOX_SUFFIX)
	bin/test-box.sh $< vmware_desktop vmware_fusion $(CURRENT_DIR)/test/*_spec.rb

test-$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): $(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX)
	bin/test-box.sh $< virtualbox virtualbox $(CURRENT_DIR)/test/*_spec.rb

test-$(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX): $(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX)
	bin/test-box.sh $< parallels parallels $(CURRENT_DIR)/test/*_spec.rb

ssh-$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): $(VMWARE_BOX_DIR)/%$(BOX_SUFFIX)
	bin/ssh-box.sh $< vmware_desktop vmware_fusion $(CURRENT_DIR)/test/*_spec.rb

ssh-$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): $(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX)
	bin/ssh-box.sh $< virtualbox virtualbox $(CURRENT_DIR)/test/*_spec.rb

ssh-$(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX): $(PARALLELS_BOX_DIR)/%$(BOX_SUFFIX)
	bin/ssh-box.sh $< parallels parallels $(CURRENT_DIR)/test/*_spec.rb
