#!/bin/bash
echo $SSH_ORIGINAL_COMMAND
#Use the original command as positional parameter
set $SSH_ORIGINAL_COMMAND
if ! [[ "$SSH_ORIGINAL_COMMAND" =~ ^[a-zA-Z0-9\.\/\|\ \+\-]*$ ]] ;
then
        echo "Error: Invalid character found in command."
        exit 1
fi
case "$1" in
        '/sbin/fsfreeze')
        ;;
        *)
                echo "Error: Invalid command over ssh executed."
                exit 1
        ;;
esac
#echo $SSH_ORIGINAL_COMMAND
eval "sudo $SSH_ORIGINAL_COMMAND"
