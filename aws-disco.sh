#!/usr/bin/env bash
#  PURPOSE: Discover current AWS $resource state and export to terraform
#           formatted file to begin modular work quickly and without type-os.
# -----------------------------------------------------------------------------
#  PREREQS: a) Install:  'ruby', 'gem' and 'terraforming' (gem)
#           b) Optional: install 'bundle'
#           c)
# -----------------------------------------------------------------------------
#  EXECUTE: ./aws-disco.sh -v -o /tmp/tforms -i 2>&1 | tee ~/aws-disco.out
#  EXECUTE: curl -fsSL https://URL 2>&1 | bash -o /tmp/tforms | tee /tmp/terraforming.out
# -----------------------------------------------------------------------------
#     TODO: 1) Only tested on macOS right now; test on Linux.
#           2)
#           3)
# -----------------------------------------------------------------------------
#   AUTHOR: Todd E Thomas
# -----------------------------------------------------------------------------
#  CREATED: 2017/04/17
# -----------------------------------------------------------------------------
set -x

###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
# ENV Stuff
: "${AWS_PROFILE?'AWS_PROFILE is not exported to the environment; exiting.'}"
myFileName=$(basename "$0")
# Program Data
declare reqdProgs=('ruby' 'gem' 'terraform' 'terraforming')
declare tfState='terraform.tfstate'
declare tfSvcs="$(terraforming help | grep terraforming | cut -d' ' -f4)"


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
show_help()   {
    printf '\n%s\n\n' """
    Discover current AWS build details and export them to Terraform format.

    Usage: ./$myFileName [OPTION1] [OPTION2]...

    WARNING: THIS program will install ruby, gem, and terraforming (gem) on your
    system automatically.

    OPTIONS:
    -p, --prereqs       Test your local system. See if you have all of the
                        necessary programs to run this script.
                        Example: ./$myFileName -p

    -o, --outputdir     Pass in a value for output directory. Sometimes you
                        don't want it 'here'. Useless if not interrogating.
                        Example: ./$myFileName -v --outputdir /tmp/tforms/

    -o, --interrogate   Finally, interrogate your AWS account and dump
                        everything locally. This is intended to be used in
                        conjunction with --outputdir.
                        Example: ./$myFileName -v -o /tmp/tforms -i

    """
}


###---
### Check whether all required progrms are installed
###---
procPrereqs() {
    printf '\n%s\n' "Verfiying required programs..."
    for program in "${reqdProgs[@]}"; do
        if ! type -P "$program" >/dev/null 2>&1; then
           printf '\n%s\n\n'  "  Install:  $program"
        else
            printf '%s\n' "  All good: $program"
        fi
    done
    exit
}


###---
### Prep an output directory
###---
prepOutputDir() {
    printf '\n%s\n' "Prepping the output directory..."
    specdOutputDir="$1"
    if [[ -z "$specdOutputDir" ]] || \
       [[ "$specdOutputDir" == '.' ]]; then
        export myOutputDir="$(pwd)"
        printf '%s\n' "  Dumping output to the current working directory."
    else
        export myOutputDir="$specdOutputDir"
        printf '%s\n' "  Dumping output to: $myOutputDir"
        # if myOutputDir does not exist then
        if [[ ! -d "$myOutputDir" ]]; then
            # Create it, or
            mkdir "$myOutputDir"
        else
            # Destroy it then re-create it
            rm -rf "$myOutputDir"
            mkdir "$myOutputDir"
        fi
    fi
}


###---
### Sync Remote State
###---
procState() {
    printf '\n%s\n' "Synchronizing remote state..."
    myState="$myOutputDir/$tfState"
    touch "$myState"
    # Get the ball rolling with a good dump; there's always a vpc
    terraforming vpc --tfstate > "$myState"
    printf '%s\n' "  Initial State File size:"
    wc -l "$myState"
    while read -r awsService; do
        [[ "$awsService" = 'help' ]] && continue
        [[ "$awsService" = 'vpc'  ]] && continue
        printf '%s\n' "  Merging state for: $awsService"
        # Now add the state for a given service
        terraforming "$awsService" --tfstate --merge="$myState"
        printf '%s\n' "  Size after adding $awsService:"
        wc -l "$myState"
    done <<< "$tfSvcs"
}


###---
### Get supported terraforming-AWS services
###---
procInterrogation() {
    printf '\n%s\n' "Outputting Terraform files..."
    while read -r awsService; do
        [[ "$awsService" = 'help' ]] && continue
        printf '%s\n' "  Saving config for: $awsService"
        export svcDir="$myOutputDir/$awsService"
        export tFile="$svcDir/main.tf"
        mkdir "$svcDir"
        terraforming "$awsService" --profile "$AWS_PROFILE" > "$tFile"
        # if file size is 0 or 1 byte then get rid of $awsService directory
        if  [[ (( $(wc -c < "$tFile") == 0 )) ]]  || \
            [[ (( $(wc -c < "$tFile") == 1 )) ]]; then
            printf '%s\n' "    Removing empty file for $awsService"
            rm -rf "$svcDir"
        fi
    done <<< "$tfSvcs"
    #done <<< 'vpc'
    procState
}


###---
### Funct11
###---
functName() {
    printf '\n%s\n' "MESG"
    specdVar="$1"
        printf '%s\n' "  MESG-sub"
    export myVar="$specdVar"
}


###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
### Parse Arguments
###---
while :; do
       case "$1" in
            -h|-\?|--help) # Call "show_help" function; display and exit.
                show_help
                exit 0
                ;;
            -p | --prereqs)
                procPrereqs "$2"
                shift
                ;;
            -i | --interrogate)
                procInterrogation "$2"
                shift
                ;;
            -o | --outputdir)
                prepOutputDir "$2"
                shift
                ;;
            -s | --state-only)
                prepOutputDir "$2"
                shift
                ;;
            -a | --all)
                prepOutputDir "$2"
                shift
                ;;
            -v|--verbose)
                set -x
                ;;
            --) # End of all options.
                shift
                break
                ;;
            -?*)
                printf '\n%s\n' '  WARN: Unknown option (ignored):' "$1" >&2
                printf '\n%s\n\n' "  Run: ./$myFileName --help for more info."
                show_help
                exit
                ;;
            *)  # Default case: If no more options then break out of the loop.
                break
        esac
        shift
done


###---
### Export the AWS Structure into Terraform-formatted files
###---
printf '\n%s\n' "These are your Terraform files:"
tree "$myOutputDir"


###---
### REQ
###---


###---
### fin~
###---
exit 0
