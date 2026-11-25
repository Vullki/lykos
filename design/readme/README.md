# README artwork

`showcase.html` lays the four screenshots in `docs/screenshots/` out in matching phone frames. It renders to `docs/screenshots/showcase.png` (1600×760, transparent background, so it works on GitHub's light and dark themes).

To re-render after a screenshot changes, run from the repo root in Git Bash:

```sh
"/c/Program Files/Google/Chrome/Application/chrome.exe" --headless=new --disable-gpu --hide-scrollbars \
  --default-background-color=00000000 --force-device-scale-factor=1 --window-size=1600,800 \
  --virtual-time-budget=4000 --screenshot="$PWD/docs/screenshots/showcase.png" \
  "file:///$PWD/design/readme/showcase.html"
```

Then crop the bottom to 1600×760 (`python -c "from PIL import Image as I; p='docs/screenshots/showcase.png'; I.open(p).crop((0,0,1600,760)).save(p, optimize=True)"`).

The individual screenshots stay as they are: the AltStore source links them one by one.
