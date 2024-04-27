#Coded by : ROHAN SANGODKAR
#
#Input parms validation
if [ -z "$1" ]; then
  echo "All parameters are not provided."
  exit
fi

if [ -z "$2" ]; then
  echo "All parameters are not provided."
  exit
fi

#Checking if ini file exists or not
if [ ! -f "$1" ]; then
  echo "ini file path is invalid"
  exit
fi

#Checking if Essentis Path is valid or not
if [ ! -d "$1" ]; then
  echo "Essentis Home path is invalid"
  exit
fi

#Extracting package path from the ini file and validating it
pk_path=$(awk -F '=' '/CMMPackageName/ {print $2}' "$1" | sed 's/^[ \t]*//;s/[ \t]*$//')

if [ ! -f "pk_path" ]; then
  echo "Package mentioned in the ini file is invalid."
  exit
fi

echo "THE END!!!"
