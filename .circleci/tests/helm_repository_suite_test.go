package tests

import (
	"flag"
	"maps"
	"os"
	"path"
	"regexp"
	"slices"
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/gruntwork-io/terratest/modules/k8s"
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

func (s *helmRepoSuite) SetupSuite() {
	// Run the helm repo add command
	// helm repo add wiz-sec https://wiz-sec.github.io/charts
	if _, err := helm.RunHelmCommandAndGetOutputE(s.T(), &helm.Options{}, "repo", "add", "wiz-chart-test", "https://wiz-sec.github.io/charts"); err != nil {
		s.Failf("Failed to add helm repository", "error is %s", err)
	}

	//// Run the helm repo update command
	if _, err := helm.RunHelmCommandAndGetOutputE(s.T(), &helm.Options{}, "repo", "update"); err != nil {
		s.Failf("Failed to update helm repository", "error is %s", err)
	}
}

type goldenHelmTest struct {
	ChartPath          string
	Release            string
	Namespace          string
	GoldenFileName     string
	Templates          []string
	SetValues          map[string]string
	ValueFiles         []string
	GoldenSubDirectory string
}

// runGoldenHelmTest Code is based on the article here:  https://medium.com/@zelldon91/advanced-test-practices-for-helm-charts-587caeeb4cb
// This function allows to test rendering of helm charts with values and rendering specific templates.
func runGoldenHelmTest(t *testing.T, testCase *goldenHelmTest) {
	r := require.New(t)

	options := &helm.Options{
		KubectlOptions:    k8s.NewKubectlOptions("", "", testCase.Namespace),
		SetValues:         testCase.SetValues,
		ValuesFiles:       testCase.ValueFiles,
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
	r.Equal(string(expected), output, "Rendered output does not match golden file. Please run tests with -update-golden flag to update the golden files.")
}

func (s *helmRepoSuite) getChartDirectory(chartName string) string {
	chartDir := path.Join(chartsRootDir, chartName)
	if _, err := os.Stat(path.Join(chartDir, "Chart.yaml")); os.IsNotExist(err) {
		//	fail the test
		s.Fail("Chart.yaml file not found in %s", chartDir)
	}

	isChartDir, err := chartutil.IsChartDir(chartDir)
	s.NoError(err)
	s.True(isChartDir)

	return chartDir
}

func (s *helmRepoSuite) getChartsInDirectory(dir string) []string {
	// There's no need to add directories to this list, but this is for extra care, to ensure we don't miss these charts
	charts := map[string]struct{}{
		"wiz-broker":                 {},
		"wiz-sensor":                 {},
		"wiz-admission-controller":   {},
		"wiz-kubernetes-connector":   {},
		"wiz-kubernetes-integration": {},
	}

	files, err := os.ReadDir(dir)
	s.NoError(err)

	for _, fileInfo := range files {
		if !fileInfo.IsDir() {
			continue
		}

		chartName := fileInfo.Name()
		chartFilePath := path.Join(path.Join(chartsRootDir, chartName), "Chart.yaml")
		if _, err := os.Stat(chartFilePath); os.IsNotExist(err) {
			continue
		}

		charts[chartName] = struct{}{}
	}

	return slices.Collect(maps.Keys(charts))
}
