
#!/bin/bash

# Ensure a domain is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 domain.com"
    exit 1
fi

DOMAIN=$1

echo "### DNS Troubleshooting Checklist for $DOMAIN ###"

# Audit Section: Gather system DNS configuration information
echo "### DNS Configuration Audit ###"

# 1. Display /etc/hosts
echo "Contents of /etc/hosts:"
cat /etc/hosts
echo

# 2. Display /etc/resolv.conf
echo "Contents of /etc/resolv.conf:"
cat /etc/resolv.conf
echo

# 3. Check the status of systemd-resolved service
echo "Status of systemd-resolved service:"
systemctl is-active systemd-resolved
echo

# 4. Display DNS settings using resolvectl
echo "DNS settings using resolvectl:"
resolvectl status
echo


# Extract nameserver IP from /etc/resolv.conf
NAMESERVER_IP=$(awk '/^nameserver/ {print $2}' /etc/resolv.conf)

# Check which process is listening on the extracted IP
echo "Process listening on $NAMESERVER_IP:53:"
sudo lsof -Pn -i @$NAMESERVER_IP:53
echo



# 5. Check which process is listening on 127.0.0.53:53
echo "Process listening on 127.0.0.53:53:"
sudo lsof -Pn -i @127.0.0.53:53
echo


# x. Check the DNS from DHCP of the netwoek with network manager
echo "Check DHCP DNS"
nmcli dev show | grep DNS
echo


echo "### End of DNS Configuration Audit ###"
echo

# Troubleshooting Section

# 1. Check /etc/hosts for any manual entries
echo "Checking /etc/hosts for manual entries..."
grep $DOMAIN /etc/hosts
echo

# 2. Check DNS resolution using dig
echo "Checking DNS resolution using dig..."
dig $DOMAIN +short
echo

# 3. Check DNS resolution using nslookup
echo "Checking DNS resolution using nslookup..."
nslookup $DOMAIN
echo

# 4. Ping the domain
echo "Pinging $DOMAIN..."
ping -c 4 $DOMAIN
echo

# 5. Check DNS resolution using resolvectl
echo "Checking DNS resolution using resolvectl..."
resolvectl query $DOMAIN
echo

# 6. Check mDNS resolution (if applicable)
if [[ $DOMAIN == *.local ]]; then
    echo "Checking mDNS resolution..."
    avahi-resolve --name $DOMAIN
    echo
fi

# 7. Check for DNSSEC validation issues
echo "Checking DNSSEC validation..."
dig $DOMAIN +dnssec
echo

# 8. Check full DNS trace
echo "Checking full DNS trace..."
dig $DOMAIN +trace
echo

# 9. Check connectivity to the domain's nameservers
echo "Checking connectivity to the domain's nameservers..."
for NS in $(dig NS $DOMAIN +short); do
    echo "Pinging nameserver $NS..."
    ping -c 2 $NS
    echo
done

# 10. Check if domain is reachable via a web request (using curl)
echo "Checking domain via a web request..."
curl -I $DOMAIN
echo

# 11. Check DNS statistics using resolvectl
echo "Checking DNS statistics using resolvectl..."
resolvectl statistics
echo

echo "### Troubleshooting Checklist Complete ###"

PORT=443 # https
# 12 certinfo
echo | openssl s_client -connect $DOMAIN:$PORT -servername $DOMAIN 2>/dev/null | openssl x509 -text
echo


