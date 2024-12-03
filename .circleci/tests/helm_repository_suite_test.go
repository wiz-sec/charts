package tests

import (
	"flag"
	"fmt"
	"os"
	"path"
	"regexp"
	"testing"

	helmclient "github.com/mittwald/go-helm-client"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"helm.sh/helm/v3/pkg/chart/loader"
	"helm.sh/helm/v3/pkg/chartutil"
)

const (
	thisRepo = "https://wiz-sec.github.io/charts"
)

const (
	chartsRootDir = "../../."
)

var update = flag.Bool("update-golden", false, "update golden test output files")

type helmRepoSuite struct {
	suite.Suite
	localizedChartsDir string
}

func TestHelmRepository(t *testing.T) {
	suite.Run(t, new(helmRepoSuite))
}

func (s *helmRepoSuite) SetupSuite() {
	tmpDir, err := os.MkdirTemp("", "helmRepoSuite-")
	s.NoError(err)
	s.localizedChartsDir = tmpDir

	subDirs, err := os.ReadDir(chartsRootDir)
	s.NoError(err)
	for _, d := range subDirs {
		if !d.IsDir() {
			continue
		}
		chartDir := path.Join(chartsRootDir, d.Name())
		_, err := os.Stat(path.Join(chartDir, chartutil.ChartfileName))
		if os.IsNotExist(err) {
			continue
		}
		s.makeLocalizedChart(chartDir, s.localizedChartsDir)
	}
}

func (s *helmRepoSuite) TearDownSuite() {
	_ = os.RemoveAll(s.localizedChartsDir)
}

func (s *helmRepoSuite) makeLocalizedChart(srcChartDir string, dstDir string) {
	chart, err := loader.Load(srcChartDir)
	s.NoError(err)

	s.T().Logf("Making localized version of %s in %s", chart.Name(), dstDir)
	for _, d := range chart.Metadata.Dependencies {
		if d.Repository == thisRepo {
			d.Repository = fmt.Sprintf("file://../%s", d.Name)
		}
	}
	s.NoError(chartutil.SaveDir(chart, dstDir))
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
	regexes := []*regexp.Regexp{
		regexp.MustCompile(`(helm.sh/chart:\s+).*`),
		regexp.MustCompile(`(tls.crt:\s+).*`),
		regexp.MustCompile(`(tls.key:\s+).*`),
		regexp.MustCompile(`(rollme:\s+).*`),
		regexp.MustCompile(`(rollme.webhookCert:\s+).*`),
		regexp.MustCompile(`(caBundle:\s+).*`),
		regexp.MustCompile(`(- name: WIZ_CHART_VERSION\n\s+value: )".*"`),
	}

	for _, regex := range regexes {
		replaced := regex.ReplaceAllStringFunc(string(output), func(match string) string {
			return regex.ReplaceAllString(match, "${1}\"GOLDEN_STATIC_VALUE\"")
		})
		output = []byte(replaced)
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
