#!/bin/bash

filename=$PWD/startup.bash
echo $filename
if [ -f $PWD/Sesame.plist.bak ]; then
sed s,PROGRAMNAMEHERE,$filename,g  $PWD/Sesame.plist.bak > $PWD/Sesame.plist

fi

if [ ! -d ~/Library/LaunchAgents ]; then
   mkdir ~/Library/LaunchAgents
fi

cp $PWD/Sesame.plist ~/Library/LaunchAgents

launchctl load ~/Library/LaunchAgents/Sesame.plist
