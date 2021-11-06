#!/bin/bash

new_tools_selector ( ) {
#*****************************
echo "A copy of 'tools.tar.?z' has been found."
echo "if you wish to untar this for your tools directory, select 'old'. "
echo "otherwise select 'new' to build a new tools directory."
echo "If you desire to quit, select 'quit'. "
PS3="Your choice: "
	select NEW_TOOLS in old new quit 
	do
		if [ "$NEW_TOOLS" != "quit" ]
		then
			return 2
		elif [ "$NEW_TOOLS" = "old" ]
		then
			return 0
		elif [ "$NEW_TOOLS" = "new" ]
		then
			return 1
		fi
	done
}

tools_test () {
#*****************************
for f in "$PATDIR"/"$TOOLS_DIR"/* ; do
	[ -e "$f" ] && new_tools_selector || echo "no copy of 'tools.tar.?x' has been found"
	break
done
}


new_tools_selector ( ) {
#*****************************
echo "A copy of 'tools.tar.?z' has been found."
echo "if you wish to untar this for your tools directory, select 'old'. "
echo "otherwise select 'new' to build a new tools directory."
echo "If you desire to quit, select 'quit'. "
PS3="Your choice: "
	select new_tools in old new quit; do
		case $new_tools in
			old  ) return 0 ;;
			new  ) return 1 ;;
			*    ) return 2 ;;
		esac
	done
}

tools_test_new () {
#*****************************
file_path="$PATDIR"/"$TOOLS_DIR"/tools.tar.?z
[ -e "$file_path" ] && new_tools_selector || echo "no copy of 'tools.tar.?x' has been found"
exit 1
}
