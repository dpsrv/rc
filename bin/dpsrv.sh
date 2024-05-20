cd $(dirname ${BASH_SOURCE[0]})/../..
export DPSRV_HOME=$PWD
cd $OLDPWD

if [ -f $DPSRV_HOME/local.env ]; then
	[[ $- =~ a ]] || set -a && a=a
	. $DPSRV_HOME/local.env
	[ -z $a ] || set +a
fi

export DPSRV_SERVICES=( $( grep -l 'restart:[ ]*unless-stopped' $DPSRV_HOME/*/docker-compose.yml | sed "s#^$DPSRV_HOME/##g"|cut -d/ -f1 ) )
export DPSRV_SERVICES_UP=( scheduler bind nginx mongo mysql mailserver roundcube )

export HOSTNAME=${HOSTNAME:-$(hostname)}
export GIT_CREDENTIALS=$(cat $HOME/.git-credentials|base64 -w 0)

if ! [[ "$PATH" =~ "$DPSRV_HOME/rc/bin" ]]; then
	export PATH="$PATH:$DPSRV_HOME/rc/bin"
fi

function dpsrv-vm() {
	if [ -z "$1" ]; then
		echo "Usage: $FUNCNAME <vm> <command>"
		echo "  e.g: $FUNCNAME docker reset"
		return 1
	fi
	VBoxManage controlvm "$@" 
}

function dpsrv-startvm() {
	if [ -z "$1" ]; then
		echo "Usage: $FUNCNAME <vm>"
		echo "  e.g: $FUNCNAME docker"
		return 1
	fi
	VBoxManage startvm --type headless "$@"
}

function dpsrv-spotlight-off() {
	sudo mdutil -a -d -i off
}

function dpsrv-show-keychain-info() {
	 security -v show-keychain-info $HOME/Library/Keychains/login.keychain-db
}

function dpsrv-unlock-keychain() {
	[ -x security ] || return 0
	show-keychain-info || security -v unlock-keychain $HOME/Library/Keychains/login.keychain-db
}

function dpsrv-up() {(
	set -e
	dpsrv-unlock-keychain
	for service in "${DPSRV_SERVICES_UP[@]}"; do
		cd $DPSRV_HOME/$service
		echo "Bringing up ${PWD##*/}"
		docker compose up --build -d
		echo "exit: $?"
		cd $OLDPWD
	done
)}

function dpsrv-down() {(
	set -e
	for service in "${DPSRV_SERVICES[@]}"; do
		cd $DPSRV_HOME/$service
		echo "Tearing down ${PWD##*/}"
		docker compose down
		cd $OLDPWD
	done
)}

function dpsrv-build() {(
	set -e
	for service in "${DPSRV_SERVICES[@]}"; do
		cd $DPSRV_HOME/$service
		echo "Tearing down ${PWD##*/}"
		docker compose build
		cd $OLDPWD
	done
)}

function dpsrv-git-clone() {(
	set -e
	repos=$(curl -s https://api.github.com/orgs/dpsrv/repos|jq -r '.[].name')
	cd $DPSRV_HOME
	for repo in $repos; do
		[ -d "$repo" ] && continue
		git clone https://github.com/dpsrv/$repo.git
	done
	cd $OLDPWD
)}

function dpsrv-git-status() {(
	set -e
	ls -1d $DPSRV_HOME/*/.git | while read dir; do
		dir=${dir%.git}
		cd $dir
		echo "Checking ${PWD##*/}"
		git status
		cd $OLDPWD
	done
)}

function dpsrv-git-pull() {(
	set -e
	ls -1d $DPSRV_HOME/*/.git | while read dir; do
		dir=${dir%.git}
		cd $dir
		echo "Pulling ${PWD##*/}"
		git pull
		cd $OLDPWD
	done
)}

function dpsrv-git-push() {(
	set -e
	ls -1d $DPSRV_HOME/*/.git | while read dir; do
		dir=${dir%.git}
		cd $dir
		echo "Pushing ${PWD##*/}"
		git commit -a -m updated || true
		git push || true
		cd $OLDPWD
	done
)}

function dpsrv-git-init-secrets() {(
	set -e
	ls -1d $DPSRV_HOME/*/.gitattributes | while read dir; do
		dir=${dir%.gitattributes}
		cd $dir
		echo "Init secrets ${PWD##*/}"
		../git-openssl-secrets/git-init-openssl-secrets.sh
		cd $OLDPWD
	done
)}

function dpsrv-openssl-cert() {
	if [ -z "$1" ]; then
		echo "Usage: $FUNCNAME <dir>"
		echo "  e.g: $FUNCNAME mongo"
		return 1
	fi

	local dir=$DPSRV_HOME/rc/secrets/$1

	[ ! -f $dir/cert.pem ] || return
	[ -d $dir ] || mkdir -p $dir

	ipinfo=$( curl ipinfo.io )
	
	country=$( echo $ipinfo | jq -r .country )
	state=$( echo $ipinfo | jq -r .region )
	city=$( echo $ipinfo | jq -r .city )

	openssl req -nodes -newkey rsa:2048 -new -x509 -days 3650 -keyout $dir/cert.key -out $dir/cert.crt -subj "/C=$country/ST=$state/L=$city/O=dpsrv/OU=dpsrv/CN=dpsrv.me"
	cat $dir/cert.key $dir/cert.crt > $dir/cert.pem
}

function dpsrv-iptables-forward-port() {(
	set -e

	local if_type=$1
	local proto=$2
	local cport=$3
	local dport=$4
	local toAddr_iptables=$5
	local toAddr_iptables6=$6

	if [ -z "$toAddr_iptables" ]; then
		echo "Usage: $FUNCNAME <public|private> <tcp|udp> <container port> <destination port> <container ipv4> [container ipv6]"
		echo " e.g.: $FUNCNAME public tcp 50080 80 172.18.0.3"
		return 1
	fi

	dpsrv-iptables-clear-port $proto $dport

	local comment="dpsrv:forward:port:$proto:$dport"

	local localAddr_iptables=127.0.0.1
	local localAddr_ip6tables=::1

	local dstAddr_iptables=$(hostname -I|tr ' ' '\n'|grep -v ':'|tr '\n' ' '|sed 's/ *$//g')
	local dstAddr_ip6tables=$(hostname -I|tr ' ' '\n'|grep ':'|tr '\n' ' '|sed 's/ *$//g')

	local bridgeIP=$(docker network inspect --format '{{(index .IPAM.Config 0).Gateway}}' dpsrv)
	local brideIF=$(ip -json address show to "$bridgeIP/32" | jq -r '.[].ifname')

	for iptables in iptables ip6tables; do
		local localAddrName=localAddr_$iptables
		local localAddr=${!localAddrName}

		local dstAddrName=dstAddr_$iptables
		local dstAddr=${!dstAddrName}

		local toAddrName=toAddr_$iptables
		local toAddr=${!toAddrName}

		[ -n "$dstAddr" ] || continue
		[ -n "$toAddr" ] || continue

		local accept="-p $proto -j ACCEPT -m comment --comment $comment --dport $dport"
		local dnat="-t nat -p $proto --dport $dport -j DNAT --to-destination $toAddr:$dport -m comment --comment $comment"
		local masquerade="-t nat -p $proto --dport $dport -j MASQUERADE -m comment --comment $comment"

		sudo /sbin/${iptables} -I INPUT $accept
		[ "$if_type" != "public" ] || sudo /sbin/${iptables} -I PREROUTING -d ${dstAddr// /,} $dnat
		sudo /sbin/${iptables} -I OUTPUT -d $localAddr,${dstAddr// /,} $dnat
		sudo /sbin/${iptables} -I POSTROUTING $masquerade

	done
)}

function dpsrv-iptables-clear-port() {(
	set -e

	local proto=$1
	local dport=$2

	if [ -z "$proto" ]; then
		echo "Usage: $FUNCNAME <proto> <dst port>"
		echo " e.g.: $FUNCNAME tcp 80"
		return 1
	fi

	local comment="dpsrv:forward:port:$proto:$dport"

	for iptables in iptables ip6tables; do
		sudo /sbin/${iptables}-save | while read line; do
			if [[ $line =~ ^\*(.*) ]]; then
				local table=${BASH_REMATCH[1]}
				continue
			fi
			local command=$(echo "$line" | grep -- "$comment" | sed 's/^-A/-D/g')
			[ -n "$command" ] || continue
			echo $command | xargs sudo /sbin/${iptables} -t $table
		done
	done
)}

function dpsrv-iptables-save() {(
	set -e

	for iptables in iptables ip6tables; do
		sudo /sbin/${iptables}-save | sudo /usr/bin/tee /etc/sysconfig/${iptables} >/dev/null
	done
)}

function dpsrv-iptables-list-ports() {
	local comment="dpsrv:forward:port:$dport"

	for iptables in iptables ip6tables; do
		echo "# ${iptables}"
		sudo /sbin/${iptables}-save | grep "$comment"
	done
}

function dpsrv-iptables-debug() {
	local action=I
	local line=1
	if [ "$1" = "off" ]; then
		action=D
		line=
	fi

	sudo /sbin/iptables -$action INPUT $line -j LOG
	sudo /sbin/iptables -$action FORWARD $line -j LOG
	sudo /sbin/iptables -$action OUTPUT $line -j LOG
	sudo /sbin/iptables -t nat -$action PREROUTING $line -j LOG
	sudo /sbin/iptables -t nat -$action POSTROUTING $line -j LOG
	sudo /sbin/iptables -t nat -$action OUTPUT $line -j LOG
}


function dpsrv-activate() {(
	set -e
	local containerName=$1
	local if_type=${2:-public}

	if [ -z "$containerName" ]; then
		echo "Usage: $FUNCNAME <svc name> [public|private]"
		echo " e.g.: $FUNCNAME dpsrv-bind-1.0.0 private"
		echo
		echo "Services:"
		docker ps --format json|jq -r .Names
		return 1
	fi

	local toAddr=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $containerName)
	while read cport dport proto; do
		[ -n "$cport" ] || continue
		[ -n "$dport" ] || continue
		dpsrv-iptables-forward-port $if_type $proto $cport $dport $toAddr 
	done < <(docker ps -f name=$containerName --format json|jq -r .Ports|sed 's/, /\n/g' | sed 's/^.*://g' | sed 's/->/ /g' | sed 's#/# #g')
)}

function dpsrv-deactivate() {(
	set -e
	local containerName=$1

	if [ -z "$containerName" ]; then
		echo "Usage: $FUNCNAME <svc name>"
		echo " e.g.: $FUNCNAME dpsrv-bind-1.0.0"
		echo
		echo "Services:"
		docker ps --format json|jq -r .Names
		return 1
	fi

	while read containerPort dport proto; do
		dpsrv-iptables-clear-port $proto $dport
	done < <(docker ps -f name=$containerName --format json|jq -r .Ports|sed 's/, /\n/g' | sed 's/^.*://g' | sed 's/->/ /g' | sed 's#/# #g')
)}

function dpsrv-list() {(
	set -e
	local images=$(docker ps --format '{{.Names}} {{.Image}}')
	local iptables_ports=$(dpsrv-iptables-list-ports)
	echo "$images" | while read containerName image; do
		local imageName=$(echo "$image"|cut -d: -f1)
		local imageVersion=$(echo "$image"|cut -d: -f2)
		local toAddr=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $containerName)
		local activePorts=$(echo "$iptables_ports" | grep $toAddr)
		local active=$( echo "$activePorts" | grep -q $toAddr && echo active )
		echo "$imageName $imageVersion $containerName $toAddr $active"
	done
)}

function dpsrv-latest() {(
	local list=$(dpsrv-list)
	local images=$(echo "$list" | cut -d" " -f1 | sort -fu)
	for image in $images; do
		echo "$list"|grep ^$image|sort|tail -1
	done
)}

function dpsrv-activate-latest() {(
	local containerNames=$(dpsrv-latest | cut -d" " -f3 | sort -fu)
	for containerName in $containerNames; do
		dpsrv-activate $containerName
	done
)}

function dpsrv-cp() {(
	set -e
	local image=$1
	local dest=$2

	if [ -z "$dest" ]; then
		echo "Usage: $FUNCNAME <image> <dest>"
		echo
		echo "Available images:"
		docker image ls --format json|jq -r '.Repository + ":" + .Tag'
		echo
		echo "Available dest:"
		ls -d1 $DPSRV_HOME/rc/secrets/local/*|sed 's#^.*/##g'
		return 1 
	fi

	docker save $image | bzip2 | pv | ssh $dest 'bunzip2 | docker load'
)}

