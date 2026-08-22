# inference engine for sysk adn sysd
# I decided to use a categorical approach for inferencing 
# rather than a numerical one for accuracy reasons
# rules are found in engine/.rules/*.yaml

from sys import exit, argv
from os import environ, path, makedirs
from json import load, dump
from yaml import safe_load

DATE = environ.get("DATE")
PROG_PATH = environ.get("SCRIPT_DIR")   # program path


