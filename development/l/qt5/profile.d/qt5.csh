#!/bin/csh
# Environment path variables for the Qt package:
if ( ! $?QT5DIR ) then
    # It's best to use the generic directory to avoid
    # compiling in a version-containing path:
    if ( -d /usr/lib@LIBDIRSUFFIX@/qt5 ) then
        setenv QT5DIR /usr/lib@LIBDIRSUFFIX@/qt5
    else
        # Find the newest Qt directory and set $QT5DIR to that:
        foreach qtd ( /usr/lib@LIBDIRSUFFIX@/qt5-* )
            if ( -d $qtd ) then
                setenv QT5DIR $qtd
            endif
        end
    endif
endif
set path = ( $path $QT5DIR/bin )
# Unfortunately Chromium and derived projects (including QtWebEngine) seem
# to be suffering some bitrot when it comes to 32-bit support, so we are
# forced to disable the seccomp filter sandbox on 32-bit or else all of these
# applications crash. If anyone has a patch that gets these things running on
# 32-bit without this workaround, please let volkerdi or alienBOB know, or
# post your solution on LQ. Thanks. :-)
file /bin/cat | grep -wq 32-bit
if ( "$?" == "0" ) then
  setenv QTWEBENGINE_CHROMIUM_FLAGS "--disable-seccomp-filter-sandbox"
endif
