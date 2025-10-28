#!/bin/bash

echo "Hello"

package_name="xxl-job-admin-3.2.1"

mkdir -p $package_name/bin
mkdir -p $package_name/lib
mkdir -p $package_name/conf
mkdir -p $package_name/work/log

JAVA_HOME=$(/usr/libexec/java_home -v 21.0.1) ./mvnw clean install -Dmaven.test.skip=true -Dgpg.skip=true
cp xxl-job-admin/target/xxl-job-admin-*.jar ./$package_name/lib
cp ./jvm.options ./$package_name/bin
cp ./manager.sh ./$package_name/bin
cp ./xxl-job-admin/src/main/resources/application*.properties ./$package_name/conf

tar -czvf $package_name.tar.gz ./$package_name

tree -L 2 $package_name