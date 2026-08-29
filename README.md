# Sysk

Sysk gathers live system information (CPU, memory, disk, thermal, and hardware) and evaluates it against configurable rules to produce a health verdict.

This project is a learning-first system health monitor built while teaching myself Bash and Python. It is intentionally practical, transparent, and easy to follow: Bash handles collection and normalization, while Python handles inference, categorization, and final decision-making.

---

## Architecture overview

Sysk follows a simple two-language pipeline:

1. Bash collectors gather raw system data from Linux sources such as /proc, /sys, dmidecode, and smartctl.
2. Those scripts normalize and convert the output into structured JSON using jq and other shell utilities.
3. Python code in engine/inference.py reads the JSON payload and applies threshold rules defined in YAML files for each device type.
4. Each metric is tagged with a status value: OK, WARNING, or CRITICAL.
5. engine/decision.py reads the tagged results and produces an aggregate verdict for the current system state.

This keeps the responsibilities clean:

- Bash is optimized for live system interrogation and lightweight data extraction.
- Python is used for rule-based interpretation, status evaluation, and final decision logic.

In other words, Sysk is not just a script collection; it is a small evidence-driven health engine that turns raw system signals into readable, explainable results.

---

## Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/sysk.git
cd sysk
```

On first run, Sysk checks and installs the required dependencies automatically. The project is designed to work across common Linux package managers, including:

- apt
- dnf
- pacman
- zypper
- emerge

Python dependencies are managed through a requirements file or equivalent setup in the project environment.

For local development, it is also common to use a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## Usage

Run the tool from the project root:

```bash
./sysk
```

Sysk currently supports the following command-line flags from the parser:

```bash
./sysk -h
./sysk -v
./sysk -r
./sysk -m cpu
./sysk -m memory
./sysk -m thermal
./sysk -m disk
```

### Supported flags

- `-h` : display the help menu and exit.
- `-v` : print the current Sysk version and exit.
- `-r` : clear old collected data and exit.
- `-m [module]`: display the most recent data for a given module, such as `cpu`, `memory`, `thermal`, or `disk`.

### Example commands

```bash
# Show help
./sysk -h

# Show the current project version
./sysk -v

# Reset stored health data
./sysk -r

# View the latest CPU data
./sysk -m cpu

# View the latest memory data
./sysk -m memory

# View the latest thermal data
./sysk -m thermal

# View the latest disk data
./sysk -m disk
```

The flag parser is still under active development, but these are the options currently implemented in the Bash layer.

---

## Example output

The inference layer emits structured results in a JSON-like format. A representative sample is shown below:

```json
{
  "cpu": {
    "core_usage_percent": {
      "value": 72,
      "status": "WARNING",
      "threshold": 75
    },
    "temperature_c": {
      "value": 88,
      "status": "CRITICAL",
      "threshold": 85
    }
  },
  "memory": {
    "used_percent": {
      "value": 61,
      "status": "OK",
      "threshold": 80
    }
  }
}
```

This output is later consumed by the decision layer to determine whether the overall verdict should be healthy, degraded, or critical.

---

## Project structure

```text
sysk/
├── lib/
│   ├── core/                  # bootstrap, dependency checks, and shared shell helpers
│   ├── devices/
│   │   ├── multimedia/        # sound and media device collection scripts
│   │   ├── storage/           # disk and memory collectors
│   │   └── sys/               # CPU, GPU, and thermal system probes
│   └── hw/                   # hardware discovery and system inventory scripts
├── engine/
│   ├── inference.py          # parses JSON against YAML rules and tags metric health
│   ├── decision.py           # aggregates tagged results into a final verdict
│   └── results/              # generated result snapshots and decision output
├── .rules/                   # YAML threshold rules grouped by device or metric type
├── cache/                    # cached data and working artifacts for repeated runs
├── config/                   # configuration files and runtime settings
├── features/                 # helper scripts and transformation utilities for collection logic
├── tests/                    # shell and Python tests for validation
├── sysk                      # main entry-point script
├── README.md                 # project overview and usage instructions
├── requirements.txt          # Python dependency definitions
├── todo.txt                  # development notes and next steps
├── .gitignore                # repository ignore rules
└── .venv/                    # local virtual environment for development
```

The layout is intentionally simple: the collection layer stays in Bash, while the interpretation and verdict logic live in Python.

---

## Roadmap

Sysk is still an evolving project, and the roadmap is shaped around both practical monitoring needs and the learning goals behind the tool.

Planned work includes:

- TUI interface for interactive health review
- Flag-based CLI options once the parser is implemented
- Future v2 baseline and comparison tracking for health trend analysis
- Companion tools: syskd for daemon-style monitoring
- Companion tools: syskg for graphical presentation

The long-term direction is to evolve from a single-run health check into a more complete monitoring toolkit without losing the simplicity that makes it a good teaching project.

---

## Contributing

Contributions are welcome in the form of issues, pull requests, and discussion around better data collection, clearer thresholds, or improved diagnostics.

This project is a learning tool, so thoughtful questions and small improvements are encouraged. If you contribute, please use a branch naming convention such as:

- feature/
- fix/
- refactor/

That keeps the project history easy to follow as the tool grows.

---

## License

License information to be added.

---

## Closing note

Sysk is a straightforward but meaningful project: it demonstrates how shell-based system introspection and Python-based rule evaluation can work together to build a useful monitoring tool. It also reflects a personal journey of learning by doing, which is part of why the project is worth reading and improving.
 