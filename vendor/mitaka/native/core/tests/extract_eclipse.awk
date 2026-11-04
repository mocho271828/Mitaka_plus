# 保存済み公式ファイルから単独の円盤面積関数を抽出する。式は変更しない。
/^calc_eclipse_fraction\(/ { print "double"; copying = 1 }
copying {
    sub(/\r$/, "")
    sub(/\/\/.*/, "")
    print
    if ($0 ~ /^}/) exit
}
