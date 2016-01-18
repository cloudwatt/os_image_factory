#!/bin/sh
#Script generated by packit.perl on Fri Jun 19 16:46:31 2015.

if [ -z "$UNPACK_ONLY" -a "`id -u`" != 0 ] ; then
  echo "This script needs to be run with root privileges.  Please try:"
  echo "  sudo -H sh $0"
  exit 1
fi
export HOME="`getent passwd 0 | cut -d: -f6`"
cd /var/bio/
if [ "$?" != 0 ] ; then
  echo "Unable to change to temporary directory; cannot continue."
  exit 2
fi
echo "Working in `pwd`..."
#Add hook to ensure the payload runs after successful unpacking

nexit() {
if [ "$1" = "0" ] ; then
 do_md5_check || { echo "Checksum fail." ; exit 1 ; }
 if [ -n "$UNPACK_ONLY" ] ; then
  echo "Unpack complete in `pwd`. Exiting."
 else
  chmod +x upgrade_to_8.sh
  echo 'Unpack phase complete.  Running upgrade_to_8.sh' ; echo '====>>>'
  exec ./upgrade_to_8.sh <&1
 fi
else \exit "$@"
fi }
alias exit=nexit
#Always prefer Perl for uudecoding
uudecode() {
 if which perl >/dev/null ; then
  read l0 l1 l2
  perl -ne 'print unpack("u*",$_)' >$l2 &&
  chmod $l1 $l2
 else
  uudecode "$@"
 fi
}
#No extra md5sum checking
do_md5_check() {
  true
}
#!/bin/sh
# This is a shell archive (produced by GNU sharutils 4.14).
# To extract the files from this archive, save it to some FILE, remove
# everything before the '#!/bin/sh' line above, then type 'sh FILE'.
#
lock_dir=_sh09863
# Made on 2015-06-19 16:46 BST by <tbooth@balisaur>.
# Source directory was '/home/tbooth/sandbox/bl8_things'.
#
# Existing files WILL be overwritten.
#
# This shar contains:
# length mode       name
# ------ ---------- ------------------------------------------
#   8990 -rw-rw-r-- bio-linux-keyring.deb
#   5490 -rwxrw-r-- pick_cran_mirror.py
#   3125 -rw-r--r-- sources.list.clean
#   2212 -rwxrwxr-x bl_install_master_list.sh
#  13459 -rwxrwxr-x upgrade_to_8.sh
#    725 -rw-rw-r-- pseudo_orphans.txt
#   4851 -rwxrwxr-x bl_master_package_list.txt
#   1746 -rw-rw-r-- message1.txt
#
MD5SUM=${MD5SUM-md5sum}
f=`${MD5SUM} --version | egrep '^md5sum .*(core|text)utils'`
test -n "${f}" && md5check=true || md5check=false
${md5check} || \
  echo 'Note: not verifying md5sums.  Consider installing GNU coreutils.'
if test "X$1" = "X-c"
then keep_file=''
else keep_file=true
fi
echo=echo
save_IFS="${IFS}"
IFS="${IFS}:"
gettext_dir=
locale_dir=
set_echo=false

for dir in $PATH
do
  if test -f $dir/gettext \
     && ($dir/gettext --version >/dev/null 2>&1)
  then
    case `$dir/gettext --version 2>&1 | sed 1q` in
      *GNU*) gettext_dir=$dir
      set_echo=true
      break ;;
    esac
  fi
done

if ${set_echo}
then
  set_echo=false
  for dir in $PATH
  do
    if test -f $dir/shar \
       && ($dir/shar --print-text-domain-dir >/dev/null 2>&1)
    then
      locale_dir=`$dir/shar --print-text-domain-dir`
      set_echo=true
      break
    fi
  done

  if ${set_echo}
  then
    TEXTDOMAINDIR=$locale_dir
    export TEXTDOMAINDIR
    TEXTDOMAIN=sharutils
    export TEXTDOMAIN
    echo="$gettext_dir/gettext -s"
  fi
fi
IFS="$save_IFS"
if (echo "testing\c"; echo 1,2,3) | grep c >/dev/null
then if (echo -n test; echo 1,2,3) | grep n >/dev/null
     then shar_n= shar_c='
'
     else shar_n=-n shar_c= ; fi
else shar_n= shar_c='\c' ; fi
if test ! -d ${lock_dir} ; then :
else ${echo} "lock directory ${lock_dir} exists"
     exit 1
fi
if mkdir ${lock_dir}
then ${echo} "x - created lock directory ${lock_dir}."
else ${echo} "x - failed to create lock directory ${lock_dir}."
     exit 1
fi