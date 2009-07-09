#!/bin/bash -
#
# Copyright (C) 2008 Red Hat Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

# 'virt-what' tries to detect the type of virtualization being
# used (or none at all if we're running on bare-metal).  It prints
# out one of more lines each being a 'fact' about the virtualization.
#
# Please see also the manual page virt-what(1).
# This script should be run as root.
#
# The following resources were useful in writing this script:
# . http://www.dmo.ca/blog/20080530151107

VERSION="@VERSION@"

function fail {
    echo "virt-what: $1"
    exit 1
}

function usage {
    echo "virt-what [options]"
    echo "Options:"
    echo "  --help          Display this help"
    echo "  --version       Display version and exit"
    exit 0
}

# Handle the command line arguments, if any.

TEMP=`getopt -o v --long help --long version -n 'virt-what' -- "$@"`
if [ $? != 0 ]; then exit 1; fi
eval set -- "$TEMP"

while true; do
    case "$1" in
	--help) usage ;;
	-v|--version) echo $VERSION; exit 0 ;;
	--) shift; break ;;
	*) fail "internal error" ;;
    esac
done

# Check we're running as root.

uid=`id -u`
if [ "$uid" != 0 ]; then
    fail "this script must be run as root"
fi

PATH=/sbin:/usr/sbin:$PATH

# Check for various products in the BIOS information.

dmi=`dmidecode 2>&1`

if echo "$dmi" | grep -q 'Manufacturer: VMware'; then
    echo vmware
fi

if echo "$dmi" | grep -q 'Manufacturer: Microsoft Corporation'; then
    echo virtualpc
fi

# Check for OpenVZ / Virtuozzo.
# Added by Evgeniy Sokolov.
# /proc/vz - always exists if OpenVZ kernel is running (inside and outside
# container)
# /proc/bc - exists on node, but not inside container.

if [ -d /proc/vz -a ! -d /proc/bc ]; then
    echo openvz
fi

# Check for Xen.

if [ -f /proc/xen/privcmd ]; then
    echo xen; echo xen-dom0
    is_xen=1
elif [ -f /proc/xen/capabilities ]; then
    echo xen; echo xen-domU
    is_xen=1
elif [ -d /proc/xen ]; then
    # This directory can be present when Xen paravirt drivers are
    # installed, even on baremetal.  Don't confuse people by
    # printing anything.
    :
fi

# Check for QEMU/KVM.

if [ ! "$is_xen" ]; then
    # Disable this test if we know this is Xen already, because Xen
    # uses QEMU for its device model.

    if grep -q 'QEMU' /proc/cpuinfo; then
        # XXX How to distinguish between QEMU & KVM?
	echo qemu
    fi
fi
