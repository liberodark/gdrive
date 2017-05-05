#!/bin/bash


##
## Install grive2 as per http://bit.ly/28InB2O
##


##
## ChangeLog
##
## @author Dr. John X Zoidberg <drjxzoidberg@gmail.com>
## @version 1.1.0
## @date 2017-02-05
##  - first release
##
##
## @author Dr. John X Zoidberg <drjxzoidberg@gmail.com>## @version 1.0.0
## @date 2016-07-21
##  - first release
##


WD="$(dirname "$0")"


cat >"${WD}/grive.settings" <<EOD
PREFIX=/usr/local
PREFIX_BIN="\${PREFIX}/bin"
EXEC_PREFIX=
INTERVAL=5
TIMEOUT=5
GDRIVE_DIR="~/gdrive"
GDRIVE_LOG="~/.gdrive-sync.log"
SETTINGS="~/.gdrive-sync.settings"
EOD

if [ -r "${WD}/grive.settings.user" ] ; then
  cat "${WD}/grive.settings.user" >>"${WD}/grive.settings"
fi
. "${WD}/grive.settings"



##
## Install: user must be sudoer.
##
install ()
{
  cat <<-EOD
	This will install grive2 and its companions.
	The procedure has been tested on 2017-02-17 on Ubuntu 16.10.
	Dependencies:
	a) lockfile-progs
EOD

  read -p 'Continue [y/N]?' a
  if [ "${a}" != "y" ] ; then
    return 1
  fi

  sudo pacman -S yaourt || return 1
    yaourt -S grive || return 1


  echo "Installing '/usr/local/bin/${EXEC_PREFIX}gdrive-sync.sh'."

  rm -fr "${WD}/build"
  mkdir -p "${WD}/build"

  cp gdrive-sync.sh.template "${WD}/build/${EXEC_PREFIX}gdrive-sync.sh"
  cp gdrive-sync.cron.template "${WD}/build/gdrive-sync.cron"
  cp gdrive-sync.sh.desktop.template "${WD}/build/${EXEC_PREFIX}gdrive-sync.sh.desktop"
  IFS=$'\n'
  for p in $(grep -v ^# "${WD}/grive.settings") ; do
    name="${p%%=*}"
    eval value=\"\$${name}\"
    sed -i -e 's:@@'"${name}"'@@:'"${value}"':g' \
      "${WD}/build/${EXEC_PREFIX}gdrive-sync.sh" \
      "${WD}/build/gdrive-sync.cron" \
      "${WD}/build/${EXEC_PREFIX}gdrive-sync.sh.desktop"
  done

  sudo install "${WD}/build/${EXEC_PREFIX}gdrive-sync.sh" /usr/local/bin/${EXEC_PREFIX}gdrive-sync.sh || return 1
#  echo install "${WD}/build/${EXEC_PREFIX}gdrive-sync.sh" /usr/local/bin/${EXEC_PREFIX}gdrive-sync.sh || return 1



  echo "Now can run '$0 init'."
}



installSync ()
{
  read -p 'Do you want to install sync daemon? [y/N]' a
  if [ "${a}" != "y" ] ; then
    return 1
  fi

  read -p 'What type of daemon Autostart/Cron? [a/c]' a

  if [ "${a}" = "a" ] ; then
    cp "${WD}/build/${EXEC_PREFIX}gdrive-sync.sh.desktop" ~/.config/autostart/
    return $?
  fi

  if [ "${a}" = "c" ] ; then
    crontab -l 2>/dev/null | grep -v "^no crontab for ${USER}" | cat - "${WD}/build/gdrive-sync.cron"
    return $?
  fi

  return 0
}



init ()
{
  mkdir -p "${GDRIVE_DIR}"
  RES=$?
  if [ ${RES} -ne 0 ] ; then
    echo "[EE] cannot mkdir (${RES}) gdrive dir. '${GDRIVE_DIR}' [\${GDRIVE_DIR}]."
    return 1
  fi

  ## else...

  cd "${GDRIVE_DIR}"
  RES=$?
  if [ ${RES} -ne 0 ] ; then
    echo "[EE] cannot cd (${RES}) gdrive dir. '${GDRIVE_DIR}' [\${GDRIVE_DIR}]."
    return 1
  fi

  ## else...

  grive -a || return 1

  installSync
}



##
## MAIN
##

cmd="$1"

case $cmd in
  install)
    install
  ;;

  init)
    init
  ;;

  installSync)
    installSync
  ;;

  *)
     echo "usage: $(basename "$0") install | init"
  ;;
esac
