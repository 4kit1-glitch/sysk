# this is the decision engine script 
# simply get number of results


import sys
from os import environ
from json import load, JSONDecodeError
from pathlib import Path
from inference import load_json, run_file_check, run_dir_check,is_dir_present, is_file_present, RESULT_DIR, DATE, FLAGS

DUMPS = environ.get("DUMPS_PATH")

def load_result(result_path) -> dict:
    """ loads the present result"""
    try:
        return load_json(result_path)
    except(OSError, JSONDecodeError) as err:
        print(f"[ERROR] failed to load results: {err}", file=sys.stderr)
        sys.exit(1)

def decide_effect(results: dict) -> tuple:
    causes = []
    for name, result in results.items():
        if result["status"] != FLAGS[0] and result["status"] != FLAGS[3]:
            causes.append((name, result["value"]))
    if not causes:
        return causes, "OKAY"
    return causes, "ALERT"

def main() -> int:
    """ entry point"""
    result_path = Path(RESULT_DIR) /f"result_{DATE}.json"
    cause_path = Path(DUMPS) / f"cause_{DATE}.log"

    # confirm file presence
    run_dir_check(RESULT_DIR, DUMPS)
    run_file_check(result_path)

    cause, action = decide_effect(load_result(result_path))

    if action != "OKAY":
        try:
            with cause_path.open("w") as file:
                file.write(f"{cause}")
            run_file_check(cause_path)
            return 90
        except (PermissionError, OSError):
            print(f"[ERROR] failed to write {cause_path}", file=sys.stderr)
            sys.exit(1)
    return 0
    




if __name__ == "__main__":
    sys.exit(main())

