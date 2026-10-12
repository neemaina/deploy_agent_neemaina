PROJECT OVERVIEW

deploy_agent.sh is a shell script that bootstraps, runs and archives the Student Attendance Tracker. It wraps the provided Python application (attendance_checker.py, which is never modified) and automates everything around it: it validates the environment, builds the directory structure, copies the source files, builds the class roster, sets safe file permissions, configures the attendance alert thresholds, launches the app to verify the deployment, archives the log files, and cleans up safely if the user presses Ctrl+C or Ctrl+Z in the middle of a deployment.

The script has three features, selected from an interactive menu:

Deploy the application
Run the application
Archive the log files

REPOSITORY STRUCTURE
deploy_agent_neemaina/
├── deploy_agent.sh          # the master script (this is what you run)
├── README.md                # this file
└── templates/               # the three original, unmodified source files
    ├── attendance_checker.py
    ├── assets.csv
    └── config.json

deploy_agent.sh must sit next to the templates/ folder, not inside it. The script finds its templates relative to its own location.

REQUIREMENTS
Bash (Linux, WSL or macOS)
python3
zip (and unzip, if you want to read the archive)
On macOS, the sed commands in the script need sed -i '' instead of sed -i.

The script checks for python3 and zip itself and stops with a clear message if either is missing.



