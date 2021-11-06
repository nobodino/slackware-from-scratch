#!/bin/bash
cp -v gcc.SlackBuild gcc.SlackBuild.old
sed -i -e 's/$PKG{1,2,3,4,6,8,9,10}/$PKG{1,2}/g' gcc.SlackBuild
sed -i -e 's/ada,brig,c,c++,d,fortran,go,lto,objc,obj-c++/c,c++/g' gcc.SlackBuild
sed -i -e '82,87d;142,148d;158,164d;171,173d;208,312d;382,390d;434d;446,454d;467,472d;518,631d;637,648d' gcc.SlackBuild
