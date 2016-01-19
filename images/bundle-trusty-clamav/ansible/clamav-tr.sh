#!/bin/bash

DOSSIER=/home
QUARANTAINE=/tmp
LOG=$HOME/.clamav-tr.log

inotifywait -q -m -r -e create,modify,access "$DOSSIER" --format '%w%f|%e' | sed --unbuffered 's/|.*//g' |

while read FICHIER; do
        clamdscan --quiet --no-summary -i -m "$FICHIER" --move=$QUARANTAINE
        if [ "$?" == "1" ]; then
		echo "`date` - Malware trouvé dans le fichier '$FICHIER'. Le fichier a été déplacé dans $QUARANTAINE." >> $LOG
		echo -e "\033[31mMalware trouvé!!!\033[00m" "Le fichier '$FICHIER' a été déplacé en quarantaine."
		if [ -f /usr/bin/notify-send ]; then
			notify-send -u critical "ClamAV Temps Réel" "Malware trouvé!!! Le fichier '$FICHIER' a été déplacé en quarantaine."
		fi
        fi
done
