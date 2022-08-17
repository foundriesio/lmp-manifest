#!/bin/sh

set -ex

TOPDIR=$(readlink -f $(dirname $(readlink -f $0))/..)

mkdir -p $TOPDIR/repo
cd $TOPDIR/repo

repo init -b main-next ..
repo sync

cp -v $TOPDIR/next/*.xml $TOPDIR
git commit -s -a -m fecth

repo sync
repo manifest -r --suppress-upstream-revision --suppress-dest-branch -o $TOPDIR/default.xml
git commit -s -a -m freeze
