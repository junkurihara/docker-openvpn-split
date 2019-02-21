# Docker image of OpenVPN for split tunneling of DNS query

This is a fork of https://github.com/kylemanna/docker-openvpn for split tunneling of DNS query.

## Installation

```
$ docker pull jqtype/openvpn-split
```

or

```
$ docker build -t jqtype/openvpn-split .
```

## Configuration

Before launching the container `vpn.env` must be filled.

```
#######################
# Common
#######################
# Define VPN users
# - Uncomment and replace with your own values
# - Usernames must be separated by spaces
VPN_USERS=your_vpn_username_one your_vpn_username_two

# (Optional) Use alternative DNS servers
# - By default, clients are set to use Google Public DNS
# - Example below shows using Cloudflare's DNS service
# VPN_DNS_SRV1=1.1.1.1
# VPN_DNS_SRV2=1.0.0.1

#######################
# OpenVPN
#######################
# VPN host name (fqdn)

VPN_HOST_NAME=example.com

# (Optional)
# VPN_OVPN_ROUTES=192.168.111.19/32 

VPN_OVPN_EXTERNAL_PORT=21194
```

## Deployment

By executing the following command, everything will be set-up.

```
$ docker-compose up -d
```

OpenVPN profiles for users will be generated as `./data/openvpn/profiles/<username>.ovpn`.