package tests

import (
	"flag"
	"os"
	"regexp"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/require"
)

var update = flag.Bool("update-golden", false, "update golden test output files")

type TemplateGoldenTest struct {
	ChartPath      string
	Release        string
	Namespace      string
	GoldenFileName string
	Templates      []string
	SetValues      map[string]string
	ValuesFile     string
}

// TestContainerGoldenTestDefaults Code is based on the article here:  https://medium.com/@zelldon91/advanced-test-practices-for-helm-charts-587caeeb4cb
func TestContainerGoldenTestDefaults(t *testing.T, testCase *TemplateGoldenTest) {
	r := require.New(t)

	options := &helm.Options{
		KubectlOptions:    k8s.NewKubectlOptions("", "", testCase.Namespace),
		SetValues:         testCase.SetValues,
		ValuesFiles:       []string{testCase.ValuesFile},
		BuildDependencies: true,
	}
	output := helm.RenderTemplate(t, options, testCase.ChartPath, testCase.Release, testCase.Templates)
	regex := regexp.MustCompile(`\s+helm.sh/chart:\s+.*`)
	bytes := regex.ReplaceAll([]byte(output), []byte(""))
	output = string(bytes)

	goldenFile := "golden/" + testCase.GoldenFileName + ".golden.yaml"

	if *update {
		err := os.WriteFile(goldenFile, bytes, 0644)
		r.NoError(err, "Golden file was not writable")
	}

	expected, err := os.ReadFile(goldenFile)

	// then
	r.NoError(err, "Golden file doesn't exist or was not readable")
	r.Equal(string(expected), output)
}
