# if Makefile.local exists, include it
ifneq ("$(wildcard Makefile.local)", "")
	include Makefile.local
endif

FEDORA20_X86_64 ?= http://mirrors.kernel.org/fedora/releases/20/Fedora/x86_64/iso/Fedora-20-x86_64-DVD.iso
FEDORA19_X86_64 ?= http://download.fedoraproject.org/pub/fedora/linux/releases/19/Fedora/x86_64/iso/Fedora-19-x86_64-DVD.iso
FEDORA18_X86_64 ?= http://mirrors.kernel.org/fedora/releases/18/Fedora/x86_64/iso/Fedora-18-x86_64-DVD.iso
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
# Packer does not allow empty variables, so only pass variables that are defined
ifdef CM_VERSION
	PACKER_VARS := -var 'cm=$(CM)' -var 'cm_version=$(CM_VERSION)' -var 'headless=$(HEADLESS)' -var 'update=$(UPDATE)'
else
	PACKER_VARS := -var 'cm=$(CM)' -var 'headless=$(HEADLESS)' -var 'update=$(UPDATE)'
endif
ifeq ($(CM),nocm)
	BOX_SUFFIX := -$(CM).box
else
	BOX_SUFFIX := -$(CM)$(CM_VERSION).box
endif
BUILDER_TYPES := vmware virtualbox
TEMPLATE_FILENAMES := $(wildcard *.json)
BOX_FILENAMES := $(TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
BOX_FILES := $(foreach builder, $(BUILDER_TYPES), $(foreach box_filename, $(BOX_FILENAMES), box/$(builder)/$(box_filename)))
TEST_BOX_FILES := $(foreach builder, $(BUILDER_TYPES), $(foreach box_filename, $(BOX_FILENAMES), test-box/$(builder)/$(box_filename)))
VMWARE_BOX_DIR := box/vmware
VIRTUALBOX_BOX_DIR := box/virtualbox
VMWARE_OUTPUT := output-vmware-iso
VIRTUALBOX_OUTPUT := output-virtualbox-iso
VMWARE_BUILDER := vmware-iso
VIRTUALBOX_BUILDER := virtualbox-iso
CURRENT_DIR = $(shell pwd)
SOURCES := $(wildcard script/*.sh)

.PHONY: all list validate clean

all: $(BOX_FILES)

test: $(TEST_BOX_FILES)

###############################################################################
# Target shortcuts
define SHORTCUT

$(1): vmware/$(1) virtualbox/$(1)

test-$(1): test-vmware/$(1) test-virtualbox/$(1)

vmware/$(1): $(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

test-vmware/$(1): test-$(VMWARE_BOX_DIR)/$(1)$(BOX_SUFFIX)

virtualbox/$(1): $(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

test-virtualbox/$(1): test-$(VIRTUALBOX_BOX_DIR)/$(1)$(BOX_SUFFIX)

endef

SHORTCUT_TARGETS := fedora20 fedora20-i386 fedora19 fedora19-i386 fedora18 fedora18-i386
$(foreach i,$(SHORTCUT_TARGETS),$(eval $(call SHORTCUT,$(i))))
###############################################################################

# Generic rule - not used currently
#$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): %.json
#	cd $(dir $<)
#	rm -rf output-vmware-iso
#	mkdir -p $(VMWARE_BOX_DIR)
#	packer build -only=vmware-iso $(PACKER_VARS) $<

$(VMWARE_BOX_DIR)/fedora20$(BOX_SUFFIX): fedora20.json $(SOURCES) http/ks.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA20_X86_64)" $<

$(VMWARE_BOX_DIR)/fedora19$(BOX_SUFFIX): fedora19.json $(SOURCES) http/ks.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA19_X86_64)" $<

$(VMWARE_BOX_DIR)/fedora18$(BOX_SUFFIX): fedora18.json $(SOURCES) http/ks-fedora18.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA18_X86_64)" $<

$(VMWARE_BOX_DIR)/fedora20-i386$(BOX_SUFFIX): fedora20-i386.json $(SOURCES) http/ks.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA20_I386)" $<

$(VMWARE_BOX_DIR)/fedora19-i386$(BOX_SUFFIX): fedora19-i386.json $(SOURCES) http/ks.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA19_I386)" $<

$(VMWARE_BOX_DIR)/fedora18-i386$(BOX_SUFFIX): fedora18-i386.json $(SOURCES) http/ks-fedora18.cfg
	rm -rf $(VMWARE_OUTPUT)
	mkdir -p $(VMWARE_BOX_DIR)
	packer build -only=$(VMWARE_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA18_I386)" $<

# Generic rule - not used currently
#$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): %.json
#	cd $(dir $<)
#	rm -rf output-virtualbox-iso
#	mkdir -p $(VIRTUALBOX_BOX_DIR)
#	packer build -only=virtualbox-iso $(PACKER_VARS) $<
	
$(VIRTUALBOX_BOX_DIR)/fedora20$(BOX_SUFFIX): fedora20.json $(SOURCES) http/ks.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA20_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/fedora19$(BOX_SUFFIX): fedora19.json $(SOURCES) http/ks.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA19_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/fedora18$(BOX_SUFFIX): fedora18.json $(SOURCES) http/ks-fedora18.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA18_X86_64)" $<

$(VIRTUALBOX_BOX_DIR)/fedora20-i386$(BOX_SUFFIX): fedora20-i386.json $(SOURCES) http/ks.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA20_I386)" $<

$(VIRTUALBOX_BOX_DIR)/fedora19-i386$(BOX_SUFFIX): fedora19-i386.json $(SOURCES) http/ks.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA19_I386)" $<

$(VIRTUALBOX_BOX_DIR)/fedora18-i386$(BOX_SUFFIX): fedora18-i386.json $(SOURCES) http/ks-fedora18.cfg
	rm -rf $(VIRTUALBOX_OUTPUT)
	mkdir -p $(VIRTUALBOX_BOX_DIR)
	packer build -only=$(VIRTUALBOX_BUILDER) $(PACKER_VARS) -var "iso_url=$(FEDORA18_I386)" $<

list:
	@echo "Prepend 'vmware/' or 'virtualbox/' to build only one target platform:"
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
	
ssh-$(VMWARE_BOX_DIR)/%$(BOX_SUFFIX): $(VMWARE_BOX_DIR)/%$(BOX_SUFFIX)
	bin/ssh-box.sh $< vmware_desktop vmware_fusion $(CURRENT_DIR)/test/*_spec.rb
	
ssh-$(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX): $(VIRTUALBOX_BOX_DIR)/%$(BOX_SUFFIX)
	bin/ssh-box.sh $< virtualbox virtualbox $(CURRENT_DIR)/test/*_spec.rb	
