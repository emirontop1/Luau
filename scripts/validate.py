from pathlib import Path

required = [Path("src/Aurora.lua"), Path("examples/latest.lua"), Path("examples/test_all_elements.lua"), Path(".github/workflows/latest-example.yml")]
for path in required:
    data = path.read_text(encoding="utf-8")
    if not data.strip():
        raise SystemExit(f"{path} is empty")

example = Path("examples/latest.lua").read_text(encoding="utf-8")
full_test = Path("examples/test_all_elements.lua").read_text(encoding="utf-8")
if "loadstring(game:HttpGet(" not in example:
    raise SystemExit("example must include loadstring(game:HttpGet(...))")
if "emirontop1/luau" not in example or "emirontop1/luau" not in full_test:
    raise SystemExit("example loader must target emirontop1/luau")

library_path = Path("src/Aurora.lua")
library = library_path.read_text(encoding="utf-8")
for token in [
    "CreateWindow",
    "AddTab",
    "AddSection",
    "AddButton",
    "AddToggle",
    "AddSlider",
    "AddTextbox",
    "AddDropdown",
    "Notify",
    "SetTheme",
    "SetAccent",
    "RegisterTheme",
    "SaveConfigNow",
    "LoadConfigNow",
    "Flags",
    "AddDivider",
    "AddProgress",
    "AddKeybind",
    "AddColorPicker",
]:
    if token not in library:
        raise SystemExit(f"missing API token: {token}")

for token in ["AddLabel", "AddParagraph", "AddDivider", "AddButton", "AddToggle", "AddSlider", "AddTextbox", "AddDropdown", "AddProgress", "AddKeybind", "AddColorPicker", "SetTheme", "SetAccent", "RegisterTheme", "Destroy", "SaveConfigNow", "LoadConfigNow", "Flag", "Save"]:
    if token not in full_test:
        raise SystemExit(f"full element test missing token: {token}")

line_count = sum(1 for _ in library_path.open(encoding="utf-8"))
if line_count < 1000:
    raise SystemExit(f"src/Aurora.lua must be at least 1000 lines, found {line_count}")

print(f"Aurora files validated ({line_count} source lines)")
