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


HOW TO RUN

Make the script executable once:

chmod +x deploy_agent.sh

Then use either command:

./deploy_agent.sh
      OR
bash deploy_agent.sh

The script shows an interactive menu. This is the chosen way to select a feature:

Attendance Deploy Agent
1) Deploy
2) Run
3) Archive logs
4) Exit
Choose:

Type 1, 2, 3 or 4 and press Enter. Anything else prints "Invalid choice." and shows the menu again. The menu returns after every feature, so you can deploy, run and archive in one sitting.

To slow the deployment down so you have time to press Ctrl+C or Ctrl+Z (for testing and for the video), set the optional DELAY variable. It adds a pause of that many seconds between the deployment steps:

DELAY=3 ./deploy_agent.sh
FEATURE 1: DEPLOY THE APPLICATION

Choose option 1. The script then does the following, in order:

PRE-FLIGHT CHECKS. It confirms python3 and zip are installed and prints the python3 version (python3 --version). It then confirms attendance_checker.py, assets.csv and config.json exist in templates/. If anything is missing it prints a clear ERROR message and returns to the menu without creating anything.
PROJECT NAME. It asks for a project name and builds the folder name attendance_tracker_{name}. An empty name is rejected. If that folder already exists, it asks "Overwrite? (y/n)". Typing y deletes the old folder and continues. Anything else cancels with "Cancelled. Nothing changed." and the existing project is left untouched.
DIRECTORY STRUCTURE. It creates the structure the application expects:

