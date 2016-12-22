
NETWORKS_STACK_NAME="$NAME_PREFIX-networks"
NET_DRIVE=`$GIT config -f $INIFILE --get default.driveNetworkId`
NET_BACKBONE=`$GIT config -f $INIFILE --get default.backboneNetworkId`

NET_JUMP_IP=`$GIT config -f $INIFILE --get default.floatingIpId`

export RSC_NETWORKS="jump_ip_id=${NET_JUMP_IP};net_drive=${NET_DRIVE};net_backbone=${NET_BACKBONE}"
