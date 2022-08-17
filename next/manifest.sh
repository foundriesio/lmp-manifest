#!/bin/sh

set -ex

TOPDIR=$(readlink -f $(dirname $(readlink -f $0))/..)
BRANCH=$(git rev-parse --abbrev-ref HEAD)

mkdir -p $TOPDIR/repo
cd $TOPDIR/repo

_repo(){
repo init -b $BRANCH ..
repo sync --detach
repo manifest -r --suppress-upstream-revision --suppress-dest-branch -o $TOPDIR/default.xml
}

_repo
git commit -s -a -m "next: current [run: $0]"

cp $TOPDIR/next/*.xml $TOPDIR
git checkout HEAD~1 -- $TOPDIR/default.xml
git commit -s -a -m "next: freeze [run: $0]"
_repo
git commit --all --amend --no-edit
