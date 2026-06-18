# LuaBank Obfuscator Website

LuaBank replaces the old FL direction with a high-impact Lua obfuscator and Lua script bank landing page. It is a static, deployable website with a client-side obfuscation demo, script-vault positioning, key-system copy, and pricing sections.

## What changed

- **Lua obfuscator demo:** paste Lua and generate protected-looking output in the browser.
- **Lua bank:** market scripts as a vault/library for loaders, releases, changelogs, and buyer access.
- **Key-system focus:** copy and layout inspired by whitelist/key platforms such as Luarmor, with clear notes that real hardened obfuscation should run through a server-side pipeline.
- **GitHub Pages deployment:** pushes to `main` run GitHub Actions validation, package `index.html`, `styles.css`, and `script.js`, then deploy the site to GitHub Pages.

## Run locally

Open `index.html` directly, or serve the folder:

```bash
python3 -m http.server 8000
```

Then visit <http://localhost:8000>.

## Deploy on GitHub Pages

1. In the repository, open **Settings → Pages**.
2. Set **Build and deployment → Source** to **GitHub Actions**. If it has not been enabled yet, the workflow also passes `enablement: true` to `actions/configure-pages@v6` so GitHub can create/enable the Pages site during deployment.
3. Push to `main` or run **Deploy LuaBank to GitHub Pages** manually from the Actions tab.
4. Pull requests validate and build the Pages artifact, but only non-PR runs deploy.
5. The workflow uses the current Pages action majors (`configure-pages@v6`, `upload-pages-artifact@v5`, and `deploy-pages@v5`) so it does not opt back into insecure Node 20 execution.

## Research notes

During the redesign, current Lua protection platforms were reviewed for common expectations: automatic obfuscation, whitelist/key checks, ad-link/key monetization, local privacy claims, and script verification/review workflows. The site uses those patterns as product inspiration without copying vendor source or branding.
