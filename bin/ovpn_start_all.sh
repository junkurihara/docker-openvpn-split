#!/bin/sh

nospaces() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
onespace() { printf '%s' "$1" | tr -s ' '; }
noquotes() { printf '%s' "$1" | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/"; }
noquotes2() { printf '%s' "$1" | sed -e 's/" "/ /g' -e "s/' '/ /g"; }
# commatospc() { printf '%s' "$1" | tr ',' '\n' | xargs -I{} echo "{}" | paste -s -d ' ' -; }
countcolumn() { printf '%s' "$1" | awk -F ' ' '{print NF}'; }


if [ ! -f "${OPENVPN}/openvpn.conf" ]; then
    # generate config file
    echo "-- Generate openvpn.conf"
    if [ -z "${VPN_OVPN_ROUTES}" ]; then
	OVPN_ROUTES_OPT="-r 192.168.255.0/24"
    else
	OVPN_ROUTES_OPT="-r ${VPN_OVPN_ROUTES}"
    fi

    if [ -z "${VPN_DNS_SRV1}" ] && [ -z "${VPN_DNS_SRV2}" ]; then
	OVPN_DNS_OPT=""
    elif [ ! -z "${VPN_DNS_SRV1}" ] && [ -z "${VPN_DNS_SRV2}" ]; then
	OVPN_DNS_OPT="-n ${VPN_DNS_SRV1}"
    elif [ -z "${VPN_DNS_SRV1}" ] && [ ! -z "${VPN_DNS_SRV2}" ]; then
	OVPN_DNS_OPT="-n ${VPN_DNS_SRV2}"
    elif [ ! -z "${VPN_DNS_SRV1}" ] && [ ! -z "${VPN_DNS_SRV2}" ]; then
	OVPN_DNS_OPT="-n ${VPN_DNS_SRV1} -n ${VPN_DNS_SRV2}"
    fi
    
    ovpn_genconfig -u udp://${VPN_HOST_NAME} ${OVPN_DNS_OPT} ${OVPN_ROUTES_OPT}
fi

# check if pki files exist.
# Unless they eixist, pki files would be produced.
if [ ! -d ${EASYRSA_PKI} ]; then
    echo "-- Initialize EasyRSA."
    echo "-- Note: CA key is not encrypted with passphrase by default."
    ovpn_initpki nopass
else
    echo "-- PKI files exist. Skip to initialize EasyRSA."
fi

VPN_USERS=$(nospaces "$VPN_USERS")
VPN_USERS=$(noquotes "$VPN_USERS")
VPN_USERS=$(onespace "$VPN_USERS")
VPN_USERS=$(noquotes2 "$VPN_USERS")

if [ ! -d "${OPENVPN}/profiles" ]; then
    mkdir -p ${OPENVPN}/profiles
fi
count=1
cuser=$(printf '%s' "$VPN_USERS" | cut -d ' ' -f 1)
while [ -n "$cuser" ]; do
    if [ -f "${EASYRSA_PKI}/issued/${cuser}.crt" ]; then
	echo "-- ${cuser}: user certificate exists";
    else
	echo "-- ${cuser}: generate user certificate";
	easyrsa build-client-full $cuser nopass
    fi
    echo "-- ${cuser}: generate/overwrite OpenVPN profile"
    ovpn_getclient ${cuser} > $OPENVPN/profiles/${cuser}.ovpn
    count=$((count+1))
    cuser=$(printf '%s' "$VPN_USERS" | cut -s -d ' ' -f "$count")
done

# start normally
echo "-- Start OpenVPN."
ovpn_run --log /var/log/openvpn/openvpn.log
