# 公式 1.3.1 の固定された関数だけを、本文と許諾表示を変えず比較用に取り出す。
# 構造が変わった原本を部分的に取り込まないよう、対象と終端を確認する。
BEGIN {
    names["calc_planet_orientation_angle"] = 1
    names["calc_Earth_ec_to_pl_matrix_Captine2003"] = 1
    names["calc_planet_ec_to_pl_matrix"] = 1
}
NR == 1 {
    if ($0 !~ /^\/\*/) {
        print "rotation reference: missing original license header" > "/dev/stderr"
        failed = 1
        exit 1
    }
    in_license = 1
}
in_license {
    print
    if ($0 ~ /\*\//) {
        in_license = 0
        license_complete = 1
        print "#include \"vector3.h\""
        print "#include \"astro_const.h\""
    }
    next
}
{
    name = $0
    sub(/\(.*/, "", name)
    if (name in names) {
        if (in_function || previous !~ /^void\r?$/ || seen[name]++) {
            print "rotation reference: unexpected function layout" > "/dev/stderr"
            failed = 1
            exit 1
        }
        print previous
        in_function = 1
    }
    if (in_function) {
        print
        if ($0 ~ /^}\r?$/) {
            in_function = 0
            ++complete
        }
    }
    previous = $0
}
END {
    if (!failed && (!license_complete || in_function || complete != 3)) {
        print "rotation reference: expected three complete official functions" > "/dev/stderr"
        exit 1
    }
}
