from pathlib import Path

required = [Path("src/Aurora.lua"), Path("examples/latest.lua"), Path(".github/workflows/latest-example.yml")]
for path in required:
    data = path.read_text(encoding="utf-8")
    if not data.strip():
        raise SystemExit(f"{path} is empty")

example = Path("examples/latest.lua").read_text(encoding="utf-8")
if "loadstring(game:HttpGet(" not in example:
    raise SystemExit("example must include loadstring(game:HttpGet(...))")

library = Path("src/Aurora.lua").read_text(encoding="utf-8")
for token in ["CreateWindow", "AddTab", "AddSection", "AddButton", "AddToggle", "AddSlider", "AddTextbox", "AddDropdown", "Notify"]:
    if token not in library:
        raise SystemExit(f"missing API token: {token}")

print("Aurora files validated")
