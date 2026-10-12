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
attendance_tracker_{name}/
├── attendance_checker.py
├── Helpers/
│   ├── assets.csv
│   └── config.json
└── reports/              # starts empty; the app creates the logs here

If a folder cannot be created (for example a permissions problem), it prints an error, removes the half-built project and returns to the menu.

COPY THE UNMODIFIED FILES. attendance_checker.py and config.json are copied from templates/ exactly as they are. Each copy is checked, and a failure is reported.
BUILD THE ROSTER (Helpers/assets.csv). The script asks how the roster should be built:
Option A: copy from the template. It asks how many students and copies that many rows, plus the header, from templates/assets.csv. The sample students each already have 4 recorded sessions.
Option B: generate a fresh roster. It asks how many students and builds that many rows directly in the script from arrays of sample names and emails. Attendance Count and Absence Count start at 0. Only 10 sample names are built in, so a larger number is capped at 10 with a message.
The choice must be A or B (either case), and the student count must be a whole number of 1 or more. Invalid input re-prompts instead of crashing.
SET PERMISSIONS. attendance_checker.py is made executable (chmod +x) and Helpers/config.json is restricted to owner read/write only (chmod 600), because it controls the grading thresholds. The script prints the result with ls -l as confirmation.
OFFER TO UPDATE THE THRESHOLDS (see the next section).
VERIFY THE DEPLOYMENT. The deploy feature finishes by launching the application (Feature 2). A successful start proves the structure, roster and config work together.
HOW THE THRESHOLD UPDATE WORKS

After the permissions step the script asks "Update alert thresholds? (y/n)". If the answer is not y, the defaults in config.json stay as they are.

If the answer is y, the script asks for two values:

Warning threshold [75]
Failure threshold [50]

How the input is handled:

Pressing Enter on an empty answer uses the default shown in brackets (75 and 50).
Both values are checked to be whole numbers before anything is written. If either is not a number, the script prints "Invalid input (numbers only). Keeping the defaults." and config.json is not touched.
If both are valid, sed edits the deployed Helpers/config.json in place. It targets only the "warning": <number> and "failure": <number> lines, so the file is not reformatted or reordered.

Example of the two lines before and after choosing 80 and 60:

"warning": 75,      ->      "warning": 80,
"failure": 50       ->      "failure": 60

The threshold update only changes the deployed copy in attendance_tracker_{name}/Helpers/. The original templates/config.json is never modified.

HOW total_sessions STAYS CONSISTENT WITH THE ROSTER

config.json has a total_sessions value that must always be one more than the number of prior sessions recorded in the roster (today's session counts too). The script sets it automatically, so there is no prompt for it:

Roster option	Prior sessions per student	total_sessions set by the script
A (copied)	4	5
B (generated)	0	1

The value is written with sed right after the roster is built.

HOW TO RUN THE GENERATED APP (FEATURE 2)

From the menu, choose option 2 and enter the project name. The script checks that attendance_tracker_{name} exists, changes into it and runs the app. The same thing can be done by hand:

cd attendance_tracker_{name}
python3 attendance_checker.py

The app is interactive. It prompts the instructor to mark each student present or absent, updates the counts in Helpers/assets.csv, applies the thresholds in Helpers/config.json, and writes the session logs into reports/:

reports/attendance.log
reports/absent.log (only created if at least one student was absent)

If the project does not exist, the script prints "ERROR: ... does not exist. Deploy it first." and returns to the menu.

HOW LOG ARCHIVING WORKS (FEATURE 3)

After a marking session, choose option 3 and enter the project name. The script checks whether each log exists and archives each one into its own directory with a timestamp in the filename:

attendance_tracker_{name}/
└── archives/
    ├── attendance/
    │   └── attendance_20261012_143022.log
    └── absent/
        └── absent_20261012_143022.log
The filename format is {log}_YYYYMMDD_HHMMSS.log, taken from the system clock when the archive runs. Every archived copy is therefore unique and traceable.
The archive directories (archives/attendance and archives/absent) are created automatically if they do not exist.
Each log is copied, not moved, so the original stays in reports/. Running the archive again later creates a new timestamped copy.
For each log the script prints "Archived: <final path>".
If a log does not exist (for example nobody was absent, so there is no absent.log), the script prints "No absent.log found - skipped." and carries on. It does not crash.
HOW TO TRIGGER THE ARCHIVE-ON-INTERRUPT FEATURE

While the Deploy feature is running, press Ctrl+C (SIGINT) or Ctrl+Z (SIGTSTP). Ctrl+Z would normally freeze the script, but the script traps both signals and treats them the same way.

On either signal the script:

Prints "Deployment interrupted!"
Zips whatever exists so far of attendance_tracker_{name}/ into attendance_tracker_{name}_archive.zip, in the same folder as the script.
Deletes the incomplete attendance_tracker_{name}/ directory so no half-made project is left behind. The zip is created first and the folder is deleted second.
Prints a confirmation and exits cleanly (exit code 1).

If the signal arrives before the project folder exists (during the pre-flight checks or at the name prompt), there is nothing to save, so the script reports that and exits. The project folder is only registered for cleanup after the overwrite question has been answered, so interrupting at that prompt can never delete an existing project.

The trap is active only while the script is deploying. It is switched off as soon as the build finishes, and also if a deployment step fails, so Ctrl+C works normally during the live marking session and at the menu.

HOW TO READ THE ARCHIVE

The archive is a compressed binary .zip file. Do not open it in a text editor, because it will look like scrambled symbols. Use unzip instead. The two commands you can use are:

unzip -l attendance_tracker_{name}_archive.zip     # list contents
unzip attendance_tracker_{name}_archive.zip        # extract it back

If unzip is not installed, install it with sudo apt install unzip.

The contents depend on how far the deployment got when it was interrupted. For example, an interruption after the files were copied lists something like:

attendance_tracker_{name}/
attendance_tracker_{name}/attendance_checker.py
attendance_tracker_{name}/reports/
attendance_tracker_{name}/Helpers/
attendance_tracker_{name}/Helpers/config.json

An interruption later in the run also includes Helpers/assets.csv.

HOW TO TEST THE CTRL+C / CTRL+Z PATH
Start the script with a delay: DELAY=3 ./deploy_agent.sh
Choose 1 (Deploy), enter a project name, then wait until "Created folders." appears.
Press Ctrl+C. (Repeat the whole test once more and press Ctrl+Z instead.)
Confirm the script printed "Deployment interrupted!", reported the saved archive, and returned to the shell.
Run ls and confirm attendance_tracker_{name}archive.zip exists and the attendance_tracker{name}/ folder is gone.
Run unzip -l attendance_tracker_{name}_archive.zip and confirm it holds the partial project.

Expected result: a .zip archive of the partial project, and no leftover half-made directory.

HOW THE DEPLOYED STRUCTURE WAS TESTED

After a deployment, the structure, permissions, roster and config were checked with these commands:

ls -R attendance_tracker_{name}                              # folders and files match the required structure
ls -l attendance_tracker_{name}/attendance_checker.py        # shows -rwx... (executable)
ls -l attendance_tracker_{name}/Helpers/config.json          # shows -rw------- (owner only)
cat attendance_tracker_{name}/Helpers/config.json            # thresholds and total_sessions are correct
cat attendance_tracker_{name}/Helpers/assets.csv             # header plus the requested number of students

Both deployment paths were tested:

Test	What was checked
Option A (copy), e.g. 4 students	assets.csv has 5 lines (header + 4 rows); total_sessions is 5
Option B (generate), e.g. 3	rows end in 0,0; total_sessions is 1
Thresholds changed (80 and 60)	only the warning and failure lines changed
Thresholds invalid ("abc")	script rejects the input and config.json keeps 75 and 50
Thresholds left empty	defaults 75 and 50 are applied
Existing project, answer n	"Cancelled. Nothing changed." and the old folder is untouched
Run after deploy	app starts, and reports/ is filled after a short marking session
Archive after a run	timestamped files appear in archives/attendance and archives/absent
Archive with no absent.log	"No absent.log found - skipped." and no crash
Ctrl+C and Ctrl+Z during deploy	.zip created, incomplete folder removed
EDGE CASES HANDLED
python3, zip, or a template file is missing
Empty project name
Project already exists: overwrite or cancel
A folder cannot be created or a file cannot be copied
Roster option other than A or B
Student count that is not a number, or is less than 1
More students requested than the 10 sample names (capped at 10)
Empty threshold input (defaults are used)
Non-numeric threshold input (rejected, config unchanged)
Ctrl+C or Ctrl+Z before anything exists, or partway through the build
Running or archiving a project that was never deployed
A missing attendance.log or absent.log when archiving
KNOWN LIMITATIONS
Threshold values are checked to be numeric but not to be within 0 to 100, and failure is not required to be lower than warning.
The overwrite and threshold prompts accept a lowercase y only.
Archiving copies the logs rather than moving them, so a later archive can include earlier sessions if the app appends to its logs.
