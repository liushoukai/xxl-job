#!/bin/bash

# 严格模式
set -euo pipefail # 兼容性写法（部分 shell 可能不支持 pipefail）
shopt -s failglob nullglob

# 调试模式（按需启用），用法：DEBUG=true ./your_script.sh
if [[ "${DEBUG:-}" == "true" ]]; then
  set -xv
fi

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

rm -rf $package_name