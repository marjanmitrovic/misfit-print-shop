#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$root/assets/prints-v3" "$root/assets/prints-light-v3"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

i=0
while IFS= read -r file; do
  src="$root/assets/$file"
  i=$((i+1))
  slug="$(printf '%03d' "$i")"
  normal="$root/assets/prints-v3/$slug.png"
  light="$root/assets/prints-light-v3/$slug.png"

  # Čisti pozadinu sa sva četiri ugla (ne samo iz gornjeg levog), pa čuva
  # isključivo motiv na providnom platnu. Privremeni fajl sprečava oštećene PNG-ove.
  work="$tmpdir/$slug-base.png"
  ntemp="$tmpdir/$slug-normal.png"
  ltemp="$tmpdir/$slug-light.png"
  # Uklanja pozadinu povezanu sa ivicom bez obzira da li je crna ili bela,
  # zatim uklanja čistu crnu iz zatvorenih otvora slova (O, P, R, A...).
  convert "$src" -alpha on -fuzz 18% -fill none -draw 'matte 0,0 floodfill' \
    -fuzz 5% -transparent black -trim +repage "$work"
  convert "$work" -filter Lanczos -resize '1120x966>' -unsharp 0x0.55+0.55+0.02 \
    -gravity center -background none -extent 1400x1190 "$ntemp"

  # Na svetlim majicama pretvara bela i skoro bela slova u tamna,
  # dok žuta, crvena i ostale akcentne boje ostaju netaknute. Pre toga
  # uklanja tamne pravougaone podloge povezane sa uglovima samog motiva.
  read -r ww hh < <(identify -format '%w %h' "$work"; echo)
  wx=$((ww-1)); hy=$((hh-1))
  convert "$work" -alpha on -fuzz 12% -fill none \
    -draw "matte 0,0 floodfill" -draw "matte $wx,0 floodfill" \
    -draw "matte 0,$hy floodfill" -draw "matte $wx,$hy floodfill" \
    -filter Lanczos -resize '1120x966>' -unsharp 0x0.55+0.55+0.02 \
    -gravity center -background none -extent 1400x1190 \
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
