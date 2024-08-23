

while getopts ":hnpna" opt; do
    case $opt in
        h)
            Help
            exit 0
            ;;
        n)
            case $OPTARG in
                p)
                    echo "-np"
                    CheckRoot
                    CheckCTS
                    CheckSettingsFiles
                    CheckSettingsNoPass
                    CreateArchive
                    ;;
                a)
                    echo "-na"
                    CheckRoot
                    CheckCTS
                    CheckSettingsFiles
                    ;;
            esac
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            Help
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            Help
            exit 1
            ;;
    esac
done

# Если не было передано никаких аргументов
if [ $OPTIND -eq 1 ]; then
    echo "No check argument"
    CheckRoot
    CheckCTS
    CheckSettingsFiles
    CreateArchive
fi



if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        Help
elif [ "$1"  == "--nopass" ] || [ "$1" == "-np" ]; then
        echo "-np"
        CheckRoot
        CheckCTS
        CheckSettingsFiles
        CheckSettingsNoPass
        CreateArchive
elif [ "$1" == "--noarchive" ] || [ "$2" == "--noarchive" ] || [ "$1" == "-na" ] || [ "$2" == "-na" ]; then
        echo "-na"
        CheckRoot
        CheckCTS
        CheckSettingsFiles
else 
    echo "No check argument"
    CheckRoot
    CheckCTS
    CheckSettingsFiles
    CreateArchive

fi

#CheckCTS

#CreateArchive