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
if [  -d /attacq/$1 ]; then
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

cd /attacq/
mkdir $1
cd $1
mkdir packages

if [ "$2" = "p" ];
then
  mkdir PG_Cert
fi

mkdir install_ini
cd install_ini

if [ "$2" = "o" ];
then
  cp /attacq/scripts/oracle_ini/oracle_acq_sample.ini .
  mv oracle_sample.ini $1.ini
else
  cp /attacq/scripts/postgres_ini/postgres_acq_sample.ini .
  mv postgres_sample.ini $1.ini
fi

#Copying the package into the region.
cp $3 /attacq/$1/packages/

#Port selection logic.

typeset -i count=0
typeset -i port_count=8922

while [ $count -lt 2 ] && [ $port_count -le  9999 ];
do
  netstat -na|grep $port_count > port.txt
  if [ ! -s port.txt ] && ! fgrep -q "$port_count" /attacq/scripts/portlog.txt;
  then
    if [[ $count -eq  0 ]];
    then
      port1=$port_count
      count=$((count+1))
      port_count=$((port_count+1))
    else
      port2=$port_count
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
  echo "Ports found. ports are $port1 and $port2"
  echo "-----------------------------------------------------------------------------------------------"
fi

#Making entries into port-log file.
echo -e $port1 >> /devel/CMM64/portlog/portlog.txt
echo -e $port2 >> /devel/CMM64/portlog/portlog.txt 


#ini file update logic.

rep1=$(cat $1.ini | grep -h "TPEServerPort")
repwith1="TPEServerPort:"
repwith1+=$port1
sed -i "s/$rep1/$repwith1/g" $1.ini 

rep2=$(grep -h "J3270Port" $1.ini)
repwith2="J3270Port:"
repwith2+=$port2
sed -i "s/$rep2/$repwith2/g" $1.ini 

rep3="xxxxxx"
repwith3=$1
sed -i "s/$rep3/$repwith3/g" $1.ini

rep4="pkg"
repwith4=$pack
sed -i "s/$rep4/$repwith4/g" $1.ini

rm port.txt
echo "-----------------------------------------------------------------------------------------------"
echo "ini file successfully updated."
echo "-----------------------------------------------------------------------------------------------"

if [ "$2" = "p" ];
then
  echo "-----------------------------------------------------------------------------------------------"
  echo "Generating Postgres artifacts."
  echo "-----------------------------------------------------------------------------------------------"
   sudo -u postgres /attacq/scripts/postgres.ksh $1
  if [ $? -eq  0 ];
  then
    cp /var/lib/pgsql/$1_generated_certificate/root.crt /attacq/$1/PG_Cert/
    cp /var/lib/pgsql/$1_generated_certificate/postgres.crt /attacq/$1/PG_Cert/
    cp /var/lib/pgsql/$1_generated_certificate/postgres.key.der /attacq/$1/PG_Cert/
    echo "-----------------------------------------------------------------------------------------------"
    echo "Postgres artifacts are copied to the below location:"
    echo "/attacq/$1/PG_Cert"
    echo "-----------------------------------------------------------------------------------------------"
  else
    rm -rf /attacq/$1
    sed -i "s/\b${port1}\b//g" /attacq/scripts/portlog.txt
    sed -i "s/\b${port2}\b//g" /attacq/scripts/portlog.txt
    exit
  fi
else
  :
fi

read -p "Do you want to continue with the region creation? (y/Y or n/N)  :" choice

if [ "$choice" = "N" ] || [ "$choice" = "n" ];
then
  echo "-----------------------------------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------------------------------"
  echo "Please carefully verify the generated ini file placed at the below location: "
  echo "/attacq/$1/install_ini"
  echo "-----------------------------------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------------------------------"
  echo "Post verification, run the below command to create the region:" 
  echo "ESS_UTL_REGION_CREATE.ksh -c -i /attacq/$1/install_ini/$1.ini ACQ $1"
  echo "-----------------------------------------------------------------------------------------------"
  echo "The end."
  echo "-----------------------------------------------------------------------------------------------"
elif [ "$choice" = "Y" ] || [ "$choice" = "y" ];
then
  ESS_UTL_REGION_CREATE.ksh -c -i /attacq/$1/install_ini/$1.ini ACQ $1
else
  echo "-----------------------------------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------------------------------"
  echo "WARNING : You entered invalid choice!!!"
  echo "Please carefully verify the generated ini file placed at the below location:"
  echo "/attacq/$1/install_ini"
  echo "-----------------------------------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------------------------------"
  echo "Post verification, run the below command to create the region:"
  echo "ESS_UTL_REGION_CREATE.ksh -c -i /attacq/$1/install_ini/$1.ini ACQ $1"
  echo "-----------------------------------------------------------------------------------------------"
  echo "The end."
  echo "-----------------------------------------------------------------------------------------------"
fi
