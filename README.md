# Packer templates for Fedora

### Overview

This repository contains templates for Fedora that can create Vagrant boxes
using Packer.

## Current Boxes

64-bit boxes:

* Fedora 21 (64-bit), VMware 464MB/VirtualBox 406MB
* Fedora 20 (64-bit), VMware 426MB/VirtualBox 367MB
* Fedora 19 (64-bit), VMware 406MB/VirtualBox 357MB
* Fedora 18 (64-bit), VMware 371MB/VirtualBox 306MB

32-bit boxes:

* Fedora 21 (32-bit), VMware 460MB/VirtualBox 399MB
* Fedora 20 (32-bit), VMware 421MB/VirtualBox 356MB
* Fedora 19 (32-bit), VMware 404MB/VirtualBox 336MB
* Fedora 18 (32-bit), VMware 360MB/VirtualBox 301MB


## Building the Vagrant boxes

To build all the boxes, you will need VirtualBox and VMware
installed.

A GNU Make `Makefile` drives the process via the following targets:

    make        # Build all the box types (VirtualBox, VMware & Parallels)
    make test   # Run tests against all the boxes
    make list   # Print out individual targets
    make clean  # Clean up build detritus

### Proxy Settings

The templates respect the following network proxy environment variables
and forward them on to the virtual machine environment during the box creation
process, should you be using a proxy:

* http_proxy
* https_proxy
* ftp_proxy
* rsync_proxy
* no_proxy
 
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
some of the default settings.  The variables can that can be currently
used are:

* CM
* CM_VERSION
* HEADLESS
* \<iso_path\>
* UPDATE

`Makefile.local` is most commonly used to override the default configuration
management tool, for example with Chef:

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

The variable `UPDATE` can be used to perform OS patch management.  The
default is to not apply OS updates by default.  When `UPDATE := true`,
the latest OS updates will be applied.

The variable `HEADLESS` can be set to run Packer in headless mode.
Set `HEADLESS := true`, the default is false.

Another use for `Makefile.local` is to override the default locations
for the Fedora install ISO files.

For Fedora, the ISO path variables are:

* FEDORA21_X86_64
* FEDORA20_X86_64
* FEDORA19_X86_64
* FEDORA18_X86_64
* FEDORA21_I386
* FEDORA20_I386
* FEDORA19_I386
* FEDORA18_I386

This override is commonly used to speed up Packer builds by
pointing at pre-downloaded ISOs instead of using the default
download Internet URLs:
`FEDORA20_X86_64 := file:///Volumes/Fedora-20-x86_64-DVD.iso`
