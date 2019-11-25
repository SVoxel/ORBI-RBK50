#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
logger -- initial argument is $*

## Please modify this section for sepcific board
LINUX_VERSION=""
LINUX_TREEISH="9111369f4bf370516cb6dfd477eef86032599220"
#
# For newer git which cannot archive through commit ID
#
#LINUX_TREEISH="m/release"
#######################################################
dest_dir="$(dirname $0)/../qca/src"

TEMP=`getopt -o vh --long \
help,\
git-home:,\
linux-git-repo: \
     -n "$0" -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
eval set -- "$TEMP"

verbose=0

usage_msg()
{
cat << EOF
Usage: $0 [options] (--git-home|--linux-git-repo) /path/to/target/dir/

Command switches:
  --git-home          git-home directory (will use git-home/linux.git)
  --linux-git-repo    git repository URL

Options:
  -h,--help  Show this help message
  -v         verbose
EOF
  exit 1
}

while true ; do
    case "$1" in
	-h|--help)
                usage_msg
                exit
                ;;
	--linux-git-repo)
                LINUX_GIT_REPO="$2"
                shift 2
                ;;
	--git-home)
                GIT_HOME="$2"
                shift 2
                ;;
	-v)
                verbose=1
                shift 1
                ;;
	--) shift ; break ;;
	*) exit 1
	   ;;
    esac
done

if [ "x$LINUX_GIT_REPO" = "x" ]; then
    if [ "x$GIT_HOME" = "x" ]; then
        echo "ERROR: \"--linux-git-repo\" or \"--git-home\" must be specified!!"
        usage_msg
        exit 1
    fi
    LINUX_GIT_REPO="$GIT_HOME/linux${LINUX_VERSION}.git"
fi

if [ ! -d "$LINUX_GIT_REPO" ]; then
    echo "ERROR: Directory \"$LINUX_GIT_REPO\" does not exist!"
    exit 1
fi

(cd "$LINUX_GIT_REPO" && git cat-file -e $LINUX_TREEISH)
if [ "$?" -ne "0" ]; then
    echo "ERROR: Treeish \"$LINUX_TREEISH\" does not exist in $LINUX_GIT_REPO"
    exit 1
fi

# dni-netfilter
#if [ "x$NETFILTER_TREEISH" != "x" ]; then
#    [ -d $GIT_HOME/dni-netfilter.git ] || exit 1
#    (cd $GIT_HOME/dni-netfilter.git && git cat-file -e $NETFILTER_TREEISH) || exit 1
#fi
#test -d "$dest_dir" || exit 1

## prepare Linux kernel
echo -n "Fetch $LINUX_TREEISH ... "
(git clone --shared $LINUX_GIT_REPO $dest_dir/linux-3.14 && cd "$dest_dir/linux-3.14" && git checkout $LINUX_TREEISH)
echo "done"

# dni-netfilter
#if [ "x$NETFILTER_TREEISH" != "x" ]; then
#    echo -n "Fetch $NETFILTER_TREEISH ... "
#    (cd "$dest_dir" && git archive --format=tar --prefix=linux/ --remote=$GIT_HOME/dni-netfilter.git $NETFILTER_TREEISH | tar -xf - linux/include/net/netfilter linux/include/linux/netfilter linux/include/linux/netfilter_ipv6 linux/include/linux/netfilter_ipv4 linux/net/netfilter linux/net/ipv6/netfilter linux/net/ipv4/netfilter)
#    echo "done"
#fi

exit 0
