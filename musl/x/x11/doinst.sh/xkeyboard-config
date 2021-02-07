# This has to assume the use of upgradepkg to work.
# Ever wondered why we install new packages twice?
# Here's an example:
if [ -d etc/X11/xkb/symbols/pc ]; then
  mv etc/X11/xkb etc/X11/xkb.old.bak.$$
  mkdir -p etc/X11/xkb/rules etc/X11/xkb
fi
