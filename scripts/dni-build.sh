#!/bin/sh

GIT_HOME=$1
PWD=$(pwd)

CHIPCODE_GIT_REPO="$GIT_HOME/qsdk-chipcode.git"
CHIPCODE_TREEISH=206f34d6ca9d3621d28528c60dac0c265cc06ad3
SINGLE_IMG_OUTPUT_DIR="$PWD/bin/ipq806x/bin-single-imgs/"

prepare()
{
	./scripts/prepare-kernel.sh --linux-git-repo "$GIT_HOME/linux.git"

	./scripts/feeds update -a
	./scripts/feeds install -a -f
}

build_img()
{
	cp qca/configs/qsdk/ipq806x_premium.config .config

	make defconfig
	for pkg_num in 2 9; do
		sed 's/CONFIG_PACKAGE_qca-wifi-fwhw'${pkg_num}'-10.4-asic=y/#CONFIG_PACKAGE_qca-wifi-fw-hw'${pkg_num}'-10.4-asic is not set/g' -i .config
	done
	sed 's/CONFIG_PACKAGE_kmod-wil6210=y/# CONFIG_PACKAGE_kmod-wil6210 is not set/g' -i .config
	sed 's/CONFIG_PACKAGE_wigig-firmware=y/# CONFIG_PACKAGE_wigig-firmware is not set/g' -i .config

	make GIT_HOME=$GIT_HOME V=sc || exit
}

build_single_img()
{
	mkdir "$SINGLE_IMG_OUTPUT_DIR"
	./scripts/gen-single-img.sh --force-remove --git-repo "$CHIPCODE_GIT_REPO" --treeish $CHIPCODE_TREEISH \
			-w "$PWD/build_dir/host/qsdk-chipcode-$CHIPCODE_TREEISH" -o "$SINGLE_IMG_OUTPUT_DIR" \
			"$PWD/bin/ipq806x/"openwrt*
}


case "$2" in
prepare)
    prepare
    ;;
build)
	build_img
    ;;
build_single_img)
    build_single_img
    ;;
all)
    prepare
	build_img
    build_single_img
    ;;
*)
    echo "Usage: $0 /path/to/git-home {all|prepare|build|build_single_img}"
    ;;
esac

