#!/bin/bash
#819535 Peralta Gonzalez, Isabel, M, 3, B
#818903 Martínez Vicens, Ismael, M, 3, B


function CrearUsuario(){
	if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] # si alguno de los campos es vacío
	then
		echo "Campo invalido"
		exit
	fi
	
	useradd -c "$3" "$1" -m -k /etc/skel -K UID_MIN=1815 -U
	#useradd -c "$3" "$1" -m -k /bin/bash -g "$1"
	if id -u "$1" >/dev/null 2>&1; then
		echo El usuario "$1" ya existe
	else

		#fechexp=$(date --date='+30 day' +"%Y-%m-%d")
		#useradd -c "$3" "$1" -m /bin/bash -g "$1"
		
		echo "$1:$2" | chpasswd
		usermod "$1" -f 30
		echo ""$3" ha sido creado"
	fi
}




if [ "$EUID" -ne 0 ]
then
	echo "Este script necesita privilegios de administracion"
	exit 1
elif [ "$#" -ne 2 ]
then
	echo "Numero incorrecto de parametros"

else
		# para que as no ponga contraseña cuando usa sudo
	np="as ALL=(ALL) NOPASSWD: ALL"
	echo "$np" >> /etc/sudoers.d/as
	
	OldIFS="$IFS"	#Salva el valor de IFS
	
	if [ "$1" = "-a" ]
	then
		um="$UID_MIN"
		pmd="$PASS_MAX_DAYS"
		UID_MIN=1815
		PASS_MAX_DAYS=30
		IFS=,		
		cat "$2" |
		while read username password nombreCompleto
		do
			CrearUsuario "$username" "$password" "$nombreCompleto"
		done
		UID_MIN="$um"
		PASS_MAX_DAYS="$pmd"

	elif [ "$1" = "-s" ]
	then
		mkdir -p /extra/backup
		IFS=,		
		cat "$2" |
		while read username password nombreCompleto
		do
			if [ -z "$1" ]
			then	
				echo "Campo invalido"
				exit
			else
				homedir=$(grep "$username" /etc/passwd | cut -d ":" -f6) #: delimitador entre palabras y lee la sexta
				# Realizar un backup del directorio home del usuario
				if tar -cf "$username".tar "$homedir" >/dev/null 2>&1
				then
					# moverlo a la carpeta creada anteriormente
					mv "$username".tar /extra/backup
					# borramos el usuario
					userdel -r "$username" >/dev/null 2>&1
				fi
			fi
		done
	else
		echo "Opcion invalida" 
	fi
		
	IFS="$OldIFS"
	

fi
