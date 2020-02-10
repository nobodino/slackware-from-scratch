# if rc.local doesn't exist, create it
if [ ! -e $ROOT/etc/rc.d/rc.local ]; then
        echo "#!/bin/sh" > $ROOT/etc/rc.d/rc.local
        chmod 755 $ROOT/etc/rc.d/rc.local
fi

# apply a check to remove any stale PAM console.lock files.
grep "rm -f /var/run/console/" $ROOT/etc/rc.d/rc.local > /dev/null
if [ $? != 0 ]; then
        echo "" >> $ROOT/etc/rc.d/rc.local
        echo "# Delete pam_console lock and refcount files" >> $ROOT/etc/rc.d/rc.local
        echo "rm -f /var/run/console/*" >> $ROOT/etc/rc.d/rc.local
fi
