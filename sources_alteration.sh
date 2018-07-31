#######################  sources_alteration.sh #################################
#!/bin/bash
#
# Copyright 2018  J. E. Garrott Sr, Puyallup, WA, USA
# Copyright 2018  "nobodino", Bordeaux, FRANCE
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#--------------------------------------------------------------------------
#
#	Revision	0				10022017		nobodino
#		-split the alteration of slackware sources from sfsinit.sh
#		-remove execute_doxygen
#	Revision 1				22042017		nobodino
#		-added patch to build strigi
#		-added patch to build php
#		-added patch to build k3b
#	Revision 2				27042017		nobodino
#		-updated to current 26042017
#		-disabled dmapi patch for current
#	Revision 3				27052017		nobodino
#		-updated to current 26052017 : glibc-2.25, gcc-7.1.0
#		-added diffutils patch for current
#		-added linuxdoc-tools patch for current
#		-added fontconfig patch for current
#		-added aspell patch for current
#		-added oprofile patch for current
#		-added librevenge patch for current
#		-added gnu-efi patch for current
#		-added js185 patch for current
#		-modified execute_llvm in execute_llvm_14_2 and execute_llvm_c
#		-added audiofile patch for current
#		-added scim patch for current
#		-added scim-anthy patch for current
#		-added htdig patch for current
#		-added clisp patch for current
#		-added rp-pppoe patch for current
#		-added crda patch for current
#	Revision 4				09062017		nobodino
#		-added kate patch for current
#		-added smokeqt patch  for current
#		-added ktorrent patch for current
#		-modified execute_pykde4 for current
#	Revision 5				15062017		nobodino
#		-added glade3 patch for current
#		-removed linuxdoc-tools patch for current
#		-added mariadb patch for current (x86_64)
#		-added herqq patch for current (x86_64)
#		-added readline patch for current
#		-removed diffutils patch
#		-fixed fontconfig
#		-fixed pykde4
#
###########################################################################
# set -x

#*******************************************************************
# sub-system of execution of patches
#*******************************************************************

execute_net_tools () {
#******************************************************************
if [ ! -f $SRCDIR/n/net-tools/net-tools.SlackBuild.old ]; then
	cp -v $SRCDIR/n/net-tools/net-tools.SlackBuild \
		$SRCDIR/n/net-tools/net-tools.SlackBuild.old
	cp -v $PATCHDIR/net-tools-includes.patch.gz $SRCDIR/n/net-tools
	(
		cd $SRCDIR/n/net-tools
		zcat $PATCHDIR/net-toolsSB.patch.gz |patch net-tools.SlackBuild --verbose
	)
fi
}

execute_lcms () {
#******************************************************************
 if [ ! -f $SRCDIR/l/lcms/lcms-1.19-cve_2013_4276-1.patch.gz ]; then
	cp -v $SRCDIR/l/lcms/lcms.SlackBuild \
		$SRCDIR/l/lcms/lcms.SlackBuild.old
	cp -v $PATCHDIR/lcms-1.19-cve_2013_4276-1.patch.gz $SRCDIR/l/lcms
	(
		cd $SRCDIR/l/lcms
		zcat $PATCHDIR/lcmsSB.patch.gz |patch lcms.SlackBuild --verbose
	)
fi
}

execute_rcs () {
#******************************************************************
 if [ ! -f $SRCDIR/d/rcs/upstream-260704a916.diff.gz ]; then
	cp -v $SRCDIR/d/rcs/rcs.SlackBuild \
		$SRCDIR/d/rcs/rcs.SlackBuild.old
	cp -v $PATCHDIR/upstream-260704a916.diff.gz $SRCDIR/d/rcs
	(
		cd $SRCDIR/d/rcs
		zcat $PATCHDIR/rcsSB.patch.gz |patch rcs.SlackBuild --verbose
	)
fi
}

execute_dbus () {
#******************************************************************
if [ ! -f $SRCDIR/a/dbus/dbus.SlackBuild.old ]; then
	cp -v $SRCDIR/a/dbus/dbus.SlackBuild $SRCDIR/a/dbus/dbus.SlackBuild.old
	(
		cd $SRCDIR/a/dbus
		zcat $PATCHDIR/dbusSB.patch.gz |patch dbus.SlackBuild --verbose
	)
fi
}

execute_dbus_d () {
#******************************************************************
if [ ! -f $SRCDIR/dlackware/dbus/dbus.SlackBuild.old ]; then
	cp -v $SRCDIR/dlackware/dbus/dbus.SlackBuild $SRCDIR/dlackware/dbus/dbus.SlackBuild.old
	(
		cd $SRCDIR/dlackware/dbus
		zcat $PATCHDIR/dbus-dSB.patch.gz |patch dbus.SlackBuild --verbose
	)
fi
}

execute_gst_plugins_base0 () {
#******************************************************************
if [ ! -f $SRCDIR/l/gst-plugins-base0/gst-plugins-base-0.10.36-gcc_4_9_0_i686-1.patch.gz ]; then
	cp -v $SRCDIR/l/gst-plugins-base0/gst-plugins-base0.SlackBuild \
		$SRCDIR/l/gst-plugins-base0/gst-plugins-base0.SlackBuild.old
	cp -v $PATCHDIR/gst-plugins-base-0.10.36-gcc_4_9_0_i686-1.patch.gz $SRCDIR/l/gst-plugins-base0
	(
		cd $SRCDIR/l/gst-plugins-base0
		zcat $PATCHDIR/gst-plugins-base0SB.patch.gz |patch -Esp0 gst-plugins-base0.SlackBuild  --verbose
	)
fi
}

execute_gstreamer0 () {
#******************************************************************
if [ ! -f $SRCDIR/l/gstreamer0/gstreamer0.SlackBuild.old ]; then
	cp -v $SRCDIR/l/gstreamer0/gstreamer0.SlackBuild $SRCDIR/l/gstreamer0/gstreamer0.SlackBuild.old
	(
		cd $SRCDIR/l/gstreamer0
		zcat $PATCHDIR/gstreamer0SB.patch.gz |patch gstreamer0.SlackBuild  --verbose
	)
fi
}

execute_glib () {
#******************************************************************
if [ ! -f $SRCDIR/l/glib/glib.SlackBuild.old ]; then
	cp -v $SRCDIR/l/glib/glib.SlackBuild $SRCDIR/l/glib/glib.SlackBuild.old
	(
		cd $SRCDIR/l/glib
		zcat $PATCHDIR/glibSB.patch.gz |patch glib.SlackBuild --verbose
	)
fi
}

execute_subversion () {
#******************************************************************
if [ ! -f $SRCDIR/d/subversion/subversion.SlackBuild.old ]; then
	cp -v $SRCDIR/d/subversion/subversion.SlackBuild \
		$SRCDIR/d/subversion/subversion.SlackBuild.old
	(
		cd $SRCDIR/d/subversion
		zcat $PATCHDIR/subversionSB.patch.gz |patch subversion.SlackBuild --verbose
	)
fi
}

execute_llvm_14_2 () {
#******************************************************************
if [ ! -f $SRCDIR/d/llvm/llvm.SlackBuild.old ]; then
	cp -v $SRCDIR/d/llvm/llvm.SlackBuild $SRCDIR/d/llvm/llvm.SlackBuild.old
	(
		cd $SRCDIR/d/llvm
		zcat $PATCHDIR/llvmSB.patch.gz |patch llvm.SlackBuild --verbose
	)
fi
}

execute_llvm_c () {
#******************************************************************
if [ ! -f $SRCDIR/d/llvm/llvm.SlackBuild.old ]; then
	cp -v $SRCDIR/d/llvm/llvm.SlackBuild $SRCDIR/d/llvm/llvm.SlackBuild.old
	cp -v $PATCHDIR/lldb-gcc7.patch.gz $SRCDIR/d/llvm
	(
		cd $SRCDIR/d/llvm
		zcat $PATCHDIR/llvmSB.patch.gz |patch llvm.SlackBuild --verbose
		zcat $PATCHDIR/llvmSB2.patch.gz |patch llvm.SlackBuild.old --verbose
	)
fi
}

execute_cmake () {
#******************************************************************
if [ ! -f $SRCDIR/d/cmake/cmake.SlackBuild.old ]; then
	cp -v $SRCDIR/d/cmake/cmake.SlackBuild $SRCDIR/d/cmake/cmake.SlackBuild.old
	(
		cd $SRCDIR/d/cmake
		zcat $PATCHDIR/cmakeSB.patch.gz |patch cmake.SlackBuild  --verbose
	)
fi
}

execute_gcc () {
#******************************************************************
if [ ! -f $SRCDIR/d/gcc/gcc.SlackBuild.old ]; then
	cp -v $SRCDIR/d/gcc/gcc.SlackBuild $SRCDIR/d/gcc/gcc.SlackBuild.old
	(
		cd $SRCDIR/d/gcc
		zcat $PATCHDIR/gccSB.patch.gz |patch gcc.SlackBuild  --verbose
	)
fi
}


execute_libcap () {
#******************************************************************
if [ ! -f $SRCDIR/l/libcap/libcap.SlackBuild.old ]; then
	cp -v $SRCDIR/l/libcap/libcap.SlackBuild \
		$SRCDIR/l/libcap/libcap.SlackBuild.old
	(
		cd $SRCDIR/l/libcap
		zcat $PATCHDIR/libcapSB.patch.gz |patch libcap.SlackBuild  --verbose
	)
fi
}

execute_libusb () {
#******************************************************************
if [ ! -f $SRCDIR/l/libusb/libusb.SlackBuild.old ]; then
	cp -v $SRCDIR/l/libusb/libusb.SlackBuild \
		$SRCDIR/l/libusb/libusb.SlackBuild.old
	(
		cd $SRCDIR/l/libusb
		zcat $PATCHDIR/libusbSB.patch.gz |patch libusb.SlackBuild  --verbose
	)
fi
}

execute_pkg_config () {
#******************************************************************
if [ ! -f $SRCDIR/d/pkg-config/pkg-config.SlackBuild.old ]; then
	cp -v $SRCDIR/d/pkg-config/pkg-config.SlackBuild \
		$SRCDIR/d/pkg-config/pkg-config.SlackBuild.old
	(
		cd $SRCDIR/d/pkg-config
		zcat $PATCHDIR/pkg-configSB.patch.gz |patch pkg-config.SlackBuild --verbose
	)
fi
}

execute_svgalib () {
#******************************************************************
if [ ! -f $SRCDIR/l/svgalib/svgalib.SlackBuild.old ]; then
	cp -v $SRCDIR/l/svgalib/svgalib.SlackBuild \
		$SRCDIR/l/svgalib/svgalib.SlackBuild.old
	cp -v $PATCHDIR/svga-quickmath.patch.gz $SRCDIR/l/svgalib
	(
		cd $SRCDIR/l/svgalib
		zcat $PATCHDIR/svgalibSB.patch.gz |patch svgalib.SlackBuild --verbose
	)
fi
}

execute_dmapi () {
#******************************************************************
if [ ! -f $SRCDIR/ap/dmapi/dmapi.SlackBuild.old ]; then
	cp -v $SRCDIR/ap/dmapi/dmapi.SlackBuild $SRCDIR/ap/dmapi/dmapi.SlackBuild.old
	cp -v $PATCHDIR/bug799162.patch.gz $SRCDIR/ap/dmapi
	(
		cd $SRCDIR/ap/dmapi
		zcat $PATCHDIR/dmapiSB.patch.gz |patch dmapi.SlackBuild --verbose
	)
fi
}

execute_libva_intel_driver () {
#******************************************************************
if [ ! -f $SRCDIR/x/libva-intel-driver/libva-intel-driver.SlackBuild.old ]; then
	cp -v $SRCDIR/x/libva-intel-driver/libva-intel-driver.SlackBuild \
	$SRCDIR/x/libva-intel-driver/libva-intel-driver.SlackBuild.old
	(
		cd $SRCDIR/x/libva-intel-driver
		zcat $PATCHDIR/libva-intel-driverSB.patch.gz |patch libva-intel-driver.SlackBuild --verbose
	)
fi
}

execute_x11_14_2 () {
#******************************************************************
if [ ! -f $SRCDIR/x/x11/x11.SlackBuild.old ]; then
	mkdir -p $SRCDIR/x/x11/patch/sessreg
	cp -v $PATCHDIR/sessreg.patch.gz $SRCDIR/x/x11/patch/sessreg
	cp -v $PATCHDIR/sessreg.patch $SRCDIR/x/x11/patch
fi

grep aiptek $SRCDIR/x/x11/package-blacklist 2>&1 >/dev/null
if [ $? != 0 ]; then
	echo "# My blacklists" >>$SRCDIR/x/x11/package-blacklist
	echo "xf86-input-aiptek" >>$SRCDIR/x/x11/package-blacklist
fi
}

execute_x11_c () {
#******************************************************************
if [ ! -f $SRCDIR/x/x11/x11.SlackBuild.old ]; then
	mkdir -p $SRCDIR/x/x11/patch/sessreg
	cp -v $PATCHDIR/sessreg.patch.gz $SRCDIR/x/x11/patch/sessreg
	cp -v $PATCHDIR/sessreg.patch $SRCDIR/x/x11/patch
fi

}

execute_tetex () {
#******************************************************************
if [ ! -f $SRCDIR/tetex/tetex/jadetex.build.old ]; then
	cp -v $SRCDIR/t/tetex/jadetex.build $SRCDIR/t/tetex/jadetex.build.old
	(
		cd $SRCDIR/t/tetex
		zcat $PATCHDIR/jadetexSB.patch.gz |patch jadetex.build --verbose
	)
fi
}

execute_tix () {
#******************************************************************
if [ ! -f $SRCDIR/tcl/tix/tix.SlackBuild.old ]; then
	cp -v $SRCDIR/tcl/tix/tix.SlackBuild $SRCDIR/tcl/tix/tix.SlackBuild.old
	cp -v $PATCHDIR/tix-headers.patch.gz $SRCDIR/tcl/tix
	(
		cd $SRCDIR/tcl/tix
		zcat $PATCHDIR/tixSB.patch.gz |patch tix.SlackBuild --verbose
	)
fi
}

execute_nasm () {
#******************************************************************
if [ ! -f $SRCDIR/d/nasm/nasm.SlackBuild.old ]; then
	cp -v $SRCDIR/d/nasm/nasm.SlackBuild $SRCDIR/d/nasm/nasm.SlackBuild.old
	(
		cd $SRCDIR/d/nasm
		zcat $PATCHDIR/nasmSB.patch.gz |patch nasm.SlackBuild --verbose
	)
fi
}

execute_kmod () {
#******************************************************************
if [ ! -f $SRCDIR/a/kmod/kmod.SlackBuild.old ]; then
	cp -v $SRCDIR/a/kmod/kmod.SlackBuild $SRCDIR/a/kmod/kmod.SlackBuild.old
	(
		cd $SRCDIR/a/kmod
		zcat $PATCHDIR/kmodSB.patch.gz |patch kmod.SlackBuild --verbose
	)
fi
}

execute_ksh93 () {
#******************************************************************
if [ ! -f $SRCDIR/ap/ksh93/ksh93.SlackBuild.old ]; then
	cp -v $SRCDIR/ap/ksh93/ksh93.SlackBuild $SRCDIR/ap/ksh93/ksh93.SlackBuild.old
	(
		cd $SRCDIR/ap/ksh93
		zcat $PATCHDIR/ksh93SB.patch.gz |patch ksh93.SlackBuild --verbose
	)
fi
}

execute_libcaca () {
#******************************************************************
if [ ! -f $SRCDIR/l/libcaca/libcaca.SlackBuild.old ]; then
	cp -v $SRCDIR/l/libcaca/libcaca.SlackBuild $SRCDIR/l/libcaca/libcaca.SlackBuild.old
	(
		cd $SRCDIR/l/libcaca
		zcat $PATCHDIR/libcacaSB.patch.gz |patch libcaca.SlackBuild --verbose
	)
fi
}

execute_libmad () {
#******************************************************************
if [ ! -f $SRCDIR/l/libmad/libmad.SlackBuild.old ]; then
	cp -v $SRCDIR/l/libmad/libmad.SlackBuild $SRCDIR/l/libmad/libmad.SlackBuild.old
	cp -v $PATCHDIR/libmad-0.15.1b-fixes-1.patch.gz $SRCDIR/l/libmad
	(
		cd $SRCDIR/l/libmad
		zcat $PATCHDIR/libmadSB.patch.gz |patch libmad.SlackBuild --verbose
	)
fi
}

execute_newspost () {
#******************************************************************
if [ ! -f $SRCDIR/n/newspost/newspost.SlackBuild.old ]; then
	cp -v $SRCDIR/n/newspost/newspost.SlackBuild $SRCDIR/n/newspost/newspost.SlackBuild.old
#	cp -v $PATCHDIR/newspost.new.patch.gz $SRCDIR/n/newspost
	(
		cd $SRCDIR/n/newspost
		zcat $PATCHDIR/newspostSB.patch.gz |patch newspost.SlackBuild --verbose
	)
fi
}

execute_procmail () {
#******************************************************************
if [ ! -f $SRCDIR/n/procmail/procmail.SlackBuild.old ]; then
	cp -v $SRCDIR/n/procmail/procmail.SlackBuild $SRCDIR/n/procmail/procmail.SlackBuild.old
#	cp -v $PATCHDIR/procmail.new.patch.gz $SRCDIR/n/procmail
	(
		cd $SRCDIR/n/procmail
		zcat $PATCHDIR/procmailSB.patch.gz |patch procmail.SlackBuild --verbose
	)
fi
}

execute_seyon () {
#******************************************************************
if [ ! -f $SRCDIR/xap/seyon/seyon.SlackBuild.old ]; then
	cp -v $SRCDIR/xap/seyon/seyon.SlackBuild $SRCDIR/xap/seyon/seyon.SlackBuild.old
#	cp -v $PATCHDIR/seyon.new.patch.gz $SRCDIR/xap/seyon
	(
		cd $SRCDIR/xap/seyon
		zcat $PATCHDIR/seyonSB.patch.gz |patch seyon.SlackBuild --verbose
	)
fi
}

execute_clisp_14_2 () {
#******************************************************************
if [ ! -f $SRCDIR/d/clisp/clisp.SlackBuild.old ]; then
	cp -v $SRCDIR/d/clisp/clisp.SlackBuild $SRCDIR/d/clisp/clisp.SlackBuild.old
	cp -v $PATCHDIR/clisp-gcc5.patch.gz $SRCDIR/d/clisp
	(
		cd $SRCDIR/d/clisp
		zcat $PATCHDIR/clispSB.patch.gz |patch clisp.SlackBuild --verbose
	)
fi
}

execute_clisp_c () {
#******************************************************************
if [ ! -f $SRCDIR/d/clisp/clisp.SlackBuild.old ]; then
	cp -v $SRCDIR/d/clisp/clisp.SlackBuild $SRCDIR/d/clisp/clisp.SlackBuild.old
	(
		cd $SRCDIR/d/clisp
		zcat $PATCHDIR/clispSB.patch.gz |patch clisp.SlackBuild --verbose
	)
fi
}

execute_taglib_extras () {
#******************************************************************
if [ ! -f $SRCDIR/l/taglib-extras/taglib-extras.SlackBuild.old ]; then
	cp -v $SRCDIR/l/taglib-extras/taglib-extras.SlackBuild $SRCDIR/l/taglib-extras/taglib-extras.SlackBuild.old
	cp -v $PATCHDIR/taglib-1.10.patch.gz $SRCDIR/l/taglib-extras
	(
		cd $SRCDIR/l/taglib-extras
		zcat $PATCHDIR/taglib-extrasSB.patch.gz |patch taglib-extras.SlackBuild --verbose
	)
fi
}

execute_esound () {
#******************************************************************
if [ ! -f $SRCDIR/l/esound/esound.SlackBuild.old ]; then
	cp -v $SRCDIR/l/esound/esound.SlackBuild $SRCDIR/l/esound/esound.SlackBuild.old
	cp -v $PATCHDIR/01_relocate_libesddsp.patch.gz $SRCDIR/l/esound
	cp -v $PATCHDIR/02_missing_var.patch.gz $SRCDIR/l/esound
	cp -v $PATCHDIR/03_hurd.patch.gz $SRCDIR/l/esound
	cp -v $PATCHDIR/04_audsp_crash.patch.gz $SRCDIR/l/esound
	cp -v $PATCHDIR/05_libm.patch.gz $SRCDIR/l/esound
	(
		cd $SRCDIR/l/esound
		zcat $PATCHDIR/esoundSB.patch.gz |patch esound.SlackBuild --verbose
	)
fi
}

execute_libspectre () {
#******************************************************************
if [ ! -f $SRCDIR/l/libspectre/libspectre.SlackBuild.old ]; then
	cp -v $SRCDIR/l/libspectre/libspectre.SlackBuild $SRCDIR/l/libspectre/libspectre.SlackBuild.old
	cp -v $PATCHDIR/upstream_Fix-the-build-with-Ghostscript-9.18.patch.gz  $SRCDIR/l/libspectre
	(
		cd $SRCDIR/l/libspectre
		zcat $PATCHDIR/libspectreSB.patch.gz |patch libspectre.SlackBuild --verbose
	)
fi
}

execute_netkit_rwho_synth () {
#******************************************************************
if [ ! -f $SRCDIR/n/netkit-rwho/netkit-rwho.SlackBuild.old ]; then
	cp -v $SRCDIR/n/netkit-rwho/netkit-rwho.SlackBuild $SRCDIR/n/netkit-rwho/netkit-rwho.SlackBuild.old
	cp -v $PATCHDIR/netkit-rwho-synthetic.patch.gz $SRCDIR/n/netkit-rwho
	(
		cd $SRCDIR/n/netkit-rwho
		zcat $PATCHDIR/netkit-rwhoSB.patch.gz |patch netkit-rwho.SlackBuild --verbose
	)
fi
}

execute_a2ps () {
#******************************************************************
if [ ! -f $SRCDIR/ap/a2ps/a2ps.SlackBuild.old ]; then
	cp -v $SRCDIR/ap/a2ps/a2ps.SlackBuild $SRCDIR/ap/a2ps/a2ps.SlackBuild.old
	(
		cd $SRCDIR/ap/a2ps
		zcat $PATCHDIR/a2psSB.patch.gz |patch a2ps.SlackBuild --verbose
	)
fi
}

execute_qt_nowebkit () {
#******************************************************************
if [ ! -f $SRCDIR/l/qt/qt-nowebkit.SlackBuild.old ]; then
	cp -v $SRCDIR/l/qt/qt-nowebkit.SlackBuild $SRCDIR/l/qt/qt-nowebkit.SlackBuild.old
	(
		cd $SRCDIR/l/qt
		zcat $PATCHDIR/qt-nowebkitSB.patch.gz |patch qt-nowebkit.SlackBuild --verbose
	)
fi
}

execute_gv () {
#******************************************************************
if [ ! -f $SRCDIR/xap/gv/gv.SlackBuild.old ]; then
	cp -v $SRCDIR/xap/gv/gv.SlackBuild $SRCDIR/xap/gv/gv.SlackBuild.old
	(
		cd $SRCDIR/xap/gv
		zcat $PATCHDIR/gvSB.patch.gz |patch gv.SlackBuild --verbose
	)
fi
}

execute_sysklogd () {
#******************************************************************
if [ ! -f $SRCDIR/a/sysklogd/sysklogd.SlackBuild.old ]; then
	cp -v $SRCDIR/a/sysklogd/sysklogd.SlackBuild $SRCDIR/a/sysklogd/sysklogd.SlackBuild.old
	(
		cd $SRCDIR/a/sysklogd
		zcat $PATCHDIR/sysklogdSB.patch.gz |patch sysklogd.SlackBuild --verbose
	)
fi
}

execute_tcsh () {
#******************************************************************
if [ ! -f $SRCDIR/a/tcsh/tcsh.SlackBuild.old ]; then
	cp -v $SRCDIR/a/tcsh/tcsh.SlackBuild $SRCDIR/a/tcsh/tcsh.SlackBuild.old
	cp -v $PATCHDIR/tcsh-bsdwait-fix.diff.gz $SRCDIR/a/tcsh
	cp -v $PATCHDIR/tcsh-6.19.00-calloc-gcc-5.patch.gz $SRCDIR/a/tcsh
	(
		cd $SRCDIR/a/tcsh
		zcat $PATCHDIR/tcshSB.patch.gz |patch tcsh.SlackBuild --verbose
	)
fi
}

execute_nftables () {
#******************************************************************
if [ ! -f $SRCDIR/n/nftables/nftables.SlackBuild.old ]; then
	cp -v $SRCDIR/n/nftables/nftables.SlackBuild $SRCDIR/n/nftables/nftables.SlackBuild.old
	cp -v $DNDIR/nftables/nft.8.gz $SRCDIR/n/nftables/
	(
		cd $SRCDIR/n/nftables
		zcat $PATCHDIR/nftablesSB.patch.gz |patch nftables.SlackBuild --verbose
	)
fi
}

execute_ulogd () {
#******************************************************************
if [ ! -f $SRCDIR/n/ulogd/ulogd.SlackBuild.old ]; then
	cp -v $SRCDIR/n/ulogd/ulogd.SlackBuild $SRCDIR/n/ulogd/ulogd.SlackBuild.old
	(
		cd $SRCDIR/n/ulogd
		zcat $PATCHDIR/ulogdSB.patch.gz |patch ulogd.SlackBuild --verbose
	)
fi
}

execute_pykde4 () {
#******************************************************************
mkdir -pv $SRCDIR/kde/patch/pykde4
cp -v $PATCHDIR/0002-Add-some-missing-link-libraries.patch.gz $SRCDIR/kde/patch/pykde4
cp -v $PATCHDIR/0003-Fix-build-with-sip-4.19.patch.gz $SRCDIR/kde/patch/pykde4
cp -v $PATCHDIR/Annotate-KAutoMount-as-Abstract.patch.gz $SRCDIR/kde/patch/pykde4
cp -v $PATCHDIR/fix_kpythonpluginfactory_build.diff.gz $SRCDIR/kde/patch/pykde4

cp -v $PATCHDIR/pykde4.patch $SRCDIR/kde/patch
}

execute_kdevelop_pg_qt_c () {
#******************************************************************
cp -v $PATCHDIR/kdevelop-pg-qt.patch.gz $SRCDIR/kde/patch/kdevelop-pg-qt
cd $SRCDIR/kde/patch
zcat $PATCHDIR/kdevelop-pg-qtSB.patch.gz |patch kdevelop-pg-qt.patch --verbose
}

execute_k3b () {
#******************************************************************
mkdir -pv $SRCDIR/kde/patch/k3b
cp -v $PATCHDIR/upstream_Fixed-compilation-on-newer-ffmpeg-libav.patch.gz $SRCDIR/kde/patch/k3b
cp -v $PATCHDIR/k3b.patch $SRCDIR/kde/patch
}

execute_readline_c () {
#******************************************************************
if [ ! -f $SRCDIR/l/readline/readline.SlackBuild.old ]; then
	cp -v $SRCDIR/l/readline/readline.SlackBuild $SRCDIR/l/readline/readline.SlackBuild.old
	(
		cd $SRCDIR/l/readline
		zcat $PATCHDIR/readlineSB.patch.gz |patch readline.SlackBuild --verbose
	)
fi
}

execute_isapnptools () {
#******************************************************************
if [ ! -f $SRCDIR/a/isapnptools/isapnptools.SlackBuild.old ]; then
	cp -v $SRCDIR/a/isapnptools/isapnptools.SlackBuild $SRCDIR/a/isapnptools/isapnptools.SlackBuild.old
	cp -v $PATCHDIR/isapnptools.patch.gz $SRCDIR/a/isapnptools
	(
		cd $SRCDIR/a/isapnptools
		zcat $PATCHDIR/isapnptoolsSB.patch.gz |patch isapnptools.SlackBuild --verbose
	)
fi
}

execute_reiserfsprogs () {
#******************************************************************
if [ ! -f $SRCDIR/a/reiserfsprogs/reiserfsprogs.SlackBuild.old ]; then
	cp -v $SRCDIR/a/reiserfsprogs/reiserfsprogs.SlackBuild $SRCDIR/a/reiserfsprogs/reiserfsprogs.SlackBuild.old
	(
		cd $SRCDIR/a/reiserfsprogs
		zcat $PATCHDIR/reiserfsprogsSB.patch.gz |patch reiserfsprogs.SlackBuild --verbose
	)
fi
}

execute_lxc_14_2 () {
#******************************************************************
if [ ! -f $SRCDIR/ap/lxc/lxc.SlackBuild.old ]; then
	cp -v $SRCDIR/ap/lxc/lxc.SlackBuild $SRCDIR/ap/lxc/lxc.SlackBuild.old
	cp -v $PATCHDIR/lxc_readdir_r.patch.gz $SRCDIR/ap/lxc
	(
		cd $SRCDIR/ap/lxc
		zcat $PATCHDIR/lxcSB.patch.gz |patch lxc.SlackBuild --verbose
	)
fi
}

execute_p2c () {
#******************************************************************
if [ ! -f $SRCDIR/d/p2c/p2c.SlackBuild.old ]; then
	cp -v $SRCDIR/d/p2c/p2c.SlackBuild $SRCDIR/d/p2c/p2c.SlackBuild.old
	(
		cd $SRCDIR/d/p2c
		zcat $PATCHDIR/p2cSB.patch.gz |patch p2c.SlackBuild --verbose
	)
fi
}

execute_eudev () {
#******************************************************************
if [ ! -f $SRCDIR/a/eudev/eudev.SlackBuild.old ]; then
	cp -v $SRCDIR/a/eudev/eudev.SlackBuild $SRCDIR/a/eudev/eudev.SlackBuild.old
	cp -v $PATCHDIR/eudev.patch.gz $SRCDIR/a/eudev
	(
		cd $SRCDIR/a/eudev
		zcat $PATCHDIR/eudevSB.patch.gz |patch eudev.SlackBuild --verbose
	)
fi
}

execute_xfce () {
#******************************************************************
if [ ! -f $SRCDIR/xfce/xfce-build-all.sh.old ]; then
	cp -v $SRCDIR/xfce/xfce-build-all.sh  $SRCDIR/xfce/xfce-build-all.sh.old 
	(
		cd $SRCDIR/xfce
		zcat $PATCHDIR/xfce-build-all.patch.gz |patch xfce-build-all.sh --verbose
	)
fi
}

execute_strigi () {
#******************************************************************
if [ ! -f $SRCDIR/l/strigi/strigi.SlackBuild.old ]; then
	cp -v $SRCDIR/l/strigi/strigi.SlackBuild $SRCDIR/l/strigi/strigi.SlackBuild.old
	cp -v $PATCHDIR/strigi-0.7.8-ffmpeg29.patch.gz $SRCDIR/l/strigi
	(
		cd $SRCDIR/l/strigi
		zcat $PATCHDIR/strigiSB.patch.gz |patch strigi.SlackBuild --verbose
	)
fi
}

execute_php () {
#******************************************************************
if [ ! -f $SRCDIR/n/php/php.SlackBuild.old ]; then
	cp -v $SRCDIR/n/php/php.SlackBuild $SRCDIR/n/php/php.SlackBuild.old
	(
		cd $SRCDIR/n/php
		zcat $PATCHDIR/phpSB.patch.gz |patch php.SlackBuild --verbose
	)
fi
}

execute_diffutils () {
#******************************************************************
if [ ! -f $SRCDIR/ap/diffutils/diffutils.SlackBuild.old ]; then
	cp -v $SRCDIR/ap/diffutils/diffutils.SlackBuild $SRCDIR/ap/diffutils/diffutils.SlackBuild.old
	(
		cd $SRCDIR/ap/diffutils
		zcat $PATCHDIR/diffutilsSB.patch.gz |patch diffutils.SlackBuild --verbose
	)
fi
}

execute_fontconfig () {
#******************************************************************
if [ ! -f $SRCDIR/x/fontconfig/fontconfig.SlackBuild.old ]; then
	cp -v $SRCDIR/x/fontconfig/fontconfig.SlackBuild $SRCDIR/x/fontconfig/fontconfig.SlackBuild.old
	cp -v $PATCHDIR/0001-Avoid-conflicts-with-integer-width-macros-from-TS-18.patch.gz $SRCDIR/x/fontconfig
	(
		cd $SRCDIR/x/fontconfig
		zcat $PATCHDIR/fonconfigSB.patch.gz |patch fontconfig.SlackBuild --verbose
	)
fi
}

execute_aspell () {
#******************************************************************
if [ ! -f $SRCDIR/l/aspell/aspell.SlackBuild.old ]; then
	cp -v $SRCDIR/l/aspell/aspell.SlackBuild $SRCDIR/l/aspell/aspell.SlackBuild.old
	(
		cd $SRCDIR/l/aspell
		zcat $PATCHDIR/aspellSB.patch.gz |patch aspell.SlackBuild --verbose
	)
fi
}

execute_oprofile () {
#******************************************************************
if [ ! -f $SRCDIR/d/oprofile/oprofile.SlackBuild.old ]; then
	cp -v $SRCDIR/d/oprofile/oprofile.SlackBuild $SRCDIR/d/oprofile/oprofile.SlackBuild.old
	cp -v $PATCHDIR/oprofile-1.1.0-gcc6.patch.gz $SRCDIR/d/oprofile
	cp -v $PATCHDIR/oprofile-1.1.0-gcc6-template-depth.patch.gz $SRCDIR/d/oprofile
	(
		cd $SRCDIR/d/oprofile
		zcat $PATCHDIR/oprofileSB.patch.gz |patch oprofile.SlackBuild --verbose
	)
fi
}

execute_librevenge () {
#******************************************************************
if [ ! -f $SRCDIR/l/librevenge/librevenge.SlackBuild.old ]; then
	cp -v $SRCDIR/l/librevenge/librevenge.SlackBuild $SRCDIR/l/librevenge/librevenge.SlackBuild.old
	(
		cd $SRCDIR/l/librevenge
		zcat $PATCHDIR/librevengeSB.patch.gz |patch librevenge.SlackBuild --verbose
	)
fi
}

execute_gnu_efi () {
#******************************************************************
if [ ! -f $SRCDIR/l/gnu-efi/gnu-efi.SlackBuild.old ]; then
	cp -v $SRCDIR/l/gnu-efi/gnu-efi.SlackBuild $SRCDIR/l/gnu-efi/gnu-efi.SlackBuild.old
	(
		cd $SRCDIR/l/gnu-efi
		zcat $PATCHDIR/gnu-efiSB.patch.gz |patch gnu-efi.SlackBuild --verbose
	)
fi
}

execute_js185 () {
#******************************************************************
if [ ! -f $SRCDIR/l/js185/js185.SlackBuild.old ]; then
	cp -v $SRCDIR/l/js185/js185.SlackBuild $SRCDIR/l/js185/js185.SlackBuild.old
	cp -v $PATCHDIR/js-1.8.5-c++11.patch.gz $SRCDIR/l/js185
	(
		cd $SRCDIR/l/js185
		zcat $PATCHDIR/js185SB.patch.gz |patch js185.SlackBuild --verbose
	)
fi
}

execute_audiofile () {
#******************************************************************
if [ ! -f $SRCDIR/l/audiofile/audiofile.SlackBuild.old ]; then
	cp -v $SRCDIR/l/audiofile/audiofile.SlackBuild $SRCDIR/l/audiofile/audiofile.SlackBuild.old
	cp -v $PATCHDIR/01_gcc6.patch.gz $SRCDIR/l/audiofile
	cp -v $PATCHDIR/03_CVE-2015-7747.patch.gz $SRCDIR/l/audiofile
	(
		cd $SRCDIR/l/audiofile
		zcat $PATCHDIR/audiofileSB.patch.gz |patch audiofile.SlackBuild --verbose
	)
fi
}

execute_scim () {
#******************************************************************
if [ ! -f $SRCDIR/x/scim/scim.SlackBuild.old ]; then
	cp -v $SRCDIR/x/scim/scim.SlackBuild $SRCDIR/x/scim/scim.SlackBuild.old
	cp -v $PATCHDIR/scim-1.4.17-fixes-send-function-call.patch.gz $SRCDIR/x/scim
	(
		cd $SRCDIR/x/scim
		zcat $PATCHDIR/scimSB.patch.gz |patch scim.SlackBuild --verbose
	)
fi
}

execute_scim_anthy () {
#******************************************************************
if [ ! -f $SRCDIR/x/scim-anthy/scim-anthy.SlackBuild.old ]; then
	cp -v $SRCDIR/x/scim-anthy/scim-anthy.SlackBuild $SRCDIR/x/scim-anthy/scim-anthy.SlackBuild.old
	cp -v $PATCHDIR/scim-anthy-fix-typo.patch.gz $SRCDIR/x/scim-anthy
	(
		cd $SRCDIR/x/scim-anthy
		zcat $PATCHDIR/scim-anthySB.patch.gz |patch scim-anthy.SlackBuild --verbose
	)
fi
}

execute_htdig () {
#******************************************************************
if [ ! -f $SRCDIR/n/htdig/htdig.SlackBuild.old ]; then
	cp -v $SRCDIR/n/htdig/htdig.SlackBuild $SRCDIR/n/htdig/htdig.SlackBuild.old
	cp -v $PATCHDIR/htdig-3.2.0b6-narrowing.patch.gz $SRCDIR/n/htdig
	cp -v $PATCHDIR/htdig-3.2.0b6-htstat-segv.patch.gz $SRCDIR/n/htdig
	cp -v $PATCHDIR/htdig-3.2.0b6-const.patch.gz $SRCDIR/n/htdig
	cp -v $PATCHDIR/htdig-3.2.0b6-buildfix.patch.gz $SRCDIR/n/htdig
	(
		cd $SRCDIR/n/htdig
		zcat $PATCHDIR/htdigSB.patch.gz |patch htdig.SlackBuild --verbose
	)
fi
}

execute_rp_pppoe () {
#******************************************************************
if [ ! -f $SRCDIR/n/rp-pppoe/rp-pppoe.SlackBuild.old ]; then
	cp -v $SRCDIR/n/rp-pppoe/rp-pppoe.SlackBuild $SRCDIR/n/rp-pppoe/rp-pppoe.SlackBuild.old
	cp -v $PATCHDIR/01_auto_ifup.patch.gz $SRCDIR/n/rp-pppoe
	cp -v $PATCHDIR/02_change_mac_option.patch.gz $SRCDIR/n/rp-pppoe
	cp -v $PATCHDIR/03_man_pages.patch.gz $SRCDIR/n/rp-pppoe
	cp -v $PATCHDIR/04_ignore_broadcasted_pado_packets.patch.gz $SRCDIR/n/rp-pppoe
	cp -v $PATCHDIR/05_change_default_timeout.patch.gz $SRCDIR/n/rp-pppoe
	cp -v $PATCHDIR/06_typo_fixes.patch.gz $SRCDIR/n/rp-pppoe
	cp -v $PATCHDIR/rp-pppoe-3.10-posix-source-sigaction.patch.gz $SRCDIR/n/rp-pppoe
	cp -v $PATCHDIR/rp-pppoe-3.12-linux-headers.patch.gz $SRCDIR/n/rp-pppoe
	(
		cd $SRCDIR/n/rp-pppoe
		zcat $PATCHDIR/rp-pppoeSB.patch.gz |patch rp-pppoe.SlackBuild --verbose
	)
fi
}

execute_crda () {
#******************************************************************
if [ ! -f $SRCDIR/n/crda/crda.SlackBuild.old ]; then
	cp -v $SRCDIR/n/crda/crda.SlackBuild $SRCDIR/n/crda/crda.SlackBuild.old
	cp -v $PATCHDIR/regulatory-rules-setregdomain.patch.gz $SRCDIR/n/crda
	cp -v $PATCHDIR/crda-remove-ldconfig.patch.gz $SRCDIR/n/crda
	cp -v $PATCHDIR/crda-ldflags.patch.gz $SRCDIR/n/crda
	(
		cd $SRCDIR/n/crda
		zcat $PATCHDIR/crdaSB.patch.gz |patch crda.SlackBuild --verbose
	)
fi
}

execute_kate () {
#******************************************************************
mkdir -pv $SRCDIR/kde/patch/kate
cp -v $PATCHDIR/cmake-policy.diff.gz $SRCDIR/kde/patch/kate
cp -v $PATCHDIR/kate-4.14.3-gcc7.patch.gz $SRCDIR/kde/patch/kate
cp -v $PATCHDIR/kate.patch $SRCDIR/kde/patch
}

execute_smokeqt () {
#******************************************************************
mkdir -pv $SRCDIR/kde/patch/smokeqt
cp -v $PATCHDIR/0001-set-cmake_min_req-to-match-kdelibs4-and-enable-newer.patch.gz $SRCDIR/kde/patch/smokeqt
cp -v $PATCHDIR/smokeqt.patch $SRCDIR/kde/patch
}

execute_ktorrent () {
#******************************************************************
mkdir -pv $SRCDIR/kde/patch/ktorrent
cp -v $PATCHDIR/upstream_webinterface-rename-major-minor-to-major_version-min.patch.gz $SRCDIR/kde/patch/ktorrent
cp -v $PATCHDIR/ktorrent.patch $SRCDIR/kde/patch
}

execute_kde_options () {
#******************************************************************
if [ ! -f $SRCDIR/kde/KDE.options.old ]; then
	cp -v $SRCDIR/kde/KDE.options $SRCDIR/kde/KDE.options.old
	(
		cd $SRCDIR/kde
		zcat $PATCHDIR/KDE_optionsSB.patch.gz |patch KDE.options --verbose
	)
fi
}

execute_glade3 () {
#******************************************************************
if [ ! -f $SRCDIR/l/glade3/glade3.SlackBuild.old ]; then
	cp -v $SRCDIR/l/glade3/glade3.SlackBuild $SRCDIR/l/glade3/glade3.SlackBuild.old
	(
		cd $SRCDIR/l/glade3
		zcat $PATCHDIR/glade3SB.patch.gz |patch glade3.SlackBuild --verbose
	)
fi
}

execute_mariadb () {
#******************************************************************
if [ ! -f $SRCDIR/ap/mariadb/mariadb.SlackBuild.old ]; then
	cp -v $SRCDIR/ap/mariadb/mariadb.SlackBuild $SRCDIR/ap/mariadb/mariadb.SlackBuild.old
	(
		cd $SRCDIR/ap/mariadb
		zcat $PATCHDIR/mariadbSB.patch.gz |patch mariadb.SlackBuild --verbose
	)
fi
}

execute_herqq () {
#******************************************************************
if [ ! -f $SRCDIR/l/herqq/herqq.SlackBuild.old ]; then
	cp -v $SRCDIR/l/herqq/herqq.SlackBuild $SRCDIR/l/herqq/herqq.SlackBuild.old
	cp -v $PATCHDIR/herqq-gcc6.patch.gz $SRCDIR/l/herqq
	(
		cd $SRCDIR/l/herqq
		zcat $PATCHDIR/herqqSB.patch.gz |patch herqq.SlackBuild --verbose
	)
fi
}

#*******************************************************************
# End of sub-system of execution of patches
#*******************************************************************


sources_alteration () {
#**********************************
# alteration of the slackware sources
#**********************************
PS3="Your choice:"
echo
echo "Do you want to alter the slackware sources: yes, no or quit."
echo
select sources_alteration in yes no quit
do
	if [[ "$sources_alteration" = "yes" ]]
	then
		execute_net_tools
		execute_lcms
		execute_rcs
		execute_dbus
		execute_gstreamer0
		execute_glib
		execute_subversion
		execute_cmake
		execute_libcap
		execute_libusb
		execute_pkg_config
		execute_svgalib
		execute_tix
		execute_nasm
		execute_kmod
		execute_ksh93
		execute_libcaca
		execute_libmad
		execute_newspost
		execute_procmail
		execute_seyon
		execute_taglib_extras
		execute_netkit_rwho_synth
#		execute_qt_nowebkit
		execute_gv
		execute_sysklogd
		execute_tcsh
		execute_nftables
		execute_ulogd
		execute_pykde4
		execute_isapnptools
		execute_reiserfsprogs
		execute_p2c
		case $(uname -m) in
			x86_64 )
#				execute_eudev
				execute_a2ps
				execute_mariadb
				execute_herqq
				execute_tetex ;;
			* )
#				execute_eudev
				execute_gst_plugins_base0 ;;
		esac

		case $distribution in
			slackware )
				execute_aspell
				execute_audiofile
				execute_clisp_c
				execute_crda
				execute_fontconfig
				execute_glade3
				execute_gnu_efi
				execute_htdig
				execute_php
#				execute_diffutils
				execute_js185
				execute_kdevelop_pg_qt_c
#				execute_k3b
				execute_kate
				execute_smokeqt
				execute_ktorrent
				execute_kde_options
				execute_librevenge
				execute_llvm_c
				execute_oprofile
				execute_rp_pppoe
				execute_scim
				execute_scim_anthy
				execute_xfce
				execute_strigi
				execute_readline_c
				case $(uname -m) in
					x86_64 )
						echo ;;
					* )
					execute_k3b ;;
				esac
				echo ;;

			slackware_14_2 )
				execute_dmapi
				execute_esound
				execute_gcc
				execute_llvm_14_2
				execute_lxc_14_2
				execute_x11_14_2
				execute_libva_intel_driver
				execute_libspectre
				execute_clisp_14_2 ;;

			dlackware )
				execute_aspell
				execute_audiofile
				execute_clisp_c
				execute_crda
				execute_fontconfig
				execute_glade3
				execute_gnu_efi
				execute_htdig
				execute_js185
				execute_kdevelop_pg_qt_c
#				execute_k3b
				execute_kate
				execute_smokeqt
				execute_ktorrent
				execute_kde_options
				execute_php
#				execute_diffutils
				dlackware_dir
				execute_dbus_d
				execute_librevenge
				execute_libxkbcommon
				execute_llvm_c
				execute_oprofile
				execute_rp_pppoe
				execute_scim
				execute_scim_anthy
				execute_xfce
				execute_strigi
				execute_readline_c ;;
		esac
		break
	elif [[ "$sources_alteration" = "no" ]]
	then
		echo "You decided to keep the slackware sources."
		echo "The building of slackware won't build completely"
		echo
		break
	elif [[ "$sources_alteration" = "quit" ]]
	then
		echo "You have decided to quit. Goodbye." && exit 1
	fi
done
export $distribution
echo $distribution
echo "You choose $sources_alteration."
}


#************************************************************************
#************************************************************************
# MAIN CORE SCRIPT
#************************************************************************
#************************************************************************

#***********************************************************
echo
echo "Making adjustments to sources."
echo
#***********************************************************
sources_alteration

