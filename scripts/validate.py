from pathlib import Path

required = [
    Path("index.html"),
    Path("styles.css"),
    Path("script.js"),
    Path("README.md"),
    Path(".github/workflows/deploy-pages.yml"),
]
for path in required:
    data = path.read_text(encoding="utf-8")
    if not data.strip():
        raise SystemExit(f"{path} is empty")

html = Path("index.html").read_text(encoding="utf-8")
for token in ["LuaBank", "Lua Obfuscator", "Lua bank", "obfuscator", "pricing"]:
    if token not in html:
        raise SystemExit(f"missing website token: {token}")

script = Path("script.js").read_text(encoding="utf-8")
for token in ["obfuscateLua", "encodeString", "local", "string.char"]:
    if token not in script:
        raise SystemExit(f"missing obfuscator token: {token}")

workflow = Path(".github/workflows/deploy-pages.yml").read_text(encoding="utf-8")
for token in ["actions/configure-pages@v6", "enablement: true", "actions/upload-pages-artifact@v5", "actions/deploy-pages@v5", "github-pages"]:
    if token not in workflow:
        raise SystemExit(f"missing GitHub Pages workflow token: {token}")

print("LuaBank website files validated")
