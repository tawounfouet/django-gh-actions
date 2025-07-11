#!/bin/bash
# Django Deployment Helper Script
# This script helps you set up proper deployment for your Django application

echo "Django Deployment Helper"
echo "======================="
echo ""
echo "This script will help you set up proper deployment for your Django application."
echo ""

PS3="Select an option: "
options=("Test SSH connection to VM" "Generate new SSH keys" "Set up local VM tunnel with ngrok" "Get VM information" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Test SSH connection to VM")
            echo ""
            read -p "Enter VM IP address: " vm_ip
            read -p "Enter VM username: " vm_user
            read -p "Enter SSH key path (default: ~/.ssh/id_rsa): " ssh_key
            ssh_key=${ssh_key:-~/.ssh/id_rsa}
            
            echo "Testing SSH connection to $vm_ip..."
            ssh -i "$ssh_key" -o ConnectTimeout=5 "$vm_user@$vm_ip" "echo 'Connection successful! VM is reachable.'" || echo "Connection failed. Check your VM IP, username, and SSH key."
            echo ""
            ;;
            
        "Generate new SSH keys")
            echo ""
            read -p "Enter filename for the new key (default: ~/.ssh/deploy_key): " key_path
            key_path=${key_path:-~/.ssh/deploy_key}
            
            ssh-keygen -t rsa -b 4096 -f "$key_path" -N ""
            
            echo ""
            echo "SSH key pair generated:"
            echo "- Private key: $key_path"
            echo "- Public key: $key_path.pub"
            echo ""
            echo "Add this public key to your VM's authorized_keys file:"
            cat "$key_path.pub"
            echo ""
            echo "Add this private key to your GitHub repository secrets as SSH_PRIVATE_KEY:"
            cat "$key_path"
            echo ""
            ;;
            
        "Set up local VM tunnel with ngrok")
            # Check if ngrok is installed
            if ! command -v ngrok &> /dev/null; then
                echo "ngrok not found. Installing..."
                brew install ngrok
            fi
            
            echo ""
            read -p "Enter VM IP address: " vm_ip
            read -p "Enter VM SSH port (default: 22): " vm_port
            vm_port=${vm_port:-22}
            
            echo "Starting ngrok tunnel to $vm_ip:$vm_port..."
            echo "Keep this terminal window open to maintain the tunnel."
            echo "Press Ctrl+C to stop the tunnel when done."
            echo ""
            echo "After ngrok starts, note the forwarding address and update your GitHub secrets:"
            echo "- SSH_HOST: The hostname part (e.g., 0.tcp.ngrok.io)"
            echo "- SSH_PORT: The port number part (e.g., 12345)"
            echo ""
            ngrok tcp "$vm_ip:$vm_port"
            ;;
            
        "Get VM information")
            echo ""
            echo "Multipass VM information:"
            if command -v multipass &> /dev/null; then
                multipass list
                echo ""
                read -p "Enter VM name to show details: " vm_name
                multipass info "$vm_name"
            else
                echo "Multipass is not installed."
            fi
            echo ""
            ;;
            
        "Quit")
            break
            ;;
            
        *) 
            echo "Invalid option $REPLY"
            ;;
    esac
done
