#!/bin/bash

startDate=`/bin/date`
revision=""
upload=1
ql=1

while [ "$#" -gt 0 ]
do
    case "$1" in
        --revision|-r)
                revision="-r $2"
                upload=0
                break
                ;;
        *)
                echo "$CMDNAME: invalid option: $1" 1>&2
                exit 1
                ;;
    esac
    shift
done


xcodebuild=/Developer/usr/bin/xcodebuild

echo cleaning.
rm -rf /tmp/letters

cd /tmp

echo "doing remote checkout ($revision)"
git clone git://github.com/ccgus/letters.git
#cp -r ~/Projects/letters .

cd /tmp/letters

v=`git log --pretty=oneline | wc -l | sed -e "s/ //g"`

echo setting build id to $v
sed -e "s/BUILDID/$v/g"  resources/Letters-Info.plist > resources/Letters-Info.plist.tmp
mv resources/Letters-Info.plist.tmp resources/Letters-Info.plist

function buildTarget {
    
    echo Building "$1"
    
    $xcodebuild -target "$1" -configuration Release OTHER_CFLAGS="-DHAVE_CONFIG_H"
    
    if [ $? != 0 ]; then
        echo "****** Bad build for $1 ********"
        say "Bad build for $1"
        exit
    fi
}

buildTarget "Letters"

echo "done building"

open /tmp/letters/build/Release
