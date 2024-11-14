package tests

import (
	"flag"
	"os"
	"path"
	"regexp"
	"testing"

	"github.com/mittwald/go-helm-client"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"helm.sh/helm/v3/pkg/chartutil"
)

const (
	chartsRootDir = "../../."
)

var update = flag.Bool("update-golden", false, "update golden test output files")

type helmRepoSuite struct {
	suite.Suite
}

func TestHelmRepository(t *testing.T) {
	suite.Run(t, new(helmRepoSuite))
}

type goldenHelmTest struct {
	ChartPath          string
	Release            string
	Namespace          string
	GoldenFileName     string
	ValueFiles         []string
	GoldenSubDirectory string
}

// runGoldenHelmTest Code is based on the article here:  https://medium.com/@zelldon91/advanced-test-practices-for-helm-charts-587caeeb4cb
// This function allows to test rendering of helm charts with values and rendering specific templates.
func runGoldenHelmTest(t *testing.T, testCase *goldenHelmTest) {
	r := require.New(t)

	values := ""
	for _, valuesFile := range testCase.ValueFiles {
		valuesFileContent, err := os.ReadFile(valuesFile)
		r.NoError(err, "Values file was not readable")
		values += string(valuesFileContent)
		values += "\n"
	}

	chartSpec := helmclient.ChartSpec{
		ReleaseName:      testCase.Release,
		Namespace:        testCase.Namespace,
		ChartName:        testCase.ChartPath,
		DependencyUpdate: true,
		ValuesYaml:       values,
	}

	client, err := helmclient.New(&helmclient.Options{
		Debug:   true,
		Linting: true,
	})
	r.NoError(err, "Failed to create helm client")

	// run the helm template command
	output, err := client.TemplateChart(&chartSpec, nil)
	r.NoError(err, "Failed to render helm chart")

	// Replacing expressions which change on every run so they won't be compared in the golden file
	regexes := map[*regexp.Regexp]string{
		regexp.MustCompile(`helm.sh/chart:\s+.*`):      "helm.sh/chart: \"GOLDEN_STATIC_VALUE\"",
		regexp.MustCompile(`tls.crt:\s+.*`):            "tls.crt: \"GOLDEN_STATIC_VALUE\"",
		regexp.MustCompile(`tls.key:\s+.*`):            "tls.key: \"GOLDEN_STATIC_VALUE\"",
		regexp.MustCompile(`rollme:\s+.*`):             "rollme: \"GOLDEN_STATIC_VALUE\"",
		regexp.MustCompile(`rollme.webhookCert:\s+.*`): "rollme.webhookCert: \"GOLDEN_STATIC_VALUE\"",
		regexp.MustCompile(`caBundle:\s+.*`):           "caBundle: \"GOLDEN_STATIC_VALUE\"",
	}
	for regex, replaced := range regexes {
		output = regex.ReplaceAll(output, []byte(replaced))
	}

	goldenFile := "golden/" + testCase.GoldenSubDirectory + "/" + testCase.GoldenFileName + ".golden.yaml"

	if *update {
		if _, err := os.Stat(path.Dir(goldenFile)); os.IsNotExist(err) {
			err := os.MkdirAll(path.Dir(goldenFile), 0755)
			r.NoError(err, "Golden file directory was not writable")
		}

		err := os.WriteFile(goldenFile, output, 0644)
		r.NoError(err, "Golden file was not writable")
	}

	expected, err := os.ReadFile(goldenFile)

	r.NoError(err, "Golden file doesn't exist or was not readable")
	r.Equal(string(expected), string(output), "Rendered output does not match golden file. Please run tests with -update-golden flag to update the golden files.")
}

func (s *helmRepoSuite) getChartDirectory(chartName string) string {
	chartDir := path.Join(chartsRootDir, chartName)
	if _, err := os.Stat(path.Join(chartDir, "Chart.yaml")); os.IsNotExist(err) {
		s.Fail("Chart.yaml file not found in %s", chartDir)
	}

	isChartDir, err := chartutil.IsChartDir(chartDir)
	s.NoError(err)
	s.True(isChartDir)

	return chartDir
}
