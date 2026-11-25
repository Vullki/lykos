#!/usr/bin/env python3
"""Build the AltStore / SideStore source (altstore-source.json) for a Lykos release.

Reads the app's facts (bundle ID, version, build, minimum iOS, privacy strings) from the
Info.plist inside the IPA itself, so nothing here can drift from project.yml. Earlier
versions are carried over from the previous release's source when one is given.

Standard library only. Used by the release job in .github/workflows/build.yml:

  python3 scripts/altstore_source.py --ipa Lykos.ipa --repo owner/name --tag v0.1.0 \
      --download-url https://.../Lykos-v0.1.0-unsigned.ipa --previous old.json --out altstore-source.json
"""

import argparse
import datetime
import hashlib
import json
import os
import plistlib
import zipfile

SUBTITLE = "Unofficial iOS app for Claude AI"
DESCRIPTION = (
    "Lykos opens claude.ai full screen in its own native iPhone shell: no browser bar, "
    "sign in once, no analytics and no third-party SDKs.\n\n"
    "Claude, claude.ai and everything inside the app are made by Anthropic, and all credit "
    "for Claude goes to them. Lykos is an independent open-source project, not affiliated "
    "with or endorsed by Anthropic."
)
TINT = "#C2C2C2"  # Brushed Silver Noir silver
SCREENSHOTS = ["launch.jpg", "chat.jpg", "sidebar.jpg", "code.jpg"]


def read_info_plist(ipa_path):
    with zipfile.ZipFile(ipa_path) as ipa:
        names = [n for n in ipa.namelist()
                 if n.startswith("Payload/") and n.endswith(".app/Info.plist") and n.count("/") == 2]
        if len(names) != 1:
            raise SystemExit(f"Expected one Payload/*.app/Info.plist in {ipa_path}, found {names}")
        return plistlib.loads(ipa.read(names[0]))


def sha256_of(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def previous_versions(path, bundle_id):
    if not path or not os.path.exists(path):
        return []
    try:
        with open(path, encoding="utf-8") as handle:
            source = json.load(handle)
        for app in source.get("apps", []):
            if app.get("bundleIdentifier") == bundle_id:
                return app.get("versions", [])
    except (OSError, ValueError) as error:
        print(f"Ignoring the previous source ({error}); starting a new version list.")
    return []


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ipa", required=True)
    parser.add_argument("--repo", required=True, help="owner/name on GitHub")
    parser.add_argument("--tag", required=True)
    parser.add_argument("--download-url", required=True)
    parser.add_argument("--previous", default="")
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    info = read_info_plist(args.ipa)
    bundle_id = info["CFBundleIdentifier"]
    version = info["CFBundleShortVersionString"]
    raw = f"https://raw.githubusercontent.com/{args.repo}/{args.tag}"

    entry = {
        "version": version,
        "buildVersion": str(info["CFBundleVersion"]),
        "date": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "localizedDescription": f"Lykos {args.tag}. What changed: https://github.com/{args.repo}/blob/{args.tag}/CHANGELOG.md",
        "downloadURL": args.download_url,
        "size": os.path.getsize(args.ipa),
        "sha256": sha256_of(args.ipa),
        "minOSVersion": info.get("MinimumOSVersion", "15.0"),
    }
    versions = [entry] + [v for v in previous_versions(args.previous, bundle_id) if v.get("version") != version]

    privacy = {key: value for key, value in sorted(info.items())
               if key.startswith("NS") and key.endswith("UsageDescription")}

    source = {
        "name": "Lykos",
        "subtitle": SUBTITLE,
        "description": DESCRIPTION,
        "iconURL": f"{raw}/design/icon/final/lykos-any.png",
        "website": f"https://github.com/{args.repo}",
        "tintColor": TINT,
        "featuredApps": [bundle_id],
        "apps": [{
            "name": "Lykos",
            "bundleIdentifier": bundle_id,
            "developerName": "Vullki",
            "subtitle": SUBTITLE,
            "localizedDescription": DESCRIPTION,
            "iconURL": f"{raw}/design/icon/final/lykos-any.png",
            "tintColor": TINT,
            "category": "utilities",
            "screenshots": {"iphone": [f"{raw}/docs/screenshots/{name}" for name in SCREENSHOTS
                                       if os.path.exists(os.path.join("docs", "screenshots", name))]},
            "versions": versions,
            "appPermissions": {"entitlements": [], "privacy": privacy},
        }],
        "news": [],
    }

    with open(args.out, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(source, handle, indent=2, ensure_ascii=False)
        handle.write("\n")
    print(f"Wrote {args.out}: {bundle_id} {version} ({entry['buildVersion']}), {len(versions)} version(s)")


if __name__ == "__main__":
    main()
