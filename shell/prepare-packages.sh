#!/bin/sh
# 收集第三方 apk 到 packages/ 目录 (供 ImageBuilder 的 make image 使用)
#
# szwjp/luci 仓库结构: 一级子目录对应一个软件, 目录内为该软件的 .apk;
# 该仓库整体被复制到 WORK_DIR/extra-packages/, 由本脚本整理到 WORK_DIR/packages/。
#
# 同一包名在仓库里可能出现多份 (不同版本, 或同版本不同内容), 直接平铺会让结果
# 依赖 find 的遍历顺序。这里给出确定的取舍规则:
#   1) 同包名多版本   -> 保留版本号最高者 (版本号取自文件名, 与 apk 内部一致)
#   2) 版本号相同     -> 保留 EXTERNAL_APK_PRIORITY 中靠前的目录, 未命中则保留
#                        目录名字典序靠前者, 并把被舍弃的一方打印出来
# 保留下来的包与官方源同名包并存, 按设计优先使用本地这一份。
#
# 环境变量:
#   EXTERNAL_APK_PRIORITY  目录优先级, 空白分隔, 例: "passwall pwcore"
#   PREPARE_PACKAGES_MODE  默认 full: 整理 extra-packages 下全部包
#                          strict: 只整理 $1 中实际用到的包(避免白复制与过期版本)
set -eu

MODE="${PREPARE_PACKAGES_MODE:-full}"
REQUESTED="${1-}"

BASE_DIR="extra-packages"
TARGET_DIR="packages"

if [ ! -d "$BASE_DIR" ]; then
  echo "❌ 未找到 $BASE_DIR 目录" >&2
  exit 1
fi

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

WORK_LIST=$(mktemp)
WINNERS=$(mktemp)
trap 'rm -f "$WORK_LIST" "$WINNERS"' EXIT

# 由 apk 文件名推出包名: 去掉第一个以数字开头的段及其后的版本号
# 例: luci-app-quickfile-1.0.0-r99.apk -> luci-app-quickfile
apk_pkgname() {
  printf '%s\n' "$1" | awk -F- '{
    n=NF
    for (i=2; i<=NF; i++) if ($i ~ /^[0-9]/) { n=i-1; break }
    out=""
    for (i=1; i<=n; i++) out = out (i>1 ? "-" : "") $i
    print out
  }'
}

# 版本比较: $1 比 $2 新则输出 1
# 规则与 apk 大体一致: 先剥掉 -rN 发布号再逐段比较; 纯数字段比数值, 其余比字典序
# 额外处理一类真实存在的写法差异: 20260529193437-r1 与 202606182327.1 属同一
# "时间戳"版本体系, 但它们的分段不同(14位数字 vs 12位数字+小数段), 直接比较会
# 因段数多而误判前者更新。这里识别前 8 位为纯日期的版本, 按 yyyymmdd + 剩余部分比较。
apk_is_newer() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    if (b == "") { print 1; exit }
    if (a == "") { print 0; exit }
    va_up=a; vb_up=b
    sub(/-r[0-9]+$/, "", va_up); sub(/-r[0-9]+$/, "", vb_up)
    va_rel=0; vb_rel=0
    if (a ~ /-r[0-9]+$/) { va_rel=a; sub(/^.*-r/, "", va_rel); va_rel+=0 }
    if (b ~ /-r[0-9]+$/) { vb_rel=b; sub(/^.*-r/, "", vb_rel); vb_rel+=0 }
    r = version_cmp(va_up, vb_up)
    if (r != 0) { print r; exit }
    if (va_rel > vb_rel) { print 1; exit }
    if (va_rel < vb_rel) { print 0; exit }
    print 0
  }
  function version_cmp(a, b,   na, nb, i, xa, xb, x, y, ra, rb) {
    if (b == "") return 1
    if (a == "") return 0
    if (a ~ /^[0-9]{8}/ && b ~ /^[0-9]{8}/) {
      if (substr(a,1,8) != substr(b,1,8)) return (substr(a,1,8) > substr(b,1,8)) ? 1 : -1
      ra=a; rb=b; gsub(/[^0-9A-Za-z]/, "", ra); gsub(/[^0-9A-Za-z]/, "", rb)
      if (ra == rb) return 0
      if (length(ra) != length(rb)) return (length(ra) > length(rb)) ? 1 : -1
      return (ra > rb) ? 1 : -1
    }
    na=split(a,x,/[^0-9A-Za-z]+/); nb=split(b,y,/[^0-9A-Za-z]+/)
    for (i=1; i<=na || i<=nb; i++) {
      if (i>nb) return 1
      if (i>na) return -1
      if (x[i] ~ /^[0-9]+$/ && y[i] ~ /^[0-9]+$/) { xa=x[i]+0; xb=y[i]+0 }
      else { xa=x[i] ""; xb=y[i] "" }
      if (xa > xb) return 1
      if (xa < xb) return -1
    }
    return 0
  }'
}

# 生成候选清单: 优先级目录在前(rank 小), 其余按目录名/文件名排序, 保证顺序稳定
: > "$WORK_LIST"
find "$BASE_DIR" -mindepth 2 -maxdepth 2 -type f -name '*.apk' | LC_ALL=C sort | while IFS= read -r f; do
  rank=9999
  if [ -n "${EXTERNAL_APK_PRIORITY:-}" ]; then
    i=0
    for d in $EXTERNAL_APK_PRIORITY; do
      i=$((i + 1))
      case "$f" in
        "$BASE_DIR/$d/"*) rank=$i; break ;;
      esac
    done
  fi
  printf '%s\t%s\n' "$rank" "$f"
done > "$WORK_LIST"
LC_ALL=C sort -k1,1n -k2,2 "$WORK_LIST" -o "$WORK_LIST"

total=0; replaced=0; skipped=0
while IFS="$(printf '\t')" read -r rank path; do
  [ -f "$path" ] || continue
  total=$((total + 1))
  base=$(basename "$path")
  name=$(apk_pkgname "$base")
  ver=${base#"$name"-}
  ver=${ver%.apk}

  if [ "$MODE" = "strict" ]; then
    case " $REQUESTED " in
      *" $name "*) ;;
      *) skipped=$((skipped + 1)); continue ;;
    esac
  fi

  prev=$(awk -F'\t' -v n="$name" '$1==n {print $2"\t"$3"\t"$4; exit}' "$WINNERS" || true)
  if [ -z "$prev" ]; then
    cp -f "$path" "$TARGET_DIR/"
    printf '%s\t%s\t%s\t%s\n' "$name" "$rank" "$path" "$ver" >> "$WINNERS"
    continue
  fi

  prev_path=$(printf '%s' "$prev" | cut -f2)
  prev_ver=$(printf '%s' "$prev" | cut -f3)
  if [ "$(apk_is_newer "$ver" "$prev_ver")" = "1" ]; then
    echo "♻️  $name: 保留更高版本 $ver, 取代 $(basename "$prev_path") ($prev_ver)"
    rm -f "$TARGET_DIR/$(basename "$prev_path")"
    cp -f "$path" "$TARGET_DIR/"
    old=$(awk -F'\t' -v n="$name" '$1==n {next} {print}' "$WINNERS")
    printf '%s\t%s\t%s\t%s\n' "$name" "$rank" "$path" "$ver" > "$WINNERS"
    if [ -n "$old" ]; then printf '%s\n' "$old" >> "$WINNERS"; fi
    replaced=$((replaced + 1))
  else
    if [ "$ver" = "$prev_ver" ]; then
      echo "⚠️  $name: 版本号相同($ver), 保留 $prev_path, 舍弃 $path (内容可能不同)"
    else
      echo "⏭️  $name: 跳过较低版本 $ver (已保留 $(basename "$prev_path"))"
    fi
    skipped=$((skipped + 1))
  fi
done < "$WORK_LIST"

kept=$(wc -l < "$WINNERS" | tr -d ' ')
echo "✅ .apk 已整理至 $TARGET_DIR/ (候选 $total, 保留 $kept, 跳过 $skipped, 版本升级替换 $replaced)"
