# Django Deployment Guide

## Understanding the Issue

Your current GitHub Actions workflow is failing because it's trying to deploy to a Multipass VM with a local IP address (`192.168.64.44`). GitHub Actions cannot reach this IP address because:

1. It's a private IP address on your local network
2. GitHub Actions runs on GitHub's servers with no access to your local network

## Solution Options

### Option 1: Deploy to a Cloud VM (Recommended)

The most straightforward solution is to deploy to a cloud-based VM with a public IP address.

#### Steps:

1. **Create a cloud VM**:
   - Use a cloud provider like DigitalOcean, AWS, Azure, or Google Cloud
   - Create a small VM (1GB RAM is enough for a basic Django app)
   - Make note of the public IP address

2. **Configure SSH access**:
   - Generate an SSH key pair if you haven't already: 
     ```sh
     ssh-keygen -t rsa -b 4096 -f ~/.ssh/cloud_deploy_key
     ```
   - Add the public key to your cloud VM during setup or after creation
   - Add the private key to your GitHub repository secrets as `SSH_PRIVATE_KEY`

3. **Update GitHub secrets**:
   - Set `SSH_HOST` to your cloud VM's public IP address
   - Set `SSH_USER` to the VM user (often `ubuntu`, `root`, or `admin` depending on the provider)

4. **Update the deploy.yml workflow**:
   - Use the updated workflow with proper repository details

### Option 2: Use ngrok for Local Development

If you want to continue using your local Multipass VM for development, you can use ngrok to create a tunnel.

#### Steps:

1. **Install ngrok**:
   ```sh
   brew install ngrok
   ```

2. **Create a free ngrok account** at https://ngrok.com/

3. **Configure ngrok**:
   ```sh
   ngrok config add-authtoken YOUR_AUTH_TOKEN
   ```

4. **Create a tunnel to your Multipass VM**:
   ```sh
   ngrok tcp 192.168.64.44:22
   ```

5. **Update GitHub secrets**:
   - Set `SSH_HOST` to the ngrok hostname (e.g., `0.tcp.ngrok.io`)
   - Set `SSH_PORT` to the ngrok port (e.g., `12345`)
   - Update the workflow to use this port:
     ```yaml
     ssh -p $SSH_PORT $SSH_USER@$SSH_HOST
     ```

Note: The free tier of ngrok will provide a different hostname/port each time you restart ngrok, requiring you to update your secrets regularly.

### Option 3: Set up Port Forwarding (Advanced)

If you have control over your router and have a static public IP address:

1. Configure port forwarding on your router to direct external traffic to your Mac
2. Set up port forwarding from your Mac to the Multipass VM
3. Use a dynamic DNS service like DuckDNS to handle your home IP address changes

## Recommended Approach for Learning Purposes

If this is for learning purposes only and not a production application, Option 1 (using a cloud VM) is the most straightforward:

1. Create a free tier VM on AWS, Azure, or DigitalOcean
2. Set up SSH access with your existing keys
3. Update the GitHub secrets with the new VM details

This will provide a realistic deployment environment without the complexity of tunneling or port forwarding.
