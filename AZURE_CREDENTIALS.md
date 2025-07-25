# Setting Up Azure Credentials for GitHub Actions

This document explains how to set up Azure credentials for use with the GitHub Actions workflow for testing Terraform modules.

## Prerequisites

- Azure CLI installed
- Access to an Azure subscription with permissions to create service principals
- GitHub repository where you want to set up the workflow

## Creating an Azure Service Principal

1. Log in to Azure using the Azure CLI:

```bash
az login
```

2. List your subscriptions and note the ID of the subscription you want to use:

```bash
az account list --output table
```

3. Set the active subscription:

```bash
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

4. Create a service principal with Contributor role on the subscription:

```bash
az ad sp create-for-rbac --name "terraform-ci" --role Contributor --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
```

This command will output something like:

```json
{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "terraform-ci",
  "password": "abcdefghijklmnopqrstuvwxyz12345678",
  "tenant": "00000000-0000-0000-0000-000000000000"
}
```

Note down these values as you'll need them in the next step.

## Setting Up GitHub Secrets

1. Go to your GitHub repository.
2. Click on "Settings" > "Secrets and variables" > "Actions".
3. Click on "New repository secret" and add the following secrets:

- `ARM_CLIENT_ID`: The `appId` value from the service principal creation output
- `ARM_CLIENT_SECRET`: The `password` value from the service principal creation output
- `ARM_SUBSCRIPTION_ID`: Your Azure subscription ID
- `ARM_TENANT_ID`: The `tenant` value from the service principal creation output

## Verifying the Setup

1. Push a change to your repository or manually trigger the workflow.
2. Go to the "Actions" tab in your repository to see the workflow running.
3. Check that the workflow can authenticate to Azure and perform the necessary operations.

## Security Considerations

- The service principal has Contributor access to the entire subscription. For production use, consider limiting the scope to specific resource groups.
- Regularly rotate the service principal credentials.
- Consider using OpenID Connect (OIDC) for keyless authentication instead of storing secrets.

## Using OIDC for Keyless Authentication (Advanced)

For enhanced security, you can use OpenID Connect (OIDC) to authenticate to Azure without storing secrets in GitHub:

1. Create an OIDC provider in Azure:

```bash
az ad app create --display-name "GitHub Actions OIDC"
```

2. Configure the federated credentials for your GitHub repository.

3. Update the GitHub Actions workflow to use OIDC authentication.

For detailed instructions, refer to the [GitHub documentation on configuring OpenID Connect in Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure).
