# Adapting Terratest for Different Terraform Modules

This document explains how to adapt the Terratest files for testing different Terraform modules.

## Overview

The Terratest files in this directory are designed to test the Azure Virtual Network Terraform module. To adapt these tests for a different module, you'll need to modify the test files to match the resources and outputs of your module.

## Step 1: Update the Go Module

Update the `go.mod` file to reflect your module's name:

```go
module github.com/your-org/your-module-name/test

go 1.20

require (
    github.com/Azure/azure-sdk-for-go v68.0.0+incompatible
    github.com/gruntwork-io/terratest v0.43.0
    github.com/stretchr/testify v1.8.4
)
```

## Step 2: Create Test Files for Your Module

You can use the `template_test.go.example` file as a starting point. Copy it to a new file named after your module, for example `storage_account_test.go`.

## Step 3: Modify the Test Functions

Update the test functions to match your module's resources and outputs:

1. Update the resource names and types:

```go
// Generate a random name to prevent a naming conflict
uniqueID := random.UniqueId()
resourceName := fmt.Sprintf("your-resource-%s", uniqueID)
resourceGroupName := fmt.Sprintf("rg-test-%s", uniqueID)
```

2. Update the Terraform directory paths to point to your module's examples:

```go
// The path to where our Terraform code is located
TerraformDir: "../examples/your-example",
```

3. Update the variables to match your module's input variables:

```go
// Variables to pass to our Terraform code using -var options
Vars: map[string]interface{}{
    "name":                resourceName,
    "resource_group_name": resourceGroupName,
    "your_variable":       "your_value",
},
```

4. Update the output variables to match your module's outputs:

```go
// Run `terraform output` to get the values of output variables
resourceID := terraform.Output(t, terraformOptions, "your_output_name")
```

5. Update the assertions to verify your module's resources:

```go
// Verify that the resource ID is not empty
assert.NotEmpty(t, resourceID, "Resource ID should not be empty")

// Add more assertions specific to your module
```

## Step 4: Add Module-Specific Tests

Add tests that are specific to your module's functionality. For example, if you're testing a storage account module, you might want to verify that the storage account is created with the correct access tier or replication type.

```go
// Verify that the storage account has the correct access tier
accessTier := terraform.Output(t, terraformOptions, "access_tier")
assert.Equal(t, "Hot", accessTier, "Storage account should have Hot access tier")
```

## Step 5: Test Multiple Examples

Create test functions for each example in your module, similar to how the Virtual Network module tests different examples:

- Basic example
- Complete example
- Feature-specific examples (e.g., service delegations, DDoS protection)

## Step 6: Run the Tests

Run the tests to make sure they work:

```bash
cd test
go mod tidy
go test -v -timeout 30m
```

## Example: Adapting for a Storage Account Module

Here's an example of how you might adapt the tests for an Azure Storage Account module:

```go
func TestTerraformAzureStorageAccountBasicExample(t *testing.T) {
    t.Parallel()

    // Generate a random name to prevent a naming conflict
    uniqueID := random.UniqueId()
    storageAccountName := fmt.Sprintf("sttest%s", uniqueID)
    resourceGroupName := fmt.Sprintf("rg-test-%s", uniqueID)

    // Construct the terraform options with default retryable errors
    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        // The path to where our Terraform code is located
        TerraformDir: "../examples/basic",

        // Variables to pass to our Terraform code using -var options
        Vars: map[string]interface{}{
            "name":                storageAccountName,
            "resource_group_name": resourceGroupName,
            "account_tier":        "Standard",
            "replication_type":    "LRS",
        },
    })

    // At the end of the test, run `terraform destroy` to clean up any resources that were created
    defer terraform.Destroy(t, terraformOptions)

    // Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
    terraform.InitAndApply(t, terraformOptions)

    // Run `terraform output` to get the values of output variables
    storageAccountID := terraform.Output(t, terraformOptions, "storage_account_id")
    primaryBlobEndpoint := terraform.Output(t, terraformOptions, "primary_blob_endpoint")

    // Verify that the storage account ID is not empty
    assert.NotEmpty(t, storageAccountID, "Storage account ID should not be empty")

    // Verify that the primary blob endpoint is not empty and has the correct format
    assert.NotEmpty(t, primaryBlobEndpoint, "Primary blob endpoint should not be empty")
    assert.True(t, strings.Contains(primaryBlobEndpoint, storageAccountName), "Primary blob endpoint should contain the storage account name")
    assert.True(t, strings.HasPrefix(primaryBlobEndpoint, "https://"), "Primary blob endpoint should start with https://")
}
```

## Conclusion

By following these steps, you can adapt the Terratest files to test any Terraform module. Remember to:

1. Update the Go module name
2. Modify the test functions to match your module's resources and outputs
3. Add module-specific tests
4. Test multiple examples
5. Run the tests to verify they work
