#!/bin/bash

echo "Hello"

package_name="xxl-job-admin-2.4.1"

mkdir -p $package_name/bin
mkdir -p $package_name/lib
mkdir -p $package_name/conf
mkdir -p $package_name/work

./mvnw clean install -Dmaven.test.skip=true
cp xxl-job-admin/target/${package_name}.jar ./$package_name/lib
cp ./jvm.options ./$package_name/bin
cp ./run.sh ./$package_name/bin

tree -L 2 $package_name

tar -czvf $package_name.tar.gz ./$package_name
