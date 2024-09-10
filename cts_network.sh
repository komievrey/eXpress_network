#!/bin/bash
#____________________
END="\033[0m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
PURPLE="\033[0;35m"
#_____________________________________________________________________________
CTS=/opt/express/
VOEX=/opt/express-voice/
FBf=$(grep "cts_frontend:" /opt/express/settings.yaml | awk '{print $1}')
FBb=$(grep "cts_backend:" /opt/express/settings.yaml | awk '{print $1}')
#_______________________________________________________________________________________________________________
function CheckRoot () {
        echo -e "${PURPLE} CheckRoot ${END}"
        if [ "$EUID" -ne 0 ]; then
                echo -e "${RED} This script must be run when root or sudoer, because of docker checking ${END}"
                exit 1
        else
                echo -e "${GREEN} good ${END}"
                mkdir -p $PWD/cts_network/network
                mkdir cts_network/settings_files
        fi
}

#____________________________________________________________________________
function CheckCTS() {

	if [ -d "$CTS" ]; then
                echo -e "${PURPLE} CheckCTS ${END}"

                if [ -n "$FBf" ]; then
                        echo -e "${YELLOW} This Front CTS ${END}"
                        CheckRedis
                        CheckNetwork
        	            CheckTelnet
        	            CheckSS
                        CheckDB
                        CheckKafka
                        CheckEtcd
                        CheckFB
                        CheckSSL
                        

                elif [ -n "$FBb" ]; then
                        echo -e "${YELLOW} This Back CTS ${END}"
                        CheckNetwork
        	            CheckTelnet
        	            CheckSS
                        CheckDB
                        CheckKafka
                        CheckEtcd
                        CheckRedis
                        CheckVoexCS
                        CheckFB
                        CheckJanus
                        CheckSSL
                        

                elif [ -z "$FBb" ] && [ -z "$FBf" ]; then
                        echo -e "${YELLOW} This Single CTS ${END} "
                        CheckNetwork
        	            CheckTelnet
        	            CheckSS
                        CheckDB
                        CheckKafka
                        CheckEtcd
                        CheckRedis
                        CheckVoexCS
                        CheckJanus
                        CheckSSL
                        

                fi
        fi
	if [ -d "$VOEX" ]; then
            echo -e "${YELLOW} This Voex server ${END}"
		    CheckNetwork
            CheckSS
		    CheckVoexService
	fi
}
#____________________________________________________________________________

function CheckSettingsNoPass () {
        echo -e "${PURPLE} CheckSettingsNoPass ${END}"
        if [ -d "$CTS" ]; then
                cp /opt/express/settings.yaml $PWD/cts_network/settings_files/cts_settings.yaml
        fi
        if [ -d "$VOEX" ]; then
		cp /opt/express-voice/settings.yaml $PWD/cts_network/settings_files/voice_settings.yaml
        fi

        settM=("postgres_password:" "etcd_password:" "redis_password:" "sentinel_password:" "prometheus:" "AWS_ACCESS_KEY_ID:" "AWS_SECRET_ACCESS_KEY:" "api_internal_token:" "phoenix_secret_key_base:" "rts_token:")

        for settM in "${settM[@]}"; do 
                #echo $settM
                sed -i "s/^$settM .*/$settM /" $PWD/cts_network/settings_files/cts_settings.yaml
                sed -i "s/^$settM .*/$settM /" $PWD/cts_network/settings_files/voice_settings.yaml
        done

        echo -e "${GREEN} good ${END}"


}

function Help(){
    echo -e "${PURPLE} HELP ${END}"
    echo "*************************************************************************************"
    echo "Script collects data about service availability, network connections and settings:
            - Redis
            - Postgres
            - Kafka
            - Etcd
            - iptables
            - ip route
            - nslookup ccs_host
            - Telnet to registry.public.express
            - Telnet to ru.public.express (RTS)
            - Netstat (ss)
            - SSL
            - Copy settings.yaml
            - voex_redis
            - Availability Janus"
    echo "
        keys:
                -h                     help
                -np                    removes passwords from settings.yaml
                -ar                    archive created cts_network
        "
    echo "*************************************************************************************"
}


function CheckVoexService() {
        echo -e "${PURPLE} CheckVoexService ${END}"
        if [ -d "$VOEX" ]; then
        cp /opt/express-voice/.voex/express-voice.service $PWD/cts_network/network/
        fi
        echo -e "${GREEN} good ${END}"        
}

function CheckNetwork() {
        echo -e " ${PURPLE} CheckNetwork ${END} "
        ip a > $PWD/cts_network/network/interfaces.txt
        iptables -L -nvx > $PWD/cts_network/network/iptables.txt
        ip route > $PWD/cts_network/network/iproute.txt
        if [ -d "$CTS" ]; then
        ccs_host=$(grep "ccs_host:" /opt/express/settings.yaml | awk '{print $2}')
        nslookup $ccs_host > $PWD/cts_network/network/nslookup.txt 2>&1
        elif [ ! -d "$CTS" -a -d "$VOEX" ]; then
        ccs_host=$(grep "turnserver_server_name:" /opt/express-voice/settings.yaml | awk '{print $2}')
        nslookup $ccs_host > $PWD/cts_network/network/nslookup.txt 2>&1
        elif [ ! -d "$CTS" -a ! -d "$VOEX" ]; then
        echo "/opt/express/ and /opt/express-voice/ didn't exist" > $PWD/cts_network/no-express-folders!.txt
        ccs_host=noname
        fi
        echo -e "${GREEN} good ${END}"
}

function CheckTelnet() {
        echo -e " ${PURPLE} CheckTelnet ${END} "
        if command -v telnet > /dev/null ; then
        (echo open ru.public.express 5001; sleep 1; echo quit) | telnet > $PWD/cts_network/network/telnet.txt 2> /dev/null
        (echo open registry.public.express 443; sleep 1; echo quit) | telnet >> $PWD/cts_network/network/telnet.txt 2> /dev/null
        else
        echo -e "${RED} Telnet is not installed ${END}"
        echo "Telnet is not installed" > $PWD/cts_network/network/telnet.txt
        fi
        echo -e "${GREEN} good ${END}"
}

function CheckSS(){
        echo -e " ${PURPLE} CheckSS ${END} "
        if command -v ss > /dev/null ; then
        ss -tunlp > $PWD/cts_network/network/ss.txt
        else
        echo -e "${RED} SS is not installed ${END}"
        echo "SS is not installed" > $PWD/cts_network/network/ss.txt
        fi
        echo -e "${GREEN} good ${END}"
}

function CheckSSL () {
        echo -e "${PURPLE} CheckSSL ${END}"
        echo -e "GET / HTTP/1.0\n\n" | timeout 15 openssl s_client -connect $ccs_host:443 > $PWD/cts_network/network/openssl_info.txt 2>&1
        echo -e "${GREEN} good ${END}"
}

function CheckSettingsFiles () {
        echo -e "${PURPLE} CheckSettingsFiles ${END}"

        if [ -d "$CTS" ]; then
                cp /opt/express/settings.yaml $PWD/cts_network/settings_files/cts_settings.yaml
        fi
        if [ -d "$VOEX" ]; then
		cp /opt/express-voice/settings.yaml $PWD/cts_network/settings_files/voice_settings.yaml
        fi

        echo -e "${GREEN} good ${END}"
}

function CheckDB(){
        echo -e "${PURPLE} CheckDB ${END}"
	check_DB_ip=$(grep "postgres_endpoints:" /opt/express/settings.yaml | awk '{print $2}')
	IFS=',' read -r -a addresses <<< "$check_DB_ip"
	declare -a ips
	declare -a ports
	for address in "${addresses[@]}"; do
    		IFS=':' read -r ip port <<< "$address"
    		ips+=("$ip")
    		ports+=("$port")
	done
	for i in "${!ips[@]}"; do
		ip="${ips[$i]}"
		port="${ports[$i]}"
		#echo $ip $port
		(echo open $ip $port; sleep 1; echo quit) | telnet >> $PWD/cts_network/network/db_telnet.txt 2> /dev/null
                
                status_ok=$(grep 'Connected to' $PWD/cts_network/network/db_telnet.txt )
                status_error=$(grep 'telnet: Unable to connect to remote host: Connection refused' $PWD/cts_network/network/db_telnet.txt )
                if [ -n "$status_ok" ]; then
                        echo -e "${GREEN} Connected to $ip ${END}"
                elif [ -n "$status_error" ]; then
                        echo -e "${RED} Error connected to $ip ${END}"
                fi
	done
}


function CheckKafka(){
        echo -e " ${PURPLE} CheckKafka ${END}"
        port_kafka_1="9092"
        port_kafka_2="9093"
        check_Kafka_ip=$(grep "kafka_host:" /opt/express/settings.yaml | awk '{print $2}')

        IFS=',' read -r -a addresses <<< "$check_Kafka_ip"
        declare -a ipk
        for address in "${addresses[@]}"; do
                IFS=':' read -r ip <<< "$address"
                ipk+=("$ip")
        done
        for i in "${!ipk[@]}"; do
                ip="${ipk[$i]}"
                #echo $ip
                echo "check port 9092" >> $PWD/cts_network/network/kafka_telnet.txt
                (echo open $ip $port_kafka_1; sleep 1; echo quit) | telnet "$ip" "$port_kafka_1" >> $PWD/cts_network/network/kafka_telnet.txt 2>&1
                echo "check port 9093" >> $PWD/cts_network/network/kafka_telnet.txt
                (echo open $ip $port_kafka_2; sleep 1; echo quit) | telnet "$ip" "$port_kafka_2" >> $PWD/cts_network/network/kafka_telnet.txt 2>&1

                status_ok=$(grep 'Connected to' $PWD/cts_network/network/kafka_telnet.txt )
                status_error=$(grep 'telnet: Unable to connect to remote host: Connection refused' $PWD/cts_network/network/kafka_telnet.txt )
                if [ -n "$status_ok" ]; then
                        echo -e "${GREEN} Connected to $ip ${END}"
                elif [ -n "$status_error" ]; then
                        echo -e "${RED} Error connected to $ip ${END}"
                fi
        done
}


function CheckEtcd(){
        echo -e "${PURPLE} CheckEtcd ${END}"
	check_etcd_ip=$(grep "etcd_endpoints:" /opt/express/settings.yaml | awk '{print $2}' | sed 's,http://,,g')
	IFS=',' read -r -a addresses <<< "$check_etcd_ip"
	declare -a ips
	declare -a ports
	for address in "${addresses[@]}"; do
    		IFS=':' read -r ip port <<< "$address"
    		ips+=("$ip")
    		ports+=("$port")
	done
	for i in "${!ips[@]}"; do
		ip="${ips[$i]}"
		port="${ports[$i]}"
		#echo $ip $port
		(echo open $ip $port; sleep 1; echo quit) | telnet >> $PWD/cts_network/network/etcd_telnet.txt 2> /dev/null

                status_ok=$(grep 'Connected to' $PWD/cts_network/network/etcd_telnet.txt )
                status_error=$(grep 'telnet: Unable to connect to remote host: Connection refused' $PWD/cts_network/network/etcd_telnet.txt )
                if [ -n "$status_ok" ]; then
                        echo -e "${GREEN} Connected to $ip ${END}"
                elif [ -n "$status_error" ]; then
                        echo -e "${RED} Error connected to $ip ${END}"
                fi
	done
}

function CheckRedis(){
        echo -e "${PURPLE} CheckRedis ${END}"
	check_redis_ip=$(grep -E 'redis_connection_string' /opt/express/settings.yaml | grep -v 'voex_' | awk '{print $2}' | sed -e 's,redis://,,g' -e 's,/0,,g')
	IFS=',' read -r -a addresses <<< "$check_redis_ip"
	declare -a ips
	declare -a ports
	for address in "${addresses[@]}"; do
    		IFS=':' read -r ip port <<< "$address"
    		ips+=("$ip")
    		ports+=("$port")
	done
	for i in "${!ips[@]}"; do
		ip="${ips[$i]}"
		port="${ports[$i]}"
		#echo $ip $port
		(echo open $ip $port; sleep 1; echo quit) | telnet >> $PWD/cts_network//network/redis_telnet.txt 2> /dev/null

                status_ok=$(grep 'Connected to' $PWD/cts_network/network/redis_telnet.txt )
                status_error=$(grep 'telnet: Unable to connect to remote host: Connection refused' $PWD/cts_network/network/redis_telnet.txt )
                if [ -n "$status_ok" ]; then
                        echo -e "${GREEN} Connected to $ip ${END}"
                elif [ -n "$status_error" ]; then
                        echo -e "${RED} Error connected to $ip ${END}"
                fi
	done
}


function CheckVoexCS(){
        echo -e "${PURPLE} CheckVoexCS ${END}"
	check_voex_cs=$(grep "voex_redis_connection_string:" /opt/express/settings.yaml | awk -F'[@:]' '{print $(NF-1)":"$NF}' | sed 's,/1,,g')
	if [ -n $check_voex_cs ]; then
        IFS=',' read -r -a addresses <<< "$check_voex_cs"
	declare -a ips
	declare -a ports
	for address in "${addresses[@]}"; do
    		IFS=':' read -r ip port <<< "$address"
    		ips+=("$ip")
    		ports+=("$port")
	done
	for i in "${!ips[@]}"; do
		ip="${ips[$i]}"
		port="${ports[$i]}"
		#echo $ip $port
		(echo open $ip $port; sleep 1; echo quit) | telnet >> $PWD/cts_network/network/voex_r_cs_telnet.txt 2> /dev/null

                status_ok=$(grep 'Connected to' $PWD/cts_network/network/voex_r_cs_telnet.txt )
                status_error=$(grep 'telnet: Unable to connect to remote host: Connection refused' $PWD/cts_network/network/voex_r_cs_telnet.txt )
                if [ -n "$status_ok" ]; then
                        echo -e "${GREEN} Connected to $ip ${END}"
                elif [ -n "$status_error" ]; then
                        echo -e "${RED} Error connected to $ip ${END}"
                fi

	done
        fi
}

function CheckFB() {
    echo -e "${PURPLE} CheckFB ${END}"
    
    front_ip=$(grep "frontend_host:" /opt/express/settings.yaml | awk '{print $2}')
    back_ip=$(grep "backend_host:" /opt/express/settings.yaml | awk '{print $2}')

    ping -c 15 $front_ip > $PWD/cts_network/network/ping_front.txt 2> /dev/null
    status_front=$(grep "PING $front_ip" -A 4 $PWD/cts_network/network/ping_front.txt)
    
    if [ -n "$status_front" ]; then
        echo -e "${PURPLE} front ${END}"
        echo -e "${GREEN} $status_front ${END}" | sed 's/data\./data.\n/g; s/ms/ms\n/g'
    else
        echo -e "${RED} Please view the file ping_front.txt ${END}"
    fi
    
    ping -c 15 $back_ip > $PWD/cts_network/network/ping_back.txt 2> /dev/null
    status_back=$(grep "PING $back_ip" -A 4 $PWD/cts_network/network/ping_back.txt)
    
    if [ -n "$status_back" ]; then
        echo -e "${PURPLE} back ${END}"
        echo -e "${GREEN} $status_back ${END}" | sed 's/data\./data.\n/g; s/ms/ms\n/g'
    else
        echo -e "${RED} Please view the file ping_back.txt ${END}"
    fi
}


function CheckJanus(){
        echo -e "${PURPLE} CheckJanus ${END}"
	check_janus_ws=$(docker exec -it cts-messaging-1 ./bin/messaging rpc Messaging.janus_urls | sed -e 's/\[//g' -e 's/\]//g' -e 's/\"//g' -e 's,ws://,,g')
	if [ -n $check_voex_cs ]; then
        IFS=',' read -r -a addresses <<< "$check_janus_ws"
	declare -a ips
	declare -a ports
	for address in "${addresses[@]}"; do
    		IFS=':' read -r ip port <<< "$address"
    		ips+=("$ip")
    		ports+=("$port")
	done
	for i in "${!ips[@]}"; do
		ip="${ips[$i]}"
		port="${ports[$i]}"
		#echo $ip $port
		(echo open $ip $port; sleep 1; echo quit) | telnet >> $PWD/cts_network/network/janus_telnet.txt 2> /dev/null

                status_ok=$(grep 'Connected to' $PWD/cts_network/network/janus_telnet.txt )
                status_error=$(grep 'telnet: Unable to connect to remote host: Connection refused' $PWD/cts_network/network/janus_telnet.txt )
                if [ -n "$status_ok" ]; then
                        echo -e "${GREEN} Connected to $ip ${END}"
                elif [ -n "$status_error" ]; then
                        echo -e "${RED} Error connected to $ip ${END}"
                fi
	done
        fi
}


function CreateArchive () {
        echo -e "${PURPLE} CreateArchive ${END}"
        date=$(date +"%d.%m_%H.%M")
        if [ -d "$CTS" ]; then
                if grep -q "cts_frontend: true" /opt/express/settings.yaml; then serverrole=front-network
                elif grep -q "cts_backend: true" /opt/express/settings.yaml; then serverrole=back-network
                else serverrole=single-network
                fi
        elif [ ! -d "$CTS" -a -d "$VOEX" ]; then
        serverrole=voex-network
        elif [ ! -d "$CTS" -a ! -d "$VOEX" ]; then
        serverrole=noserver
        echo -e "${RED} No Express folders in /opt! ${END}"
        fi
        tar -czf $date-$ccs_host-$serverrole.tar.gz cts_network/
        rm -rf cts_network
        echo -e "${GREEN} Written to $PWD/$date-$ccs_host-$serverrole.tar.gz ${END}"
}

check_root_done=false
check_cts_done=false
check_settings_no_pass_done=false
create_archive_done=false

if [[ "$*" == *"-h"* && "$*" != "-h" ]]; then
    echo -e "${RED} Ключ -h не может использоваться с другими ключами ${END}"
    exit 1
fi

if [[ "$*" == *"-np"* || "$*" == *"-npar"* || "$*" == *"-arnp"* ]]; then
    if [ "$check_root_done" = false ]; then
        CheckRoot
        check_root_done=true
    fi
    if [ "$check_cts_done" = false ]; then
        CheckCTS
        check_cts_done=true
    fi
    if [ "$check_settings_no_pass_done" = false ]; then
        CheckSettingsNoPass
        check_settings_no_pass_done=true
    fi
fi

if [[ "$*" == *"-ar"* ]]; then
    if [ "$check_root_done" = false ]; then
        CheckRoot
        check_root_done=true
    fi
    if [ "$check_cts_done" = false ]; then
        CheckCTS
        check_cts_done=true
    fi
    if [ "$create_archive_done" = false ]; then
        CreateArchive
        create_archive_done=true
    fi
fi

for arg in "$@"; do
    case $arg in
        -h)
            Help
            ;;
        -np)
            # CheckSettingsNoPass
            ;;
        -ar)
            # CreateArchive
            ;;
        -npar)
            if [ "$create_archive_done" = false ]; then
                CreateArchive
                create_archive_done=true
            fi
            ;;
        -arnp)
            if [ "$create_archive_done" = false ]; then
                CreateArchive
                create_archive_done=true
            fi
            ;;
        *)
            echo -e "${RED} Неизвестный ключ: $arg ${END}"
            ;;
    esac
done

if [ $# -eq 0 ]; then
    if [ "$check_root_done" = false ]; then
        CheckRoot
        check_root_done=true
    fi
    if [ "$check_cts_done" = false ]; then
        CheckCTS
        check_cts_done=true
    fi
    if [ "$check_settings_no_pass_done" = false ]; then
        CheckSettingsFiles
        check_settings_no_pass_done=true
    fi
fi