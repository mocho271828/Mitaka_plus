# 公式本文の scalar 経路を参照試験だけへ取り出す。数式・演算順序は書き換えない。
# SSE はプラットフォーム固有なので入口を false に固定し、到達したら失敗させる。
BEGIN {
    names["calc_ray"] = "inline RGBf"
    names["inline_calc_scattered_light_intensity"] = "inline RGBf"
    names["calc_scattered_light_intensity"] = "RGBf"
    names["emMap"] = "inline RGBf"
    names["init_multiple_scattering"] = "void"
    names["free_multiple_scattering_work"] = "void"
    names["calc_multiple_scattered_light_intensity"] = "RGBf"
}
NR == 1 {
    if ($0 !~ /^\/\*/) {
        print "atmosphere reference: missing original license header" > "/dev/stderr"
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
        print "#include \"mtk_approx_func.h\""
        print "#include <cstdio>"
        print "#include <stdexcept>"
        print "typedef vector3<float> RGBf;"
        print "static bool is_SSE_Enable() { return false; }"
        print "static float calc_ray_sub_SSE(vector3d&, const vector3d&, float, int) {"
        print "    throw std::logic_error(\"reference SSE path must remain disabled\");"
        print "}"
    }
    next
}
/^const float lmd_R / { in_constants = 1; ++constants_started }
in_constants {
    print
    if ($0 ~ /^const double sgm_B /) { in_constants = 0; ++constants_complete }
    next
}
/^int msRN;/ { in_globals = 1; ++globals_started }
in_globals {
    print
    if ($0 ~ /^bool bInitMultipleScattering = false;/) { in_globals = 0; ++globals_complete }
    next
}
{
    name = $0
    sub(/\(.*/, "", name)
    if (name in names) {
        previous_type = previous
        sub(/\r$/, "", previous_type)
        if (in_function || previous_type != names[name] || seen[name]++) {
            print "atmosphere reference: unexpected function layout" > "/dev/stderr"
            failed = 1
            exit 1
        }
        print previous
        in_function = 1
    }
    if (in_function) {
        print
        if ($0 ~ /^}\r?$/) { in_function = 0; ++complete }
    }
    previous = $0
}
END {
    if (!failed && (!license_complete || in_function || complete != 7 ||
                   constants_started != 1 || constants_complete != 1 ||
                   globals_started != 1 || globals_complete != 1)) {
        print "atmosphere reference: expected all official functions, constants and globals" > "/dev/stderr"
        exit 1
    }
    if (!failed) {
        # inline 関数への外部試験用入口だけを追加する。本文は上で原文抽出済み。
        print "RGBf reference_atmosphere_single(double R1, double R2, double n0, double H, double I0,"
        print "    const vector3d& r0, const vector3d& ev, const vector3d& lv, int imax) {"
        print "    return inline_calc_scattered_light_intensity(R1, R2, n0, H, I0, r0, ev, lv, imax);"
        print "}"
    }
}
