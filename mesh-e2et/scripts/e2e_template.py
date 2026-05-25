# -*- coding: utf-8 -*-
"""
E2E Test Script Template for Windows Desktop Applications
Uses pywinauto UIA backend for UI automation testing
"""

import sys
import time
import re
from pywinauto import Application

# ============================================================
# CONFIGURATION - Customize these for your project
# ============================================================
PROJECT_NAME = "{{PROJECT_NAME}}"  # e.g., "meshda"
EXECUTABLE_PATH = "{{EXECUTABLE_PATH}}"  # e.g., "target/debug/meshda.exe"
WINDOW_TITLE_PATTERN = "{{WINDOW_TITLE}}"  # e.g., ".*Meshda.*" or ".*MyApp.*"

# Expected UI elements (customize as needed)
EXPECTED_SIDEBAR_ITEMS = [
    # "Item 1", "Item 2", "Item 3"
]

EXPECTED_BUTTONS = [
    # "Button 1", "Button 2"
]

# ============================================================
# TEST FUNCTIONS
# ============================================================

def connect_to_app(executable_path=None, process_id=None, process_name=None):
    """Connect to application by path, PID, or name"""
    app = Application(backend="uia")

    if process_id:
        app.connect(process=process_id)
        print(f"Connected to PID: {process_id}")
    elif process_name:
        app.connect(path=process_name)
        print(f"Connected to: {process_name}")
    elif executable_path:
        import subprocess
        proc = subprocess.Popen([executable_path])
        time.sleep(2)  # Wait for app to start
        app.connect(process=proc.pid)
        print(f"Started and connected to: {executable_path} (PID: {proc.pid})")
    else:
        raise ValueError("Must provide executable_path, process_id, or process_name")

    return app


def get_main_window(app, title_pattern=None):
    """Get the main application window"""
    if title_pattern:
        window = app.window(title_re=title_pattern)
        if window.exists():
            return window

    # Fallback to top window
    window = app.top_window()
    if window.exists():
        return window

    raise Exception("Could not find main window")


def verify_ui_elements(window, expected_sidebar=None, expected_buttons=None):
    """Verify expected UI elements exist"""
    results = {"passed": 0, "failed": 0, "warnings": 0}

    # Test sidebar items
    if expected_sidebar:
        print("\nTesting sidebar items...")
        for item_name in expected_sidebar:
            try:
                elem = window.child_window(title=item_name, control_type="Text")
                if elem.exists():
                    print(f"  [PASS] Sidebar item: {item_name}")
                    results["passed"] += 1
                else:
                    print(f"  [FAIL] Sidebar item missing: {item_name}")
                    results["failed"] += 1
            except Exception as e:
                print(f"  [FAIL] Error finding {item_name}: {e}")
                results["failed"] += 1

    # Test buttons
    if expected_buttons:
        print("\nTesting buttons...")
        for btn_name in expected_buttons:
            try:
                btn = window.child_window(title=btn_name, control_type="Button")
                if btn.exists():
                    print(f"  [PASS] Button: {btn_name}")
                    results["passed"] += 1
                else:
                    print(f"  [FAIL] Button missing: {btn_name}")
                    results["failed"] += 1
            except Exception as e:
                print(f"  [FAIL] Error finding {btn_name}: {e}")
                results["failed"] += 1

    return results


def test_click_interaction(window, element_title, control_type="Text"):
    """Test clicking on an element"""
    try:
        elem = window.child_window(title=element_title, control_type=control_type)
        if elem.exists():
            elem.click_input()
            time.sleep(0.3)
            print(f"  [PASS] Clicked: {element_title}")
            return True
        else:
            print(f"  [FAIL] Element not found: {element_title}")
            return False
    except Exception as e:
        print(f"  [FAIL] Click error on {element_title}: {e}")
        return False


def analyze_ui_structure(window):
    """Analyze and report UI structure"""
    print("\nAnalyzing UI structure...")

    elements = window.descendants()
    control_types = {}

    for elem in elements:
        try:
            ct = elem.element_info.control_type
            control_types[ct] = control_types.get(ct, 0) + 1
        except:
            pass

    print(f"Control type counts: {control_types}")

    # Find all text elements
    texts = window.descendants(control_type="Text")
    text_names = []
    for t in texts:
        try:
            txt = t.window_text()
            if txt and len(txt) > 0:
                text_names.append(txt)
        except:
            pass

    print(f"Text elements found: {text_names[:20]}")

    # Check for WebView
    docs = window.descendants(control_type="Document")
    if docs:
        print(f"WebView detected: {len(docs)} Document controls")
    else:
        print("No WebView detected")

    return control_types


def run_full_test(executable_path=None, process_id=None, process_name=None,
                  window_title=None, sidebar_items=None, buttons=None):
    """Run complete E2E test suite"""

    print("=" * 70)
    print(f"E2E Test: {PROJECT_NAME}")
    print("=" * 70)

    total_results = {"passed": 0, "failed": 0, "warnings": 0}

    # Step 1: Connect
    print("\n[Step 1] Connecting to application...")
    try:
        app = connect_to_app(
            executable_path=executable_path,
            process_id=process_id,
            process_name=process_name
        )
        print("  [PASS] Connected successfully")
        total_results["passed"] += 1
    except Exception as e:
        print(f"  [FAIL] Connection failed: {e}")
        return False

    # Step 2: Get window
    print("\n[Step 2] Getting main window...")
    try:
        window = get_main_window(app, window_title)
        print(f"  [PASS] Window found: {window.window_text()}")
        total_results["passed"] += 1
    except Exception as e:
        print(f"  [FAIL] Window not found: {e}")
        return False

    # Step 3: Analyze UI
    print("\n[Step 3] Analyzing UI structure...")
    try:
        control_types = analyze_ui_structure(window)
        print("  [PASS] UI analysis complete")
        total_results["passed"] += 1
    except Exception as e:
        print(f"  [WARN] UI analysis error: {e}")
        total_results["warnings"] += 1

    # Step 4: Verify elements
    print("\n[Step 4] Verifying UI elements...")
    results = verify_ui_elements(
        window,
        expected_sidebar=sidebar_items or EXPECTED_SIDEBAR_ITEMS,
        expected_buttons=buttons or EXPECTED_BUTTONS
    )
    total_results["passed"] += results["passed"]
    total_results["failed"] += results["failed"]
    total_results["warnings"] += results["warnings"]

    # Step 5: Test interactions
    print("\n[Step 5] Testing interactions...")
    if sidebar_items:
        for item in sidebar_items[:3]:  # Test first 3 items
            if test_click_interaction(window, item):
                total_results["passed"] += 1
            else:
                total_results["failed"] += 1

    # Final report
    print("\n" + "=" * 70)
    print("Test Results Summary:")
    print(f"  Passed: {total_results['passed']}")
    print(f"  Failed: {total_results['failed']}")
    print(f"  Warnings: {total_results['warnings']}")

    total = total_results["passed"] + total_results["failed"]
    if total > 0:
        success_rate = total_results["passed"] / total * 100
        print(f"  Success Rate: {success_rate:.1f}%")
    print("=" * 70)

    return total_results["failed"] == 0


# ============================================================
# MAIN ENTRY POINT
# ============================================================

if __name__ == "__main__":
    # Parse command line arguments
    import argparse
    parser = argparse.ArgumentParser(description="E2E Test for Desktop App")
    parser.add_argument("--exe", help="Path to executable")
    parser.add_argument("--pid", type=int, help="Process ID to connect to")
    parser.add_argument("--name", help="Process name to connect to")
    args = parser.parse_args()

    success = run_full_test(
        executable_path=args.exe or EXECUTABLE_PATH,
        process_id=args.pid,
        process_name=args.name,
        window_title=WINDOW_TITLE_PATTERN
    )

    sys.exit(0 if success else 1)
