PROJECT OVERVIEW

deploy_agent.sh is a shell script that bootstraps, runs and archives the Student Attendance Tracker. It wraps the provided Python application (attendance_checker.py, which is never modified) and automates everything around it: it validates the environment, builds the directory structure, copies the source files, builds the class roster, sets safe file permissions, configures the attendance alert thresholds, launches the app to verify the deployment, archives the log files, and cleans up safely if the user presses Ctrl+C or Ctrl+Z in the middle of a deployment.

The script has three features, selected from an interactive menu:

Deploy the application
Run the application
Archive the log files
