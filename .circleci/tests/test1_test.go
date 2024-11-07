package tests

import (
	"os"
	"path"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/suite"
	"helm.sh/helm/v3/pkg/chartutil"
)

type ss struct {
	suite.Suite
}

func TestSs(t *testing.T) {
	suite.Run(t, new(ss))
}

var supportedHelmCharts = []string{
	"wiz-sensor",
	"wiz-admission-controller",
	"wiz-kubernetes-connector",
	"wiz-kubernetes-integration",
}

func (s *ss) TestChartTemplateWithDefaultValues() {
	for _, chartName := range supportedHelmCharts {
		s.Run(chartName, func() {
			chartDir := path.Join(chartsRootDir, chartName)
			chartFilePath := path.Join(chartDir, "Chart.yaml")
			if _, err := os.Stat(chartFilePath); os.IsNotExist(err) {
				//	fail the test
				s.Fail("Chart.yaml file not found in %s", chartDir)
			}

			_, err := chartutil.IsChartDir(chartDir)
			s.NoError(err)

			chartDirFullPath, err := filepath.Abs(chartDir)
			s.NoError(err)
			defaultValuesFilePath := path.Join(chartDir, "values.yaml")

			TestContainerGoldenTestDefaults(s.T(), &TemplateGoldenTest{
				ChartPath:      chartDirFullPath,
				Release:        "release-test",
				Namespace:      "release-helm-namespace",
				GoldenFileName: chartName,
				ValuesFile:     defaultValuesFilePath,
			})
		})
	}
}
