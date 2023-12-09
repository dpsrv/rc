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

