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
#_____________________________________________________________________________
mkdir -p $PWD/cts_diagnostic/host_info/network
mkdir cts_diagnostic/settings_files
#_______________________________________________________________________________________________________________
function CheckRoot () {
        echo -e "${GREEN} CheckRoot ${END}"
        if [ "$EUID" -ne 0 ]; then
                echo -e "${RED} This script must be run when root or sudoer, because of docker checking ${END}"
                exit 1
        else
                echo -e "${PURPLE} good ${END}"
        fi
}

#____________________________________________________________________________
function CheckCTS() {

	if [ -d "$CTS" ]; then
                echo -e "${GREEN} CheckCTS ${END}"

                if [ -n "$FBf" ]; then
                        echo -e "${PURPLE} This Front CTS ${END}"
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
                        echo -e "${PURPLE} This Back CTS ${END}"
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
                        echo -e "${PURPLE} This Single CTS ${END} "
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
                echo -e "${PURPLE} This Voex server ${END}"
		CheckNetwork
        	CheckSS
		CheckVoexService
	fi
}
#____________________________________________________________________________

function CheckSettingsNoPass () {
        echo -e "${GREEN} CheckSettingsNoPass ${END}"
        if [ -d "$CTS" ]; then
                cp /opt/express/settings.yaml $PWD/cts_diagnostic/settings_files/cts_settings.yaml
        fi
        if [ -d "$VOEX" ]; then
		cp /opt/express-voice/settings.yaml $PWD/cts_diagnostic/settings_files/voice_settings.yaml
        fi

        settM=("postgres_password:" "etcd_password:" "redis_password:" "sentinel_password:" "prometheus:" "AWS_ACCESS_KEY_ID:" "AWS_SECRET_ACCESS_KEY:" "api_internal_token:" "phoenix_secret_key_base:" "rts_token:")

        for settM in "${settM[@]}"; do 
                echo $settM
                sed -i "s/^$settM .*/$settM /" $PWD/cts_diagnostic/settings_files/cts_settings.yaml
                sed -i "s/^$settM .*/$settM /" $PWD/cts_diagnostic/settings_files/voice_settings.yaml
        done

        echo -e "${PURPLE} good ${END}"


}

function Help(){
    echo -e "${GREEN} HELP ${END}"
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
                --help / -h                     help
                --nopass / -np                  removes passwords from settings.yaml
                --noarchive / -na               archive is not created and cts_diagnostic is not deleted
        "
    echo "*************************************************************************************"
}


function CheckVoexService() {
        echo -e "${GREEN} CheckVoexService ${END}"
        if [ -d "$VOEX" ]; then
        cp /opt/express-voice/.voex/express-voice.service $PWD/cts_diagnostic/host_info/network/
        fi
        echo -e "${PURPLE} good ${END}"        
}

function CheckNetwork() {
        echo -e " ${GREEN} CheckNetwork ${END} "
        ip a > $PWD/cts_diagnostic/host_info/network/interfaces.txt
        iptables -L -nvx > $PWD/cts_diagnostic/host_info/network/iptables.txt
        ip route > $PWD/cts_diagnostic/host_info/network/iproute.txt
        if [ -d "$CTS" ]; then
        ccs_host=$(grep "ccs_host:" /opt/express/settings.yaml | awk '{print $2}')
        nslookup $ccs_host > $PWD/cts_diagnostic/host_info/network/nslookup.txt 2>&1
        elif [ ! -d "$CTS" -a -d "$VOEX" ]; then
        ccs_host=$(grep "turnserver_server_name:" /opt/express-voice/settings.yaml | awk '{print $2}')
        nslookup $ccs_host > $PWD/cts_diagnostic/host_info/network/nslookup.txt 2>&1
        elif [ ! -d "$CTS" -a ! -d "$VOEX" ]; then
        echo "/opt/express/ and /opt/express-voice/ didn't exist" > $PWD/cts_diagnostic/host_info/no-express-folders!.txt
        ccs_host=noname
        fi
        echo -e "${PURPLE} good ${END}"
}

function CheckTelnet() {
        echo -e " ${GREEN} CheckTelnet ${END} "
        if command -v telnet > /dev/null ; then
        (echo open ru.public.express 5001; sleep 1; echo quit) | telnet > $PWD/cts_diagnostic/host_info/network/telnet.txt 2> /dev/null
        (echo open registry.public.express 443; sleep 1; echo quit) | telnet >> $PWD/cts_diagnostic/host_info/network/telnet.txt 2> /dev/null
        else
        echo -e "${RED} Telnet is not installed ${END}"
        echo "Telnet is not installed" > $PWD/cts_diagnostic/host_info/network/telnet.txt
        fi
        echo -e "${PURPLE} good ${END}"
}

function CheckSS(){
        echo -e " ${GREEN} CheckSS ${END} "
        if command -v ss > /dev/null ; then
        ss -tunlp > $PWD/cts_diagnostic/host_info/network/ss.txt
        else
        echo -e "${RED} SS is not installed ${END}"
        echo "SS is not installed" > $PWD/cts_diagnostic/host_info/network/ss.txt
        fi
        echo -e "${PURPLE} good ${END}"
}

function CheckSSL () {
        echo -e "${GREEN} CheckSSL ${END}"
        echo -e "GET / HTTP/1.0\n\n" | timeout 15 openssl s_client -connect $ccs_host:443 > $PWD/cts_diagnostic/host_info/network/openssl_info.txt 2>&1
        echo -e "${PURPLE} good ${END}"
}

function CheckSettingsFiles () {
        echo -e "${GREEN} CheckSettingsFiles ${END}"

        if [ -d "$CTS" ]; then
                cp /opt/express/settings.yaml $PWD/cts_diagnostic/settings_files/cts_settings.yaml
        fi
        if [ -d "$VOEX" ]; then
		cp /opt/express-voice/settings.yaml $PWD/cts_diagnostic/settings_files/voice_settings.yaml
        fi

        echo -e "${PURPLE} good ${END}"
}

function CheckDB(){
        echo -e "${GREEN} CheckDB ${END}"
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
		(echo open $ip $port; sleep 1; echo quit) | telnet >> $PWD/cts_diagnostic/host_info/network/db_telnet.txt 2> /dev/null
                
                status_ok=$(grep 'Connected to' $PWD/cts_diagnostic/host_info/network/db_telnet.txt )
                status_error=$(grep 'telnet: Unable to connect to remote host: Connection refused' $PWD/cts_diagnostic/host_info/network/db_telnet.txt )
                if [ -n "$status_ok" ]; then
                        echo -e "${PURPLE} Connected to $ip ${END}"
                elif [ -n "$status_error" ]; then
                        echo -e "${RED} Error connected to $ip ${END}"
                fi
	done
}


function CheckKafka(){
        echo -e " ${GREEN} CheckKafka ${END}"
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
                echo "check port 9092" >> $PWD/cts_diagnostic/host_info/network/kafka_telnet.txt
                (echo open $ip $port_kafka_1; sleep 1; echo quit) | telnet "$ip" "$port_kafka_1" >> $PWD/cts_diagnostic/host_info/network/kafka_telnet.txt 2>&1
                echo "check port 9093" >> $PWD/cts_diagnostic/host_info/network/kafka_telnet.txt
                (echo open $ip $port_kafka_2; sleep 1; echo quit) | telnet "$ip" "$port_kafka_2" >> $PWD/cts_diagnostic/host_info/network/kafka_telnet.txt 2>&1

                status_ok=$(grep 'Connected to' $PWD/cts_diagnostic/host_info/network/kafka_telnet.txt )
                status_error=$(grep 'telnet: Unable to connect to remote host: Connection refused' $PWD/cts_diagnostic/host_info/network/kafka_telnet.txt )
                if [ -n "$status_ok" ]; then
                        echo -e "${PURPLE} Connected to $ip ${END}"
                elif [ -n "$status_error" ]; then
                        echo -e "${RED} Error connected to $ip ${END}"
                fi
        done
}


function CheckEtcd(){
        echo -e "${GREEN} CheckEtcd ${END}"
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
		(echo open $ip $port; sleep 1; echo quit) | telnet >> $PWD/cts_diagnostic/host_info/network/etcd_telnet.txt 2> /dev/null

                status_ok=$(grep 'Connected to' $PWD/cts_diagnostic/host_info/network/etcd_telnet.txt )
                status_error=$(grep 'telnet: Unable to connect to remote host: Connection refused' $PWD/cts_diagnostic/host_info/network/etcd_telnet.txt )
                if [ -n "$status_ok" ]; then
                        echo -e "${PURPLE} Connected to $ip ${END}"
                elif [ -n "$status_error" ]; then
                        echo -e "${RED} Error connected to $ip ${END}"
                fi
	done
}

function CheckRedis(){
        echo -e "${GREEN} CheckRedis ${END}"
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
		(echo open $ip $port; sleep 1; echo quit) | telnet >> $PWD/cts_diagnostic/host_info/network/redis_telnet.txt 2> /dev/null

                status_ok=$(grep 'Connected to' $PWD/cts_diagnostic/host_info/network/redis_telnet.txt )
                status_error=$(grep 'telnet: Unable to connect to remote host: Connection refused' $PWD/cts_diagnostic/host_info/network/redis_telnet.txt )
                if [ -n "$status_ok" ]; then
                        echo -e "${PURPLE} Connected to $ip ${END}"
                elif [ -n "$status_error" ]; then
                        echo -e "${RED} Error connected to $ip ${END}"
                fi
	done
}


function CheckVoexCS(){
        echo -e "${GREEN} CheckVoexCS ${END}"
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
		(echo open $ip $port; sleep 1; echo quit) | telnet >> $PWD/cts_diagnostic/host_info/network/voex_r_cs_telnet.txt 2> /dev/null

                status_ok=$(grep 'Connected to' $PWD/cts_diagnostic/host_info/network/voex_r_cs_telnet.txt )
                status_error=$(grep 'telnet: Unable to connect to remote host: Connection refused' $PWD/cts_diagnostic/host_info/network/voex_r_cs_telnet.txt )
                if [ -n "$status_ok" ]; then
                        echo -e "${PURPLE} Connected to $ip ${END}"
                elif [ -n "$status_error" ]; then
                        echo -e "${RED} Error connected to $ip ${END}"
                fi

	done
        fi
}

function CheckFB() {
        echo -e "${GREEN} CheckFB ${END}"
        front_ip=$(grep "frontend_host:" /opt/express/settings.yaml | awk '{print $2}')
        back_ip=$(grep "backend_host:" /opt/express/settings.yaml | awk '{print $2}')
        ping -c 15 $front_ip >> $PWD/cts_diagnostic/host_info/network/ping_front.txt 2> /dev/null
        status_ok=$(grep 'Connected to' $PWD/cts_diagnostic/host_info/network/voex_r_cs_telnet.txt )
        status_front=$(grep "PING $front_ip" -A 15 $PWD/cts_diagnostic/host_info/network/ping_front.txt )
        if [ -n "$status_ok" ]; then
                echo -e "${GREEN} front ${END}"
                echo -e "${PURPLE} "$status_front" ${END}" | sed 's/data\./data.\n/g; s/ms/ms\n/g'
       else
                echo -e "${RED} Please view the file ping_front.txt ${END}"

        fi
        ping -c 15 $back_ip >> $PWD/cts_diagnostic/host_info/network/ping_back.txt 2> /dev/null

        status_back=$(grep "PING $back_ip " -A 15 $PWD/cts_diagnostic/host_info/network/ping_back.txt )
        if [ -n "$status_ok" ]; then
                echo -e "${GREEN} back ${END}"
                echo -e "${PURPLE} "$status_back" ${END}" | sed 's/data\./data.\n/g; s/ms/ms\n/g'
        else
                echo -e "${RED} Please view the file ping_back.txt ${END}"
        fi
}

function CheckJanus(){
        echo -e "${GREEN} CheckJanus ${END}"
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
		echo $ip $port
		(echo open $ip $port; sleep 1; echo quit) | telnet >> $PWD/cts_diagnostic/host_info/network/janus_telnet.txt 2> /dev/null

                status_ok=$(grep 'Connected to' $PWD/cts_diagnostic/host_info/network/janus_telnet.txt )
                status_error=$(grep 'telnet: Unable to connect to remote host: Connection refused' $PWD/cts_diagnostic/host_info/network/janus_telnet.txt )
                if [ -n "$status_ok" ]; then
                        echo -e "${PURPLE} Connected to $ip ${END}"
                elif [ -n "$status_error" ]; then
                        echo -e "${RED} Error connected to $ip ${END}"
                fi
	done
        fi
}


function CreateArchive () {
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
        tar -czf $ccs_host-$serverrole.tar.gz cts_diagnostic/
        rm -rf cts_diagnostic
        echo -e "${GREEN} Written to $PWD/$ccs_host-$serverrole.tar.gz ${END}"
}


# Переменная для отслеживания ключей
nopass=false
noarchive=false

while getopts ":hna" opt; do
    case $opt in
        h)
            Help
            exit 0
            ;;
        n)
            nopass=true
            ;;
        a)
            noarchive=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            Help
            exit 1
            ;;
    esac
done


CheckRoot
CheckCTS
CheckSettingsFiles

if [ "$nopass" = true ]; then
    echo "No password option selected."
    CheckSettingsNoPass
    CreateArchive
fi

if [ "$noarchive" = true ]; then
    echo "No archive option selected."
    
fi


if [ "$nopass" = false ] && [ "$noarchive" = false ]; then
    echo "No specific options selected; proceeding with default operations."
    CreateArchive
fi



