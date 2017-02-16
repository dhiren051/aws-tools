#!/usr/bin/env bash
#  PURPOSE: Find the latest AMIs based on ordered criteria; e.g.:
#             1) Distro:             'debian'
#             2) Region:             'us-west-2'
#             3) Architecture:       'x86_64'
#             4) VirtualizationType: 'hvm'
#             5) RootDeviceType:     'ebs'
#             6) ImageLocation:      "$OwnerId/${reqdDistro}-jessie"
#             7) CreationDate:       'latest'
#   RESULT: Only 1 ImageId should be output post execution; e.g.: ami-98e114f8
# -----------------------------------------------------------------------------
#  PREREQS: Minimally, these elements must be specified at run time:
#           a) Distro
#           b) Name/Version
#           c)
# -----------------------------------------------------------------------------
#  EXECUTE: ./find-latest-amis.sh -n xenial-16.04-amd64 -d ubuntu
# -----------------------------------------------------------------------------
#     TODO: 1) parameter position matters; it shouldn't.
#           2)
#           3)
# -----------------------------------------------------------------------------
#   AUTHOR: todd-dsm
# -----------------------------------------------------------------------------
#  CREATED: 2017/02/12
# -----------------------------------------------------------------------------
#set -x


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
# ENV Stuff; defaults passed if none provided:
declare defRegion='us-west-2'
declare defArch='x86_64'
declare defVirType='hvm'
declare defRootDevType='ebs'
# Data Files


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
show_help()   {
    printf '\n%s\n\n' """
    Description: Find the 'latest' Amazon AMI of a given specification.
      The position of the parameters matters - for now.

    Usage: ./find-latest-amis.sh [OPTION1] [OPTION2]...

    OPTIONS:
    -a, --arch          Which architecture is required?
                        OPTIONAL: Very few Distros offer a 32-bit AMI.
                        Defaults to: 'x86_64' if no argument is passed.
                        Possible values are:
                          'i386', and 'x86_64'
                        Example: ./find-latest-amis.sh --verbose --arc x86_64

    -d, --distro        For which distro are you looking? Popular values are:
                        REQUIRED
                          'self', 'CoreOS', 'CentOS', 'debian', 'ubuntu',
                          'RHEL' and 'Amazon'
                        Example: ./find-latest-amis.sh --distro debian

    --dev-type          Which RootDeviceType do you require?
                        OPTIONAL
                        Defaults to: 'ebs' if no argument is passed. Options are:
                          'ebs' or 'instance store'
                        Example: ./find-latest-amis.sh --dev-type ebs

    -r, --region        In which AWS region will you need this AMI? Possible values are:
                        OPTIONAL
                           Asia:   ap-south-1, ap-northeast-2, ap-northeast-1,
                                   ap-southeast-1, ap-southeast-2
                           Canada: ca-central-1
                           Europe: eu-west-2, eu-west-1, eu-central-1
                           USA:    us-east-1, us-east-2, us-west-1, us-west-2
                         Defaults to: 'us-west-2' if no argument is passed.
                         Example: ./find-latest-amis.sh -v -r us-west-2

    -n, --dist-name     Which Name (Version) of the Distro do you require?
                        REQUIRED
                        *****    -n, --dist-name must be the 1st/2nd option    *****
                         Value patterns are different from among Distros; do like:
                           CoreOS: 'stable-1235.9.0', 'beta-1298.3.0', 'alpha-1313.0.0'
                             See Releases: https://coreos.com/releases/
                           CentOS: '6.8', '7.3', '6.8-plain', '7.3-hardened', etc
                           debian: 'jessie', 'stretch', etc.
                           ubuntu: 'xenial' -or- '15.04-Snappy-core'
                           RHEL:   '6.8', '7.3', etc.
                           Amazon: '6.8', '7.3', etc.
                         Example: ./find-latest-amis.sh --distro debian

    -v, --verbose        Turn on 'set -x' debug output.

    Search Examples:
      With debugging:
        Search for your own AMIs: (most common)
        ./find-latest-amis.sh -v -n base -d self

      CoreOS
        ./find-latest-amis.sh -v -n CoreOS-stable -d coreos
        ./find-latest-amis.sh -v -n CoreOS-beta   -d coreos
        ./find-latest-amis.sh -v -n CoreOS-alpha  -d coreos

      With another region:
      CentOS
        ./find-latest-amis.sh -r ap-northeast-1 -n 'CentOS Linux 7' -d centos
        ./find-latest-amis.sh --region eu-west-1 -n 'Linux 6' -d centos

      Ubuntu:
        ./find-latest-amis.sh -r eu-central-1 -n xenial-16.04-amd64 -d ubuntu
             But these can substitute: yakkety-16.10-amd64
                                       trusty-14.04-amd64
                                       precise-12.04-amd64

        ./find-latest-amis.sh -n 15.04-Snappy-core -d ubuntu

      You get the idea; these are the rest:
      Debian:
        ./find-latest-amis.sh -n jessie  -d debian
        ./find-latest-amis.sh -n stretch -d debian

      Amazon AMI
        ./find-latest-amis.sh -n ecs-optimized -d amazon

      Red Hat Enterprise Linux
        ./find-latest-amis.sh -n RHEL-7 -d rhel
        ./find-latest-amis.sh -n RHEL-6 -d rhel
    """
}

print_error_noval() {
    emptyArg="$1"
    printf '%s\n\n' """
    ERROR: The option '$emptyArg' requires a non-empty argument." >&2
    exit 1
}

# FUNCTION: confirm the argument value is non-empty
testOpt() {
    testArg=$1
    testVal=$2
    if [[ -z "$testVal" ]]; then
        print_error_noval "$testArg"
    else
        return 0
    fi
}

# Process Architecture
# If no value is given then default to: x86_64
procArch() {
    specdArch="$1"
    if [[ -z "$specdArch" ]]; then
        printf '%s\n' "    No architecture was specified; defaulting to x86_64"
        export reqdArch="$defArch"
    elif [[ "$specdArch" == 'i386' ]]; then
        printf '%s\n' "    The specified architecture is $specdArch"
        export reqdArch="$specdArch"
    else
        printf '\n%s\n\n' "    This Architecture looks like a type-o: $specdArch"
        exit
    fi
}

# Process Region
procRegion() {
    specdRegion="$1"
    # Create array of AWS regions for later validation
    declare -a allRegions=()
    while read -r -d ''; do
        allRegions+=("$REPLY")
        count="${#allRegions[@]}"
    done < <(aws ec2 describe-regions --region-names --output text | \
        sort -u -k3 | awk -F '[\t]' '{printf "%s\0", $3}')
    # Use default region of none was passed
    if [[ -z "$specdRegion" ]]; then
        specdRegion="$defRegion"
    fi
    #printf '%s\n' "All Regions: ${allRegions[*]}"
    printf '%s\n' "  Searching for $specdRegion in ${#allRegions[@]} AWS Regions."
    for (( i = 0; i < count; i++ )); do
        if [[ "${allRegions[$i]}" == "$specdRegion" ]]; then
            printf '%s\n' "    Found the specified region: ${allRegions[$i]}"
            export reqdRegion="$specdRegion"
            break
        fi
        if [[ "$i" -ge '13' ]]; then
            printf '\n%s\n\n' "  This Region looks like a type-o: $specdRegion"
            exit
        fi
    done
}

# Process anything that hasn't been triggered yet
callDefaults() {
    if [[ -z "$reqdArch" ]]; then
        procArch
    fi
    if [[ -z "$reqdDevType" ]]; then
        procDevType
    fi
    if [[ -z "$reqdRegion" ]]; then
        procRegion
    fi
}

# Process the Distro Name/Version
procName() {
    # Test the name to query
    specdName="$1"
    if [[ -z "$specdName" ]]; then
        printf '%s\n' "Dude, you're gonna get a lotta stuff."
    else
        printf '%s\n' "  The specified Name/Version is: $specdName"
        export reqdName="$specdName"
    fi
    # Now export the query string
    ## Use this one to output more detail
    #export reqdQuerry="sort_by(Images[?contains(Name, \`$reqdName\`)], &CreationDate)[*].[ImageId,Name,CreationDate,Description]"
    ## Use this one to output the ImageId only
    export reqdQuerry="sort_by(Images[?contains(Name, \`$reqdName\`)], &CreationDate)[*].[ImageId]"
    #printf '%s\n' "  The Querry string is: $reqdQuerry"
}

# Process Distro
procDistro() {
    specdDistro="$1"
    if [[ -z "$reqdName" ]]; then
        show_help
        printf '%s\n' """
        If Distro is specified you must call -n (Name) as well.
        See Help above; exiting.
        """
        exit 1
    fi
    case $specdDistro in
        self)
            export reqdOwnerId='self'
            ;;
        centos)
            case "${specdName##*\ }" in
                7)
                    export reqdProdCodeId="aw0evgkw8e5c1q413zgy5pjce"
                ;;
                6)
                    export reqdProdCodeId="6x5jmcajty9edm3f211pqjfn2"
                ;;
            esac
            export reqdDistro="$specdDistro"
            export reqdOwnerId='aws-marketplace'
            ;;
        debian)
            export reqdDistro="$specdDistro"
            export reqdOwnerId='379101102735'
            ;;
        ubuntu)
            export reqdDistro="$specdDistro"
            export reqdOwnerId='099720109477'
            ;;
        coreos)
            export reqdDistro="$specdDistro"
            case "${reqdName##*-}" in
                stable)
                    export reqdOwnerId='aws-marketplace'
                    ;;
                beta)
                    export reqdOwnerId='595879546273'
                    ;;
                alpha)
                    export reqdOwnerId='595879546273'
                    ;;
            esac
            ;;
        rhel)
            export reqdDistro="$specdDistro"
            export reqdOwnerId='309956199498'
            ;;
        amazon)
            export reqdDistro="$specdDistro"
            export reqdOwnerId='aws-marketplace'
            ;;
        *)
            printf '\n%s\n\n' "  This Distro looks like a type-o: $specdDistro"
            exit
            ;;
    esac
    printf '%s\n' "  The Distro:      $reqdDistro"
    printf '%s\n' "  $reqdDistro OwnerId:  $reqdOwnerId"
    # Set defaults if they haven't been triggered
    callDefaults
}

# Process RootDeviceType
procDevType() {
    specdDevType="$1"
    if [[ -z "$specdDevType" ]]; then
        printf '%s\n' "    No RootDeviceType was specified; defaulting to 'ebs'"
        export reqdDevType="$defRootDevType"
    elif [[ "$specdDevType" == 'instance store' ]]; then
        printf '%s\n' "    The specified RootDeviceType is $specdDevType"
        export reqdDevType="$specdDevType"
    else
        printf '\n%s\n\n' "    This RootDeviceType looks like a type-o: $specdDevType"
        exit
    fi
}

###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
### If no arguments were passed then just print the help message and exit
###---
if [[ $# -eq 0 ]]; then
    show_help
    exit
fi


###---
### Make the announcement
###---
printf '\n%s\n\n' "Processing your requested parameters and values..."


###---
### Parse options
###---
#set -x
#echo "$@"
#echo "$#"
while :; do
       case "$1" in
            -h|-\?|--help) # Call "show_help" function; display and exit.
                show_help
                exit 0
                ;;
            -a | --arch)
                procArch "$2"
                shift
                ;;
            -n | --dist-name)
                procName "$2"
                shift
                ;;
            -d | --distro)
                testOpt '-d' "$2"
                procDistro "$2"
                shift
                ;;
            --dev-type)
                procDevType "$2"
                shift
                ;;
            -r | --region)
                procRegion "$2"
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
                printf '\n%s\n\n' '  Run: ./find-latest-amis.sh --help for more info.'
                exit
                ;;
            *)  # Default case: If no more options then break out of the loop.
                break
        esac
        shift
done

###----------------------------------------------------------------------------
### Process AMI Ident Request
###----------------------------------------------------------------------------
printf '\n%s\n' "Finding the latest AMI..."
if [[ "$reqdOwnerId" == 'aws-marketplace' ]]; then
    printf '%s\n' """
    Hang tight; searching the whole $reqdOwnerId takes a minute...
    """
fi

case "$reqdDistro" in
    coreos)
        export amiLatest="$(aws ec2 describe-images                 \
            --filters                                               \
                Name=architecture,Values="$reqdArch"                \
                Name=virtualization-type,Values="$defVirType"       \
                Name=root-device-type,Values="$reqdDevType"         \
            --owners "$reqdOwnerId"                                 \
            --region "$reqdRegion"                                  \
            --query "$reqdQuerry"                                   \
            --output text | tail -1)"
            ;;
    centos)
        export amiLatest="$(aws ec2 describe-images                 \
            --filters                                               \
                Name=product-code,Values="$reqdProdCodeId"          \
            --owners "$reqdOwnerId"                                 \
            --region "$reqdRegion"                                  \
            --query "$reqdQuerry"                                   \
            --output text | tail -1)"
            ;;
    *)
        export amiLatest="$(aws ec2 describe-images                 \
            --filters                                               \
                Name=architecture,Values="$reqdArch"                \
                Name=virtualization-type,Values="$defVirType"       \
                Name=root-device-type,Values="$reqdDevType"         \
                Name=block-device-mapping.volume-type,Values=gp2    \
            --owners "$reqdOwnerId"                                 \
            --region "$reqdRegion"                                  \
            --query "$reqdQuerry"                                   \
            --output text | tail -1)"
            ;;
esac
# OUTPUT: export only 1 ImageId 'ami-a1b2c3d4'
#-----------------------------------


###---
### Call it out
###   The amiLatest is sent to stdOut for consumption by a calling script.
###   The other is exits for testing purposes.
###---
#printf '\n%s\n\n' "The latest ImageId for $reqdDistro $reqdName: '$amiLatest'"
printf '%s\n' "$amiLatest"
# OUTPUT:
#-----------------------------------

###---
### fin~
###---
exit 0


###----------------------------------------------------------------------------
### OwnerIdTab
###----------------------------------------------------------------------------
# Distro              OwnerId
# --------------------------------------
# CoreOS            aws-marketplace
# CentOS            aws-marketplace
# Debian            379101102735
# Ubuntu            099720109477
# RHEL              309956199498
# Amazon            aws-marketplace
