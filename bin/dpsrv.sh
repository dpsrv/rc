cd $(dirname ${BASH_SOURCE[0]})/../..
export DPSRV_HOME=$PWD
cd $OLDPWD

export DPSRV_SERVICES=( $( grep -l 'restart:[ ]*unless-stopped' $DPSRV_HOME/*/docker-compose.yml | sed "s#^$DPSRV_HOME/##g"|cut -d/ -f1 ) )

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
	show-keychain-info || security -v unlock-keychain $HOME/Library/Keychains/login.keychain-db
}

function dpsrv-up() {(
	set -e
	dpsrv-unlock-keychain
	for service in "${DPSRV_SERVICES[@]}"; do
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
	if [ -z $1 ]; then
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

function dpsrv-iptables-redirect-port() {(
	set -e

	local proto=$1
	local srcPort=$2
	local dstAddr=$3
	local dstPort=$4

	if [ -z $dstPort ]; then
		echo "Usage: $FUNCNAME <protocol> <src port> <dst addr> <dst port>"
		echo " e.g.: $FUNCNAME tcp 80 172.18.0.3 50080"
		return 1
	fi

	dpsrv-iptables-clear-port $proto $srcPort

	local comment="dpsrv:redirect:port:$proto:$srcPort"

	local redirect="-t nat -p $proto --dport $srcPort -j REDIRECT --to-port $dstPort -m comment --comment $comment"
	local dnat="-t nat -p $proto --dport $srcPort -j DNAT --to-destination $dstAddr:$srcPort -m comment --comment $comment"
	local accept="-A INPUT -p $proto -j ACCEPT -m comment --comment $comment --dport"

	# No need to assign ip6, docker is not yet using it
	for iptables in iptables; do
		sudo /sbin/${iptables} $accept $srcPort
		sudo /sbin/${iptables} $accept $dstPort
		sudo /sbin/${iptables} -A PREROUTING $dnat
		sudo /sbin/${iptables} -A OUTPUT -o lo $redirect
	done
)}

function dpsrv-iptables-clear-port() {(
	set -e

	local proto=$1
	local srcPort=$2

	if [ -z $proto ]; then
		echo "Usage: $FUNCNAME <proto> <src port>"
		echo " e.g.: $FUNCNAME tcp 80"
		return 1
	fi

	comment="dpsrv:redirect:port:$proto:$srcPort"

	for iptables in iptables ip6tables; do
		sudo /sbin/${iptables}-save | while read line; do
			if [[ $line =~ ^\*(.*) ]]; then
				table=${BASH_REMATCH[1]}
				continue
			fi
			command=$(echo "$line" | grep -- "$comment" | sed 's/^-A/-D/g')
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
	comment="dpsrv:redirect:port:$srcPort"

	for iptables in iptables ip6tables; do
		echo "# ${iptables}"
		sudo /sbin/${iptables}-save | grep "$comment"
	done
}

function dpsrv-activate() {(
	set -e
	local containerName=$1

	if [ -z $containerName ]; then
		echo "Usage: $FUNCNAME <svc name>"
		echo " e.g.: $FUNCNAME dpsrv-bind-1.0.0"
		echo
		echo "Services:"
		docker ps --format json|jq -r .Names
		return 1
	fi

	ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $containerName)
	while read dst src proto; do
		dpsrv-iptables-redirect-port $proto $src $ip $dst
	done < <(docker ps -f name=$containerName --format json|jq -r .Ports|sed 's/, /\n/g' | sed 's/^.*://g' | sed 's/->/ /g' | sed 's#/# #g')
)}

function dpsrv-deactivate() {(
	set -e
	local containerName=$1

	if [ -z $containerName ]; then
		echo "Usage: $FUNCNAME <svc name>"
		echo " e.g.: $FUNCNAME dpsrv-bind-1.0.0"
		echo
		echo "Services:"
		docker ps --format json|jq -r .Names
		return 1
	fi

	while read dst src proto; do
		dpsrv-iptables-clear-port $proto $src
	done < <(docker ps -f name=$containerName --format json|jq -r .Ports|sed 's/, /\n/g' | sed 's/^.*://g' | sed 's/->/ /g' | sed 's#/# #g')
)}

function dpsrv-cp() {(
	set -e
	local image=$1
	local dest=$2

	if [ -z $dest ]; then
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

