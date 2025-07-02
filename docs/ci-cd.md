

# CI/CD Documentation
This document outlines the CI/CD setup for the Django project using GitHub Actions.

```sh
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_rsa 


ls ~/.ssh

cd ~/.ssh

# private key - to paste in GitHub secrets
cat github_rsa
cat ~/.ssh/github_rsa

# create variable in GitHub secrets
# SSH_PRIVATE_KEY


```

```sh
# setup multipass server --cpus 1 --memory 500M --disk 5G

multipass list

multipass launch --name devops-dev-vm --cpus 1 --memory 500M --disk 10G
#multipass launch --name django-pro-core --cpus 2 --mem 4G --disk 10G
multipass shell devops-dev-vm
# or login using ssh
#ssh ubuntu@192.168.64.44
# en fait Par défaut, SSH utilise ~/.ssh/id_rsa. Si ta clé privée est github_rsa, précise-la :
ssh -i ~/.ssh/github_rsa ubuntu@192.168.64.44

# check the IP address
multipass info devops-dev-vm
# Name:           devops-dev-vm
# State:          Running
# Snapshots:      0
# IPv4:           192.168.64.44
# Release:        Ubuntu 24.04.2 LTS
# Image hash:     be8976045dc7 (Ubuntu 24.04 LTS)
# CPU(s):         1
# Load:           0.08 0.03 0.01
# Disk usage:     2.0GiB out of 9.6GiB
# Memory usage:   138.5MiB out of 439.2MiB
```

```sh
# Create this as a variable in GitHub secrets
# SSH_HOST
SSH_HOST=192.168.64.44
# SSH_USER
SSH_USER=ubuntu

# public key
cat github_rsa.pub

# copy the public key to the VM
ssh-copy-id -i ~/.ssh/github_rsa.pub ubuntu@192.168.64.44

# or 
multipass transfer ~/.ssh/github_rsa.pub devops-dev-vm:~/github_rsa.pub

# connect to the VM
ssh ubuntu@192.168.64.44
#sudo cat /home/ubuntu/github_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
sudo cat ~/.ssh/authorized_keys

vi ~/.ssh/authorized_keys
```

```sh
# check my macos ipv4 address
ifconfig | grep inet
# awf@MacBook-Pro-de-Thomas django-pro-core % ifconfig | grep inet
#         inet 127.0.0.1 netmask 0xff000000
#         inet6 ::1 prefixlen 128 
#         inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1 
#         inet6 fe80::e66a:f45:931a:dcb0%utun0 prefixlen 64 scopeid 0x10 
#         inet6 fe80::abd9:b817:eef3:fafb%utun1 prefixlen 64 scopeid 0x11 
#         inet6 fe80::69a4:e1ec:63c5:38ed%utun2 prefixlen 64 scopeid 0x12 
#         inet6 fe80::ce81:b1c:bd2c:69e%utun3 prefixlen 64 scopeid 0x13 
#         inet6 fe80::c32:bfd6:bc3c:3af%en0 prefixlen 64 secured scopeid 0xe 
#         inet 192.168.1.99 netmask 0xffffff00 broadcast 192.168.1.255
#         inet6 2a01:e0a:1be:b900:1c03:6c94:4da4:adfa prefixlen 64 autoconf secured 
#         inet6 2a01:e0a:1be:b900:99e5:caae:307:60ba prefixlen 64 autoconf temporary 
#         inet6 fe80::d420:dcff:fe05:4eef%awdl0 prefixlen 64 scopeid 0x14 
#         inet6 fe80::d420:dcff:fe05:4eef%llw0 prefixlen 64 scopeid 0x15 
#         inet 192.168.64.1 netmask 0xffffff00 broadcast 192.168.64.255
#         inet6 fe80::603e:5fff:fec8:264%bridge100 prefixlen 64 scopeid 0x17 
#         inet6 fdbc:3c02:3ba0:e58a:1031:361f:fd08:2d77 prefixlen 64 autoconf secured 
#         inet6 fe80::2f60:eb5f:56f4:e473%utun4 prefixlen 64 scopeid 0x1a 
#         inet6 fe80::cec3:9f23:737c:7ba7%utun5 prefixlen 64 scopeid 0x1b 
#         inet6 fe80::1fc:74c7:cb42:7c5f%utun6 prefixlen 64 scopeid 0x1c 
#         inet6 fe80::bce5:135a:c1ad:64a2%utun7 prefixlen 64 scopeid 0x1d 

# just want the ipv4 address
ifconfig | grep inet | grep -v inet6
# awf@MacBook-Pro-de-Thomas django-pro-core % ifconfig | grep inet | grep -v inet6
# inet 127.0.0.1 netmask 0xff000000
# inet 192.168.1.99 netmask 0xffffff00 broadcast 192.168.1.255
# inet 192.168.64.1 netmask 0xffffff00 broadcast 192.168.64.255

- 192.168.1.99 : est l'adresse IPv4 principale de ton Mac sur ton réseau local (Wi-Fi ou Ethernet)  
- 192.168.64.1 : est une adresse virtuelle créée par Multipass (interface bridge ou NAT pour les VM).
```

La bonne adresse à utiliser pour accéder à ton Mac depuis ton réseau local est :
```sh
192.168.1.99
```
Utilise celle-ci pour les connexions SSH, transferts de fichiers, etc., depuis d'autres appareils sur le même réseau.


### Clone the repository in the VM

```sh
multipass shell devops-dev-vm

# create ssh key in the VM
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa


# copy vm public key to github
#ls ~/.ssh
ls -la /home/ubuntu/.ssh/
cat ~/.ssh/id_rsa.pub
cat ~/.ssh/id_rsa

# restart the VM
multipass restart devops-dev-vm
#cd ~/.ssh