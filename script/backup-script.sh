#!/usr/bin/env bash

# TODO:
# - [x] Verzeichnis als Argument übergeben
#   - [x] mehrere Verzeichnisse?
# - [x] tar Archiv nicht mit sichern (woanders ablegen) -> /backup
# - [x] Speicherort Backup-Datei? -> als letztes Argument übergeben
# - [x] Name des Backups anpassen (je nach übergebenem Verzeichnis)
# - [x] Fehlerbehandlung: existiert übergebenes Verzeichnis und ist es ein Verzeichnis?
# - [ ] wenn kein Verzeichnis, dann prüfen ob datei existiert und kein tar verwenden, nur Komprimierung
# - [ ] wie gehen wir mit Fehlermeldungen um? -> Log Datei erstellen
# - [x] Prüfung auf Root-Rechte
# - [ ] keine Passworteingabe für sudo?

# set -x

# Defaults setzen
default_backup_dir="/backup"
default_dirs="/etc /boot /var/log"

if [ $# -eq 1 ] && [ "$1" == "-i" ]; then
	read -p "Welches Verzeichnisse sollen gesichert werden? (Eingabe durch Leerzeichen getrennt): " dirs_to_backup
	read -p "Wo sollen die Backups gespeichert werden? " interactive_backup_dir
fi

# Prüfen, ob Eingabe stattgefunden hat, ansonsten Defaults verwenden
[ -z "$dirs_to_backup" ] && dirs_to_backup="$default_dirs"
[ -z "$interactive_backup_dir" ] && interactive_backup_dir="$default_backup_dir"

# Falls keine Argumente oder eins übergeben werden, ersetze $@ durch die Defaults bbzw. die interaktive Eingabe
# NOTE: bissl hacky... :)
if [ $# -eq 0 ] || [ "$1" == "-i" ]; then
	set -- $dirs_to_backup $interactive_backup_dir
fi

# Zugriff auf das letzte übergebene Argument
backup_dir=${@: -1}

# Verzeichnis für Backups erstellen (falls es nicht esistiert)
mkdir -p $backup_dir

# Wird das Skript mit root-Rechten ausgeführt?
if [ $UID -ne 0 ]; then
	echo Das Skript benötigt Root-Rechte, Abbruch
	exit 3
fi

# Wir wollen das letzte Argument vom Loop ausschliessen
# also iterieren wir über das gesamte Array @, aber nur 
# von ersten Element (1) bis zum vorletzten ($#-1)
for dir in ${@:1:$#-1}; do
	# Prüfung ob übergebenes Argument ein Verzeichnis ist
	if [ -d "$dir" ]; then
		clean_dir_name=$(echo "$dir" | tr '/' '_' | tr ' ' '_')
		backup_name=backup${clean_dir_name}_$(date +"%Y-%m-%d_%H-%M-%S").tar.gz
		# gzip komprimiertes Backup mit tar erstellen
		tar --create --gzip --file ${backup_dir}/${backup_name} "$dir" 
		exit_code_tar=$?
		
		# Ausgabe, ob Script erfolgreich ausgeführt wurde oder nicht
		if [ $? -eq 0 ]; then
			echo Backup erfolgreich erstellt | systemd-cat -t backupscript -p info
		else
			echo Fehler beim Erstellen des Backups | systemd-cat -t backupscript -p err 
			echo exit_code_tar: $exit_code_tar
			exit 2
		fi
	else 
		echo "$dir" ist kein Verzeichnis, Abbruch | systemd-cat -t backupscript -p err 
		exit 1
	fi
done





