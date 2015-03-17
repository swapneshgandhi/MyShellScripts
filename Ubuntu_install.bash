#!/bin/bash

filename=$PWD/startup.bash

echo $filename
if [ -f $PWD/Sesame.desktop ]; then
replacestr=`grep "Exec=" $PWD/Sesame.desktop | awk -F'=' '{print $2}'`
sed -i'.bak' s,Exec=${replacestr},Exec=$filename,g $PWD/Sesame.desktop

fi

if [ ! -d ~/.config/autostart ]; then
   mkdir ~/.config/autostart
fi

cp $PWD/Sesame.desktop ~/.config/autostart
