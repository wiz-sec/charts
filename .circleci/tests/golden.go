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

type goldenHelmTest struct {
	ChartPath          string
	Release            string
	Namespace          string
	GoldenFileName     string
	Templates          []string
	SetValues          map[string]string
	ValuesFile         string
	GoldenSubDirectory string
}

// runGoldenHelmTest Code is based on the article here:  https://medium.com/@zelldon91/advanced-test-practices-for-helm-charts-587caeeb4cb
// This function allows to test rendering of helm charts with values and rendering specific templates.
func runGoldenHelmTest(t *testing.T, testCase *goldenHelmTest) {
	r := require.New(t)

	options := &helm.Options{
		KubectlOptions:    k8s.NewKubectlOptions("", "", testCase.Namespace),
		SetValues:         testCase.SetValues,
		ValuesFiles:       []string{testCase.ValuesFile},
		BuildDependencies: true,
	}
	output := helm.RenderTemplate(t, options, testCase.ChartPath, testCase.Release, testCase.Templates)

	// Replacing expressions which change on every run so they won't be compared in the golden file
	regexes := map[*regexp.Regexp]string{
		regexp.MustCompile(`helm.sh/chart:\s+.*`):      "helm.sh/chart: \"REDACTED\"",
		regexp.MustCompile(`tls.crt:\s+.*`):            "tls.crt: \"REDACTED\"",
		regexp.MustCompile(`tls.key:\s+.*`):            "tls.key: \"REDACTED\"",
		regexp.MustCompile(`rollme:\s+.*`):             "rollme: \"REDACTED\"",
		regexp.MustCompile(`rollme.webhookCert:\s+.*`): "rollme.webhookCert: \"REDACTED\"",
		regexp.MustCompile(`caBundle:\s+.*`):           "caBundle: \"REDACTED\"",
	}
	for regex, replaced := range regexes {
		bytes := regex.ReplaceAll([]byte(output), []byte(replaced))
		output = string(bytes)
	}

	goldenFile := "golden/" + testCase.GoldenSubDirectory + "/" + testCase.GoldenFileName + ".golden.yaml"

	if *update {
		err := os.WriteFile(goldenFile, []byte(output), 0644)
		r.NoError(err, "Golden file was not writable")
	}

	expected, err := os.ReadFile(goldenFile)

	// then
	r.NoError(err, "Golden file doesn't exist or was not readable")
	r.Equal(string(expected), output)
}
