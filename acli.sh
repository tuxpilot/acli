#!/bin/bash

# le 6 Septembre 2019
# Last modification : 6 Décembre 2019 : Création

#____________________________________________________________________________
#acli stands for Asterisk Call Light Indicator

# We define here a name for the group of people we will monitor if they are in a conversation or not.
# It is very usefull since if you change it, you can run multiple instances of raspberrys with this script with only one Asterisk server
call_group_to_monitor=group_a

## Prérequisits
#1) Have an SSH account named 'acli' on the Asterisk server

#2) Can log in the Asterisk server via SSH keys with the 'acli' account from the raspberry

#3) Have a Cron that runs as root :          */1 * * * * root  ./root/bin/acli_asterisk_local_query.sh

############### Asterisk Server Script details :

# acli_asterisk_local_query.sh
#____________________________________________________________________________


##!/bin/bash
#exe_time=1
#while [ $exe_time -le 11 ]

#do
#   acli_home_dir=$(cat /etc/passwd | grep 'acli' |awk -F ':' '{ print $6 }')
#   asterisk -rx 'core show channels' >> "${acli_home_dir}"/acli_asterisk_ongoing_calls_"${call_group_to_monitor}".txt 2>&1
#   echo -e "old_data" >> "${acli_home_dir}"/acli_asterisk_ongoing_calls_"${call_group_to_monitor}".txt 2>&1
#   chmod 755 "${acli_home_dir}"/acli_asterisk_ongoing_calls_"${call_group_to_monitor}".txt
#   exe_time=$[$exe_time+1]

#done
# pkill -f acli

#____________________________________________________________________________
############### Asterisk Server Script END :  acli_asterisk_local_query.sh

#4) acli_asterisk_ongoing_calls_"${call_group_to_monitor}".txt has to be readable by the 'acli' account








#____________________________________________________________________________
# Start of the script to run on the raspberry


# We create acli_relay_last_known_state.txt, Otherwize, the script will never know the last status of the relay
echo -e 'green' > acli_relay_last_known_state.txt 2>&1

# If acli_asterisk_ongoing_calls_"${call_group_to_monitor}".txt doesn't exists already, we create it, otherwize the script will never know the last state of the relay
# If needed to have mulptiple rooms to be monitored
if [[ ! -e acli_asterisk_ongoing_calls_"${call_group_to_monitor}".txt ]]
    then    echo -e '' > acli_asterisk_ongoing_calls_"${call_group_to_monitor}".txt 2>&1
fi

# We define here the IP of the Asterisk server
ip_of_asterisk_server='XXX.XXX.XXX.XXX'


while true

do
    # We wait 5 seconds between each checks on ongoing communications on the Asterisk server
    sleep 5

    # we gather back the datas of the ongoing communications, datas gethered from the script started locally of the Asterisk server
    scp -rp acli@"${ip_of_asterisk_server}":acli_asterisk_ongoing_calls_"${call_group_to_monitor}".txt .

    #Check the last know state of the relay
    acli_relay_last_known_state=$(cat acli_relay_last_known_state.txt)

    # By default we considere that we will find no communication. And if we find one, then we pass the variable new_relay_state to 'red', which will activate the red light
    new_relay_state='green'


    # We read the file acli_asterisk_ongoing_calls_"${call_group_to_monitor}".txt from the end to have the latest datas first
    # and we read this line by line
    tac acli_asterisk_ongoing_calls_"${call_group_to_monitor}".txt | while IFS= read -r acli_name_sip_phone_to_check
        do

                # If the line contains the indicator of old datas, then we break the loop of reading acli_asterisk_names_to_check.txt
                if [[ "${acli_name_sip_phone_to_check}" == *"old_data"* ]]
                          then    break
                fi

                # We read the file acli_asterisk_names_to_check.txt and for every line of this file, we check if the indicated name figures in the line we are reading from the file acli_asterisk_ongoing_calls_"${call_group_to_monitor}".txt
                # If the line contains the name from the reading variable, then we indicate the value to red because there is someone in a conversation
                while IFS= read -r acli_name_to_check
                  do    if [[ "${acli_name_sip_phone_to_check}" == *"${acli_name_to_check}"* ]]
                            then  new_relay_state='red'
                        fi
                done < acli_asterisk_names_to_check.txt

                echo -e "acli_relay_last_known_state:${acli_relay_last_known_state}"
                echo -e "new_relay_state:${new_relay_state}"
                if [[ "${new_relay_state}" == 'red' && "${acli_relay_last_known_state}" == "green" ]]
                  then  #./acli_relai_to_red.py
                        echo -e 'red'
                        echo -e 'red' > acli_relay_last_known_state.txt 2>&1
                fi

                if [[ "${new_relay_state}" == 'green' && "${acli_relay_last_known_state}" == "red" ]]
                  then  #./acli_relai_to_green.py
                        echo -e 'green'
                        echo -e 'green' > acli_relay_last_known_state.txt 2>&1
                fi

      done
done
