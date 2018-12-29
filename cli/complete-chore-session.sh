#!/bin/bash

chore=${1//\'/\\\'}
time_components=(${2//:/ })
when_completed=${3//\'/\\\'}
minutes=${time_components[0]}
seconds=${time_components[1]}
mysql chores -u chores -pM2TEncult7v3TrC90SUs -e "CALL complete_chore_session('$chore', '$when_completed', $minutes, $seconds, @c, @n)"
