#!/bin/bash
# The 8 store screenshots in one language at one size.
#   bash tools/store_shots.sh <lang> <WxH> <outdir>
#   lang: vi | zh_Hant | ko | en
# Sizes used: phone 1920x1080, tablet-7in 1920x1200, tablet-10in 2560x1600,
# iphone-6.3 2622x1206, ipad-13 = 2544x1908 then x1.08 to 2752x2064 (Godot
# windows can't be taller than the monitor). Check the sizes afterwards:
# a window bigger than the screen sometimes comes out clamped.
LANG_=$1; RES=$2; O=$3
G=${GODOT:-~/tools/godot/Godot_v4.7.2-stable_win64_console.exe}
T=$O/_tmp
cd "$(dirname "$0")/.."
mkdir -p "$O" "$T"
# fighter names in the language's own script (English keeps the Vietnamese)
case $LANG_ in
  zh_Hant) N=(凌風 玄智 雪兒 唐影 黑月 蕭酒 莫雲) ;;
  ko)      N=(능풍 현지 설아 당영 흑월 소주 막운) ;;
  *)       N=("Lăng Phong" "Huyền Trí" "Tuyết Nhi" "Đường Ảnh" "Hắc Nguyệt" "Tiêu Tửu" "Mạc Vân") ;;
esac
F="--pad --fullen --wglow=10 --lang=$LANG_"
run() { timeout 120 "$G" --path . --resolution "$RES" -- "$@" >/dev/null 2>&1; }
run --fighttest --p=vo_dang --e=thieu_lam --theme=peak --pname="${N[0]}" --ename="${N[1]}" $F --shot=$T/a.png --shotat=560
run --fighttest --p=nga_mi --e=duong_mon --theme=bamboo --pname="${N[2]}" --ename="${N[3]}" $F --shot=$T/b.png --shotat=420
run --fighttest --p=thieu_lam --e=nga_mi --theme=night --pname="${N[0]}" --ename="${N[4]}" --ehp=0.12 --rounds=1 --lang=$LANG_ --shot=$T/k.png
run --fighttest --p=cai_bang --e=vo_dang --theme=snow --pname="${N[5]}" --ename="${N[6]}" $F --shot=$T/c.png --shotat=420
for sc in create skill forge hub; do run --screen=$sc --sect=vo_dang --delay=90 --notoast --lang=$LANG_ --shot=$T/s_$sc.png; done
mv $T/a_560.png $O/01-quyet-dau.png
mv $T/b_420.png $O/02-truc-lam.png
mv $T/k_ink12.png $O/03-ket-lieu.png
mv $T/c_420.png $O/04-tuyet-son.png
mv $T/s_create.png $O/05-bai-su.png
mv $T/s_skill.png $O/06-vo-cong.png
mv $T/s_forge.png $O/07-lo-ren.png
mv $T/s_hub.png $O/08-giang-ho.png
rm -rf $T
ls $O
