# inference engine for sysk adn sysd
# I decided to use a categorical approach for inferencing 
# rather than a numerical one for accuracy reasons
# rules are found in engine/.rules/*.yaml

import sys
from os import environ, path, makedirs
from pathlib import Path
from json import load, dump
from yaml import safe_load

DATE = environ.get("DATE")
PROGRAM_PATH = environ.get("SCRIPT_DIR")   # program path
CACHE_PATH = environ.get("CACHE_PATH")
ENGINE_DIR = environ.get("ENGINE_DIR")
RULE_DIR = environ.get("RULE_DIR")
RESULT_DIR = environ.get("RESULT_DIR")

RULES = {}

def is_dir_present(dir_name: str) -> bool:
    """check if a directory is present"""
    return Path(dir_name).is_dir()

def is_file_present(file_path: str) -> bool:
    """check if a file is present"""
    return Path(file_path).is_file()

def is_var_set(variable) -> bool:
    """checks if var is set """
    return variable is not None

def run_var_check() -> None:
    """performs checks if the all required environment vars are set"""
    REQUIRED_VARS = { 
        "DATE": DATE, 
        "PROGRAM_PATH": PROGRAM_PATH, 
        "CACHE_PATH": CACHE_PATH,
        "ENGINE_DIR": ENGINE_DIR,
        "RULE_DIR": RULE_DIR, 
        "RESULT_DIR": RESULT_DIR
    }
    not_set_list = [name for name, value in REQUIRED_VARS.items() if not is_var_set(value)]

    if not_set_list:
        print(f"[ERROR] required variables absent: {not_set_list}")
        sys.exit(127)

def create_dir(directory) -> None:
    """ creates directory if not present """
    results_path=Path(directory)
    try:
        results_path.mkdir(parents=True, exist_ok=True)
    except OSError:
        print("[ERROR] OSError occured exiting")
        sys.exit(1)




def run_dir_check(*directories) -> None:
    """ check if directories are present """
    absent_dirs = []
    for directory in directories:
        try:
            if not is_dir_present(directory):
                absent_dirs.append(directory)
        except TypeError:
            print(f"[ERROR] invalid type: {directory}")
            sys.exit(2)

    if absent_dirs:
        print(f"[ERROR] required directories missing: {absent_dirs}")
        sys.exit(1)





def run_file_check(*files) -> None:
    """ check if requred files are present"""
    absent_files = []
    for file in files:
        try:
            if not is_file_present(file):
                absent_files.append(file)
        except TypeError:
            print(f"[ERROR] invalid type: {file}")
            sys.exit(2)

        if absent_files:
            print(f"[ERROR] required directories missing: {absent_files}")
            sys.exit(1)   











def main() -> int:
    pass
    



if __name__ == "__main__":
    sys.exit(main())