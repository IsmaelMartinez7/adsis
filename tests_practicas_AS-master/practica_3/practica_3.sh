#!/bin/bash
#819535 Peralta Gonzalez, Isabel, M, 3, B
#818903 Martínez Vicens, Ismael, M, 3, B


addUser(){
	OLDIFS=$IFS
	IFS=,
	while read user pass name
	do
		if [ "$user" = "" -o "$pass" = "" -o "$name" = "" ]
		then
			echo "Campo invalido"
			exit
		fi
		useradd -c "$name" "$user" -m -k /etc/skel -K UID_MIN=1815 -U 2>/dev/null
		
		if [ "$?" -ne 0 ]
		then
			echo "El usuario $user ya existe" >&2
		else
			echo "$user:$pass" | chpasswd
			usermod "$user" -f 30
			echo "$name ha sido creado"
		fi
	done < $1
}

delUser(){
	if [ ! -d /extra/backup ]
	then
		mkdir -p /extra/backup
	fi
	OLDIFS=$IFS
	IFS=,
	while read user pass name
	do
		userHome=$(getent passwd "$user" | cut -d: -f6)
		tar czfP /extra/backup/"$user".tar "$userHome" 2>/dev/null
		if [ "$?" -eq 0 ]
		then
			userdel -r "$user" 2>/dev/null
		fi
	done < $1
}

if [ ! $UID = 0  ]; then
  echo "Este script necesita privilegios de administración" >&2
  exit 1
fi


if [ "$#" -ne 2 ]
then
	echo "Numero incorrecto de parametros" >&2
else
	np="as ALL=(ALL) NOPASSWD: ALL"
	echo "$np" >> /etc/sudoers.d/as
	
	if [ "$1" = "-a" ]
	then
		addUser $2
	elif [ "$1" = "-s" ]
	then
		delUser $2
	else
		echo "Opcion invalida" >&2
	fi
fi

