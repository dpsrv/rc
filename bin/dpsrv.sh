cd $(dirname ${BASH_SOURCE[0]})/../..
export DPSRV_HOME=$PWD
cd $OLDPWD

export DPSRV_SERVICES=( $( grep -l 'restart:[ ]*unless-stopped' $DPSRV_HOME/*/docker-compose.yml | sed "s#^$DPSRV_HOME/##g"|cut -d/ -f1 ) )

if ! [[ "$PATH" =~ "$DPSRV_HOME/rc/bin" ]]; then
	export PATH="$PATH:$DPSRV_HOME/rc/bin"
fi

function dpsrv-unlocl() {
	security -v unlock-keychain $HOME/Library/Keychains/login.keychain-db
}

function dpsrv-up() {
	for service in "${DPSRV_SERVICES[@]}"; do
		cd $DPSRV_HOME/$service
		echo "Bringing up ${PWD##*/}"
		docker compose up --build -d
		echo "exit: $?"
		cd $OLDPWD
	done
}

function dpsrv-down() {
	for service in "${DPSRV_SERVICES[@]}"; do
		cd $DPSRV_HOME/$service
		echo "Tearing down ${PWD##*/}"
		docker compose down
		cd $OLDPWD
	done
}

function dpsrv-git-status() {
	ls -1d $DPSRV_HOME/*/.git | while read dir; do
		dir=${dir%.git}
		cd $dir
		echo "Checking ${PWD##*/}"
		git status
		cd $OLDPWD
	done
}

function dpsrv-git-pull() {
	ls -1d $DPSRV_HOME/*/.git | while read dir; do
		dir=${dir%.git}
		cd $dir
		echo "Pulling ${PWD##*/}"
		git pull
		cd $OLDPWD
	done
}

function dpsrv-git-push() {
	ls -1d $DPSRV_HOME/*/.git | while read dir; do
		dir=${dir%.git}
		cd $dir
		echo "Pushing ${PWD##*/}"
		git commit -a -m updated && git push || true
		cd $OLDPWD
	done
}

