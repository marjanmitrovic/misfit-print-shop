#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$root/assets/prints" "$root/assets/prints-light"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

i=0
while IFS= read -r file; do
  src="$root/assets/$file"
  i=$((i+1))
  slug="$(printf '%03d' "$i")"
  normal="$root/assets/prints/$slug.png"
  light="$root/assets/prints-light/$slug.png"

  # Čisti pozadinu sa sva četiri ugla (ne samo iz gornjeg levog), pa čuva
  # isključivo motiv na providnom platnu. Privremeni fajl sprečava oštećene PNG-ove.
  work="$tmpdir/$slug-base.png"
  ntemp="$tmpdir/$slug-normal.png"
  ltemp="$tmpdir/$slug-light.png"
  convert "$src" -alpha on -bordercolor black -border 2 -fuzz 22% -fill none \
    -draw 'matte 0,0 floodfill' \
    -shave 2x2 -trim +repage "$work"
  convert "$work" -resize '800x690>' -gravity center -background none \
    -extent 1000x850 "$ntemp"

  # Na svetlim majicama pretvara bela i skoro bela slova u tamna,
  # dok žuta, crvena i ostale akcentne boje ostaju netaknute. Pre toga
  # uklanja tamne pravougaone podloge povezane sa uglovima samog motiva.
  read -r ww hh < <(identify -format '%w %h' "$work")
  wx=$((ww-1)); hy=$((hh-1))
  convert "$work" -alpha on -fuzz 12% -fill none \
    -draw "matte 0,0 floodfill" -draw "matte $wx,0 floodfill" \
    -draw "matte 0,$hy floodfill" -draw "matte $wx,$hy floodfill" \
    -resize '800x690>' -gravity center -background none -extent 1000x850 \
    -channel RGB -fuzz 18% -fill '#151515' -opaque white "$ltemp"
  mv "$ntemp" "$normal"
  mv "$ltemp" "$light"
done < <(node - "$root" <<'NODE'
const fs=require('fs');
const root=process.argv[2];
const s=fs.readFileSync(root+'/app.js','utf8');
const block=s.match(/const productFiles=\[([\s\S]*?)\];/)[1];
for(const f of Function('return ['+block+']')()) console.log(f);
NODE
)
