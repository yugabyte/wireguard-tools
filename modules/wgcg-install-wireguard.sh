#!/bin/bash
# Author: Milos Buncic
# Edited: Bharat Mukheja
# Date: 2021/12/29
# Description: Prepare Wireguard server

set -e

echo "Installing Wireguard and required dependencies on the server, please wait..."
echo

# Installing wireguard kernel module and required dependencies
yum update && yum install -y linux-headers-$(uname -r) epel-release firewalld
yum-config-manager --enable PowerTools
yum install yum-plugin-copr
yum copr enable jdoss/wireguard
yum install wireguard-dkms wireguard-tools
mkdir -p /etc/wireguard

# Allow module to be loaded at boot time
echo wireguard > /etc/modules-load.d/wgcg.conf

# Load the module
echo -e "\nLoading module..."
echo -e "NOTE: If error encountered please try upgrading the Linux kernel to the latest version available and reboot\n"
modprobe -v wireguard

### Generate wgfw.sh script - will be used for adding required firewall rules
cat > /usr/local/bin/wgfw.sh <<EOF && chmod +x /usr/local/bin/wgfw.sh
#!/bin/bash
# Author: Milos Buncic
# Date: 2019/09/25
# Description: Add required Wireguard firewall rules

# Local private interface
PRIVATE_INTERFACE="$(ip a | awk -F'[ :]' '/^2:/ {print $3}')"

rules() {
  local action=\${1}

  firewall-cmd --permanent --\${action}-rich-rule='rule family="ipv4" source address="192.168.16.0/20" masquerade'
  firewall-cmd --permanent --\${action}-rich-rule='rule family="ipv4" source address="192.168.32.0/20" masquerade'
  firewall-cmd --reload
}

case \${1} in
  'add')
    echo 1 > /proc/sys/net/ipv4/ip_forward
    rules add
  ;;
  'del')
    rules remove
    echo 0 > /proc/sys/net/ipv4/ip_forward
  ;;
  *)
    echo "Usage: \$(basename \${0}) add|del"
esac
EOF

### Enable permanent IP forwarding (routing)
#cat > /etc/sysctl.d/10-wgcg.conf <<'EOF' && sysctl -p /etc/sysctl.d/10-wgcg.conf
## Enable IP forwarding (routing) - WireGuard
#net.ipv4.ip_forward = 1
#EOF
