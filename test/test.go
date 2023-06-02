package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExample1(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/example1",
		NoColor:      true,
		EnvVars: map[string]string{
			"ARM_CLIENT_ID":       os.Getenv("ARM_CLIENT_ID"),
			"ARM_CLIENT_SECRET":   os.Getenv("ARM_CLIENT_SECRET"),
			"ARM_TENANT_ID":       os.Getenv("ARM_TENANT_ID"),
			"ARM_SUBSCRIPTION_ID": os.Getenv("ARM_SUBSCRIPTION_ID"),
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)
}
