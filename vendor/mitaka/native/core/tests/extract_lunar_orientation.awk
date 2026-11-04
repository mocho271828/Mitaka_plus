# 公式の月角度と衛星姿勢行列だけを、本文・許諾表示を変えず比較用に取り出す。
# 月だけのディスパッチはテスト側が提供し、他の衛星や描画依存を持ち込まない。
BEGIN {
    names["calc_moon_orientation_angle"] = 1
    names["calc_satellite_ec_to_sat_matrix"] = 1
}
NR == 1 {
    if ($0 !~ /^\/\*/) {
        print "lunar reference: missing original license header" > "/dev/stderr"
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
        print "void calc_satellite_orientation_angle(int, const double&, double&, double&, double&);"
    }
    next
}
{
    name = $0
    sub(/\(.*/, "", name)
    if (name in names) {
        if (in_function || previous !~ /^void\r?$/ || seen[name]++) {
            print "lunar reference: unexpected function layout" > "/dev/stderr"
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
    if (!failed && (!license_complete || in_function || complete != 2)) {
        print "lunar reference: expected two complete official functions" > "/dev/stderr"
        exit 1
    }
}
