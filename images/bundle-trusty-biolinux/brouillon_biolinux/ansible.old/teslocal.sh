#/bin/sh

texte1="if grep -q '^deb .*/\([a-z]*\)\+ universe$'   /etc/apt/sources.list && \
     grep -q '^deb .*/\([a-z]*\)\+ multiverse$' /etc/apt/sources.list ; then
      true "
  texte2="if grep '^deb.* universe$' /etc/apt/sources.list &&  \
     grep '^deb.*multiverse$' /etc/apt/sources.list"
  sed  "/$texte1/$texte2/" upgrade_to_8.sh
