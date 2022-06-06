ARCHIVE_ORIG=$(/bin/ls v*.tar.gz)
NEW_BASENAME="sc-im-$(basename $ARCHIVE_ORIG .tar.gz | cut -b2-)"
rm -rf ${NEW_BASENAME}*
tar xf $ARCHIVE_ORIG
# Dump this stuff:
rm -rf $NEW_BASENAME/{examples,screenshots}
tar cf ${NEW_BASENAME}.tar ${NEW_BASENAME}
plzip -9 ${NEW_BASENAME}.tar
rm -f ${ARCHIVE_ORIG}
rm -rf ${NEW_BASENAME}
