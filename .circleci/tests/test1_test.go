package tests

import (
	"os"
	"path"
	"path/filepath"
	"strings"
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

func (s *ss) TestChartTemplateWithDefaultValues() {
	for _, chartName := range []string{
		"wiz-sensor",
		"wiz-admission-controller",
		"wiz-kubernetes-connector",
		"wiz-kubernetes-integration",
	} {
		s.Run(chartName, func() {
			chartDir := s.getChartDirectory(chartName)
			chartDirFullPath, err := filepath.Abs(chartDir)
			s.NoError(err)
			defaultValuesFilePath := path.Join(chartDir, "values.yaml")

			TestContainerGoldenTestDefaults(s.T(), &TemplateGoldenTest{
				ChartPath:          chartDirFullPath,
				Release:            "release-test",
				Namespace:          "release-helm-namespace",
				GoldenFileName:     chartName,
				ValuesFile:         defaultValuesFilePath,
				GoldenSubDirectory: "default",
			})
		})
	}
}

func (s *ss) TestChartTemplatesWithCustomValues() {
	testFiles, err := os.ReadDir("testfiles")
	s.NoError(err)

	for _, testFile := range testFiles {
		s.Run(testFile.Name(), func() {
			chartName := strings.Split(strings.Split(testFile.Name(), ".")[0], "_")[0]
			chartDir := s.getChartDirectory(chartName)

			chartDirFullPath, err := filepath.Abs(chartDir)
			s.NoError(err)

			valuesFilePath := path.Join("testfiles", testFile.Name())
			TestContainerGoldenTestDefaults(s.T(), &TemplateGoldenTest{
				ChartPath:          chartDirFullPath,
				Release:            "release-test",
				Namespace:          "release-helm-namespace",
				GoldenFileName:     chartName,
				ValuesFile:         valuesFilePath,
				GoldenSubDirectory: "custom",
			})
		})
	}
}

func (s *ss) getChartDirectory(chartName string) string {
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
