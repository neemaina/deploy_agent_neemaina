#!/bin/bash
# deploy_agent.sh - deploy, run and archive the Attendance Tracker

#menu: 1) Deploy 2) Run 3) Archive logs 4) Exit
# Test with Ctrl+C / Ctrl+Z: DELAY=3 ./deploy_agent.sh


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

cd "$SCRIPT_DIR" || exit 1
 
# Pre-flight checks


  check_requirements() {
	echo
	echo "Checking required programs..."

 if ! command -v python3 >/dev/null 2>&1
    then
        echo "ERROR: python3 is not installed."
        return 1
    fi

    if ! command -v zip >/dev/null 2>&1
    then
        echo "ERROR: zip is not installed."
        return 1
    fi
python3 --version
    echo "python3: available"
    echo "zip: available"

    return 0

}

  
   check_templates() { 
       echo
    echo "Checking template files..."

    if [ ! -f "$TEMPLATES_DIR/attendance_checker.py" ]
    then
        echo "ERROR: templates/attendance_checker.py not available."
        return 1
    fi

    if [ ! -f "$TEMPLATES_DIR/assets.csv" ]
    then
        echo "ERROR: templates/assets.csv not available."
        return 1
    fi

    if [ ! -f "$TEMPLATES_DIR/config.json" ]
    then
        echo "ERROR: templates/config.json not available."
        return 1
    fi

    echo "attendance_checker.py: available"
    echo "assets.csv: available"
    echo "config.json: available"

    return 0
}



#Signal handler - runs on Ctrl+C/Ctrl+Z when deployment is undergoing


    handle_interrupt() {   

    echo ""
    echo "Deployment interrupted!"
 
    if [ -d "$PROJECT" ]; then
        zip -r "${PROJECT}_archive.zip" "$PROJECT" > /dev/null  

     rm -rf "$PROJECT"
   
    
     echo "Saved existing project to ${PROJECT}_archive.zip"
        echo "Incomplete folder removed."
    else
        echo "It is empty."
    fi
    exit 1 
}

build_project() {
	
	#Ask for the name

    read -p "Project name: " name
    if [ -z "$name" ]; then
        echo "ERROR: name cannot be empty."
        return 1
    fi
    folder="attendance_tracker_$name"
 
    if [ -d "$folder" ]; then
        read -p "$folder already exists. Overwrite? (y/n): " answer
        if [ "$answer" != "y" ]; then
            echo "Cancelled. Nothing changed."
            return 1
        fi
        rm -rf "$folder"
    fi

#Create the folder
PROJECT="$folder"
#folder will be cleaned by an interrupt


 mkdir -p "$PROJECT/Helpers" "$PROJECT/reports" || { echo "ERROR: cannot create folders."; return 1; }
    echo "Created folders."
    sleep "${DELAY:-0}"

#Copy the unmodified files


cp "$TEMPLATES_DIR/attendance_checker.py" "$PROJECT/" || { echo "ERROR: cannot copy attendance_checker.py"; return 1; }
    cp "$TEMPLATES_DIR/config.json" "$PROJECT/Helpers/"   || { echo "ERROR: cannot copy config.json"; return 1; }
    echo "Copied attendance_checker.py and config.json."
    sleep "${DELAY:-0}"



 #Build the roster according to the (assets.csv) file   

  echo
    echo "Roster options:"
    echo "  A) Copy students from templates/assets.csv"
    echo "  B) Generate a new roster"
    while true; do
        read -p "Choose A or B: " option
        case "$option" in
            A|a|B|b) break ;;
            *) echo "Please type A or B." ;;
        esac
    done

    while true; do
        read -p "How many students? " count
        if [[ "$count" =~ ^[0-9]+$ ]] && [ "$count" -ge 1 ]; then
            break
        fi
        echo "Enter a whole number of 1 or more."
    done

    if [ "$option" = "A" ] || [ "$option" = "a" ]; then
        # header line + the first $count students
        head -n $((count + 1)) "$TEMPLATES_DIR/assets.csv" > "$PROJECT/Helpers/assets.csv"
        sessions=5          # sample students already have 4 sessions, so today is #5
    else
        names=("Alice Johnson" "Bob Smith" "Carol White" "David Brown" "Eve Davis"
               "Frank Miller" "Grace Lee" "Henry Moore" "Ivy Taylor" "Jack Wilson")
        emails=("alice@example.com" "bob@example.com" "carol@example.com" "david@example.com" "eve@example.com"
                "frank@example.com" "grace@example.com" "henry@example.com" "ivy@example.com" "jack@example.com")

        if [ "$count" -gt 10 ]; then
            echo "Only 10 sample names available, using 10."
            count=10
        fi

        echo "Email,Names,Attendance Count,Absence Count" > "$PROJECT/Helpers/assets.csv"
        for ((i = 0; i < count; i++)); do
            echo "${emails[$i]},${names[$i]},0,0" >> "$PROJECT/Helpers/assets.csv"
        done
        sessions=1          # brand new roster, today is session #1
    fi

    # keep total_sessions consistent with the roster
    sed -i "s/\"total_sessions\": [0-9]*/\"total_sessions\": $sessions/" "$PROJECT/Helpers/config.json"
    echo "Roster created. total_sessions = $sessions"
    sleep "${DELAY:-0}"

    # --- Permissions ---
    chmod +x "$PROJECT/attendance_checker.py"       # app is executable
    chmod 600 "$PROJECT/Helpers/config.json"        # owner read/write only
    echo "Permissions set:"
    ls -l "$PROJECT/attendance_checker.py" "$PROJECT/Helpers/config.json"
    sleep "${DELAY:-0}"

    # --- Optionally update the alert thresholds ---
    echo
    read -p "Update alert thresholds? (y/n): " change
    if [ "$change" = "y" ]; then
        read -p "Warning threshold [75]: " warning
        read -p "Failure threshold [50]: " failure
        warning=${warning:-75}      # empty answer -> default
        failure=${failure:-50}

        # only use sed if both are numbers
        if [[ "$warning" =~ ^[0-9]+$ ]] && [[ "$failure" =~ ^[0-9]+$ ]]; then
            sed -i "s/\"warning\": [0-9]*/\"warning\": $warning/" "$PROJECT/Helpers/config.json"
            sed -i "s/\"failure\": [0-9]*/\"failure\": $failure/" "$PROJECT/Helpers/config.json"
            echo "Thresholds updated: warning=$warning, failure=$failure"
        else
            echo "Invalid input (numbers only). Keeping the defaults."
        fi
    fi

    return 0
}


deploy() {
	trap handle_interrupt SIGINT SIGTSTP
	#remember Ctrl=C / Ctrl+Z 

	check_requirements || { trap - SIGINT SIGTSTP; return 1; }
    check_templates    || { trap - SIGINT SIGTSTP; return 1; }
 

        if ! build_project; then 
		#something failed: remove all incomplete and stop watching signals

		if [ -n "$PROJECT" ] && [ -d "$PROJECT" ]; then
            rm -rf "$PROJECT"
            echo "Removed incomplete project."
        fi
        PROJECT=""
        trap - SIGINT SIGTSTP
        return 1
    fi

    #build is done and trap can be stopped

      trap - SIGINT SIGTSTP
    PROJECT=""
 
    echo
    echo "Deployment complete. Starting the app to verify..."
    run_app "$name"
}

#Run the app

run_app() {

  app_name="$1"
    if [ -z "$app_name" ]; then
        read -p "Project name: " app_name
    fi
    app_folder="attendance_tracker_$app_name"
 
    if [ ! -d "$app_folder" ]; then
        echo "ERROR: $app_folder does not exist. Deploy it first."
        return 1
    fi
 
    cd "$app_folder" || return 1
    python3 attendance_checker.py
    cd "$SCRIPT_DIR"
}
	

archive_logs() {
   read -p "Project name: " arch_name
    arch_folder="attendance_tracker_$arch_name"
 
    if [ ! -d "$arch_folder" ]; then
        echo "ERROR: $arch_folder does not exist."
        return 1
    fi
 

    stamp=$(date +%Y%m%d_%H%M%S)


   for log in attendance absent; do
        if [ -f "$arch_folder/reports/$log.log" ]; then
            mkdir -p "$arch_folder/archives/$log"
            cp "$arch_folder/reports/$log.log" "$arch_folder/archives/$log/${log}_$stamp.log"
            echo "Archived: $arch_folder/archives/$log/${log}_$stamp.log"
        else
            echo "No $log.log found - skipped."
        fi
    done
}

# Main menu

while true; do
    echo
    echo "Attendance Deploy Agent"
    echo "1) Deploy"
    echo "2) Run"
    echo "3) Archive logs"
    echo "4) Exit"
    read -p "Choose: " choice
 
    case "$choice" in
        1) deploy ;;
        2) run_app ;;
        3) archive_logs ;;
        4) echo "Bye!"; exit 0 ;;
        *) echo "Invalid choice." ;;
    esac
done


