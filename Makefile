#
# Broadcom Linux Router Makefile
# 
# Copyright (C) 2012, Broadcom Corporation. All Rights Reserved.
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
# OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# $Id: Makefile 387385 2013-02-25 20:22:54Z $
#


include .config
include .config.plt

ifndef FW_TYPE
FW_TYPE = WW
endif
export FW_TYPE

BOARDID_FILE=compatible_r8000.txt
FW_NAME=R8000

#
# Paths
#

CPU ?=
LINUX_VERSION ?= 2_6_36
MAKE_ARGS ?=
ARCH = arm
PLT ?= arm

# Get ARCH from PLT argument
ifneq ($(findstring arm,$(PLT)),)
ARCH := arm
endif

# uClibc wrapper
ifeq ($(CONFIG_UCLIBC),y)
PLATFORM := $(PLT)-uclibc
else ifeq ($(CONFIG_GLIBC),y)
PLATFORM := $(PLT)-glibc
else
PLATFORM := $(PLT)
endif

# Source bases
export PLATFORM LIBDIR USRLIBDIR LINUX_VERSION
export BCM_KVERSIONSTRING := $(subst _,.,$(LINUX_VERSION))

WLAN_ComponentsInUse := bcmwifi clm ppr olpc
include ../makefiles/WLAN_Common.mk
export SRCBASE := $(WLAN_SrcBaseA)
export BASEDIR := $(WLAN_TreeBaseA)
export TOP := $(shell pwd)
export SRCBASE := $(shell (cd $(TOP)/.. && pwd -P))
export BASEDIR := $(shell (cd $(TOP)/../.. && pwd -P))

ifeq (2_6_36,$(LINUX_VERSION))
export 	LINUXDIR := $(BASEDIR)/components/opensource/linux/linux-2.6.36
export 	KBUILD_VERBOSE := 1
export	BUILD_MFG := 0
# for now, only suitable for 2.6.36 router platform
SUBMAKE_SETTINGS = SRCBASE=$(SRCBASE) BASEDIR=$(BASEDIR)
else ifeq (2_6,$(LINUX_VERSION))
export 	LINUXDIR := $(SRCBASE)/linux/linux-2.6
export 	KBUILD_VERBOSE := 1
export	BUILD_MFG := 0
else
export 	LINUXDIR := $(SRCBASE)/linux/linux
endif

# Opensource bases
OPENSOURCE_BASE_DIR := $(BASEDIR)/components/opensource
DNSMASQ_DIR := $(OPENSOURCE_BASE_DIR)/dnsmasq
LIBNFNETLINK_DIR := $(OPENSOURCE_BASE_DIR)/netfilter/libnfnetlink
LIBMNL_DIR := $(OPENSOURCE_BASE_DIR)/netfilter/libmnl
LIBNETFILTER_QUEUE_DIR := $(OPENSOURCE_BASE_DIR)/netfilter/libnetfilter_queue
LIBNETFILTER_CONNTRACK_DIR := $(OPENSOURCE_BASE_DIR)/netfilter/libnetfilter_conntrack

#
# Cross-compile environment variables
#

# Build platform
export BUILD := i386-pc-linux-gnu
export HOSTCC := gcc

ifeq ($(PLATFORM),mipsel)
export CROSS_COMPILE := mipsel-linux-
export CONFIGURE := ./configure mipsel-linux --build=$(BUILD)
export TOOLCHAIN := $(shell cd $(dir $(shell which $(CROSS_COMPILE)gcc))/../mipsel-linux && pwd -P)
endif

ifeq ($(PLATFORM),mipsel-uclibc)
ifeq (2_6_36,$(LINUX_VERSION))
export CROSS_COMPILE := mipsel-uclibc-linux-2.6.36-
CFLAGS += -D__EXPORTED_HEADERS__ -fPIC
else ifeq (2_6,$(LINUX_VERSION))
export CROSS_COMPILE := mipsel-uclibc-linux26-
else
export CROSS_COMPILE := mipsel-uclibc-
endif
export CONFIGURE := ./configure mipsel-linux --build=$(BUILD)
export TOOLCHAIN := $(shell cd $(dir $(shell which $(CROSS_COMPILE)gcc))/.. && pwd -P)
endif

ifeq ($(PLATFORM),mipsel-glibc)
ifeq (2_6_36,$(LINUX_VERSION))
export CROSS_COMPILE := mipsel-glibc-linux-2.6.36-
export TOOLCHAIN := $(shell cd $(dir $(shell which $(CROSS_COMPILE)gcc))/.. && pwd -P)
CFLAGS += -D__EXPORTED_HEADERS__ -fPIC
else ifeq (2_6,$(LINUX_VERSION))
export CROSS_COMPILE := mipsel-linux-linux26-
else
export CROSS_COMPILE := mipsel-linux-
export CONFIGURE := ./configure mipsel-linux --build=$(BUILD)
export TOOLCHAIN := $(shell cd $(dir $(shell which $(CROSS_COMPILE)gcc))/../mipsel-linux && pwd -P)
endif
endif

ifeq ($(PLATFORM),arm-uclibc)
export CROSS_COMPILE := arm-brcm-linux-uclibcgnueabi-
export CONFIGURE := ./configure arm-linux --build=$(BUILD)
export TOOLCHAIN := $(shell cd $(dir $(shell which $(CROSS_COMPILE)gcc))/.. && pwd -P)
export CFLAGS += -fno-strict-aliasing
SUBMAKE_SETTINGS += ARCH=$(ARCH)
EXTRA_LDFLAGS := -lgcc_s
endif

CFLAGS = -Os
ifeq ($(CONFIG_RTR_OPTIMIZE_SIZE),y)
export CFLAGS += -Os
export OPTCFLAGS = -Os
else
export CFLAGS += -O2
export OPTCFLAGS = -O2
endif

#look at driver configuration
WLCFGDIR=$(SRCBASE)/wl/config

#For NTGR Patch
NETGEAR_PATCH := 1
ifeq ($(NETGEAR_PATCH),1)
export CFLAGS += -DNETGEAR_PATCH
endif
ifeq ($(CONFIG_NVRAM),y)
export CFLAGS += -DBCMNVRAM
endif

ifeq ($(CONFIG_BCMWPA2),y)
export CFLAGS += -DBCMWPA2
endif
ifeq ($(CONFIG_DHDAP),y)
export CONFIG_DHDAP
export CFLAGS += -D__CONFIG_DHDAP__
endif

export CFLAGS += -DRESTART_ALL_PROCESSES
ifeq ($(DHDAP_USE_SEPARATE_CHECKOUTS),1)
export SRCBASE_DHD := $(SRCBASE)/../../dhd/src
export SRCBASE_FW  := $(SRCBASE)/../../43602/src
else
export SRCBASE_DHD := $(SRCBASE)
export SRCBASE_FW  := $(SRCBASE)
endif
#export CFLAGS += -DRESTART_ALL_PROCESSES_DEBUG
ifeq ($(CONFIG_GMAC3),y)
export CFLAGS += -D__CONFIG_GMAC3__
endif

ifeq ("$(CONFIG_USBAP)","y")
export CFLAGS += -D__CONFIG_USBAP__
endif

ifeq ($(CONFIG_BCMQOS),y)
export CFLAGS += -DBCMQOS
endif
ifeq ($(CONFIG_WSCCMD),y)
export CONFIG_WSCCMD
export CFLAGS += -DBCMWPS
# WFA WPS 2.0 Testbed extra caps
#export CFLAGS += -DWFA_WPS_20_TESTBED
endif

ifeq ($(CONFIG_NFC),y)
# WPS_NFC
export CFLAGS += -D__CONFIG_NFC__
endif

ifeq ($(CONFIG_EMF),y)
export CFLAGS += -D__CONFIG_EMF__
endif

ifeq ($(CONFIG_IGMP_PROXY),y)
export CFLAGS += -D__CONFIG_IGMP_PROXY__
endif

ifeq ($(CONFIG_NORTON),y)
export CFLAGS += -D__CONFIG_NORTON__
endif

ifeq ($(CONFIG_TRAFFIC_MGMT_RSSI_POLICY),y)
export CFLAGS += -DTRAFFIC_MGMT_RSSI_POLICY
endif

ifeq ($(CONFIG_WL_ACI),y)
export CFLAGS += -D__CONFIG_WL_ACI__
endif

ifeq ($(CONFIG_TRAFFIC_MGMT),y)
export CFLAGS += -DTRAFFIC_MGMT
endif

ifeq ($(CONFIG_MEDIA_IPTV),y)
export CFLAGS += -D__CONFIG_MEDIA_IPTV__
export CFLAGS += -DTRAFFIC_MGMT
export CFLAGS += -DTRAFFIC_MGMT_RSSI_POLICY
obj-$(CONFIG_UTELNETD) += utelnetd
endif

MNL_CFLAGS:="-I$(LIBMNL_DIR)/install/include"
MNL_LIBS:="-L$(LIBMNL_DIR)/install/lib -lmnl"

NFNETLINK_CFLAGS:="-I$(LIBNFNETLINK_DIR)/install/include"
NFNETLINK_LIBS:="-L$(LIBNFNETLINK_DIR)/install/lib -lnfnetlink"

NETFILTER_CONNTRACK_CFLAGS:="-I$(LIBNETFILTER_CONNTRACK_DIR)/install/include"
NETFILTER_CONNTRACK_LIBS:="-L$(LIBNETFILTER_CONNTRACK_DIR)/install/lib -lnetfilter_conntrack"

NETFILTER_QUEUE_CFLAGS:="-I$(LIBNETFILTER_QUEUE_DIR)/install/include"
NETFILTER_QUEUE_LIBS:="-L$(LIBNETFILTER_QUEUE_DIR)/install/lib -lnetfilter_queue"

ifeq ($(CONFIG_SOUND),y)
export CFLAGS += -D__CONFIG_SOUND__
endif

ifeq ($(CONFIG_VOIP),y)
export CFLAGS += -DBCMVOIP
endif

ifeq ($(CONFIG_SQUASHFS), y)
ROOT_IMG := target.squashfs
else
ROOT_IMG := target.cramfs
endif

ifeq ($(CONFIG_WAPI),y)
export CFLAGS += -DBCMWAPI_WAI -DBCMWAPI_WPI
endif

ifeq ($(CONFIG_PHYMON_UTILITY),y)
export CFLAGS += -DPHYMON
endif

ifeq ($(CONFIG_OPENSSL),y)
export CFLAGS += -DSUPPORT_REMOTE_HTTPS
endif

ifeq ($(CONFIG_QOS_AUTO_CHECK_BW),y)
export CFLAGS += -DQOS_AUTO_CHECK_BANDWIDTH
endif

ifeq ($(CONFIG_WPS_V20),y)
export CFLAGS += -DINCLUDE_WPS_V20
endif

ifeq ($(CONFIG_5G_AUTO_CHANNEL),y)
export CFLAGS += -DINCLUDE_5G_AUTO_CHANNEL
endif

ifneq (2_4,$(LINUX_VERSION))
CRAMFSDIR := cramfs
else
CRAMFSDIR := $(LINUXDIR)/scripts/cramfs
endif

ifeq ($(CONFIG_OPENDNS),y)
export CFLAGS += -DOPENDNS_PARENTAL_CONTROL
endif

ifeq ($(CONFIG_ACCESSCONTROL),y)
export CFLAGS += -DINCLUDE_ACCESSCONTROL
endif

export CFLAGS += -DINCLUDE_UCP


ifeq ($(PROFILE),R8000)
export CFLAGS += -DU12H315 -DR8000
export CFLAGS += -DMULTIPLE_SSID
export CFLAGS += -DENABLE_ML
export CFLAGS += -DOPEN_SOURCE_SUPPORT
export CFLAGS += -DBCM53125
export CFLAGS += -DBCM5301X
export CFLAGS += -DACS_INTF_DETECT_PATCH
export CFLAGS +=  -DCONFIG_RUSSIA_IPTV
export CFLAGS +=  -DCONFIG_SAMBA_NO_RESTART
ifeq ($(CONFIG_GPIO_LED_SWITCH),y)
export CFLAGS += -DLED_GPIO_SWITCH
endif
ifeq ($(INCLUDE_FBWIFI_FLAG),y)
export CFLAGS += -DFBWIFI_FLAG
endif
ifeq ($(CONFIG_DLNA),y)
export CFLAGS += -DDLNA
#export CFLAGS += -DDLNA_DEBUG
endif
export CFLAGS += -DHTTP_ACCESS_USB
export CFLAGS += -DMAX_USB_ACCESS
export CFLAGS += -DSAMBA_ENABLE
export CFLAGS += -DUSB_NEW_SPEC
export CFLAGS += -DINCLUDE_WIFI_BUTTON
export CONFIG_LIBNSL=y
export CFLAGS += -DINCLUDE_USB_LED
export CFLAGS += -DINCLUDE_DUAL_BAND
export CFLAGS += -DSINGLE_FIRMWARE
export CFLAGS += -DINCLUDE_GET_ST_CHKSUM
export CFLAGS += -DUNIFIED_STR_TBL
export CFLAGS += -DFIRST_MTD_ROTATION
export CFLAGS += -DWIFI_ON_OFF_SCHE
export CFLAGS += -DAUTO_CONN_24HR
export CFLAGS += -DIGMP_PROXY
export CFLAGS += -DAP_MODE
#added by dennis ,01/02/2013, for ap mode detection
#export CFLAGS += -DINCLUDE_DETECT_AP_MODE
export CFLAGS += -D__CONFIG_IGMP_SNOOPING__
ifeq ($(LINUXDIR), $(BASEDIR)/components/opensource/linux/linux-2.6.36)
export CFLAGS += -DLINUX26
export CFLAGS += -DINCLUDE_IPV6
endif
export CFLAGS += -DPRESET_WL_SECURITY
export CFLAGS += -DNEW_BCM_WPS_IPC
export CFLAGS += -DSUPPORT_AC_MODE
export CFLAGS += -DSTA_MODE
export CFLAGS += -DPPP_RU_DESIGN
export CFLAGS += -DEXT_ACS
export CFLAGS += -DARP_PROTECTION
#export CFLAGS += -DCONFIG_2ND_5G_BRIDGE_MODE
export CFLAGS += -DVLAN_SUPPORT
endif

ifeq ($(FW_TYPE),NA)
export CFLAGS += -DFW_VERSION_NA
endif

ifeq ($(CONFIG_BCMDCS),y)
export CFLAGS += -DBCM_DCS
endif

ifeq ($(CONFIG_EXTACS),y)
export CFLAGS += -DEXT_ACS
endif

ifeq ($(CONFIG_MFP),y)
export CFLAGS += -DMFP
endif

ifeq ($(CONFIG_HSPOT),y)
export CFLAGS += -DNAS_GTK_PER_STA
endif

ifeq ($(CONFIG_MFP_TEST),y)
export CFLAGS += -DMFP_TEST
endif

ifeq ($(CONFIG_SIGMA),y)
export CFLAGS += -D__CONFIG_SIGMA__
endif

ifeq ($(CONFIG_MINI_ROUTER), y)
export CFLAGS += -D__CONFIG_ROUTER_MINI__
endif

ifeq ($(CONFIG_NPS), y)
export CFLAGS += -DNPS
endif

ifneq ($(CONFIG_HSPOT)$(CONFIG_NPS),)
export CFLAGS += -DPROXYARP
endif

export CC := $(CROSS_COMPILE)gcc
export CXX := $(CROSS_COMPILE)g++
export AR := $(CROSS_COMPILE)ar
export AS := $(CROSS_COMPILE)as
export LD := $(CROSS_COMPILE)ld
export NM := $(CROSS_COMPILE)nm
export RANLIB := $(CROSS_COMPILE)ranlib
export STRIP := $(CROSS_COMPILE)strip
export SIZE := $(CROSS_COMPILE)size
export OBJCOPY := $(CROSS_COMPILE)objcopy
ifneq ("$(LINUX_VERSION)","2_4")
export MKSYM := $(shell which $(TOP)/misc/mksym.pl)
endif

#
# Install and target directories
#

export PLATFORMDIR := $(TOP)/$(PLATFORM)
export INSTALLDIR := $(PLATFORMDIR)/install
export TARGETDIR := $(PLATFORMDIR)/target

define STRIP_DEBUG_SYMBOLS
	@dbgsymf=$(basename $(1))_dbgsym$(suffix $(1)); \
	if [ "$(1)" -nt "$${dbgsymf}" ]; then \
	   echo "#- $0"; \
	   ls -ln $1 | awk '{printf "Orig  size: %10d bytes, %s\n",$$5,$$NF}'; \
	   cp -p -v $1 $$dbgsymf; $(STRIP) -d $(1); touch $$dbgsymf; \
	   ls -ln $1 | awk '{printf "Strip size: %10d bytes, %s\n",$$5,$$NF}'; \
	fi
endef

# USB AP support
# note : the dongle target is only for after pre-build 
obj-$(CONFIG_USBAP) += bmac dongle

# DHD AP support (PCIe full dongle)
obj-$(CONFIG_DHDAP) += dhd pciefd

# always build libbcmcrypto
obj-y += libbcmcrypto

#
# Configuration
#

#ifdef BCMSOUND
obj-$(CONFIG_SIGMA) += sigma
obj-$(CONFIG_SALSA) += salsa
obj-$(CONFIG_LIBZ) += libz
obj-$(CONFIG_LIBID3TAG) += libid3tag
obj-$(CONFIG_LIBMAD) += libmad
obj-$(CONFIG_MADPLAY) += madplay
obj-$(CONFIG_APLAY) += alsa-utils/aplay
#endif
obj-$(CONFIG_NVRAM) += nvram
obj-$(CONFIG_SHARED) += shared

#obj-$(CONFIG_LIBBCM) += libbcm

obj-$(CONFIG_RC) += rc
obj-$(CONFIG_GLIBC) += lib
obj-$(CONFIG_UCLIBC) += lib
obj-$(CONFIG_WLCONF) += wlconf
obj-$(CONFIG_BRIDGE) += bridge
obj-$(CONFIG_BUSYBOX) += busybox
obj-$(CONFIG_DNSMASQ) += dnsmasq
obj-$(CONFIG_IPTABLES) += iptables
obj-$(CONFIG_LIBIPT) += iptables
# Build only for kernel >= 2.6.36.
ifeq ($(call wlan_version_ge,$(BCM_KVERSIONSTRING),2.6.36),TRUE)
obj-$(CONFIG_LIBSTDCPP) += libstdcpp
obj-$(CONFIG_LIBFLOW) += libflow
obj-$(CONFIG_LIBMNL) += libmnl
obj-$(CONFIG_LIBNFNETLINK) += libnfnetlink
obj-$(CONFIG_LIBNETFILTER_CONNTRACK) += libnetfilter_conntrack
obj-$(CONFIG_LIBNETFILTER_QUEUE) += libnetfilter_queue
endif
obj-$(CONFIG_HSPOT) += hspot_ap
obj-$(CONFIG_NAS) += nas
obj-$(CONFIG_WAPI) += wapi/wapid
obj-$(CONFIG_WAPI_IAS) += wapi/as
obj-$(CONFIG_SES) += ses/ses
obj-$(CONFIG_SES_CL) += ses/ses_cl
obj-$(CONFIG_EZC) += ezc
#obj-$(CONFIG_NETCONF) += netconf
obj-$(CONFIG_NTP) += ntpclient
obj-$(CONFIG_PPP) += ppp
obj-$(CONFIG_UDHCPD) += udhcpd
obj-$(CONFIG_UPNP) += upnp
obj-$(CONFIG_NORTON) += norton
obj-$(CONFIG_LIBUPNP) += libupnp
obj-$(CONFIG_FFMPEG) += ffmpeg
obj-$(CONFIG_DLNA_DMR) += dlna/dmr
obj-$(CONFIG_DLNA_DMS) += dlna/dms
obj-$(CONFIG_SAMBA) += samba
obj-$(CONFIG_UTILS) += utils
obj-$(CONFIG_ETC) += etc
obj-$(CONFIG_VLAN) += vlan
obj-y += wps
obj-$(CONFIG_WSCCMD) += netconf
obj-$(CONFIG_WSCCMD) += iptables
#obj-$(CONFIG_WSCCMD) += bcmupnp
obj-$(CONFIG_EMF) += emf
obj-$(CONFIG_EMF) += igs
obj-$(CONFIG_IGMP_PROXY) += igmp
obj-$(CONFIG_WL_ACI) += aci
ifeq (2_6_36,$(LINUX_VERSION))
obj-y += udev
obj-y += hotplug2
endif
obj-$(CONFIG_LLD2D) += lltd/wrt54g-linux
obj-$(CONFIG_ACL_LOGD) += acl_log
#obj-$(CONFIG_GPIO) += gpio
obj-$(CONFIG_SWRESETD) += swresetd
#if defined(PHYMON)
obj-$(CONFIG_PHYMON_UTILITY) += phymon
#endif
#if defined(EXT_ACS)
#obj-$(CONFIG_EXTACS) += acsd
#endif
ifeq ($(NETGEAR_PATCH),1)
#obj-$(CONFIG_BCMBSD) += gbsd
else
#obj-$(CONFIG_BCMBSD) += bsd
endif
obj-$(CONFIG_VMSTAT) += vmstat

obj-$(CONFIG_RADVD) += radvd
obj-$(CONFIG_IPROUTE2) += iproute2
obj-$(CONFIG_IPUTILS) += iputils
obj-$(CONFIG_DHCPV6S) += dhcp6s
obj-$(CONFIG_DHCPV6C) += dhcp6c

obj-$(CONFIG_MPSTAT) += mpstat
obj-$(CONFIG_TASKSET) += taskset
#speed up USB throughput

# BUZZZ tools: function call tracing, performance monitoring, event history
obj-$(CONFIG_BUZZZ) += buzzz

# Gigle apps
obj-$(CONFIG_PLC) += plc
ifeq ($(CONFIG_PLC),y)
export CFLAGS += -D__CONFIG_PLC__ -D__CONFIG_URE__
CFLAGS	+= -DPLC -DWPS_LONGPUSH_DISABLE
endif

#ifdef __CONFIG_TREND_IQOS__
ifeq ($(LINUX_VERSION),2_6_36)
ifeq ($(CONFIG_TREND_IQOS),y)
obj-$(CONFIG_TREND_IQOS) += iqos
obj-$(CONFIG_TREND_IQOS) += bcmiqosd
# Speedtest_cli
obj-$(CONFIG_TREND_IQOS) += speedtest-cli
# curl
obj-$(CONFIG_TREND_IQOS) += curl
export CFLAGS += -D__CONFIG_TREND_IQOS__
endif
endif
#endif /* __CONFIG_TREND_IQOS__ */

# always build eap dispatcher
obj-y += eapd/linux
obj-y += parser

ifeq ($(CONFIG_VOIP),y)
obj-y += voipd
endif

ifeq ($(CONFIG_ACOS_MODULES),y)
#obj-y += ../../ap/acos
obj-y += ../../ap/gpl
fw_cfg_file := ../../../project/acos/include/ambitCfg.h
else
obj-$(CONFIG_HTTPD) += httpd
obj-$(CONFIG_WWW) += www
endif


obj-clean := $(foreach obj,$(obj-y) $(obj-n),$(obj)-clean)
obj-install := $(foreach obj,$(obj-y),$(obj)-install)

ifneq ($(WLTEST),1)
ifneq ($(shell grep "CONFIG_EMBEDDED_RAMDISK=y" $(LINUXDIR)/.config),)
export WLTEST := 1
endif
endif

#
# Basic rules
#


all: acos_link version $(LINUXDIR)/.config linux_kernel $(obj-y)
        # Also build kernel
        
linux_kernel:        
ifeq ($(LINUXDIR), $(BASEDIR)/components/opensource/linux/linux-2.6.36)
	$(MAKE) -C $(LINUXDIR) zImage
	$(MAKE) CONFIG_SQUASHFS=$(CONFIG_SQUASHFS) -C $(SRCBASE)/router/compressed
else
	if ! grep -q "CONFIG_EMBEDDED_RAMDISK=y" $(LINUXDIR)/.config ; then \
	    $(MAKE) -C $(LINUXDIR) zImage ; \
	fi
endif
	if grep -q "CONFIG_MODULES=y" $(LINUXDIR)/.config ; then \
	    $(MAKE) -C $(LINUXDIR) modules ; \
	fi
	# Preserve the debug versions of these and strip for release
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/vmlinux)
ifneq (2_4,$(LINUX_VERSION))
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/wl/wl.ko)
ifeq ("$(CONFIG_USBAP)","y")
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/wl/wl_high/wl_high.ko)
#$(STRIP) $(LINUXDIR)/drivers/net/wl/wl_high.ko
endif 
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/et/et.ko)
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/ctf/ctf.ko)
	#$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/bcm57xx/bcm57xx.ko)
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/emf/emf.ko)
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/igs/igs.ko)
else 
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/wl/wl.o)
ifeq ("$(CONFIG_USBAP)","y")
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/wl/wl_high/wl_high.o)
endif
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/et/et.o)
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/ctf/ctf.o)
	#$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/bcm57xx/bcm57xx.o)
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/emf/emf.o)
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/igs/igs.o)
	$(call STRIP_DEBUG_SYMBOLS,$(LINUXDIR)/drivers/net/ubd/ubd.o)
endif


# well, we should always be able to use the BOM, but right now, the last build step on
# the build machine doesn't have it, so we don't rerun this is the file already 
# exists

version:  $(SRCBASE)/router/shared/router_version.h

# this could fail if the bom doesn't exist. We don't care as long as there is a valid router_version.h
# if not, the build will fail anyway.
$(SRCBASE)/router/shared/router_version.h: $(SRCBASE)/router/shared/version.h.in
	[ ! -e $(SRCBASE)/tools/release/linux-router-bom.mk  ] ||  make SRCBASE=$(SRCBASE) -f $(SRCBASE)/tools/release/linux-router-bom.mk version
ifeq ($(CONFIG_DHDAP),y)
	$(MAKE) -C $(SRCBASE_DHD)/include
	$(MAKE) -C $(SRCBASE_FW)/include
endif



router-clean: $(obj-clean) config-clean
	rm -rf $(TARGETDIR)
	rm -f $(PLATFORMDIR)/linux.trx $(PLATFORMDIR)/linux-gzip.trx
	rm -f $(PLATFORMDIR)/vmlinuz $(PLATFORMDIR)/vmlinuz-gzip
	rm -f $(PLATFORMDIR)/target.cramfs $(PLATFORMDIR)/target.squashfs
	rm -rf $(INSTALLDIR)/busybox

clean: router-clean
	@echo cleaning LINUXDIR = $(LINUXDIR)
ifneq (2_4,$(LINUX_VERSION))
	# we need to pass some conf file for cleaning 2.6. The kbuild clean doesn't seem to 
	# to load the .config the way our wl Makefile  is expecting.
	$(MAKE) CONFIG_WL_CONF=wlconfig_lx_router_ap -C $(LINUXDIR) $(SUBMAKE_SETTINGS) clean
	$(MAKE) -C $(SRCBASE)/router/compressed ARCH=$(ARCH) clean
else
	$(MAKE) -C $(LINUXDIR) $(SUBMAKE_SETTINGS) clean
endif
#	$(MAKE) -C $(SRCBASE)/cfe/build/broadcom/bcm947xx ARCH=$(ARCH) clean
#	[ ! -f $(SRCBASE)/tools/misc/Makefile ] || $(MAKE) -C $(SRCBASE)/tools/misc clean

distclean mrproper: clean
	rm -f .config .config.plt $(LINUXDIR)/.config

install package: $(filter-out lib-install,$(obj-install)) $(LINUXDIR)/.config
        # Install binaries into target directory
	install -d $(TARGETDIR)
	install -d $(TARGETDIR)/usr
	install -d $(TARGETDIR)/usr/lib

	for dir in $(wildcard $(patsubst %,$(INSTALLDIR)/%,$(obj-y))) ; do \
	    (cd $${dir} && tar cpf - .) | (cd $(TARGETDIR) && tar xpf -) \
	done
	# optimize the crypto library by removing unneeded symbols
#	[ ! -d libbcmcrypto ] || $(MAKE) -C libbcmcrypto optimize
	
ifneq ("$(CONFIG_WAPI)$(CONFIG_WAPI_IAS)","")
	# optimize the OPENSSL library by removing unneeded symbols
#	[ ! -d wapi/wapid ] || $(MAKE) -C wapi/wapid optimize
endif
	# Install (and possibly optimize) C library
	$(MAKE) lib-install
	# Install modules into filesystem
	if grep -q "CONFIG_MODULES=y" $(LINUXDIR)/.config ; then \
	    $(MAKE) -C $(LINUXDIR) $(SUBMAKE_SETTINGS) \
		modules_install DEPMOD=/bin/true INSTALL_MOD_PATH=$(TARGETDIR) ; \
	fi
	#	$(MAKE) acos-install
	#water, 08/11/2009
	rm -rf $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/build
	rm -rf $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/source
	rm -rf $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/modules.*
	rm -rf $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/extra
	find $(TARGETDIR) -name .svn  | xargs rm -rf
	rm -rf $(TARGETDIR)/usr/bin/[
	rm -rf $(TARGETDIR)/usr/bin/[[
	rm -rf $(TARGETDIR)/usr/bin/test
	rm -rf $(TARGETDIR)/bin/false
	rm -rf $(TARGETDIR)/bin/true
	rm -rf $(TARGETDIR)/usr/sbin/upnpnat
	rm -rf $(TARGETDIR)/usr/sbin/epi_ttcp
	$(STRIP) $(TARGETDIR)/bin/eapd

ifeq ($(PROFILE),R8000)
	install -d $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/drivers/usbprinter
	install usbprinter/GPL_NetUSB.ko $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/drivers/usbprinter
	install usbprinter/NetUSB.ko $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/drivers/usbprinter
	install usbprinter/KC_BONJOUR $(TARGETDIR)/usr/bin
	install usbprinter/KC_PRINT $(TARGETDIR)/usr/bin
	install -d $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/drivers/ufsd
	install ufsd/ufsd.ko $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/drivers/ufsd
	install ufsd/chkntfs $(TARGETDIR)/bin
	install utelnetd/utelnetd $(TARGETDIR)/bin
	install arm-uclibc/netgear-streaming-db $(TARGETDIR)/etc
	install utelnetd/ookla $(TARGETDIR)/bin
	install fbwifi/fbwifi $(TARGETDIR)/bin
	install prebuilt/AccessCntl.ko $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/lib
	install prebuilt/opendns.ko $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/lib
	install prebuilt/acos_nat.ko $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/lib
	install prebuilt/ipv6_spi.ko $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/lib
	install prebuilt/MultiSsidCntl.ko $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/lib
	install prebuilt/ubd.ko $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/lib
	install prebuilt/br_dns_hijack.ko $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/lib
	install prebuilt/l7_filter.ko $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/lib
	install -d $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/drivers/net
	install -d $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/drivers/net/et
	install -d $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/drivers/net/dhd
	install prebuilt/et.ko $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/drivers/net/et
	install prebuilt/dhd.ko $(TARGETDIR)/lib/modules/2.6.36.4brcmarm+/kernel/drivers/net/dhd
endif

ifneq (2_4,$(LINUX_VERSION))
ifeq ("$(CONFIG_USBAP)","y")
	echo "=====> Don't delete wl_high.ko for USBAP"
	find $(TARGETDIR) -name "wl_*.ko" | sed s/\.\*wl_high\\\.ko//g | xargs rm -rf
else
	echo "=====> delete wl_high.ko"
	find $(TARGETDIR) -name "wl_*.ko" | xargs rm -rf
endif
else # Linux 2.4
ifeq ("$(CONFIG_USBAP)","y")
	echo "=====> Don't delete wl_high.o for USBAP"
	find $(TARGETDIR) -name "wl_*.o" | sed s/\.\*wl_high\\\.o//g | xargs rm -rf
else
	echo "=====> delete"
	find $(TARGETDIR) -name "wl_*.o" | xargs rm -rf
endif
endif
	# Prepare filesystem
	cd $(TARGETDIR) && $(TOP)/misc/rootprep.sh
	cp -f $(PLATFORMDIR)/acsd $(TARGETDIR)/usr/sbin/acsd
	cp -f $(PLATFORMDIR)/acs_cli $(TARGETDIR)/usr/sbin/acs_cli

ifeq ($(CONFIG_SQUASHFS), y)
	###########################################
	### Create Squashfs filesystem ############
	rm -f $(PLATFORMDIR)/$(ROOT_IMG)
	rm -f $(PLATFORMDIR)/$(ROOT_IMG).trim
	rm -f $(TARGETDIR)/sbin/st*
	find $(TARGETDIR) -name ".svn" | xargs rm -rf
endif
ifeq ($(CONFIG_SQUASHFS), y)
ifeq (2_6_36,$(LINUX_VERSION))
	$(MAKE) -C squashfs-4.2 mksquashfs
	find $(TARGETDIR) -name ".svn" | xargs rm -rf
	squashfs-4.2/mksquashfs $(TARGETDIR) $(PLATFORMDIR)/$(ROOT_IMG) -noappend -all-root
else
	# Make sure mksquashfs 3.0 is used
	$(MAKE) -C squashfs mksquashfs
	squashfs/mksquashfs $(TARGETDIR) $(PLATFORMDIR)/$(ROOT_IMG) -noappend -all-root
endif
else # CONFIG_SQUASHFS
	# Make sure mkcramfs-2.0 is used
	$(MAKE) -C $(CRAMFSDIR) mkcramfs
	# '-u 0 -g 0' will set the uid and gid of all the files to 0 (root)
	# These options are currently only available on our version of mkcramfs
	$(CRAMFSDIR)/mkcramfs -u 0 -g 0 $(TARGETDIR) $(PLATFORMDIR)/$(ROOT_IMG)
endif # CONFIG_SQUASHFS

ifneq (2_4,$(LINUX_VERSION))
	# Package kernel and filesystem
ifeq ($(BUILD_MFG), 1)
	cd $(TARGETDIR) ; \
	find . | cpio -o -H newc | gzip > $(LINUXDIR)/usr/initramfs_data.cpio.gz
	ls -l $(LINUXDIR)/usr/initramfs_data.cpio.gz
	$(MAKE) -C $(LINUXDIR) $(SUBMAKE_SETTINGS) zImage
	$(MAKE) -C $(SRCBASE)/router/compressed ARCH=$(ARCH)
else
	cp $(SRCBASE)/router/compressed/vmlinuz $(PLATFORMDIR)/
	trx -o $(PLATFORMDIR)/linux.trx $(PLATFORMDIR)/vmlinuz $(PLATFORMDIR)/$(ROOT_IMG)
	    addpattern -i $(PLATFORMDIR)/linux.trx -o $(PLATFORMDIR)/linux_lsys.bin ; \
	if grep -q "CONFIG_SQUASHFS=y" $(LINUXDIR)/.config ; then \
	cp $(SRCBASE)/router/compressed/vmlinuz-gzip $(PLATFORMDIR)/ ; \
	trx -o $(PLATFORMDIR)/linux-gzip.trx $(PLATFORMDIR)/vmlinuz-gzip $(PLATFORMDIR)/$(ROOT_IMG) ; \
	fi
endif
	# Pad self-booting Linux to a 64 KB boundary
	cp $(SRCBASE)/router/compressed/zImage $(PLATFORMDIR)/
else # LINUXDIR
	# Package kernel and filesystem
	if grep -q "CONFIG_EMBEDDED_RAMDISK=y" $(LINUXDIR)/.config ; then \
	    cp $(PLATFORMDIR)/$(ROOT_IMG) $(LINUXDIR)/arch/mips/ramdisk/$${CONFIG_EMBEDDED_RAMDISK_IMAGE} ; \
		$(MAKE) -C $(LINUXDIR) $(SUBMAKE_SETTINGS) zImage ; \
	else \
		cp $(LINUXDIR)/arch/mips/brcm-boards/bcm947xx/compressed/vmlinuz $(PLATFORMDIR)/ ; \
		trx -o $(PLATFORMDIR)/linux.trx $(PLATFORMDIR)/vmlinuz $(PLATFORMDIR)/$(ROOT_IMG) ; \
		if grep -q "CONFIG_SQUASHFS=y" $(LINUXDIR)/.config ; then \
			cp $(LINUXDIR)/arch/mips/brcm-boards/bcm947xx/compressed/vmlinuz-lzma $(PLATFORMDIR)/ ; \
			trx -o $(PLATFORMDIR)/linux-lzma.trx $(PLATFORMDIR)/vmlinuz-lzma $(PLATFORMDIR)/$(ROOT_IMG) ; \
		fi \
	fi
	# Pad self-booting Linux to a 64 KB boundary
	cp $(LINUXDIR)/arch/mips/brcm-boards/bcm947xx/compressed/zImage $(PLATFORMDIR)/
endif
	dd conv=sync bs=64k < $(PLATFORMDIR)/zImage > $(PLATFORMDIR)/linux.bin
	# Append filesystem to self-booting Linux
	cat $(PLATFORMDIR)/$(ROOT_IMG) >> $(PLATFORMDIR)/linux.bin

	###########################################
	### Create LZMA kernel ####################
	#$(OBJCOPY) -O binary -g $(LINUXDIR)/vmlinux $(PLATFORMDIR)/vmlinux.bin 
	#../../tools/lzma e $(PLATFORMDIR)/vmlinux.bin $(PLATFORMDIR)/vmlinux.lzma 
	#trx -o $(PLATFORMDIR)/linux.trx $(PLATFORMDIR)/vmlinux.lzma $(PLATFORMDIR)/$(ROOT_IMG) 
	#rm -f $(PLATFORMDIR)/vmlinux.bin $(PLATFORMDIR)/vmlinux.lzma 

	###########################################
	### Create .chk files for Web UI upgrade ##
	cd $(PLATFORMDIR) && touch rootfs && \
	../../../tools/packet -k linux.trx -f rootfs -b $(BOARDID_FILE) \
	-ok kernel_image -oall kernel_rootfs_image -or rootfs_image \
	-i $(fw_cfg_file) && \
	rm -f rootfs && \
	cp kernel_rootfs_image.chk $(FW_NAME)_`date +%m%d%H%M`.chk

#
# Configuration rules
#

conf mconf:
	$(MAKE) -C config LINUXDIR=${LINUXDIR}
	@LINUXDIR=${LINUXDIR} ./config/$@ ./config/Config
	# Also configure kernel
	$(MAKE) LINUXDIR=${LINUXDIR} k$@

oldconf: .config
	$(MAKE) -C config LINUXDIR=${LINUXDIR}
	@LINUXDIR=${LINUXDIR} ./config/conf -o ./config/Config
	# Also configure kernel
	$(MAKE) LINUXDIR=${LINUXDIR} k$@

kconf:
	$(MAKE) -C $(LINUXDIR) $(SUBMAKE_SETTINGS) config

kmconf: $(LINUXDIR)/.config 
	$(MAKE) -C $(LINUXDIR) $(SUBMAKE_SETTINGS) menuconfig

koldconf: $(LINUXDIR)/.config
	$(MAKE) -C $(LINUXDIR) $(SUBMAKE_SETTINGS) oldconfig

# Convenience
config: conf

menuconfig: mconf

oldconfig: oldconf

# Platform file
.config.plt:
	@echo "PLT=$(PLT)" > $@
	@echo "LINUX_VERSION=$(LINUX_VERSION)" >> $@

# Default configurations
.config:
ifneq (2_4,$(LINUX_VERSION))
	cp config/defconfig-2.6 $@
else
	cp config/defconfig $@
endif
	$(MAKE) SRCBASE=$(SRCBASE) LINUXDIR=$(LINUXDIR) oldconfig

$(LINUXDIR)/.config:
ifneq (2_4,$(LINUX_VERSION))
	cp $(LINUXDIR)/.config_$(PROFILE) $@
else
	cp $(LINUXDIR)/.config_$(PROFILE) $@
endif

# Overwrite Kernel .config
check_kernel_config: $(LINUXDIR)/.config
	cp $(LINUXDIR)/.config $(LINUXDIR)/.config.tmp
ifeq ($(CONFIG_SQUASHFS), y)
	if ! grep -q "CONFIG_SQUASHFS=y" $(LINUXDIR)/.config ; then \
		cp $(LINUXDIR)/.config $(LINUXDIR)/.config.chk ; \
		sed -e "s/CONFIG_CRAMFS=y/# CONFIG_CRAMFS is not set/g" $(LINUXDIR)/.config.chk | \
		sed -e "s/# CONFIG_SQUASHFS is not set/CONFIG_SQUASHFS=y/g" > \
		$(LINUXDIR)/.config ; \
		rm -f $(LINUXDIR)/.config.chk ; \
	fi
endif
ifeq ($(CONFIG_CRAMFS), y)
	if ! grep -q "CONFIG_CRAMFS=y" $(LINUXDIR)/.config ; then \
		cp $(LINUXDIR)/.config $(LINUXDIR)/.config.chk ; \
		sed -e "s/CONFIG_SQUASHFS=y/# CONFIG_SQUASHFS is not set/g" $(LINUXDIR)/.config.chk | \
		sed -e "s/# CONFIG_CRAMFS is not set/CONFIG_CRAMFS=y/g" > \
		$(LINUXDIR)/.config ; \
		rm -f $(LINUXDIR)/.config.chk ; \
	fi
endif
ifeq ($(CONFIG_SHRINK_MEMORY), y)
	if ! grep -q "CONFIG_SHRINKMEM=y" $(LINUXDIR)/.config ; then \
		cp $(LINUXDIR)/.config $(LINUXDIR)/.config.chk ; \
		sed -e "s/# CONFIG_SHRINKMEM is not set/CONFIG_SHRINKMEM=y/g" $(LINUXDIR)/.config.chk > \
		$(LINUXDIR)/.config ; \
		rm -f $(LINUXDIR)/.config.chk ; \
	fi
else
	if grep -q "CONFIG_SHRINKMEM=y" $(LINUXDIR)/.config ; then \
		cp $(LINUXDIR)/.config $(LINUXDIR)/.config.chk ; \
		sed -e "s/CONFIG_SHRINKMEM=y/# CONFIG_SHRINKMEM is not set/g" $(LINUXDIR)/.config.chk > \
		$(LINUXDIR)/.config ; \
		rm -f $(LINUXDIR)/.config.chk ; \
	fi
endif
ifeq ($(CONFIG_PLC), y)
	if ! grep -q "CONFIG_PLC=y" $(LINUXDIR)/.config ; then \
		cp $(LINUXDIR)/.config $(LINUXDIR)/.config.chk ; \
		sed -e "s/# CONFIG_PLC is not set/CONFIG_PLC=y/g" $(LINUXDIR)/.config.chk > \
		$(LINUXDIR)/.config ; \
		rm -f $(LINUXDIR)/.config.chk ; \
	fi
else
	if grep -q "CONFIG_PLC=y" $(LINUXDIR)/.config ; then \
		cp $(LINUXDIR)/.config $(LINUXDIR)/.config.chk ; \
		sed -e "s/CONFIG_PLC=y/# CONFIG_PLC is not set/g" $(LINUXDIR)/.config.chk > \
		$(LINUXDIR)/.config ; \
		rm -f $(LINUXDIR)/.config.chk ; \
	fi
endif
ifeq ($(CONFIG_NFC), y)
	if ! grep -q "CONFIG_PLAT_MUX_CONSOLE=y" $(LINUXDIR)/.config ; then \
		cp $(LINUXDIR)/.config $(LINUXDIR)/.config.chk ; \
		sed -e "s/# CONFIG_PLAT_MUX_CONSOLE is not set/CONFIG_PLAT_MUX_CONSOLE=y/g" $(LINUXDIR)/.config.chk > \
		$(LINUXDIR)/.config ; \
		rm -f $(LINUXDIR)/.config.chk ; \
	fi
	# Force UP before we fix NFC GKI communication issue
	if grep -q "CONFIG_SMP=y" $(LINUXDIR)/.config ; then \
		cp $(LINUXDIR)/.config $(LINUXDIR)/.config.chk ; \
		sed -e "s/CONFIG_SMP=y/# CONFIG_SMP is not set/g" $(LINUXDIR)/.config.chk > \
		$(LINUXDIR)/.config ; \
		rm -f $(LINUXDIR)/.config.chk ; \
		echo "# CONFIG_TINY_RCU is not set" >> $(LINUXDIR)/.config ; \
	fi
else
	if grep -q "CONFIG_PLAT_MUX_CONSOLE=y" $(LINUXDIR)/.config ; then \
		cp $(LINUXDIR)/.config $(LINUXDIR)/.config.chk ; \
		sed -e "s/CONFIG_PLAT_MUX_CONSOLE=y/# CONFIG_PLAT_MUX_CONSOLE is not set/g" $(LINUXDIR)/.config.chk > \
		$(LINUXDIR)/.config ; \
		rm -f $(LINUXDIR)/.config.chk ; \
	fi
endif
	# Make kernel config again if changed
	if ! cmp $(LINUXDIR)/.config $(LINUXDIR)/.config.tmp ; then \
		$(MAKE) -C $(LINUXDIR) $(SUBMAKE_SETTINGS) oldconfig ; \
	fi

#
# Overrides
#

ifneq (2_4,$(LINUX_VERSION))
busybox-1.x/Config.h: dummy
	cd busybox-1.x && rm -f Config.h && ln -sf include/autoconf.h Config.h && touch Config.h
ifneq ($(PROFILE),)
	+cd busybox-1.x && cp configs/bbconfig-$(CONFIG_BUSYBOX_CONFIG)_$(PROFILE) .config && $(MAKE) clean
else
	cd busybox-1.x && cp configs/bbconfig-$(CONFIG_BUSYBOX_CONFIG) .config && make clean
endif

busybox: busybox-1.x/Config.h
	$(MAKE) -C busybox-1.x ARCH=$(ARCH) INSTALL

busybox-install:
	$(MAKE) -C busybox-1.x ARCH=$(ARCH) CONFIG_PREFIX=$(INSTALLDIR)/busybox install

busybox-clean:
	$(MAKE) -C busybox-1.x ARCH=$(ARCH) clean

rc: netconf nvram shared
	+$(MAKE) LINUXDIR=$(LINUXDIR) EXTRA_LDFLAGS=$(EXTRA_LDFLAGS) -C rc
ifneq ($(CONFIG_BUSYBOX),)
rc: busybox-1.x/Config.h
endif
else #linux-2.6
CURBBCFG=$(CONFIG_BUSYBOX_CONFIG).h
OLDBBCFG=$(shell basename $$(readlink busybox/Config.h) 2> /dev/null)
busybox/Config.h: dummy
ifneq ($(OLDBBCFG),$(CURBBCFG))
	cd busybox && rm -f Config.h && ln -sf configs/$(CURBBCFG) Config.h && touch Config.h
endif

busybox: busybox/Config.h
	$(MAKE) -C busybox STRIPTOOL=$(STRIP)

busybox-install:
	$(MAKE) -C busybox STRIPTOOL=$(STRIP) PREFIX=$(INSTALLDIR)/busybox install

#rc: netconf nvram shared
rc: nvram shared
ifneq ($(CONFIG_BUSYBOX),)
rc: busybox/Config.h
endif
endif #linux-2.6

rc-install:
	make LINUXDIR=$(LINUXDIR) INSTALLDIR=$(INSTALLDIR)/rc -C rc install

lib-install:
	make LX_VERS=$(LINUX_VERSION) INSTALLDIR=$(INSTALLDIR)/lib ARCH=$(ARCH) -C lib install

www www-%:
	$(MAKE) -C www/$(CONFIG_VENDOR) $* INSTALLDIR=$(INSTALLDIR)/www

NORTON_DIR := $(BASEDIR)/components/vendor/symantec/norton

norton:
	+$(MAKE) -C $(NORTON_DIR)

norton-install:
	+$(MAKE) -C $(NORTON_DIR) install INSTALLDIR=$(INSTALLDIR)/norton

norton-clean:
	+$(MAKE) -C $(NORTON_DIR) clean

#ifdef __CONFIG_TREND_IQOS__
ifeq ($(LINUX_VERSION),2_6_36)
ifeq ($(CONFIG_TREND_IQOS),y)
IQOS_DIR := $(BASEDIR)/components/vendor/trend/iqos

iqos-install:
	+$(MAKE) -C $(IQOS_DIR) install INSTALLDIR=$(INSTALLDIR)/iqos
.PHONY: iqos-install

CURL_DIR := $(OPENSOURCE_BASE_DIR)/curl
curl:
	+$(MAKE) -C $(CURL_DIR)
curl-install:
	+$(MAKE) -C $(CURL_DIR) install INSTALLDIR=$(INSTALLDIR)/curl
curl-clean:
	+$(MAKE) -C $(CURL_DIR) clean
.PHONY: curl curl-install curl-clean
endif
endif
#endif /* __CONFIG_TREND_IQOS__ */


#Ares mark
dhd:
ifeq ($(CONFIG_DHDAP),y)
#	$(MAKE) TARGET_PREFIX=$(CROSS_COMPILE) -C $(SRCBASE_DHD)/dhd/exe
endif

#Ares mark
dhd-cleanXX :
	#$(MAKE) TARGET_PREFIX=$(CROSS_COMPILE) -C $(SRCBASE_DHD)/dhd/exe clean
	#rm -f $(INSTALLDIR)/dhd/usr/sbin/dhd

#Ares
dhd-install :
ifeq ($(CONFIG_DHDAP),y)
#	install -d $(INSTALLDIR)/dhd/usr/sbin
#	install $(SRCBASE_DHD)/dhd/exe/dhd $(INSTALLDIR)/dhd/usr/sbin
#	$(STRIP) $(INSTALLDIR)/dhd/usr/sbin/dhd
endif



# To re-build bcmdl target, uncomment and exchange libusb and  bcmdl targets
# libusb :
#	cd $(SRCBASE)/usbdev/libusb; ./configure  --host=mipsel-linux CC=mipsel-uclibc-gcc; make


# bcmdl :
#	make TARGETENV=linuxmips -C $(SRCBASE)/usbdev/usbdl

# bcmdl-install :
#	install -d $(TARGETDIR)/bin
#	install -D $(SRCBASE)/usbdev/usbdl/bcmdl $(TARGETDIR)/bin/bcmdl

libusb :

bcmdl :

bcmdl-install :	
	install -d $(INSTALLDIR)/dongle/sbin
	install -D $(SRCBASE)/usbdev/usbdl/mips_$(LINUX_VERSION)/bcmdl $(INSTALLDIR)/dongle/sbin/bcmdl

bridge:
ifneq (2_4,$(LINUX_VERSION))
	$(MAKE) -C bridge-1.x
else
	$(MAKE) -C bridge brctl/brctl
endif

dongle :

bridge-install:
ifneq (2_4,$(LINUX_VERSION))
	install -D bridge-1.x/brctl/brctl $(INSTALLDIR)/bridge/usr/sbin/brctl
else
	install -D bridge/brctl/brctl $(INSTALLDIR)/bridge/usr/sbin/brctl
endif
	$(STRIP) $(INSTALLDIR)/bridge/usr/sbin/brctl

bridge-clean:
ifneq (2_4,$(LINUX_VERSION))
	-$(MAKE) -C bridge-1.x clean
else
	-$(MAKE) -C bridge clean
endif

buzzz:
	+$(MAKE) -C buzzz ARCH=$(ARCH) EXTRA_LDFLAGS=$(EXTRA_LDFLAGS)

buzzz-install:
	install -d $(TARGETDIR)
	+$(MAKE) -C buzzz ARCH=$(ARCH) EXTRA_LDFLAGS=$(EXTRA_LDFLAGS) install

buzzz-clean:
	$(MAKE) -C buzzz clean

ifeq ($(call wlan_version_ge,$(BCM_KVERSIONSTRING),2.6.36),TRUE)
dnsmasq:
	+$(MAKE) -C $(DNSMASQ_DIR)

dnsmasq-install:
	install -D $(DNSMASQ_DIR)/src/dnsmasq $(INSTALLDIR)/dnsmasq/usr/sbin/dnsmasq
	$(STRIP) $(INSTALLDIR)/dnsmasq/usr/sbin/dnsmasq
else
dnsmasq-install:
	install -D dnsmasq/dnsmasq $(INSTALLDIR)/dnsmasq/usr/sbin/dnsmasq
	$(STRIP) $(INSTALLDIR)/dnsmasq/usr/sbin/dnsmasq
endif

libstdcpp:
	# So that generic rule does not take precedence
	@:

libstdcpp-install:
	install -D $(TOOLCHAIN)/usr/lib/libstdc++.so.6.0.14 $(INSTALLDIR)/libstdcpp/usr/lib/libstdc++.so.6.0.14
	+ldconfig -N -n -r $(INSTALLDIR)/libstdcpp usr/lib
	+$(STRIP) $(INSTALLDIR)/libstdcpp/usr/lib/libstdc++.so.6.0.14

libmnl:
	[ -f $(LIBMNL_DIR)/Makefile ] || \
	(cd $(LIBMNL_DIR); \
	 CC=$(CC) ./configure \
	    --target=$(PLATFORM)-linux \
	    --host=$(PLATFORM)-linux \
	    --build=`/bin/arch`-linux \
	    --with-kernel=$(LINUXDIR) \
	    --prefix=$(LIBMNL_DIR)/install)
	+$(MAKE) -C $(LIBMNL_DIR)
	+$(MAKE) -C $(LIBMNL_DIR) install-strip

libmnl-install:
	install -d $(INSTALLDIR)/libmnl/usr/lib
	cp -rf $(LIBMNL_DIR)/install/lib/* $(INSTALLDIR)/libmnl/usr/lib

libmnl-clean:
	+$(MAKE) -C $(LIBMNL_DIR) KERNEL_DIR=$(LINUXDIR) clean

libnfnetlink:
	[ -f $(LIBNFNETLINK_DIR)/Makefile ] || \
	(cd $(LIBNFNETLINK_DIR); \
	 CC=$(CC) ./configure \
	    --target=$(PLATFORM)-linux \
	    --host=$(PLATFORM)-linux \
	    --build=`/bin/arch`-linux \
	    --with-kernel=$(LINUXDIR) \
	    --prefix=$(LIBNFNETLINK_DIR)/install)
	+$(MAKE) -C $(LIBNFNETLINK_DIR)
	+$(MAKE) -C $(LIBNFNETLINK_DIR) install-strip

libnfnetlink-install:
	install -d $(INSTALLDIR)/libnfnetlink/usr/lib
	cp -rf $(LIBNFNETLINK_DIR)/install/lib/* $(INSTALLDIR)/libnfnetlink/usr/lib

libnfnetlink-clean:
	+$(MAKE) -C $(LIBNFNETLINK_DIR) KERNEL_DIR=$(LINUXDIR) clean

libnetfilter_conntrack: libmnl libnfnetlink
	[ -f $(LIBNETFILTER_CONNTRACK_DIR)/Makefile ] || \
	(cd $(LIBNETFILTER_CONNTRACK_DIR); \
	 CC=$(CC) ./configure \
	    --target=$(PLATFORM)-linux \
	    --host=$(PLATFORM)-linux \
	    --build=`/bin/arch`-linux \
	    --with-kernel=$(LINUXDIR) \
	    --prefix=$(LIBNETFILTER_CONNTRACK_DIR)/install \
        LIBNFNETLINK_CFLAGS=$(NFNETLINK_CFLAGS) LIBNFNETLINK_LIBS=$(NFNETLINK_LIBS) \
        LIBMNL_CFLAGS=$(MNL_CFLAGS) LIBMNL_LIBS=$(MNL_LIBS))
	+$(MAKE) -C $(LIBNETFILTER_CONNTRACK_DIR)
	+$(MAKE) -C $(LIBNETFILTER_CONNTRACK_DIR) install-strip

libnetfilter_conntrack-install:
	install -d $(INSTALLDIR)/libnetfilter_conntrack/usr/lib
	cp -rf $(LIBNETFILTER_CONNTRACK_DIR)/install/lib/* $(INSTALLDIR)/libnetfilter_conntrack/usr/lib

libnetfilter_conntrack-clean:
	+$(MAKE) -C $(LIBNETFILTER_CONNTRACK_DIR) KERNEL_DIR=$(LINUXDIR) clean

libnetfilter_queue: libmnl libnfnetlink
	[ -f $(LIBNETFILTER_QUEUE_DIR)/Makefile ] || \
	(cd $(LIBNETFILTER_QUEUE_DIR); \
	 CC=$(CC) ./configure \
	    --target=$(PLATFORM)-linux \
	    --host=$(PLATFORM)-linux \
	    --build=`/bin/arch`-linux \
	    --with-kernel=$(LINUXDIR) \
	    --prefix=$(LIBNETFILTER_QUEUE_DIR)/install \
        LIBNFNETLINK_CFLAGS=$(NFNETLINK_CFLAGS) LIBNFNETLINK_LIBS=$(NFNETLINK_LIBS) \
        LIBMNL_CFLAGS=$(MNL_CFLAGS) LIBMNL_LIBS=$(MNL_LIBS))
	+$(MAKE) -C $(LIBNETFILTER_QUEUE_DIR)
	+$(MAKE) -C $(LIBNETFILTER_QUEUE_DIR) install-strip

libnetfilter_queue-install:
	install -d $(INSTALLDIR)/libnetfilter_queue/usr/lib
	cp -rf $(LIBNETFILTER_QUEUE_DIR)/install/lib/* $(INSTALLDIR)/libnetfilter_queue/usr/lib

libnetfilter_queue-clean:
	+$(MAKE) -C $(LIBNETFILTER_QUEUE_DIR) KERNEL_DIR=$(LINUXDIR) clean

LIBFLOW_DIR := $(BASEDIR)/components/shared/libflow

libflow: libnetfilter_conntrack
	$(MAKE) -C $(LIBFLOW_DIR) LIBMNL_CFLAGS=$(MNL_CFLAGS) LIBMNL_LIBS=$(MNL_LIBS) LIBNFNETLINK_CFLAGS=$(NFNETLINK_CFLAGS) LIBNFNETLINK_LIBS=$(NFNETLINK_LIBS) LIBNETFILTER_CONNTRACK_CFLAGS=$(NETFILTER_CONNTRACK_CFLAGS) LIBNETFILTER_CONNTRACK_LIBS=$(NETFILTER_CONNTRACK_LIBS)

libflow-install:
	install -d $(INSTALLDIR)/libflow/usr/lib
	install -D $(LIBFLOW_DIR)/libflow.so $(INSTALLDIR)/libflow/usr/lib
	$(STRIP) $(INSTALLDIR)/libflow/usr/lib/libflow.so

libflow-clean:
	$(MAKE) -C $(LIBFLOW_DIR) clean

ifeq ($(CONFIG_LIBNFNETLINK),y)
# iptables will try to link with netfilter's libs if enabled.
IPTABLES_DEPS := libnfnetlink
endif

ifeq ($(CONFIG_IPV6),y)
DOIPV6=1
else
DOIPV6=0
endif

ifeq (2_6_36,$(LINUX_VERSION))
iptables:
	$(MAKE) -C iptables-1.4.12 BINDIR=/usr/sbin LIBDIR=/usr/lib \
	    KERNEL_DIR=$(LINUXDIR) DO_IPV6=1
iptables-install:
ifeq ($(CONFIG_IPTABLES),y)
	install -d $(INSTALLDIR)/iptables/usr/lib/iptables
	install iptables-1.4.12/src/extensions/*.so $(INSTALLDIR)/iptables/usr/lib/iptables
	$(STRIP) $(INSTALLDIR)/iptables/usr/lib/iptables/*.so
	cp -rf iptables-1.4.12/src/install/sbin $(INSTALLDIR)/iptables/usr/sbin
	install -d $(INSTALLDIR)/iptables/usr/lib
	cp -f iptables-1.4.12/src/install/lib/libip* $(INSTALLDIR)/iptables/usr/lib
else
	# So that generic rule does not take precedence
	@true
endif
iptables-clean:
	-$(MAKE) -C iptables-1.4.12 KERNEL_DIR=$(LINUXDIR) DO_IPV6=1 clean

else ifeq (2_6,$(LINUX_VERSION))
iptables:
	$(MAKE) -C iptables-1.x BINDIR=/usr/sbin LIBDIR=/usr/lib KERNEL_DIR=$(LINUXDIR)

iptables-install:
ifeq ($(CONFIG_IPTABLES),y)
	install -d $(INSTALLDIR)/iptables/usr/lib/iptables
	install iptables-1.x/extensions/*.so $(INSTALLDIR)/iptables/usr/lib/iptables
	$(STRIP) $(INSTALLDIR)/iptables/usr/lib/iptables/*.so
	install -D iptables-1.x/iptables $(INSTALLDIR)/iptables/usr/sbin/iptables
	$(STRIP) $(INSTALLDIR)/iptables/usr/sbin/iptables
else
        # So that generic rule does not take precedence
	@true
endif
iptables-clean:
	-$(MAKE) -C iptables-1.x KERNEL_DIR=$(LINUXDIR) clean
else # linux-2.6
iptables:
	$(MAKE) -C iptables BINDIR=/usr/sbin LIBDIR=/usr/lib KERNEL_DIR=$(LINUXDIR)

iptables-install:
ifeq ($(CONFIG_IPTABLES),y)
	install -d $(INSTALLDIR)/iptables/usr/lib/iptables
	install iptables/extensions/*.so $(INSTALLDIR)/iptables/usr/lib/iptables
	$(STRIP) $(INSTALLDIR)/iptables/usr/lib/iptables/*.so
	install -D iptables/iptables $(INSTALLDIR)/iptables/usr/sbin/iptables
	$(STRIP) $(INSTALLDIR)/iptables/usr/sbin/iptables
else
	# So that generic rule does not take precedence
	@true
endif
iptables-clean:
	-$(MAKE) -C iptables KERNEL_DIR=$(LINUXDIR) clean
endif # linux-2.6


netconf: iptables
ifeq ($(CONFIG_NETCONF),y)
	make LINUXDIR=$(LINUXDIR) -C netconf
else
	# In case of "Prerequisite 'iptables' is newer than target 'netconf'"
	@true
endif

ntpclient-install:
	install -D ntpclient/ntpclient $(INSTALLDIR)/ntpclient/usr/sbin/ntpclient
	$(STRIP) $(INSTALLDIR)/ntpclient/usr/sbin/ntpclient

ppp ppp-%:
	$(MAKE) -C ppp/pppoecd $* INSTALLDIR=$(INSTALLDIR)/ppp

udhcpd-install:
	install -D udhcpd/udhcpd $(INSTALLDIR)/udhcpd/usr/sbin/udhcpd
	$(STRIP) $(INSTALLDIR)/udhcpd/usr/sbin/udhcpd
	cd $(INSTALLDIR)/udhcpd/usr/sbin && ln -sf udhcpd udhcpc

upnp: netconf nvram shared

bcmupnp: netconf nvram shared
	[ ! -f bcmupnp/Makefile ] || $(MAKE) -C bcmupnp

bcmupnp-install:
	[ ! -f bcmupnp/Makefile ] || $(MAKE) -C bcmupnp install INSTALLDIR=$(INSTALLDIR)/bcmupnp

bcmupnp-clean:
	[ ! -f bcmupnp/Makefile ] || $(MAKE) -C bcmupnp clean

wlconf: nvram shared

vlan:
	$(MAKE) -C vlan CROSS=$(CROSS_COMPILE) STRIPTOOL=$(STRIP)

vlan-install:
	$(MAKE) -C vlan CROSS=$(CROSS_COMPILE) STRIPTOOL=$(STRIP) INSTALLDIR=$(INSTALLDIR) install

vlan-clean:
	$(MAKE) -C vlan clean

emf:
	$(MAKE) -C emf/emfconf CROSS=$(CROSS_COMPILE)

emf-install:
ifeq ($(CONFIG_EMF),y)
	install -d $(TARGETDIR)
	$(MAKE) -C emf/emfconf CROSS=$(CROSS_COMPILE) INSTALLDIR=$(INSTALLDIR) install
endif

emf-clean:
	#$(MAKE) -C emf/emfconf clean

igs:
	$(MAKE) -C emf/igsconf CROSS=$(CROSS_COMPILE)

igs-install:
ifeq ($(CONFIG_EMF),y)
	install -d $(TARGETDIR)
	$(MAKE) -C emf/igsconf CROSS=$(CROSS_COMPILE) INSTALLDIR=$(INSTALLDIR) install
endif

igs-clean:
	#$(MAKE) -C emf/igsconf clean

igmp:
	$(MAKE) -C igmp CROSS=$(CROSS_COMPILE)

igmp-install:
ifeq ($(CONFIG_IGMP_PROXY),y)
	install -d $(TARGETDIR)
	$(MAKE) -C igmp CROSS=$(CROSS_COMPILE) INSTALLDIR=$(INSTALLDIR) install
endif

igmp-clean:
	$(MAKE) -C igmp clean

wps: nvram shared
ifneq ($(PROFILE),)
	[ ! -f wps/Makefile ] || $(MAKE) -C wps EXTRA_LDFLAGS=$(EXTRA_LDFLAGS)
else
	# Prevent to use generic rules"
	@true
endif

wps-install:
ifneq ($(PROFILE),)
	[ ! -f wps/Makefile ] || $(MAKE) -C wps install INSTALLDIR=$(INSTALLDIR) EXTRA_LDFLAGS=$(EXTRA_LDFLAGS)
else
	# Prevent to use generic rules"
	@true
endif

wps-clean:
ifeq ($(PROFILE),)
	[ ! -f wps/Makefile ] || $(MAKE) -C wps clean
else
	# Prevent to use generic rules"
	@true
endif
# NFC
nfc:
ifneq (,$(and $(filter y,$(CONFIG_NFC)),$(wildcard nfc/Makefile)))
	+$(MAKE) -C nfc EXTRA_LDFLAGS=$(EXTRA_LDFLAGS)
else
	# Prevent to use generic rules"
	@true
endif

nfc-install:
ifeq ($(CONFIG_NFC),y)
	+$(if $(wildcard nfc/Makefile), \
	    $(MAKE) -C nfc INSTALLDIR=$(INSTALLDIR) EXTRA_LDFLAGS=$(EXTRA_LDFLAGS) install \
	   , \
	    @true \
	  )
else
	# Prevent to use generic rules"
	@true
endif

nfc-clean:
ifeq ($(CONFIG_NFC),y)
	[ ! -f nfc/Makefile ] || $(MAKE) -C nfc clean
else
	# Prevent to use generic rules"
	@true
endif


acos_link:
	cp $(LINUXDIR)/.config_$(PROFILE) $(LINUXDIR)/.config
	cp ./prebuilt/target ./arm-uclibc/ -rf

acos:

acos-install:

acos-clean:

gpl:
	$(MAKE) -C ../../ap/gpl CROSS=$(CROSS_COMPILE) STRIPTOOL=$(STRIP)

gpl-install:
	$(MAKE) -C ../../ap/gpl CROSS=$(CROSS_COMPILE) STRIPTOOL=$(STRIP) INSTALLDIR=$(INSTALLDIR) install

gpl-clean:
	$(MAKE) -C ../../ap/gpl clean

#Leon Lv Add below for UBD,Apr 15,2008
.PHONY:ubd opendns
ubd:
	$(MAKE) -C ubd CROSS=$(CROSS_COMPILE)

ubd-install:
ifeq ($(CONFIG_UBD),y)
	install -d $(TARGETDIR)
#	$(MAKE) -C ubd CROSS=$(CROSS_COMPILE) INSTALLDIR=$(INSTALLDIR) install
	install -D ubd/ubd $(INSTALLDIR)/ubdu/usr/sbin/ubd
	$(STRIP) $(INSTALLDIR)/ubdu/usr/sbin/ubd
endif

ubd-clean:
	$(MAKE) -C ubd clean

opendns:
	$(MAKE) -C ../../ap/acos/opendns

opendns-install:
	$(MAKE) -C ../../ap/acos/opendns install

opendns-clean:
	$(MAKE) -C ../../ap/acos/opendns clean

acos_nat:

acos_nat-install:

acos_nat-clean:

ifeq ($(LINUXDIR), $(BASEDIR)/components/opensource/linux/linux-2.6.36)
udev:
	$(MAKE) -C udev CROSS_COMPILE=$(CROSS_COMPILE)

udev-install:
	install -d $(TARGETDIR)
	$(MAKE) -C udev CROSS_COMPILE=$(CROSS_COMPILE) DESTDIR=$(INSTALLDIR) prefix=/udev install-udevtrigger

udev-clean:
	$(MAKE) -C udev clean

hotplug2:
	$(MAKE) -C hotplug2 CROSS_COMPILE=$(CROSS_COMPILE)

hotplug2-install:
	install -d $(TARGETDIR)
	install -d $(INSTALLDIR)/hotplug2
	$(MAKE) -C hotplug2 CROSS_COMPILE=$(CROSS_COMPILE) PREFIX=$(INSTALLDIR) install

hotplug2-clean:
	$(MAKE) -C hotplug2 clean
endif

ifeq ($(LINUX_VERSION),2_4)
UCLIBC_IPV6=../lib/mipsel-uclibc/libc.so.0
endif

radvd: flex dummy
	[ ! -d ../../ap/gpl/$@ ] || [ -f ../../ap/gpl/$@/Makefile ] || ( cd ../../ap/gpl/$@ && CC=$(CC) ./configure --host=arm-linux && cd .. )
	[ ! -d ../../ap/gpl/$@ ] || $(MAKE) -C ../../ap/gpl/radvd CC=$(CC) radvd_LDADD="-L../../../src/router/flex -lfl"

radvd-install:
	[ ! -d radvd ] || install -D -m 755 ../../ap/gpl/radvd/radvd $(INSTALLDIR)/radvd/usr/sbin/radvd
	[ ! -d radvd ] || $(STRIP) $(INSTALLDIR)/radvd/usr/sbin/radvd

radvd-clean:
	[ ! -f radvd/Makefile ] || $(MAKE) -C radvd distclean

flex: dummy
	[ ! -d $@ ] || [ -f $@/Makefile ] || ( cd $@ && CC=$(CC) ./configure --host=$(PLT)-linux && cd .. )
	[ ! -d $@ ] || $(MAKE) -C flex CC=$(CC) RANLIB=$(RANLIB)

iproute2:
	[ ! -d $@ ] || $(MAKE) -C iproute2 KERNEL_INCLUDE=$(LINUXDIR)/include CC=$(CC) AR=$(AR) LDLIBS=

iproute2-install:
	[ ! -d iproute2 ] || install -D -m 755 iproute2/ip/ip $(INSTALLDIR)/iproute2/usr/sbin/ip
	[ ! -d iproute2 ] || $(STRIP) $(INSTALLDIR)/iproute2/usr/sbin/ip

iputils:
	[ ! -d $@ ] || [ -f $@/include-glibc/bits/socket.h ] || ( cd $@/include-glibc/bits && ln -s ../socketbits.h socket.h && cd ../../.. )
	[ ! -d $@ ] || $(MAKE) -C iputils KERNEL_INCLUDE=$(LINUXDIR)/include CC=$(CC) LDLIBS=

iputils-install:
	[ ! -d iputils ] || install -D -m 755 iputils/ping6 $(INSTALLDIR)/iputils/usr/sbin/ping6
	[ ! -d iputils ] || $(STRIP) $(INSTALLDIR)/iputils/usr/sbin/ping6
	[ ! -d iputils ] || install -D -m 755 iputils/traceroute6 $(INSTALLDIR)/iputils/usr/sbin/traceroute6
	[ ! -d iputils ] || $(STRIP) $(INSTALLDIR)/iputils/usr/sbin/traceroute6
	[ ! -d iputils ] || install -D -m 755 iputils/tracepath6 $(INSTALLDIR)/iputils/usr/sbin/tracepath6
	[ ! -d iputils ] || $(STRIP) $(INSTALLDIR)/iputils/usr/sbin/tracepath6

dhcp6s dhcp6c: dummy
	[ ! -d dhcp6 ] || [ -f dhcp6/Makefile ] || ( cd dhcp6 && ./configure CC=gcc CFLAGS+="-I../shared" && cd .. )
ifeq ($(CONFIG_UCLIBC),y)
#	[ ! -d dhcp6 ] || $(MAKE) -C dhcp6 CC=$(CC) LIBS="$(UCLIBC_IPV6)" $@
	[ ! -d dhcp6 ] || $(MAKE) -C dhcp6 CC=$(CC) LIBS="-L lib" $@
else
	[ ! -d dhcp6 ] || $(MAKE) -C dhcp6 CC=$(CC) LIBS="-lresolv -L../libbcmcrypto -lbcmcrypto -L$(INSTALLDIR)/libbcmcrypto/usr/lib" $@
endif

dhcp6s-install:
	[ ! -d dhcp6 ] || install -D -m 755 dhcp6/dhcp6s $(INSTALLDIR)/dhcp6s/usr/sbin/dhcp6s
	[ ! -d dhcp6 ] || $(STRIP) $(INSTALLDIR)/dhcp6s/usr/sbin/dhcp6s

dhcp6c-install:
	[ ! -d dhcp6 ] || install -D -m 755 dhcp6/dhcp6c $(INSTALLDIR)/dhcp6c/usr/sbin/dhcp6c
	[ ! -d dhcp6 ] || $(STRIP) $(INSTALLDIR)/dhcp6c/usr/sbin/dhcp6c

dhcp6s-clean dhcp6c-clean:
	[ ! -f dhcp6/Makefile ] || $(MAKE) -C dhcp6 distclean

swresetd-install:
swresetd-clean:
acl_log-install:
acl_log-clean:
gpio-install:
gpio-clean:
#
# Generic rules
#

%:
	[ ! -d $* ] || $(MAKE) -C $*

%-clean:
	[ ! -d $* ] || $(MAKE) -C $* clean

%-install:
	[ ! -d $* ] || $(MAKE) -C $* install INSTALLDIR=$(INSTALLDIR)/$*

$(obj-y) $(obj-n) $(obj-clean) $(obj-install): dummy


.PHONY: all clean distclean mrproper install package
.PHONY: conf mconf oldconf kconf kmconf config menuconfig oldconfig
.PHONY: dummy
.PHONY: norton norton-install norton-clean
.PHONY: libstdcpp libstdcpp-install
.PHONY: libmnl libmnl-install libmnl-clean
.PHONY: libnfnetlink libnfnetlink-install libnfnetlink-clean
.PHONY: libnetfilter_conntrack libnetfilter_conntrack-install libnetfilter_conntrack-clean
.PHONY: libnetfilter_queue libnetfilter_queue-install libnetfilter_queue-clean
.PHONY: libflow libflow-install libflow-clean
