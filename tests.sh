#!/bin/bash
# Compares every program in this folder with the real system tool.
# Usage:  make && ./tests.sh          (prints PASS/FAIL per check)
cd "$(dirname "$0")"
T=$(mktemp -d)
printf 'hello, world\nfoo  bar baz\nWorld peace\n\nhello again\nlast world' > "$T/a.txt"   # no final \n
printf 'one\ntwo three\nworld\nworld\nworld\nfour\n' > "$T/b.txt"
seq 1 200000 > "$T/big.txt"
: > "$T/empty.txt"
pass=0; fail=0

check() {  # check "description" "our command" "real command"
    local ours real
    ours=$(eval "$2" 2>/dev/null; echo "[exit $?]")
    real=$(eval "$3" 2>/dev/null; echo "[exit $?]")
    if [ "$ours" == "$real" ]; then pass=$((pass+1)); echo "PASS  $1"
    else fail=$((fail+1)); echo "FAIL  $1"; diff <(echo "$ours") <(echo "$real") | head -10; fi
}

A=$T/a.txt; B=$T/b.txt; BIG=$T/big.txt; E=$T/empty.txt

check "cat file"            "./cat $A"              "cat $A"
check "cat 2 files"         "./cat $A $B"           "cat $A $B"
check "cat stdin"           "./cat < $A"            "cat < $A"
check "cat big"             "./cat $BIG"            "cat $BIG"
check "cat empty"           "./cat $E"              "cat $E"

check "grep file"           "./grep world $A"       "grep world $A"
check "grep 2 files"        "./grep world $A $B"    "grep -h world $A $B"
check "grep stdin"          "./grep world < $A"     "grep world < $A"
check "grep no match"       "./grep zzz $A"         "grep zzz $A"
check "grep big"            "./grep 999 $BIG"       "grep 999 $BIG"
check "grep no args"        "./grep"                "grep 2>/dev/null"

check "grep_ext -v"         "./grep_ext -v world $A"     "grep -v world $A"
check "grep_ext -i"         "./grep_ext -i WORLD $A"     "grep -i WORLD $A"
check "grep_ext -c"         "./grep_ext -c world $A"     "grep -c world $A"
check "grep_ext -n"         "./grep_ext -n world $A"     "grep -n world $A"
check "grep_ext -vin"       "./grep_ext -vin WORLD $A"   "grep -vin WORLD $A"
check "grep_ext 2 files"    "./grep_ext -n world $A $B"  "grep -n world $A $B"
check "grep_ext -c 2 files" "./grep_ext -c world $A $B"  "grep -c world $A $B"

check "wc file"             "./wc $A"               "wc $A"
check "wc -l"               "./wc -l $A"            "wc -l $A"
check "wc -w"               "./wc -w $A"            "wc -w $A"
check "wc -c"               "./wc -c $A"            "wc -c $A"
check "wc -lw"              "./wc -lw $A"           "wc -lw $A"
check "wc 2 files"          "./wc $A $B"            "wc $A $B"
check "wc stdin redirect"   "./wc < $A"             "wc < $A"
check "wc stdin pipe"       "cat $A | ./wc"         "cat $A | wc"
check "wc -l pipe"          "cat $A | ./wc -l"      "cat $A | wc -l"
check "wc big + small"      "./wc $BIG $A"          "wc $BIG $A"
check "wc empty"            "./wc $E"               "wc $E"

check "head default"        "./head $BIG"           "head $BIG"
check "head -n 3"           "./head -n 3 $A"        "head -n 3 $A"
check "head -n3"            "./head -n3 $A"         "head -n3 $A"
check "head -2"             "./head -2 $A"          "head -2 $A"
check "head more than file" "./head -n 100 $A"      "head -n 100 $A"
check "head stdin"          "./head -n 2 < $A"      "head -n 2 < $A"
check "head 2 files"        "./head -n 2 $A $B"     "head -n 2 $A $B"
check "head -n 0"           "./head -n 0 $A"        "head -n 0 $A"

check "tail default"        "./tail $BIG"           "tail $BIG"
check "tail -n 3"           "./tail -n 3 $A"        "tail -n 3 $A"
check "tail -n 100"         "./tail -n 100 $A"      "tail -n 100 $A"
check "tail stdin"          "./tail -n 2 < $B"      "tail -n 2 < $B"
check "tail 2 files"        "./tail -n 2 $A $B"     "tail -n 2 $A $B"

check "uniq"                "./uniq $B"             "uniq $B"
check "uniq -c"             "./uniq -c $B"          "uniq -c $B"
check "uniq -d"             "./uniq -d $B"          "uniq -d $B"
check "uniq -u"             "./uniq -u $B"          "uniq -u $B"
check "uniq stdin"          "./uniq < $B"           "uniq < $B"

check "echo"                "./echo a  b   c"       "/bin/echo a  b   c"
check "echo -n"             "./echo -n hi there"    "/bin/echo -n hi there"
check "echo none"           "./echo"                "/bin/echo"
check "true"                "./true"                "/bin/true"
check "false"               "./false"               "/bin/false"

./cp "$A" "$T/copy.txt";  check "cp content"  "cat $T/copy.txt"  "cat $A"
./cp "$B" "$T/copy.txt";  check "cp overwrite" "cat $T/copy.txt" "cat $B"
check "tee stdout+file"     "./tee $T/t1.txt < $A; cat $T/t1.txt"   "tee $T/t2.txt < $A; cat $T/t2.txt"
check "tee -a"              "./tee -a $T/t1.txt < $B >/dev/null; cat $T/t1.txt" "tee -a $T/t2.txt < $B >/dev/null; cat $T/t2.txt"

rm -rf "$T"
echo; echo "passed: $pass   failed: $fail"
