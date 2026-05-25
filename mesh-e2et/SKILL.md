---
name: mesh-e2et
description: Windows E2E testing using pywinauto UIA automation. Use for testing Tauri, Electron, WPF, or any Windows desktop application. Trigger when user asks to "e2e test", "test desktop app", "ui automation test", or mentions testing a Windows application. Auto-generates or updates test scripts using pywinauto backend="uia".
version: 1.0.0
source: user-created
---

# Mesh E2E Testing - Windows UIA Automation

End-to-end testing for Windows desktop applications using pywinauto's UI Automation backend.

## When to Use

- User requests E2E testing of a Windows desktop application
- User mentions "test project X", "e2e test", "ui automation"
- Testing Tauri, Electron, WPF, WinForms, or any Windows GUI app
- User wants black-box testing without image recognition

## Workflow

### Step 1: Detect Project

1. **Find project root** - Look for:
   - `Cargo.toml` with Tauri (check for `tauri` dependency)
   - `package.json` with Electron (check for `electron` dependency)
   - `.csproj` / `.vbproj` for .NET apps
   - Any executable in `target/debug/`, `dist/`, `build/`

2. **Identify executable** - Priority:
   - `target/debug/<name>.exe` (Rust/Tauri debug build)
   - `target/release/<name>.exe` (Rust/Tauri release build)
   - `dist/<name>.exe` (Electron/Native)
   - User-specified path if provided

3. **Get process** - If already running, connect by name; otherwise launch it

### Step 2: Check Existing Scripts

Check for existing test script in project:
```
test_<project>_e2e.py
test_<project>_e2e_full.py
e2e_tests/test_*.py
```

If exists → Update/enhance it
If not exists → Generate new script

### Step 3: Generate/Update Test Script

Use the bundled template in `scripts/e2e_template.py`. Customize:
- Project name
- Executable path
- Expected window title
- UI elements to test

### Step 4: Run Tests

Execute the test script:
```bash
python test_<project>_e2e_full.py
```

### Step 5: Report Results

Summarize:
- Pass/fail counts
- UI elements found
- Issues detected
- Recommendations

## Script Template

The template at `scripts/e2e_template.py` provides:

```python
# Core structure:
1. Connect to process (PID or name)
2. Get main window
3. Verify UI elements (sidebar, buttons, text)
4. Test interactions (click, type)
5. Check state changes
6. Report results
```

## Key Patterns

### Connecting to Running App

```python
from pywinauto import Application
app = Application(backend="uia").connect(process=<PID>)
# Or by name:
app = Application(backend="uia").connect(path="<exe_path>")
```

### Finding Window

```python
window = app.window(title_re=".*<AppName>.*")
# Or:
window = app.top_window()
```

### Finding Elements

```python
# By control type:
texts = window.descendants(control_type="Text")
buttons = window.descendants(control_type="Button")

# By title:
elem = window.child_window(title="Button Name", control_type="Button")
```

### Interacting

```python
# Click:
elem.click_input()

# Type:
elem.type_keys("text")

# Wait:
import time
time.sleep(0.5)
```

## Limitations

- **Windows only** - pywinauto is Windows-specific
- **UIA required** - Windows UI Automation must be available
- **No image recognition** - Pure UIA, no screenshot analysis
- **English/Chinese UI** - Title matching works for both

## Dependencies

Ensure pywinauto is installed:
```bash
pip install pywinauto
```

## Example Usage

User: "e2e test meshda"

Steps:
1. Find `target/debug/meshda.exe`
2. Check for existing `test_meshda_e2e*.py`
3. Generate/update script
4. Launch meshda.exe
5. Run tests
6. Report: "11 passed, 1 failed, 91.7% success rate"

## Arguments

Can accept optional arguments:
- `--new` - Force generate new script (ignore existing)
- `--update` - Update existing script with new tests
- `--headless` - Run without launching (connect to existing)
- `<project-path>` - Specify project directory

Examples:
- `/mesh-e2et 测试项目meshda`
- `/mesh-e2et --new meshda2`
- `/mesh-e2et --update 添加搜索功能测试`