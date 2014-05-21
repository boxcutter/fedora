# Packer templates for Fedora

### Overview

This repository contains templates for Fedora that can create Vagrant boxes
using Packer.

## Current Boxes

64-bit boxes:

* [box-cutter/fedora20](https://vagrantcloud.com/box-cutter/fedora20) - Fedora 20 (64-bit), VMware 421MB/VirtualBox 363MB
* [box-cutter/fedora19](https://vagrantcloud.com/box-cutter/fedora19) - Fedora 19 (64-bit), VMware 400MB/VirtualBox 335MB
* [box-cutter/fedora18](https://vagrantcloud.com/box-cutter/fedora18) - Fedora 18 (64-bit), VMware 359MB/VirtualBox 299MB

32-bit boxes:

* [box-cutter/fedora20-i386](https://vagrantcloud.com/box-cutter/fedora20-i386) - Fedora 20 (32-bit), VMware 419MB/VirtualBox 357MB
* [box-cutter/fedora19-i386](https://vagrantcloud.com/box-cutter/fedora19-i386) - Fedora 19 (32-bit), VMware 397MB/VirtualBox 333MB
* [box-cutter/fedora18-i386](https://vagrantcloud.com/box-cutter/fedora18-i386) - Fedora 18 (32-bit), VMware 357MB/VirtualBox 295MB


## Building the Vagrant boxes

To build all the boxes, you will need Packer and both VirtualBox and VMware Fusion
installed.

A GNU Make `Makefile` drives the process via the following targets:

    make        # Build all the box types (VirtualBox & VMware)
    make test   # Run tests against all the boxes
    make list   # Print out individual targets
    make clean  # Clean up build detritus
    
### Tests

The tests are written in [Serverspec](http://serverspec.org) and require the
`vagrant-serverspec` plugin to be installed with:

    vagrant plugin install vagrant-serverspec
    
The `Makefile` has individual targets for each box type with the prefix
`test-*` should you wish to run tests individually for each box.

Similarly there are targets with the prefix `ssh-*` for registering a
newly-built box with vagrant and for logging in using just one command to
do exploratory testing.  For example, to do exploratory testing
on the VirtualBox training environmnet, run the following command:

    make ssh-box/virtualbox/fedora20-nocm.box
    
Upon logout `make ssh-*` will automatically de-register the box as well.

### Makefile.local override

You can create a `Makefile.local` file alongside the `Makefile` to override
some of the default settings.  It is most commonly used to override the
default configuration management tool, for example with Chef:

    # Makefile.local
    CM := chef

Changing the value of the `CM` variable changes the target suffixes for
the output of `make list` accordingly.

Possible values for the CM variable are:

* `nocm` - No configuration management tool
* `chef` - Install Chef
* `puppet` - Install Puppet
* `salt`  - Install Salt

You can also specify a variable `CM_VERSION`, if supported by the
configuration management tool, to override the default of `latest`.
The value of `CM_VERSION` should have the form `x.y` or `x.y.z`,
such as `CM_VERSION := 11.12.4`

Another use for `Makefile.local` is to override the default locations
for the Ubuntu install ISO files.

For Fedora, the ISO path variables are:

* FEDORA20_X86_64
* FEDORA19_X86_64
* FEDORA18_X86_64
* FEDORA20_I386
* FEDORA19_I386
* FEDORA18_I386

This override is commonly used to speed up Packer builds by
pointing at pre-downloaded ISOs instead of using the default
download Internet URLs:
`FEDORA20_X86_64 := file:///Volumes/Fedora-20-x86_64-DVD.iso`
