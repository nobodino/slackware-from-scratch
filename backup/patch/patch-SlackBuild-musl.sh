#######################  patch-SlackBuild-musl.sh ###################################
#!/bin/bash
#####################################################################################
set -x

if [ -f autoconf.musl.diff ]
	then
		cp -v autoconf.SlackBuild autoconf.SlackBuild.old
		sed -i -e '/chmod 644/p' autoconf.SlackBuild
#		-exec chmod 644 {} \+
		sed -i -e 's/-exec chmod 644 {} /\/+/ cat $CWD\/\autoconf.musl.diff | patch -Esp1 --verbose || exit 1/g' autoconf.SlackBuild
#		sed -i -e '1,/-exec chmod 644 {} /\/+/ s/-exec chmod 644 {} /\/+/cat $CWD\/\autoconf.musl.diff | patch -Esp1 --verbose || exit 1/' autoconf.SlackBuild
elif [ ! -f autoconf.musl.diff ]
	then
		echo
fi	
