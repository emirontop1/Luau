# LuaBank Obfuscator Website

LuaBank replaces the old FL direction with a high-impact Lua obfuscator and Lua script bank landing page. It is a static, deployable website with a client-side obfuscation demo, script-vault positioning, key-system copy, and pricing sections.

## What changed

- **Lua obfuscator demo:** paste Lua and generate protected-looking output in the browser.
- **Lua bank:** market scripts as a vault/library for loaders, releases, changelogs, and buyer access.
- **Key-system focus:** copy and layout inspired by whitelist/key platforms such as Luarmor, with clear notes that real hardened obfuscation should run through a server-side pipeline.

## Run locally

Open `index.html` directly, or serve the folder:

```bash
python3 -m http.server 8000
```

Then visit <http://localhost:8000>.

## Research notes

During the redesign, current Lua protection platforms were reviewed for common expectations: automatic obfuscation, whitelist/key checks, ad-link/key monetization, local privacy claims, and script verification/review workflows. The site uses those patterns as product inspiration without copying vendor source or branding.
