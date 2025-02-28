#!/bin/bash
export LC_ALL=C
set -e
CC="${TEST_CC:-cc}"
CXX="${TEST_CXX:-c++}"
GCC="${TEST_GCC:-gcc}"
GXX="${TEST_GXX:-g++}"
MACHINE="${MACHINE:-$(uname -m)}"
testname=$(basename "$0" .sh)
echo -n "Testing $testname ... "
t=out/test/elf/$MACHINE/$testname
mkdir -p $t

cat <<EOF | $CC -o $t/a.o -c -xc -
void foo() {}
void bar1() {}

__asm__(".symver foo, foo@TEST");
__asm__(".symver bar1, bar@TEST");
EOF

cat <<EOF > $t/b.version
TEST {
global:
  foo;
  bar;
};
EOF

$CC -B. -o $t/c.so -shared $t/a.o -Wl,--version-script=$t/b.version
readelf -W --dyn-syms $t/c.so > $t/log

grep -q ' foo@TEST$' $t/log
grep -q ' bar@TEST$' $t/log
grep -q ' bar1$' $t/log
! grep -q ' foo@@TEST$' $t/log || false

echo OK
