# 🔐 GitHub Secrets Configuration Guide

This guide explains how to configure the required GitHub secrets for the DigitalOcean deployment workflow.

## Required Secrets

The deployment workflow requires three secrets to be configured in your GitHub repository:

### 1. SSH_PRIVATE_KEY
**Description**: Private SSH key for server authentication  
**Value**: Content of your private SSH key

### 2. SSH_HOST  
**Description**: DigitalOcean server IP address  
**Value**: `157.245.79.172`

### 3. SSH_USER
**Description**: Username for server access  
**Value**: `django`

## Step-by-Step Configuration

### 1. Generate SSH Key Pair (if not already done)

```bash
# Generate a new SSH key pair specifically for GitHub Actions
ssh-keygen -t rsa -b 4096 -f ~/.ssh/digitalocean_deploy_key

# This creates:
# - ~/.ssh/digitalocean_deploy_key (private key)
# - ~/.ssh/digitalocean_deploy_key.pub (public key)
```

#### 1.1 Add Private Key to GitHub Secrets
```bash
# Copy private key content (including header/footer)
cat ~/.ssh/digitalocean_deploy_key
```

### 2. Add Public Key to DigitalOcean Server

### 
```sh
cat ~/.ssh/digitalocean_deploy_key.pub

vi ~/.ssh/authorized_keys

# Paste the public key content into the authorized_keys file
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwAXk48TFER878nPMtn4gqQGpKSi3qPV4FYf2raOdvmJcP/XEm2COtHQyC1EwVTYQWE+OtYi5K1PcmODAtszpRDebKCV3Ks35M437Ebo7htkwWJ0V2zTSoeV21ippic5zJnb1ye0gibhs+8f0fR3+HDGgqKLs072PXuzTD0BynAGhJWtKsGSUVCX3uNNkbsBT22HyhBnPnz04bNFsWqco6ZQWeqrd+GhwrXlQJ8cY1CSXYxlLpya6yeZEz7EjrPaXPc+paOqhLVbz5adkHBvXPUB7GmqWdfhrlBOyisbW7REIWU80YCz/uj36c1NvgXzxVmBcSHoiQXcuYn2P72RyWHH72DhSRsnJW2FFzpXpKIgZJJ6ZOvxA8WqIGdN3z/OtMMnLsUuSpUfUNdJ9rzGma58gem0EBPDsV/qwFGjmLSCibsEV15LSVOlr8t3+Onsp/AegKExhWKC6LUJWe/wfW/WIk64Y8FBUYnz1TPF12DwJgOUkaJFNKYtf6HvNEUJ7suTPFWabk6Ajv/Leyd18dhg87lWnqmnlEfAPwzYtTkG0x95Mh25aBENcT+SQV6GaTB15PRQ74AjKOSpbqX3ZDay7dxGaXNs1giry2cqr0732fBPdGGNjYuTjkFfLeYW/tcup3SaJloL/tkt5EooKbUIJ4o+Q1KKT0U3A7OAOnlQ== django@dos-ubuntu-devops

# Save and exit the editor
```

You have two options:

#### Option A: During server setup script
The `setup-digitalocean.sh` script will prompt you to add your public key.

#### Option B: Manual addition
```bash
# Copy public key content
cat ~/.ssh/digitalocean_deploy_key.pub

# Connect to server and add the key
ssh root@157.245.79.172
mkdir -p /home/django/.ssh
echo "YOUR_PUBLIC_KEY_CONTENT" >> /home/django/.ssh/authorized_keys
chmod 600 /home/django/.ssh/authorized_keys
chmod 700 /home/django/.ssh
chown -R django:django /home/django/.ssh
```

### 3. Configure GitHub Secrets

1. **Navigate to your GitHub repository**
2. **Go to Settings → Secrets and variables → Actions**
3. **Click "New repository secret"**
4. **Add each secret:**

#### SSH_PRIVATE_KEY
- **Name**: `SSH_PRIVATE_KEY`
- **Value**: Complete content of private key file
```bash
# Copy private key content (including header/footer)
cat ~/.ssh/digitalocean_deploy_key
```
**Important**: Include the entire key including:
```
-----BEGIN OPENSSH PRIVATE KEY-----
[key content]
-----END OPENSSH PRIVATE KEY-----
```

#### SSH_HOST
- **Name**: `SSH_HOST`
- **Value**: `157.245.79.172`

#### SSH_USER
- **Name**: `SSH_USER`
- **Value**: `django`

## Verification

### Test SSH Connection Locally
```bash
# Test connection with your key
ssh -i ~/.ssh/digitalocean_deploy_key django@157.245.79.172

# Should connect without password prompt
```

### Test in GitHub Actions
1. Push a commit to the `main` branch
2. Check the Actions tab in your repository
3. The workflow should run without SSH authentication errors

## Security Best Practices

### 1. Key Management
- **Use dedicated keys**: Create specific keys for deployment only
- **Rotate regularly**: Update keys periodically for security
- **Limit permissions**: Ensure keys have minimal required permissions

### 2. Server Security
- **Disable password authentication**: Use key-based auth only
- **Configure firewall**: Only allow necessary ports (80, 443, 22)
- **Use fail2ban**: Protect against brute force attacks

### 3. GitHub Security
- **Limit repository access**: Only give access to required team members
- **Use environment protection**: Consider protected environments for production
- **Monitor secret usage**: Check Actions logs for any unauthorized access attempts

## Troubleshooting

### Common Issues

#### 1. Permission Denied (publickey)
```
Permission denied (publickey)
```
**Solutions**:
- Verify public key is correctly added to server
- Check private key format in GitHub secrets
- Ensure correct username (django, not root)

#### 2. Host Key Verification Failed
```
Host key verification failed
```
**Solutions**:
- The deployment workflow handles this automatically
- If issues persist, manually add host to known_hosts

#### 3. SSH Key Format Issues
**Common problems**:
- Missing header/footer lines
- Extra spaces or line breaks
- Wrong key type or encoding

**Solution**: Re-copy the entire key content exactly as output by `cat`

### Debug Commands

```bash
# Test SSH connection with verbose output
ssh -vvv -i ~/.ssh/digitalocean_deploy_key django@157.245.79.172

# Check server logs for SSH attempts
ssh django@157.245.79.172 'sudo journalctl -u ssh -f'

# Verify GitHub secrets (check Actions workflow logs)
```

## Next Steps

After configuring secrets:

1. **Run the setup script** on your DigitalOcean server
2. **Test the deployment workflow** by pushing to main branch
3. **Verify application** is accessible at http://157.245.79.172
4. **Monitor logs** for any issues

## Support

If you encounter issues:

1. Check the workflow logs in GitHub Actions
2. Review server logs: `sudo journalctl -f`
3. Verify all secrets are correctly configured
4. Ensure the setup script completed successfully

---

*For more information, see the complete DevOps plan in `docs/plan-action-devops_v2.md`*
