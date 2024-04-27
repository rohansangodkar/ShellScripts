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

if [ -z "$3" ]; then
  echo "All parameters are not provided."
  exit
fi

read -p "Please provide the ACQ linked region name  :" regname

read -p "Please provide the ACQ linked region path  :" regpath

#Checking package path.
if [ !  -e $regpath ]; then
  echo "-----------------------------------------------------------------------------------------------"
  echo "Invalid ACQ linked region path!!!"
  echo "-----------------------------------------------------------------------------------------------"
  exit
fi


if [ "$2" = "o" ] || [ "$2" = "p" ];
then
  echo "-----------------------------------------------------------------------------------------------"
  echo "script started."
  echo "-----------------------------------------------------------------------------------------------"
else
  echo "-----------------------------------------------------------------------------------------------"
  echo "Invalid option. Only valid options are o for Oracle and p for Postgres."
  echo "-----------------------------------------------------------------------------------------------"
  exit
fi

if [[ $1 =~ [0-9]+ ]];
then
  echo "-----------------------------------------------------------------------------------------------"
  echo "Proceeding with the region creation with the region name $1."
  echo "-----------------------------------------------------------------------------------------------"
else
  echo "-----------------------------------------------------------------------------------------------"
  echo "Invalid region name.Region name should contain at least one digit. e.g ORAREG1,CMM2REG."
  echo "-----------------------------------------------------------------------------------------------"
  exit
fi 

#Checking if the region folder structure already exists.
if [  -d /qe/JAVA/$1 ]; then
  echo "-----------------------------------------------------------------------------------------------"
  echo "Region with this name already exists!!!"
  echo "-----------------------------------------------------------------------------------------------"
  exit
fi

#Checking package path.
if [ !  -e $3 ]; then
  echo "-----------------------------------------------------------------------------------------------"
  echo "Invalid package path!!!"
  echo "-----------------------------------------------------------------------------------------------"
  exit
fi

#Extracting package name.
IFS="/" read -ra segments <<< "$3"
pack=${segments[-1]}

#Copying ANSIBLE suite
cp -r /attacq/scripts/RegionCreateDelete /qe/JAVA/AnsibleTemp


#Copying the package into the specified Ansible Path.
cp $3 /home/cmmicgts/builds/

#Port selection logic.

typeset -i count=0
typeset -i port_count=8822

while [ $count -lt 3 ] && [ $port_count -le  9999 ];
do
  netstat -na|grep $port_count > /qe/JAVA/AnsibleTemp/port.txt
  if [ ! -s port.txt ] && ! fgrep -q "$port_count" /attacq/scripts/portlog.txt;
  then
    if [[ $count -eq  0 ]];
    then
      port1=$port_count
      count=$((count+1))
      port_count=$((port_count+1))
    elif [[ $count -eq  1 ]];
    then
      port2=$port_count
      count=$((count+1))
      port_count=$((port_count+1))
    else
      port3=$port_count
      count=$((count+1))
    fi
 else
    port_count=$((port_count+1))
  fi
done

if [[ $count -lt  2 ]];
then
  echo "-----------------------------------------------------------------------------------------------"
  echo "Ports are not available."
  echo "-----------------------------------------------------------------------------------------------"
else
  echo "-----------------------------------------------------------------------------------------------"
  echo "Ports found. ports are $port1,$port2 and $port3"
  echo "-----------------------------------------------------------------------------------------------"
fi

#Making entries into port-log file.
echo -e $port1 >> /extrnapp/portuselog/portlog.txt
echo -e $port2 >> /extrnapp/portuselog/portlog.txt
echo -e $port3 >> /extrnapp/portuselog/portlog.txt

#config file update logic.
cd /qe/JAVA/AnsibleTemp/RegionCreateDelete/

if [ "$2" = "o" ]; then
  config="region_config_ora"
else
  config="region_config_pg"
fi

rep1="aaaaaa"
repwith1=$1
sed -i "s/$rep1/$repwith1/g" $config 

rep2="bbbbbb"
repwith2=$regname
sed -i "s/$rep2/$repwith2/g" $config 

rep3="cccccc"
repwith3=$regpath
repwith3_esc=$(echo "$repwith3" | sed 's/[#\/]/\\&/g')
sed -i "s#$rep3#$repwith3#g" $config

rep4="dddddd"
repwith4=$pack
sed -i "s/$rep4/$repwith4/g" $config

rep5="eeeeee"
repwith5=$port1
sed -i "s/$rep5/$repwith5/g" $config

rep6="ffffff"
repwith6=$port2
sed -i "s/$rep6/$repwith6/g" $config

rep7="gggggg"
repwith7=$port3
sed -i "s/$rep7/$repwith7/g" $config

rm -f /qe/JAVA/AnsibleTemp/port.txt
echo "-----------------------------------------------------------------------------------------------"
echo "config file successfully updated."
echo "-----------------------------------------------------------------------------------------------"

read -p "Do you want to continue with the region creation? (y/Y or n/N)  :" choice
if [ "$choice" = "N" ] || [ "$choice" = "n" ];
then
  echo "-----------------------------------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------------------------------"
  echo "Please carefully verify the generated config file placed at the below location: "
  echo "/qe/JAVA/AnsibleTemp/RegionCreateDelete/$config"
  echo "-----------------------------------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------------------------------"
  echo "Post verification, run the below command to create the region:" 
  if [ $2 = "o" ]; then
    echo "/qe/JAVA/AnsibleTemp/RegionCreateDelete/region_create.sh ora"
  else
    echo "/qe/JAVA/AnsibleTemp/RegionCreateDelete/region_create.sh pg"
  fi
  echo "-----------------------------------------------------------------------------------------------"
  echo "The end."
  echo "-----------------------------------------------------------------------------------------------"
elif [ "$choice" = "Y" ] || [ "$choice" = "y" ];
then
  if [ $2 = "o" ]; then
    /qe/JAVA/AnsibleTemp/RegionCreateDelete/region_create.sh ora
  else
    /qe/JAVA/AnsibleTemp/RegionCreateDelete/region_create.sh pg
  fi
else
  echo "-----------------------------------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------------------------------"
  echo "WARNING : You entered invalid choice!!!"
  echo "Please carefully verify the generated config file placed at the below location:"
  echo "/qe/JAVA/AnsibleTemp/RegionCreateDelete/$config"
  echo "-----------------------------------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------------------------------"
  echo "Post verification, run the below command to create the region:"
  if [ $2 = "o" ]; then
    echo "/qe/JAVA/AnsibleTemp/RegionCreateDelete/region_create.sh ora"
  else
    echo "/qe/JAVA/AnsibleTemp/RegionCreateDelete/region_create.sh pg"
  fi
  echo "-----------------------------------------------------------------------------------------------"
  echo "The end."
  echo "-----------------------------------------------------------------------------------------------"
fi
