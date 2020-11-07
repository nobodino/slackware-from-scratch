#######################  list_generator_c.sh ###################################
#!/bin/bash
#
# Copyright 2018,2019,2020  J. E. Garrott Sr, Puyallup, WA, USA
# Copyright 2018,2019,2020  "nobodino", Bordeaux, FRANCE
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
#	Above july 2018, revisions made through github project: 
#   https://github.com/nobodino/slackware-from-scratch 
#
###########################################################################
# set -x

lists_generator_c () {
#******************************************
# generator of lists of packages
#******************************************
	generate_slackware_link_build_list
	generate_slackware_build_list1_c
	generate_slackware_build_list2_c
	generate_slackware_build_list3_c
	generate_slackware_build_list4_c
}

generate_slackware_link_build_list () {
cat > $SFS/sources/link.list << "EOF"
a link_tools_slackware
EOF
}

generate_slackware_build_list1_c () {
#******************************************
cat > $SFS/sources/build1_s.list << "EOF"
a findutils
a pkgtools
a aaa_base
a etc
a sed
a coreutils
n rsync
k kernel-source
d kernel-headers
d python2
d bison
l glibc
a adjust
# a test-glibc
l zlib
d bison
d help2man
a lzip
d flex
d binutils
d libtool
l gmp
l isl
l mpfr
l libmpc
a infozip
l expat
d python2
d python3
l gc
d autoconf
d automake
d patchelf
a xz
l lz4
l zstd
# d pre-gcc
d gcc
# d post-gcc
a bzip2
d pkg-config
l ncurses
a attr
a acl
l libcap
a sed
# a xz
l libxml2
tcl tcl
l libxslt
a shadow
a grep
l readline
l gdbm
d gperf
n openssl
a kmod
a gettext
a gettext-tools
l libssh2
n curl
l elfutils
l libffi
a procps-ng
ap groff
l pcre2
a util-linux
a e2fsprogs
a coreutils
a glibc-zoneinfo
l readline
l readline
ap diffutils
a gawk
a less
a gzip
n libmnl
l libnl
l libnl3
l libpcap
n libnfnetlink
n libnetfilter_conntrack
n libnftnl
n iptables
n iproute2
a hostname
a kbd
l libunistring
l gc
l gmp
d guile
d make
a patch
a sysklogd
a utempter
a sysvinit
a sysvinit-scripts
l popt
a sysvinit-functions
a bin
a devs
n network-scripts
l pcre
d re2c
d ninja
l libffi
d python3
d python-setuptools
d meson
l glib2
l gamin
l gobject-introspection
a eudev
ap man-db
a bash
a tar
ap texinfo
ap man-pages
l jemalloc
l libaio
n openssl
n openssl10
l libssh2
l jansson
n cyrus-sasl
l db48
l rpcsvc-proto
n openldap
n krb5
n libtirpc
l libnsl
l libnss_nis
n tcp_wrappers
l icu4c
l libiodbc
n curl
l libarchive
d cmake
n dhcpcd
a dhcpcd_up
d perl
n openldap
n krb5
a cracklib
a pam
a libpwquality
a shadow
l libcap
a util-linux
n cyrus-sasl
n openssl
n openssl10
ap mariadb
d perl
n openldap
d intltool
a ed
ap bc
a file
d m4
a which
a cpio
l readline
n dhcpcd
l libedit
d llvm
d llvm
d ccache
d rust
a kernel-all
d help2man
d flex
d bison
d autoconf
d libtool
a findutils
n lynx
n nss-pam-ldapd
n pam-krb5
a end1
EOF
}

generate_slackware_build_list2_c () {
#******************************************
cat > $SFS/sources/build2_s.list << "EOF"
a dhcpcd_up
a haveged
a gpm
a gpm
a sysfsutils
l alsa-lib
n cyrus-sasl
n openldap
l libidn
l libidn2
a hwdata
a pciutils
d pkg-config
l gamin
a libgudev
d pkg-config
n wget
l libcap-ng
extra bash-completion
n libgpg-error
n libgcrypt
l libxml2
tcl tcl
l libxslt
a kmod
l fuse
l libpng
l gdbm
l lzo
l openjpeg
d nasm
l libjpeg-turbo
l mm
l slang1
l slang
l libtiff
l libusb
l libusb-compat
l libsigsegv
l svgalib
l db48
a lvm2
l lcms2
n nettle
l libtasn1
a dcron
n ca-certificates
n p11-kit
l libunistring
a dbus
a rpm2tgz
d slacktrack
ap itstool
l icu4c
a xfsprogs
ap dmapi
l graphite2
l freetype
l harfbuzz
l freetype
l harfbuzz
l gd
t texlive
ap sqlite
d gyp
l mozilla-nss
l db48
ap rpm
a cpio
a libgudev
a usbutils
a dialog
d help2man
l python-pygments	
ap linuxdoc-tools
a pam
l gobject-introspection
l glib2
ap nano
l xxHash
n rsync
ap mc
# n tcp_wrappers
l libedit
n openssh
n ncftp
l python-ply
l libuv
n bind
l gmp
n gnutls
ap cups
n iputils
l ncurses
l json-c
l argon2
l pcre2
l libpsl
l keyutils
a pre-elflibs
a aaa_elflibs
a post-elflibs
a aaa_terminfo
a kmod
a eudev
l libusb
a libgudev
f linux-faqs
f linux-howtos
d python2
d python3
d vala
l libical
a dbus
n bluez
n net-tools
x x11-skel
x libevdev
x mtdev
x xdg-user-dirs
x x11-group1
x xdg-utils
x fontconfig
ap ghostscript
ap ghostscript-fonts-std
a dialog
l dbus-glib
l dbus-python
ap sudo
l sg3_utils
a utempter
d swig
d oprofile
d binutils
d git
l icu4c
x x11-xcb
x x11-lib
l gd
l startup-notification
l zstd
x libdrm
x libva
x libva-utils
x intel-vaapi-driver
x libvdpau
l libclc
d python-setuptools
l Mako
x libglvnd
# l sdl
x wayland
x wayland-protocols
# l brotli
x mesa
x glew
x glu
x freeglut
x mesa
x libXaw3dXft
x libepoxy
l cairo
a eudev
a libgudev
x libXcm
x xcm
x libwacom
l libunwind
x x11-group2
x compiz
x dejavu-fonts-ttf
x liberation-fonts-ttf
x motif
x xterm
x libva
x urw-core35-fonts-otf
x hack-fonts-ttf
x noto-cjk-fonts-ttf
x noto-fonts-ttf
x ttf-tlwg
l pcre2
x vulkan-sdk
x pyxdg
xap rxvt-unicode
xap blackbox
n dhcp
ap nvme-cli
ap neofetch
ap undervolt
ap inxi
a end2
EOF
}

generate_slackware_build_list3_c () {
#******************************************
cat > $SFS/sources/build3_s.list << "EOF"
a dhcpcd_up
l python-pygments
ap linuxdoc-tools
a zerofree
l libpcap
a f2fs-tools
a efivar
a efibootmgr
l gnu-efi
a elilo
a dbus
d ruby
# others bison
l qt
# d bison
d cmake
l libunistring
l gc
l gmp
d guile
d mercurial
d python-setuptools
l imagemagick
l xapian-core
l poppler
l poppler-data
l shared-mime-info
l gdk-pixbuf2
l atk
l at-spi2-core
l at-spi2-atk
l fribidi
l pango
l gtk+2
l libglade
tcl expect
d clisp
t texlive
x fontconfig
d doxygen
kde5 extra-cmake-modules
# l libdbusmenu-qt
l sdl
# l openal-soft
# l libxkbcommon
# l brotli
x wayland
x wayland-protocols
# l woff2
# l hyphen
# l qt5
# l qt5-webkit
# d doxygen
# l libxkbcommon
# deps all-deps-1
d strace
d rcs
d ccache
d cvs
d yasm
l apr
l apr-util
l jansson
n nghttp2
n httpd
l neon
l utf8proc
l lz4
d subversion
d cmake
tcl tk
tcl tclx
tcl expect
tcl tix
t fig2dev
l libsigsegv
l libsigc++
d cscope
d distcc
d icecream
d dev86
d p2c
d python-pip
d re2c
d ninja
d meson
d patchelf
d parallel
l pyparsing
l python-appdirs
l python-certifi
l python-chardet
l python-docutils
l python-idna
l python-packaging
l python-requests
xap sane
l python2-module-collection
l python-urllib3
l libsndfile
l orc
l speexdsp
l libasyncns
l tdb
d check
l sbc
n bluez
l alsa-lib
l pulseaudio
l alsa-lib
l boost
l judy
l netpbm
l libwnck
l gstreamer0
d autoconf-archive
l mozjs78
l polkit
a upower
l gst-plugins-base0
l libxkbcommon
l gtk+3
x libinput
x x11-app-post
ap cups
l pcre2
d vala
l vte
l libnotify
l pygobject
l pycairo
l pygtk
l keybinder3
l libproxy
l gsettings-desktop-schemas
l glib-networking
l hicolor-icon-theme
t xfig
l librsvg
l gdk-pixbuf2
l gnome-themes-extra
l libpsl
l libsoup
l libevent
l libvpx
l GConf
l libwnck
l adwaita-icon-theme
xap ffmpegthumbnailer
xfce xfce
xfce xfce
xap seamonkey
a end3
EOF
}

generate_slackware_build_list4_c () {
#******************************************
cat > $SFS/sources/build4_s.list << "EOF"
a dhcpcd_up
l python-six
d opencl-headers
l ocl-icd
l giflib
l parted
l libatasmart
l libnih
l lzo
n gnupg
n libassuan
n libksba
n npth
n gnupg2
d python2
l json-c
l argon2
a cryptsetup
a inotify-tools
a logrotate
ap enscript
ap a2ps
ap qpdf
ap cups-filters
ap seejpeg
ap rzip
ap sc
ap sc-im
ap screen
a xfsprogs
ap xfsdump
ap xorriso
a ntfs-3g
a sharutils
a mlocate
a time
a tree
n ethtool
n iproute2
n lftp
e emacs
l pcaudiolib
l espeak-ng
e emacspeak
a acpid
a btrfs-progs
a cpufrequtils
a dcron
a dosfstools
a elvis
a floppy
a genpower
a gptfdisk
a grub
a hdparm
a isapnptools
a jfsutils
a lhasa
a libcgroup
d dev86
a lilo
a mcelog
a mdadm
a minicom
a mkinitrd
a mt-st
a mtx
a ncompress
a os-prober
a pcmciautils
d flex
a quota
a reiserfsprogs
l sg3_utils
a sdparm
a smartmontools
a splitvt
a syslinux
a tcsh
a udisks
a ndctl
a libbytesize
n gpgme
a volume_key
l libyaml
a libblockdev
a udisks2
a unarj
a upower
a usb_modeswitch
a zoo
ap acct
l alsa-lib
ap alsa-utils
ap amp
ap dash
n libmilter
n postfix
ap at
ap bpe
ap cdparanoia
ap cdrdao
ap cdrtools
ap cgmanager
ap dc3dd
a lrzip
ap ddrescue
ap diffstat
ap dmidecode
ap dvd+rw-tools
ap flac
l libgphoto2
ap gphoto2
l babl
l json-c
l json-glib
x libmypaint
l gegl
l libssh
l exiv2
l gexiv2
x mypaint-brushes
l pygobject
l pycairo
l pygtk
xap gimp
l glib
l gtk+
ap gutenprint
ap lm_sensors
n net-snmp
xap sane
xap xsane
l python-sane
l python-distro
ap hplip
ap ispell
ap jed
ap joe
ap jove
ap ksh93
ap libx86
ap lsof
ap lsscsi
ap lxc
l libmad
l libid3tag
ap madplay
ap most
# l sdl
ap mpg123
l glib
l gtk+
xap xmms
ap normalize
ap pm-utils
l libnl
ap powertop
ap radeontool
ap rzip
ap soma
ap sox
ap sysstat
ap terminus-font
ap tmux
a floppy
a lzlib
a plzip
a lbzip2
l libplist
l libusbmuxd
l libimobiledevice
ap usbmuxd
ap vbetool
l libogg
l id3lib
l opus
l opusfile
l libopusenc
ap opus-tools
l speex
l libvorbis
l libao
ap vorbis-tools
ap zsh
ap htop
ap pamixer
ap squashfs-tools
l wavpack
xap easytag
# xap audacious
xap ddd
l python-notify2
l libical
n bluez
l pygobject3
d Cython
xap blueman
l libglade
xap electricsheep
xap fvwm
xap fluxbox
xap geeqie
xap gkrellm
xap gimp
xap gftp
xap gkrellm
xap gnuchess
# xap gnuplot
l desktop-file-utils
xap gucharmap
l imagemagick
l iso-codes
l libnl3
n ppp
l gmime
xap pan
l hunspell
l enchant
l gtkspell
l libsigc++
l glibmm
l cairomm
l pangomm
l atkmm
l gtkmm3
l libcanberra
l gstreamer
d vala
l dconf
l dconf-editor
l gtkmm2
l gsl
l libcap-ng
l librevenge
l libwpd
l libvisio
l libwpg
l sbc
xap pavucontrol
l libnice
l graphene
l gst-plugins-base0
l gst-plugins-good0
l gst-plugins-base
# l gst-plugins-base
l gst-plugins-good
l farstream
xap pidgin
xap rdesktop
xap windowmaker
xap x11-ssh-askpass
xap x3270
xap gparted
l libtheora
l libcdio
l libcdio-paranoia
l libdvdread
l libdvdnav
# extra java
# l libcaca
l libcaca
l fribidi
l talloc
l tdb
l tevent
l lmdb
# n gpgme
n samba
l v4l-utils
l libpng
xap xine-lib
xap xlockmore
xap xpaint
xap xpdf
l jasper
xap xgames
n libmbim
n libqmi
n ModemManager
n alpine
n libtirpc
n autofs
n biff+comsat
n bluez-firmware
a kernel-firmware
n iputils
n bootp
n bridge-utils
n bsd-finger
n cifs-utils
n libmnl
n libnfnetlink
n libnetfilter_acct
n libnetfilter_conntrack
n libnetfilter_cthelper
n libnetfilter_cttimeout
n libnetfilter_log
n libnetfilter_queue
n conntrack-tools
l M2Crypto
n crda
n dnsmasq
l clucene
n dovecot
n ebtables
n elm
n epic5
n ethtool
l python-future
n fetchmail
n getmail
n htdig
n icmpinfo
n iftop
n inetd
n iproute2
n iptraf-ng
n irssi
n iw
n libndp
n libnftnl
n s-nail
n metamail
n mobile-broadband-provider-info
n mtr
n mutt
n nc
n ncftp
n netdate
n netkit-bootparamd
n netkit-ftp
n netkit-ntalk
n netkit-routed
n netkit-rsh
n netkit-rusers
n netkit-rwall
n netkit-rwho
n netkit-timed
n netpipes
n netwatch
n netwrite
n nfacct
n iptables
l gmp
n nftables
n nmap
n nn
n ntp
n openobex
n obexftp
n openvpn
l libmcrypt
l t1lib
n pidentd
n pinentry
n popa3d
n proftpd
n pssh
n rdist
n rp-pppoe
n rsync
n slrn
n stunnel
# n tcp_wrappers
n telnet
n tftp-hpa
n tin
n traceroute
n uucp
n vlan
n vsftpd
n whois
n wireless_tools
# n wpa_supplicant
n yptools
n ytalk
l newt
n NetworkManager
# xap libnma
l GConf
l libgnome-keyring
l libsecret
l gmp
d gnucobol
# n openldap
n netatalk
l loudmouth
n mcabber
# n lynx
n newspost
n procmail
xap seyon
l ConsoleKit2
l LibRaw
l sip
l PyQt
# l QScintilla
# l QScintilla
l a52dec
l aalib
l alsa-oss
l aspell
extra aspell-word-lists
kde5 extra-cmake-modules 
l attica
l audiofile
l automoc4
l babl
l chmlib
l djvulibre
l libzip
l ebook-tools
l libzip
l eigen2
l eigen3
l esound
l exiv2
l fftw
l fribidi
l gamin
l gd
l gmime
l gmm
l grantlee
# l gst-plugins-base0
# l gst-plugins-good0
# l gst-plugins-base
# l gst-plugins-base
# l gst-plugins-good
l hunspell
l icon-naming-utils
# l ilmbase
l keyutils
l lcms
l lcms2
l libbluedevil
l libcddb
l libdbusmenu-qt
l libdiscid
l libexif
l libfakekey
l libgpod
l libgsf
l libidl
l libidn
l libieee1284
l taglib
l taglib-extras
l libkarma
l libsamplerate
l liblastfm
l libmng
l libmtp
l jmtpfs
l libnih
l libnjb
l libodfgen
l liboggz
l liboil
l libplist
l libraw1394
l libsndfile
l libspectre
l libvisual
l libvisual-plugins
l libvncserver
l libxklavier
l libyaml
l media-player-info
l mhash
l openexr
l orc
deps phonon-qt4
deps phonon-qt4-gstreamer
l pilot-link
l polkit-qt-1
l pycups
l pycurl
l python-pillow
l qca
l qimageblitz
l qjson
l qtscriptgenerator
l raptor2
l rasqal
l redland
l shared-desktop-ontologies
l soprano
l sound-theme-freedesktop
l strigi
l system-config-printer
l tango-icon-theme
l tango-icon-theme-extras
l v4l-utils
l xapian-core
n ulogd
n tcpdump
tcl hfsutils
d indent
n ipw2100-fw
n ipw2200-fw
ap pamixer
d pmake
a quota
n rpcbind
d scons
l serf
d scons
n zd1211-firmware
x libhangul
x anthy
x scim
x scim-anthy
x scim-hangul
l libpng
x scim-input-pad
l gd
x m17n-lib
x scim-m17n
x scim-pinyin
x scim-tables
x tibmachuni-font-ttf
x ttf-indic-fonts
x wqy-zenhei-font-ttf
x sinhala_lklug-font-ttf
x sazanami-fonts-ttf
ap ghostscript
ap moc
xap gv
l boost
# deps qt-gstreamer
l qt-gstreamer
l akonadi
ap slackpkg
d gdb
l gstreamer
l libbluray
l fluidsynth
l SDL2
l SDL2_gfx
l SDL2_image
l SDL2_mixer
l SDL2_net
l SDL2_ttf
l lame
l libwebp
l ffmpeg
xap ssr
# l libcue
# xap audacious-plugins
l gst-plugins-libav
l libtiff
# d cmake
l taglib
l alsa-plugins
n links
ap vim
a nvi
n ulogd
l fuse3
n sshfs
xap hexchat
n ipset
xap xscreensaver
n gpa
n libgcrypt
l gcr
l gnome-keyring
xap libnma
xap network-manager-applet
l glade3
l gvfs
l keybinder3
l libiodbc
l libwmf
l libwnck
l polkit-gnome
l libsodium
l argon2
l oniguruma
l tidy-html5
n php
n nfs-utils
n libgcrypt
l soprano
xap MPlayer
xap xine-lib
xap xine-ui
kde kde
# n php
kdei calligra-l10n
kde post-kde
kde kdepim
kdei kde-l10n
n socat
# kde5 extra-cmake-modules
# deps all-deps-2
# kde5 frameworks
# kde5 kdepim5
# kde5 plasma
# kde5 plasma-extra
# kde5 applications
# kde5 applications-extra
d subversion
l libxml2
l ncurses
n openssl
n snownews
d python2
d python3
y bsd-games
l brotli
x wayland
x wayland-protocols
l woff2
l hyphen
l qt5
l qt5-webkit
l openal-soft
d doxygen
l libxkbcommon
l LibRaw
l PyQt5
l qca-qt5
xap xaos
xap audacious
xap gnuplot
l libcue
xap audacious-plugins
# l QScintilla
l QScintilla
l exiv2
l grantlee
l id3lib
deps phonon-qt4
deps phonon-qt4-gstreamer
# deps qt-gstreamer
l qt-gstreamer
deps phonon
deps phonon-gstreamer
l poppler
l sip
n gpgme
n wpa_supplicant
xap NetworkManager-openvpn
xap mozilla-firefox
xap mozilla-thunderbird
a end4
EOF
}


#************************************************************************
#************************************************************************
# MAIN CORE SCRIPT
#************************************************************************
#************************************************************************

lists_generator_c
