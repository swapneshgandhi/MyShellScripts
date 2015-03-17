#!/bin/bash

case $(ps  x |grep -v grep |grep  "Sesame" | awk  '{print $1}' | wc -w | sed -e 's/^[ \t]*//' ) in

0)  echo "Restarting Sesame:"  
    ./run_Sesame_Server.command
    ;;
1)  # all ok
    ;;
*)  echo "Removed extra instance of Sesame:"
    count=`ps  x |grep -v grep |grep  "Sesame" | awk  '{print $1}' | wc -w | sed -e 's/^[ \t]*//' `
    count=$((count-1))
    kill $(ps  x |grep -v grep |grep  "Sesame" | awk  '{print $1}' | tail -$count  )
    ;;
esac


