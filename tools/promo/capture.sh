#!/bin/bash
# Records the promo gameplay clips with Godot's Movie Maker (fixed 30 fps,
# game sound effects, no music) and encodes clips/<id>.mp4 (+ its audio).
# usage: FF=<ffmpeg bin dir> bash capture.sh [ids...]
set -e
cd "$(dirname "$0")"
G=~/tools/godot/Godot_v4.7.2-stable_win64_console.exe
P=$(cd ../.. && pwd)
mkdir -p clips frames
# Movie Maker records at the window size and ignores --resolution: force 1080p
# with a temporary override.cfg (removed again on exit).
printf '[display]

window/size/window_width_override=1920
window/size/window_height_override=1080
' > "$P/override.cfg"
trap 'rm -f "$P/override.cfg"' EXIT
F="--promo --nomusic --fullen --wglow=13"
# 1.2.1 promo (_wb): Cao graphics, max weapon aura (glow level 4 = +15)
F2="--promo --nomusic --fullen --gfx=2 --wglow=4"
declare -A ARGS=(
  [a]="--fighttest --p=vo_dang --e=thieu_lam --theme=peak --pname=Lăng+Phong --ename=Huyền+Trí $F"
  [b]="--fighttest --p=nga_mi --e=duong_mon --theme=bamboo --pname=Tuyết+Nhi --ename=Đường+Ảnh $F"
  [c]="--fighttest --p=cai_bang --e=vo_dang --theme=snow --pname=Tiêu+Tửu --ename=Mạc+Vân $F"
  [d]="--fighttest --p=thieu_lam --e=cai_bang --theme=desert --pname=Huyền+Không --ename=Lỗ+Bát $F"
  [w]="--fighttest --boss --wb=0 --p=vo_dang --pname=Lăng+Phong $F2"
  [v]="--fighttest --boss --wb=1 --p=nga_mi --pname=Tuyết+Nhi $F2"
  [n]="--fighttest --p=thieu_lam --e=nga_mi --theme=night --pname=Huyền+Không --ename=Nguyệt+Cung+Chủ --nm $F2"
  [x]="--fighttest --p=vo_dang --e=nga_mi --theme=night --pname=Lăng+Phong --ename=Hàn+Nguyệt+Cơ --ehp=0.05 --rounds=1 --nm $F2"
  [k]="--fighttest --p=thieu_lam --e=nga_mi --theme=night --pname=Lăng+Phong --ename=Hắc+Nguyệt --ehp=0.05 --rounds=1 $F"
)
IDS=${@:-a b c d k}
for id in $IDS; do
  N=450; [ $id = k ] && N=900; [ $id = x ] && N=900
  rm -rf frames/$id; mkdir -p frames/$id
  # names: "+" -> " " (keeps the bash array simple)
  args=()
  for w in ${ARGS[$id]}; do args+=("${w//+/ }"); done
  timeout 600 $G --path "$P" --resolution 1920x1080 --fixed-fps 30 --write-movie "$(pwd)/frames/$id/f.png" --quit-after $N -- "${args[@]}" >/dev/null 2>&1 || true
  n=$(ls frames/$id/*.png | wc -l)
  "$FF/ffmpeg" -hide_banner -loglevel error -y -framerate 30 -i frames/$id/f%08d.png -i frames/$id/f.wav \
    -c:v libx264 -crf 16 -preset medium -pix_fmt yuv420p -c:a pcm_s16le clips/$id.mkv
  rm -rf frames/$id
  echo "$id: $n frames"
done
