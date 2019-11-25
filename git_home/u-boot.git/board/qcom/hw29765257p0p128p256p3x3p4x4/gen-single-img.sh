#!/bin/sh

#
# Export qsdk-chipcode.git and generate single image
#
# Wrapper script to export specified qsdk-chipcode.git commit and generate
# single image from it.
#

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
logger -- initial argument is $*

TEMP=`getopt -o w:o:fvh --long \
git-repo:,\
treeish:,\
work-dir:,\
output-dir:,\
force-remove,\
export-only,\
version,\
help,\
     -n "$0" -- "$@"`

if [ $? != 0 ] ; then echo >&2 "Terminating..." ; exit 1 ; fi
eval set -- "$TEMP"

# Whether this script should force removing <work_dir> or not.
force_remove=0

version_string="$0 v0.1.1"

verbose=0

#
# Print usage message
#
usage_msg()
{
cat >&2 << EOF
Usage:
  gen-single-img.sh --git-repo <git_repo_dir>
                    --treeish <treeish>
                    -w|--work-dir <work_dir>
                    [-o|--output-dir <output_dir>]
                    [INPUT_FILES ...]
  gen-single-img.sh -h|--help

  When specified properly, this script export git commit <treeish> of
  qsdk-chipcode git repository located under <git_repo_dir> to <work_dir>, and
  optionally put generated single images to <output_dir>.

Required arguments:
  --git-repo <git_repo_dir>
      <git_repo_dir> is path to qsdk-chipcode.git repository to be exported

  --treeish <treeis>
      <treeis> of qsdk-chipcode.git treeish to be exported

  -w,--work-dir <work_dir>
      export qsdk-chipcode.git to <work_dir>

      <work_dir> should be empty or not exist. Otherwise, this script will
      stop with error code returned.

Options:
  -o,--output-dir <output_dir>
      Put generated single images to <output_dir>.

  -f,--force-remove
      Force removing <work_dir> even when it is not empty.

  --export-only
      Only export qsdk-chipcode.git to <work_dir>.

  -h,--help  Show this help message
  -v         verbose
EOF
}

#
# Notify possible place to get desired git commit
#
fetch_instruction_msg()
{
    cat >&2 << EOF
Please fetch $treeish of qsdk-chipcode.git from:
    ssh://itgserver/pub/scm/qualcomm-lsdk/george/qsdk-chipcode.git

You can try replacing "george" with another name if URL above does not work for you.
EOF
}

while true ; do
    case "$1" in
        --git-repo)
            git_repo_dir="$2"
            shift 2
            ;;
        --treeish)
            treeish="$2"
            shift 2
            ;;
        -w|--work-dir)
            work_dir="$2"
            shift 2
            ;;
        -o|--output-dir)
            output_dir="$2"
            shift 2
            ;;
        -f|--force-remove)
            force_remove=1
            shift 1
            ;;
        --export-only)
            export_only=1
            shift 1
            ;;
        -v)
            verbose=1
            shift 1
            ;;
        --version)
            echo $version_string
            exit 1
            ;;
        -h|--help)
            usage_msg
            exit 1
            ;;
        --) shift ; break ;;
        *) exit 1 ;;
    esac
done
input_files="$@"

##### Check whether all necessary arguments are supplied. #####
lack_required_args=0
if [ -z "$git_repo_dir" ]; then
    echo >&2 "ERROR: --git-repo is not specified!"
    lack_required_args=1
fi

if [ -z "$treeish" ]; then
    echo >&2 "ERROR: --treeish is not specified!"
    lack_required_args=1
fi

if [ -z "$work_dir" ]; then
    echo >&2 "ERROR: --work-dir is not specified!"
    lack_required_args=1
fi

if [ "$lack_required_args" -eq 1 ]; then
    exit 1
fi

##### Check whether specified arguments are valid. #####
if [ ! -d "$git_repo_dir" ]; then
    cat >&2 << EOF
ERROR: <git_repo_dir> is not a directory:
    $git_repo_dir
EOF
    exit 1
fi

if [ "$output_dir" ] && [ ! -d "$output_dir" ]; then
    cat >&2 << EOF
ERROR: <output_dir> is not a directory:
    $output_dir
EOF
    exit 1
fi

(
    cd "$git_repo_dir"
    git cat-file -p "$treeish" >/dev/null
)
if [ "$?" -ne "0" ]; then
    fetch_instruction_msg
    exit 1
fi

work_dir_has_something=$(ls -A "$work_dir" 2>/dev/null | wc -l)
if [ "$work_dir_has_something" -ne "0" ]; then
    if [ "$force_remove" -ne "0" ]; then
        rm -rf "$work_dir"
    else
        cat >&2 << EOF
ERROR: <work_dir> should be empty or not exist:
    $work_dir

Specify --force-remove if you want to force removing non-empty <work_dir>.
EOF
        exit 1
    fi
fi

##### Finally, enter main program. #####

# Export qsdk-chipcode
mkdir -p "$work_dir"
abs_work_dir="$(readlink -m "$work_dir")"
echo >&2 -n "Export $treeish ... "
(
    cd "$git_repo_dir"
    git archive --format=tar $treeish | tar -C "$abs_work_dir" -xf -
)
if [ "$?" -ne "0" ]; then
    echo >&2 "BUG: Unexpected error when exporting $treeish !!"
    exit 1
fi
echo >&2 "done"

if [ "$export_only" -ne "0" ]; then
    exit 0
fi

# Copy input files into qsdk-chipcode and generate single images
if [ "$@" ]; then
    echo >&2 -n "Copying input files ... "
    cp -t "$work_dir"/common/build/ipq/ $@ || exit 1
    echo >&2 "done"
fi

echo >&2 -n "Generating single images ... "
(
    cd "$work_dir"/common/build/ && python update_common_info.py
)

if [ "$output_dir" ]; then
    echo >&2 -n "Copying single images to $output_dir ... "
    cp -t "$output_dir" "$work_dir"/common/build/bin/*.img
    echo >&2 "done"
fi

exit 0
