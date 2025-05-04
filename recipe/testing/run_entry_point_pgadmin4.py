import os
import threading
import importlib.util
import subprocess
import time
from pgadmin_test_utils import setup_signal_handler, setup_timeout, wait_for_server

# Register signal handler
setup_signal_handler()

# Set a reasonable timeout
timer = setup_timeout(60)

try:
    # Check if pgadmin4 module is available
    if importlib.util.find_spec("pgadmin4") is None:
        print("Error: pgadmin4 module not found. Make sure it's installed properly.")
        os._exit(1)

    # Get the current script directory
    current_dir = os.path.dirname(os.path.abspath(__file__))
    print(f"Using config_local.py from: {current_dir}")

    # Add the current directory to PYTHONPATH to ensure config_local.py is loaded
    os.environ["PYTHONPATH"] = current_dir + os.pathsep + os.environ.get("PYTHONPATH", "")

    # Make sure var directory exists
    var_dir = os.path.join(current_dir, "var")
    os.makedirs(var_dir, exist_ok=True)

    # Start pgAdmin4 entry point in a separate thread
    pgadmin_process = None  # Reference to the subprocess

    def run_pgadmin_entry_point():
        global pgadmin_process  # Use global instead of nonlocal
        try:
            # Use subprocess to start pgAdmin4
            pgadmin_process = subprocess.Popen(
                ["pgadmin4"],
                cwd=current_dir,  # Set working directory to find config_local.py
                env=os.environ    # Pass current environment
            )
            pgadmin_process.wait()
        except Exception as e:
            print(f"Error in pgAdmin entry point thread: {e}")

    pgadmin_thread = threading.Thread(target=run_pgadmin_entry_point)
    pgadmin_thread.daemon = True
    pgadmin_thread.start()

    # Add a small delay to allow pgAdmin4 to initialize
    print("Waiting for pgAdmin 4 to initialize...")
    time.sleep(5)  # Delay for 5 seconds

    # Wait for server to start
    print("Starting pgAdmin 4 via entry point...")
    if wait_for_server(max_attempts=10, wait_seconds=5):  # Increase attempts and wait time
        # Cancel the timeout timer
        timer.cancel()
        print("Test completed - pgAdmin4 started successfully via entry point")
        if pgadmin_process:
            print("Terminating pgAdmin4 process...")
            pgadmin_process.terminate()  # Terminate the process
            pgadmin_process.wait()  # Wait for it to exit
        os._exit(0)
    else:
        if pgadmin_process:
            pgadmin_process.terminate()  # Ensure the process is terminated on failure
        os._exit(1)

except KeyboardInterrupt:
    print("Test interrupted")
    os._exit(0)
except Exception as e:
    print(f"Error: {e}")
    os._exit(1)
