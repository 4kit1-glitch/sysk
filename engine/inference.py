# inference engine for sysk adn sysd
# I decided to use a categorical approach for inferencing 
# rather than a numerical one for accuracy reasons
# rules are found in engine/.rules/*.yaml

import sys
from os import environ
from pathlib import Path
from typing import Any
from json import load, dump, JSONDecodeError
from yaml import safe_load

DATE = environ.get("DATE")
PROGRAM_PATH = environ.get("SCRIPT_DIR")   # program path
CACHE_PATH = environ.get("CACHE_PATH")
ENGINE_DIR = environ.get("ENGINE_DIR")
RULE_DIR = environ.get("RULE_DIR")
RESULT_DIR = environ.get("RESULT_DIR")

FLAGS = ("OK", "WARNING", "CRITICAL", "N/A")

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


def load_rules(rule_path: Path) -> dict:
    """ loads rules from yaml files in the rule_path """
    with rule_path.open(encoding="utf-8") as rule:
        return safe_load(rule)


def load_json(data_path: Path) -> Any:
    """ loads data from json in cache """
    try:
        with data_path.open(encoding="utf -8") as data:
            return load(data)
    except (TypeError, FileNotFoundError, OSError, JSONDecodeError) as err:
        print(f"[ERROR] failed to load json file {data_path}", file=sys.stderr)
        print(f"concided errors: {err}", file=sys.stderr)
        sys.exit(1)

def get_dict_value(data: dict, sub_source: any) -> any:
    """ breaks data subsections and nests and returns value of specified key """
    try:
        return data[sub_source]
    except KeyError:
        print(f"[ERROR] key {sub_source} not found in data", file=sys.stderr)
        sys.exit(1)
    except TypeError:
        print(f"[ERROR] invalid type for data: {type(data)}", file=sys.stderr)
        sys.exit(1)

def get_list_value(data: list, index: int) -> Any:
    """ returns the item in the given index """
    try:
        return data[index]
    except IndexError:
        print(f"[ERROR] index {index} not found in data", file=sys.stderr)
        sys.exit(1)
    except TypeError:
        print(f"[ERROR] invalid type for data: {type(data)}", file=sys.stderr)
        sys.exit(1)

def resolve(data: dict, source: str) -> any:
    """ gets required data provided by source"""
    objects = source.split(".")
    for obj in objects:
        if obj.isdigit():
            data = get_list_value(data, int(obj))
            continue
        data = get_dict_value(data, obj)
    return data


def clean_data(value: str, unwanted: str) -> float:
    """ removes unwanted words and chars from data """
    try:
        return float(value.strip(unwanted))
    except(AttributeError):
        return value

def get_status_flag(value: float, warning_lvl: float, critical_lvl: float) -> str:
    """ does comparisition and returns corresponding flag"""
    try:
        if (value >= warning_lvl) and (value < critical_lvl):
            return FLAGS[1]
        elif value >= critical_lvl:
            return FLAGS[2]
        else:
            return FLAGS[0]
    except(TypeError, AttributeError):
        return FLAGS[3]

def get_base_value(data: dict, base: Any) -> Any:
    """ returns base value in already calculated form """
    try:
        if isinstance(base, str):
            return resolve(data, base)
        elif isinstance(base, dict):
            return (resolve(data, base["ref"]) * base["multiplier"])
        else:
            return base
    except(TypeError):
        print("[ERROR] failed to get base", file=sys.stderr)
        sys.exit(1)

def get_module_dict(name: str, value: Any, status: str, threshold: Any) -> dict:
    """ properly forms module dictionary"""
    name = {
        "value": value,
        "status": status,
        "threshold": threshold
    }
    return name

def get_required_module_info(data: dict, rule: dict) -> tuple:
    """ returns name, value, threshold and status """
    name = rule["name"]
    source = rule["source"]
    value = clean_data(resolve(data, source), rule["unit"])
    unit = rule["unit"]
    base_value = clean_data(get_base_value(data, rule["base_value"]), unit)
    warning_limit = (base_value * rule["warning_multiplier"])
    critical_limit = (base_value * rule["critical_multiplier"])
    status = get_status_flag(value, warning_limit, critical_limit)

    if status == FLAGS[0] or status == FLAGS[1]:
        threshold = warning_limit
    elif status == FLAGS[2]:
        threshold = critical_limit
    else:
        threshold = FLAGS[3]

    return name, value, status, threshold


def _evaluate_cpu(cpu_data: dict, cpu_rule: dict) -> dict:
    """ evaluates data with rules and returns correct flag"""
    cpu_dict ={}
    for field in cpu_rule["fields"]:
        name, value, status, threshold = get_required_module_info(cpu_data, field)
        cpu_dict.update({name: get_module_dict(name, value, status, threshold)})

    def evaluate_cores():
        """ special mid functions to break core values and hadle them"""
        # very poor implementation will handle later 
        cores_value = cpu_dict["core_usage_percent"]["value"]
        cores = len(cores_value)
        overused_cores = []
        warn_count = 0
        critical_count = 0
        for core, value in cores_value.items():
            cleaned_value = clean_data(value, "%")
            if cleaned_value >= 90 and cleaned_value < 95:
                warn_count += 1
                overused_cores.append(core)
            elif cleaned_value >= 95:
                critical_count += 1
                overused_cores.append(core)

        if warn_count == 0 and critical_count == 0:
            cpu_dict["core_usage_percent"]["status"] = FLAGS[0]
        elif warn_count > critical_count:
            cpu_dict["core_usage_percent"]["status"] = FLAGS[1]
        else:
            cpu_dict["core_usage_percent"]["status"] = FLAGS[1]
    evaluate_cores()
    return cpu_dict

def _evaluate_thermal(thermal_data: dict, thermal_rule: dict) -> dict:
    """ evaluates thermal info and returns thermal result dict"""
    module = thermal_rule["module"]
    thermal_dict ={}
    for field in thermal_rule["fields"]:
        name, value, status, threshold = get_required_module_info(thermal_data, field)
        thermal_dict.update({name: get_module_dict(name, value, status, threshold)})

    def evaluate_zones():
        max = 0
        for zone, temp in thermal_dict["max_temp"]["value"].items():
            if temp == "N/A":
                continue
            elif float(temp) >= max:
                max = float(temp)
                hottest_zone = zone
        if max >= 89.8 and max < 96.8:
            thermal_dict["max_temp"]["status"] = FLAGS[1]
            thermal_dict["max_temp"]["threshold"] = 89.8

        elif max >= 96.8:
            thermal_dict["max_temp"]["status"] = FLAGS[2]
            thermal_dict["max_temp"]["threshold"] = 96.8
        else:
            thermal_dict["max_temp"]["status"] = FLAGS[0]
            thermal_dict["max_temp"]["threshold"] = 89.8

        
        thermal_dict["max_temp"]["value"] = {hottest_zone: max}
    evaluate_zones()
    return thermal_dict


def _evaluate_memory(mem_data: dict, mem_rule: dict):
    mem_dict = {}
    for field in mem_rule["fields"]:
        name, value, status, threshold = get_required_module_info(mem_data, field)
        mem_dict.update({name: get_module_dict(name, value, status, threshold)})
    return mem_dict

def _evaluate_disks(disk_data: dict, disk_rule: dict):
    # disk info is not in a correct format 
    # too difficult to parse
    # will add after ajustng disk data format
    pass

def evaluate() -> dict:
    # this is temporal fpr v1 will implement an advanced walking directory system when all modules are complete
    MODULES = {
        "cpu": {
            "rule" : load_rules(Path(RULE_DIR) / "cpu.yml"),
            "data": load_json(Path(CACHE_PATH) / f"sysk/cpu_{DATE}.json")
        },
        "memory": {
            "rule" : load_rules(Path(RULE_DIR) / "memory.yml"),
            "data": load_json(Path(CACHE_PATH) / f"sysk/memory_{DATE}.json")
        },
        "thermal": {
            "rule" : load_rules(Path(RULE_DIR) / "thermal.yml"),
            "data": load_json(Path(CACHE_PATH) / f"sysk/thermal_{DATE}.json")
        }
    }

    results = {}
    try:
        for module, value in MODULES.items():  
            if module == "cpu":
                results.update(_evaluate_cpu(value["data"], value["rule"]))
            elif module == "memory":
                results.update(_evaluate_memory(value["data"], value["rule"]))
            elif module == "thermal":
                results.update(_evaluate_thermal(value["data"], value["rule"]))
            else:
                raise NotImplementedError
    except NotImplementedError:
        print("[ERROR] MODULE NOT IMPLEMENTED", file=sys.stderr)
        sys.exit(1)
    return results

def generate_results(result: dict, path: Path):
    try:
        with path.open("w", encoding="utf-8") as file:
            dump(result, file, indent=4)
    except (PermissionError, OSError, TypeError) as err:
        print(f"[ERROR]: failed to create {path}: {ImportError}...", file=sys.stderr)
        sys.exit(1)




def main() -> int:
    """ entry point"""
    # run environment variable checks
    run_var_check()

    # run required directory and file check
    run_dir_check(Path(CACHE_PATH) / "sysk", RULE_DIR)

    # run required file checks 
    run_file_check(
        Path(RULE_DIR) / "cpu.yml",
        Path(CACHE_PATH) / f"sysk/cpu_{DATE}.json",
        Path(RULE_DIR) / "memory.yml",
        Path(CACHE_PATH) / f"sysk/memory_{DATE}.json",
        Path(RULE_DIR) / "thermal.yml",
        Path(CACHE_PATH) / f"sysk/thermal_{DATE}.json"
    )

    # create result directory
    create_dir(RESULT_DIR)
    results = evaluate()
    result_path = Path(RESULT_DIR) /f"result_{DATE}.json"
    generate_results(results, result_path)

    run_file_check(result_path)

    return 0

if __name__ == "__main__":
    sys.exit(main())