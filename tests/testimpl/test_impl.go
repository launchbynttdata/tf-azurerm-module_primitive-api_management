package testimpl

import (
	"context"
	"os"
	"testing"

	"github.com/Azure/azure-sdk-for-go/sdk/azcore"
	"github.com/Azure/azure-sdk-for-go/sdk/azcore/arm"
	"github.com/Azure/azure-sdk-for-go/sdk/azcore/cloud"
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	apiManagement "github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/apimanagement/armapimanagement"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/launchbynttdata/lcaf-component-terratest/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// getApiManagementService fetches the API Management service under test from
// the Azure API Management API, using the resource_group_name and
// api_management_name Terraform outputs.
func getApiManagementService(t *testing.T, ctx types.TestContext) apiManagement.ServiceClientGetResponse {
	subscriptionId := os.Getenv("ARM_SUBSCRIPTION_ID")
	require.NotEmpty(t, subscriptionId, "ARM_SUBSCRIPTION_ID environment variable is not set")

	credential, err := azidentity.NewDefaultAzureCredential(nil)
	require.NoError(t, err, "Unable to get Azure credentials")

	resourceGroupName := terraform.OutputContext(t, t.Context(), ctx.TerratestTerraformOptions(), "resource_group_name")
	serviceName := terraform.OutputContext(t, t.Context(), ctx.TerratestTerraformOptions(), "api_management_name")

	options := arm.ClientOptions{
		ClientOptions: azcore.ClientOptions{
			Cloud: cloud.AzurePublic,
		},
	}

	apimClient, err := apiManagement.NewServiceClient(subscriptionId, credential, &options)
	require.NoError(t, err, "Error getting API Management service client")

	apim, err := apimClient.Get(context.Background(), resourceGroupName, serviceName, nil)
	require.NoError(t, err, "Error getting API Management service")

	return apim
}

// TestComposableApiManagementReadOnly is the readonly test implementation. It
// verifies the deployed API Management service is provisioned and correctly
// configured via the Azure API Management API. It must not create, update,
// or delete any resources.
func TestComposableApiManagementReadOnly(t *testing.T, ctx types.TestContext) {
	apim := getApiManagementService(t, ctx)

	expectedName := terraform.OutputContext(t, t.Context(), ctx.TerratestTerraformOptions(), "api_management_name")
	expectedId := terraform.OutputContext(t, t.Context(), ctx.TerratestTerraformOptions(), "api_management_id")

	t.Run("TestApiManagementExists", func(t *testing.T) {
		require.NotNil(t, apim.Name, "Expected API Management service to have a name")
		assert.Equal(t, expectedName, *apim.Name, "Expected Name did not match actual Name!")
		require.NotNil(t, apim.ID, "Expected API Management service to have an ID")
		assert.Equal(t, expectedId, *apim.ID, "Expected ID did not match actual ID!")
	})

	t.Run("TestApiManagementIsProvisioned", func(t *testing.T) {
		require.NotNil(t, apim.Properties, "Expected API Management service to have properties")
		require.NotNil(t, apim.Properties.ProvisioningState, "Expected API Management service to have a provisioning state")
		assert.Equal(t, "Succeeded", *apim.Properties.ProvisioningState, "Expected API Management service to be successfully provisioned")
	})

	t.Run("TestApiManagementSku", func(t *testing.T) {
		require.NotNil(t, apim.SKU, "Expected API Management service to have SKU properties")
		require.NotNil(t, apim.SKU.Name, "Expected API Management service SKU to have a name")
		assert.Equal(t, apiManagement.SKUTypeDeveloper, *apim.SKU.Name, "Expected SKU name to match the Developer SKU configured in the test fixture")
		require.NotNil(t, apim.SKU.Capacity, "Expected API Management service SKU to have a capacity")
		assert.EqualValues(t, 1, *apim.SKU.Capacity, "Expected SKU capacity to match the test fixture")
	})

	t.Run("TestApiManagementPublisher", func(t *testing.T) {
		require.NotNil(t, apim.Properties.PublisherName, "Expected API Management service to have a publisher name")
		assert.Equal(t, "Launch DSO", *apim.Properties.PublisherName, "Expected publisher name to match the test fixture")
		require.NotNil(t, apim.Properties.PublisherEmail, "Expected API Management service to have a publisher email")
		assert.Equal(t, "example@nttdata.com", *apim.Properties.PublisherEmail, "Expected publisher email to match the test fixture")
	})

	t.Run("TestApiManagementIdentity", func(t *testing.T) {
		require.NotNil(t, apim.Identity, "Expected API Management service to have an identity")
		require.NotNil(t, apim.Identity.Type, "Expected API Management service identity to have a type")
		assert.Equal(t, apiManagement.ApimIdentityTypeUserAssigned, *apim.Identity.Type, "Expected identity type to match the test fixture")
	})
}

// TestComposableApiManagement is the functional test implementation. There is
// no meaningful mutating/write operation to exercise against a bare API
// Management service (it has no APIs deployed in this example), so the
// functional suite is the same set of read-only checks as the readonly
// suite -- reusing it directly rather than duplicating the checks avoids the
// copy/paste drift that caused the readonly suite to go stale in the first
// place.
func TestComposableApiManagement(t *testing.T, ctx types.TestContext) {
	TestComposableApiManagementReadOnly(t, ctx)
}
