#!/bin/bash
nykey
# This is the Bio-Linux 8 update script.  It depends on a few files which can
nykey
# be included by packit.perl, which also ensures the script runs as root in a
nykey
# temporary directory.
nykey

nykey
# To make a self-contained version with dependencies:
nykey
# $ packit.perl upgrade_to_8.sh > upgrade8.sh
nykey

nykey
#==I root
nykey

nykey
# Message to users when they run the script...
nykey
#==F message1.txt
nykey

nykey
# Deb file with keyrings in...
nykey
#==F bio-linux-keyring.deb
nykey

nykey
# New sources.list
nykey
#==F sources.list.clean
nykey

nykey
# CRAN mirror pickerer
nykey
#==F pick_cran_mirror.py
nykey

nykey
# Master package list
nykey
#==F bl_master_package_list.txt
nykey
#==F bl_install_master_list.sh
nykey

nykey
# Pseudo-orphans list for pinning
nykey
#==F pseudo_orphans.txt
nykey

nykey
anykey() {
nykey
#    read -p "Press any key to continue..." -n1
nykey
    t="a"
nykey
    echo $t; echo$t
nykey
    
nykey
}
nykey

nykey
echo `yes = | head -c 80` $'\n'
nykey
cat message1.txt
nykey
echo `yes = | head -c 80`
nykey
anykey
nykey

nykey
# Guess who really ran the script - not authoritative but likely right.
nykey
REALUSER=$(stat -c%U `tty 2>/dev/null` 2>/dev/null)
nykey

nykey
# Pull some procedures out into functions for readability
nykey
reset_sources_list() {
nykey
    bfname="sources.list.`date +%Y%m%d`.tar.gz"
nykey

nykey
    if ! [ -e "/etc/apt/$bfname" ] ; then
nykey
    ( cd /etc/apt ; \
nykey
      tar -cvaf "$bfname" sources.list sources.list.d )
nykey
      echo "Old configuration saved as /etc/apt/$bfname"
nykey
    fi
nykey

nykey
    rm -f /etc/apt/sources.list.d/*.list
nykey

nykey
    #Infer what mirror this user is using.
nykey

nykey
    # I could ask the user to pick from /usr/share/update-manager/mirrors.cfg but this list looks weird and
nykey
    # doesn't mention gb.archive.ubuntu.com etc. plus doing a tree picker is a PITA.
nykey

nykey
    mirrr="`apt-cache policy coreutils | grep -o '^ \{8\}[0-9]\+ [a-z]\+://[^[:space:]]\+' | awk '{print $NF}' | uniq`"
nykey
    if [ -z "$mirrr" ] || [ `echo "$mirrr" | wc -l` != 1 ] ; then
nykey
	echo "Cannot infer default mirror.  Will keep default of http://gb.archive.ubuntu.com."
nykey
	echo "You can change this under \"Download from...\" in the software sources preferences before"
nykey
	echo "running the upgrade."
nykey
	# Install the list.  Leave it to the Ubuntu installer to update the release name.
nykey
	cat sources.list.clean > /etc/apt/sources.list
nykey
    else
nykey
      sed "s,http://gb.archive.ubuntu.com/ubuntu/,`echo "$mirrr" | sed 's/[,\/&]/\\\\&/g'`," \
nykey
	  sources.list.clean > /etc/apt/sources.list
nykey
    fi
nykey
}
nykey

nykey
# I tried to get R to pick a CRAN mirror, but it refuses to do that interactively.  But then I
nykey
# realised I could make my own fun picker...
nykey
infer_cran_mirror() {
nykey
    cmirrr="`python pick_cran_mirror.py`"
nykey

nykey
    if [ -z "$cmirrr" ] || [ "$cmirrr" != "${cmirrr%% *}" ] ; then
nykey
	echo "http://www.stats.bris.ac.uk/R/"
nykey
    else
nykey
	echo "$cmirrr"
nykey
    fi
nykey
}
nykey

nykey
# A generic countdown function
nykey
countdown()
nykey
{
nykey
    from=$(( "$1" + 0 ))
nykey
    for s in `seq $from -1 1` ; do
nykey
	echo -n "$s " ; sleep 1
nykey
    done ; echo 0
nykey
}
nykey

nykey
#### Actual update starts here...
nykey

nykey
# Is this machine updated to 14.04?
nykey
# As before, use Python version to infer update status.
nykey
# I should probably use lsb-release but I'm not sure exactly when it gets set.
nykey
PYVERS=`dpkg -s python | sed -n 's/^Version: \(.*\)/\1/p'`
nykey
if ! dpkg --compare-versions 2.7.5-0 le $PYVERS ; then
nykey
    echo "Your Python package version is $PYVERS (ie. less than 2.7.5) which indicates"
nykey
    echo "that your computer has not yet been updated to Ubuntu 14.04 (Trusty)."
nykey
    echo
nykey
    echo "The first part of the update process uses the Ubuntu graphical update manager to"
nykey
    echo "upgrade the core of your system.  The updater will be launched for you now."
nykey
    echo "Follow all instructions, then after rebooting run this update script again."
nykey
    echo
nykey
    anykey
nykey

nykey
    #Ensure that the update manager is going to prompt for upgrades.
nykey
    # Not necessary if I run do-release-upgrade directly!
nykey
#     if [ -f /etc/update-manager/release-upgrades ] ; then
nykey
#  	echo " * Ensuring that upgrades are enabled in /etc/update-manager/release-upgrades * "
nykey
#  	( grep -v "^#set by bio-linux-prevent-upgrade\|^[Pp]rompt=" /etc/update-manager/release-upgrades ;
nykey
#  	  echo "Prompt=lts"
nykey
#  	) > /etc/update-manager/release-upgrades.new
nykey
#
nykey
#  	mv -f /etc/update-manager/release-upgrades.new /etc/update-manager/release-upgrades
nykey
#  	echo DONE
nykey
#     fi
nykey

nykey
    #Unpack a minimal/standardised sources.list
nykey
    echo " * Cleaning up APT configuration * "
nykey
    reset_sources_list
nykey
    #apt-get -y update
nykey
    echo DONE
nykey

nykey
    echo " * Removing some troublesome packages * "
nykey
    apt-get -y remove python-ubuntuone-control-panel
nykey
    #This jams the update, as noted in /var/log/dist-upgrade/main.log
nykey
    apt-get -y remove postgresql-plperl-8.4 postgresql-plpython-8.4
nykey

nykey
    #This will be replaced by r-bioc-qvalue.  Also remove galaxy-server-all
nykey
    #but we put it back later.
nykey
    dpkg -r --force-all galaxy-server-all
nykey
    apt-get -y --purge remove r-cran-qvalue
nykey
    apt-get -y --purge remove tigr-glimmer
nykey

nykey
    'do-release-upgrade' -p -f DistUpgradeViewGtk3
nykey

nykey
    # Do I care about crud in /var/crash?  Hell no.  All it does is nag the user, then
nykey
    # tell them they can't report the error after all.
nykey
    rm -rf /var/crash/*
nykey

nykey
    echo "***"
nykey
    echo "The upgrade to Bio-Linux 8 is not yet complete - please reboot, then run this script again."
nykey
    echo "***"
nykey
    echo "I repeat..."
nykey
    echo "The upgrade is NOT YET COMPLETE - please REBOOT, then RUN THIS SCRIPT AGAIN."
nykey
    echo "***"
nykey
    exit 1
nykey
fi
nykey

nykey
# OK, so now proceed as we did for BL7.  Add the various repos:
nykey
# 2 - Bio-Linux PPA
nykey
# 3 - c2d4u
nykey
# 5 - Bio-Linux @nebc (or at ibiblio?? mirror less important now we use PPA, and I want the stats!)
nykey
# 1 - CRAN @ Bris (now mandatory!)
nykey
# 6 - Google Chrome and Talk Plugin (repos only)
nykey
# 4 - x2go PPA (as opposed to FreeNX PPA)
nykey
# 7 - The MATE Desktop, hopefully a drop-in replacement for Gnome for x2go users.
nykey

nykey
# Ensure we have all keys.  For people who didn't start with BL they lack the keyring,
nykey
# so just manually install it here.
nykey
dpkg -EGi ./bio-linux-keyring.deb
nykey

nykey
# Tony pointed out we need this
nykey
apt-get -y install software-properties-common
nykey
if ! which add-apt-repository >/dev/null ; then
nykey
    echo "Can't proceed as add-apt-repository command is not available"
nykey
    exit 1
nykey
fi
nykey

nykey
# Note that the BL8 image has /etc/apt/sources.list.d/bl8.installed.save
nykey
# so it should be fine to run this script on a BL8 box.
nykey

nykey
if [ ! -e /etc/apt/sources.list.d/bl8.installed.save ] ; then
nykey
    mkdir -p /etc/apt/sources.list.d
nykey
#>>>> I can't indent heredocs
nykey

nykey
# 1 - since my attempts to infer the correct mirror were rubbish, pick it
nykey
echo "Trying to run graphical R mirror chooser.  If this fails we'll default to the Bristol one."
nykey
cmirrr="`infer_cran_mirror`"
nykey
cat >/etc/apt/sources.list.d/cran-latest-r.list <<.
nykey
#Latest R-cran packages
nykey
deb $cmirrr/bin/linux/ubuntu trusty/
nykey
deb-src $cmirrr/bin/linux/ubuntu trusty/
nykey
.
nykey

nykey
# 2 and 3 and 4
nykey
echo "Adding PPA repository sources.  If this fails it may indicate a web proxy configuration issue."
nykey
{
nykey
  set -o errexit
nykey
  apt-add-repository -y ppa:nebc/bio-linux
nykey
  apt-add-repository -y ppa:marutter/c2d4u
nykey
  apt-add-repository -y ppa:x2go/stable
nykey
}
nykey

nykey
# 5
nykey
cat >/etc/apt/sources.list.d/bio-linux-legacy.list <<"."
nykey
# Bio-Linux legacy packages (manually built, there is no deb-src)
nykey
# But there is an alternative mirror you can use.
nykey
# deb http://distro.ibiblio.org/bio-linux/packages/ unstable bio-linux
nykey
deb http://nebc.nerc.ac.uk/bio-linux/ unstable bio-linux
nykey
.
nykey

nykey
# 6 - to reiterate, we don't install chrome, just make it available.
nykey
cat >/etc/apt/sources.list.d/google-chrome.list <<"."
nykey
### THIS FILE IS AUTOMATICALLY CONFIGURED ###
nykey
# You may comment out this entry, but any other modifications may be lost.
nykey
deb http://dl.google.com/linux/chrome/deb/ stable main
nykey
.
nykey
cat >/etc/apt/sources.list.d/google-talkplugin.list <<"."
nykey
### THIS FILE IS AUTOMATICALLY CONFIGURED ###
nykey
# You may comment out this entry, but any other modifications may be lost.
nykey
deb http://dl.google.com/linux/talkplugin/deb/ stable main
nykey
.
nykey

nykey
# 7
nykey
#cat >/etc/apt/sources.list.d/mate-desktop.list <<"."
nykey
# # MATE is a fork of the Gnome destop.  It provides a suitable environment for
nykey
# # non-accelerated graphics diaplays like x2go.
nykey
# deb http://repo.mate-desktop.org/archive/1.8/ubuntu trusty main
nykey
# deb-src http://repo.mate-desktop.org/archive/1.8/ubuntu trusty main
nykey
# .
nykey
# TODO - put this into bio-linux-keyring package... Except the MATE repo is unsigned!
nykey
#wget -qO - http://mirror1.mate-desktop.org/debian/mate-archive-keyring.gpg | apt-key add -
nykey

nykey
#<<<<
nykey
fi
nykey

nykey
# Done, now update and upgrade (on a vanilla system this won't do much)
nykey
# Some packages need persuasion to upgrade, hence the pinning (see notes in ofile):
nykey
ofile=./pseudo_orphans.txt
nykey
pfile=./pseudo_orphans.pin
nykey
for p in `grep -v "^ *#" $ofile` ; do
nykey
    for l in "Package: $p" 'Pin: origin ?*' 'Pin-Priority: 1001' '' ; do echo "$l" ; done
nykey
done > $pfile
nykey

nykey
# If this was run on a Vanilla Ubuntu 14.04 box then Universe/Multiverse sources
nykey
# will not be active.  Tell the user about it.
nykey
if grep '^deb.* universe$' /etc/apt/sources.list &&  \
nykey
   grep '^deb.*multiverse$' /etc/apt/sources.list ; then
nykey
    true
nykey
else
nykey
    echo "**** Warning:"
nykey
    echo "You do not seem to have the Universe and Multiverse components enabled."
nykey
    echo "Not all Bio-Linux software will install without these."
nykey
    echo "To continue, run 'software-properties-gtk' in another window, select both"
nykey
    echo "of these sources to activate them, and click 'Apply' before re-running this"
nykey
    echo "script."
nykey
    echo "Alternatively you can simply edit /etc/apt/sources.list in an editor."
nykey
    exit 1
nykey
fi
nykey

nykey
apt-get -y update
nykey
echo "Updating packages.  You may see a warning about downgrades - this is normal."
nykey
apt-get -y --force-yes -o "Dir::Etc::Preferences=$pfile" upgrade
nykey
apt-get -y --force-yes -o "Dir::Etc::Preferences=$pfile" dist-upgrade
nykey

nykey
# Remove NX server.  How can I tell if it is in use?
nykey
# Or will NX even work after the upgrade from 12.04?
nykey
if [ "`dpkg-query -f '${Status}\n' -W freenx 2>/dev/null`" = "install ok installed" ] ; then
nykey
  if [ -n "$NXSESSIONID" ] ; then
nykey
    echo "You seem to be running an NX session.  But NX server is going to be removed"
nykey
    echo "and replaced by x2go.  You are advised to close NX and re-run this script"
nykey
    echo "at the console or via regular SSH to complete the update."
nykey
    echo
nykey
    echo "Update will continue regardless in 7 seconds"
nykey
    countdown 7
nykey
  fi
nykey

nykey
  apt-get -y remove --purge freenx freenx-rdp freenx-server freenx-smb freenx-vnc \
nykey
                    nx-common nxagent libxcompext3 libnx-xorg
nykey
fi
nykey

nykey
# Special handling for bio-linux-cruft-killer - TODO check it
nykey
apt-get -y --force-yes install bio-linux-cruft-killer || exit 1
nykey

nykey
#After this point, don't re-write sources.list
nykey
date >/etc/apt/sources.list.d/bl8.installed.save
nykey

nykey
# And now all the stuff that makes BL.  Note that this does need some updating.
nykey
# Also, after update, check for dangling symlinks in /usr/local/bioinf
nykey
chmod +x ./bl_install_master_list.sh
nykey
./bl_install_master_list.sh
nykey
if [ $? != 0 ] ; then
nykey
    echo "Not all packages installed properly - exiting."
nykey
    exit 1
nykey
fi
nykey

nykey
echo "Scrubbing Java6 packages now we have 7 as default"
nykey
apt-get remove -y --purge openjdk-6-jre{,-lib,-headless}
nykey

nykey
echo "Scrubbing HAL as it is obsolete and triggers ugly errors"
nykey
apt-get remove -y --purge hal
nykey

nykey
echo "Removing unity-2d dummy packages."
nykey
apt-get remove -y --purge unity-2d{,-common,-panel,-shell,-spread}
nykey

nykey
# also, we really don't need this
nykey
apt-get remove -y --purge python-software-properties
nykey

nykey
# Purge themes-v7 config and do an autoremove
nykey
dpkg -P bio-linux-themes-v7 || true
nykey
apt-get -y autoremove
nykey

nykey
# Yes, this really does seem to best way to infer a VirtualBox envronment
nykey
if lspci -n | grep -q '80ee:beef' ; then
nykey
    echo "You seem to be in VirtualBox - ensuring drivers are installed"
nykey

nykey
    apt-get -y install virtualbox-guest-{dkms,source,utils,x11}
nykey
fi
nykey

nykey
echo "Giving Google-Chrome a prod, if you have it installed"
nykey
for gc in `dpkg -l 'google-chrome-*' | grep ^ii | awk '{print$2}'` ; do
nykey
    dpkg-reconfigure $gc
nykey
done
nykey

nykey
# Ensure zsh has all completion options loaded.
nykey
if [ ! -e /etc/zsh/zshrc.ubuntu ] ; then
nykey
    echo "Restoring /etc/zsh/zshrc.ubuntu"
nykey
    apt-get install --reinstall -o "Dpkg::Options::=--force-confmiss" zsh-common
nykey
fi
nykey

nykey
# Also, this, to ensure you see the right boot screen...
nykey
dpkg-reconfigure bio-linux-plymouth-theme
nykey

nykey
# Aptitude remembers selections, and these will now be invalid
nykey
[ -x /usr/bin/aptitude ] && /usr/bin/aptitude keep-all
nykey

nykey
# Clear /var/crash for reasons given above
nykey
rm -rf /var/crash/*
nykey

nykey
# And finally set the new backdrop by invoking gconf on $REALUSER
nykey
# The image should be set up by the bio-linux-themes-v8 package, which is installed as part
nykey
# of the master package list.
nykey
WALLPAPER=/var/spool/BL_auto_cycling_background.jpg
nykey
#echo "DEBUG - WALLPAPER is $WALLPAPER, REALUSER is $REALUSER"
nykey
# if [ -e "$WALLPAPER" -a -n "$REALUSER" ] ; then
nykey
#     sudo -u "$REALUSER" gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER" >&/dev/null
nykey
# fi
nykey
# Actually, do it for all users! And account for new quirks in DBUS (Yeah, this is nasty...)
nykey
for ahome in /home/* ; do
nykey
    auser=`stat -c%U "$ahome"`
nykey
    if [ -e "$WALLPAPER" -a -d "$ahome"/.local ] ; then
nykey
	sudo -Hu "$auser" dbus-launch gsettings set \
nykey
	    org.gnome.desktop.background picture-uri "file://$WALLPAPER" >&/dev/null
nykey
	sudo -Hu "$auser" sh -c '. `( ls ~/.cache/upstart/dbus-session 2>/dev/null ;
nykey
	                              ls -t ~/.dbus/session-bus/* 2>/dev/null ;
nykey
				      echo /dev/null ) | head -n1` && export DBUS_SESSION_BUS_ADDRESS \
nykey
		&& '"gsettings set org.gnome.desktop.background picture-uri 'file://$WALLPAPER' >/dev/null 2>&1"
nykey
    fi
nykey
done
nykey

nykey
echo
nykey
echo
nykey
echo "All done - your system is updated to Bio-Linux 8!";
nykey
