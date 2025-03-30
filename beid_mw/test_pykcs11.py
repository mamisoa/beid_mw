"""
Test script for PyKCS11 functionality in isolation.
Run this to diagnose issues with the eID middleware and PyKCS11 library.
"""
import os
import sys
import platform
from datetime import datetime

def test_pykcs11_import():
    """Test importing the PyKCS11 module"""
    try:
        print(f"[{datetime.now()}] Attempting to import PyKCS11...")
        from PyKCS11 import PyKCS11, CKA_CLASS, CKO_DATA, CKA_LABEL, CKA_VALUE, CKO_CERTIFICATE, PyKCS11Error
        print(f"[{datetime.now()}] PyKCS11 imported successfully")
        return True, "Success"
    except ImportError as e:
        return False, f"Import Error: {str(e)}"
    except Exception as e:
        return False, f"Unexpected Error: {str(e)}"

def test_pykcs11_lib_load():
    """Test loading the PKCS11 library"""
    try:
        from PyKCS11 import PyKCS11, PyKCS11Error
        print(f"[{datetime.now()}] Current PYKCS11LIB environment variable: {os.environ.get('PYKCS11LIB', 'Not set')}")
        
        # Set environment variable if not already set
        if 'PYKCS11LIB' not in os.environ:
            if platform.system().lower() == 'linux':
                os.environ['PYKCS11LIB'] = 'libbeidpkcs11.so.0'
            elif platform.system().lower() == 'darwin':
                os.environ['PYKCS11LIB'] = 'libbeidpkcs11.dylib'
            else:
                os.environ['PYKCS11LIB'] = 'beidpkcs11.dll'
            print(f"[{datetime.now()}] Set PYKCS11LIB to: {os.environ['PYKCS11LIB']}")
        
        # Try to locate the library file
        if os.path.isabs(os.environ['PYKCS11LIB']):
            lib_exists = os.path.exists(os.environ['PYKCS11LIB'])
            print(f"[{datetime.now()}] Library file exists at {os.environ['PYKCS11LIB']}: {lib_exists}")
        
        print(f"[{datetime.now()}] Attempting to load PyKCS11 library...")
        pkcs11 = PyKCS11.PyKCS11Lib()
        pkcs11.load()
        print(f"[{datetime.now()}] PyKCS11 library loaded successfully")
        return True, "Success"
    except PyKCS11Error as e:
        return False, f"PyKCS11Error: {str(e)}"
    except Exception as e:
        return False, f"Unexpected Error: {str(e)}"

def test_pykcs11_slots():
    """Test accessing card slots"""
    try:
        from PyKCS11 import PyKCS11, PyKCS11Error
        
        # Make sure library is loaded
        pkcs11 = PyKCS11.PyKCS11Lib()
        pkcs11.load()
        
        print(f"[{datetime.now()}] Attempting to get slot list...")
        slots = pkcs11.getSlotList()
        print(f"[{datetime.now()}] Found {len(slots)} slots")
        
        if len(slots) == 0:
            return False, "No slots available. Make sure a card reader is connected"
        
        return True, f"Found {len(slots)} slots"
    except PyKCS11Error as e:
        return False, f"PyKCS11Error: {str(e)}"
    except Exception as e:
        return False, f"Unexpected Error: {str(e)}"

def run_all_tests():
    """Run all tests in sequence"""
    print(f"=== PyKCS11 Test Suite ===")
    print(f"Python version: {platform.python_version()}")
    print(f"Platform: {platform.system()} {platform.release()}")
    print(f"OS Environment: {os.environ.get('PYKCS11LIB', 'PYKCS11LIB not set')}")
    print(f"===========================")
    
    tests = [
        ("Import Test", test_pykcs11_import),
        ("Library Load Test", test_pykcs11_lib_load),
        ("Slot Access Test", test_pykcs11_slots)
    ]
    
    for name, test_func in tests:
        print(f"\n--- {name} ---")
        success, message = test_func()
        print(f"Result: {'SUCCESS' if success else 'FAILURE'}")
        print(f"Message: {message}")
        
        # Stop on first failure
        if not success and name != "Slot Access Test":  # We expect slot access might fail if no card reader
            print(f"Stopping tests due to failure")
            break
    
    print(f"\n=== Test Suite Complete ===")

if __name__ == "__main__":
    run_all_tests() 