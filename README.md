# uBlock Origin Chrome Setup

One-command setup for uBlock Origin on Chrome with the Manifest V2 workaround (Chrome 140+).

## One-Command Install

**PowerShell** (close Chrome first, then run):

```powershell
irm https://raw.githubusercontent.com/Neel49/uBlock-Chrome-Setup/main/install.ps1 | iex
```

**CMD** (one line):

```cmd
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Neel49/uBlock-Chrome-Setup/main/install.ps1 | iex"
```

The bootstrap fetches the latest script with cache-busting so you always get the current version.

## What It Does

1. **Creates desktop shortcut** – "Chrome (uBlock).lnk" with `--disable-features=ExtensionManifestV2Unsupported,ExtensionManifestV2Disabled`
2. **Downloads uBlock** – Latest Chromium build from [gorhill/uBlock](https://github.com/gorhill/uBlock/releases)
3. **Enables Developer mode** – In Chrome's extensions preferences
4. **Launches Chrome** – Opens `chrome://extensions` and the uBlock folder for "Load unpacked"

## After Running

1. In Chrome, click **Load unpacked**
2. Select the folder that opened (path is also in your clipboard)
3. **Always** launch Chrome from the new shortcut: **Chrome (uBlock)** on your desktop
4. After Chrome updates, close ALL Chrome tasks and launch from the shortcut again

## Manual Install

- Double-click `Install-uBlock-Chrome.cmd`, or
- `powershell -ExecutionPolicy Bypass -File .\Install-uBlock-Chrome.ps1`

## Notes

- Chrome removed `--load-extension` in v137, so you must click "Load unpacked" once
- Workarounds may stop working in Chrome 142
- For long-term use, consider Firefox, Brave, or Opera
