package tests

import (
	"maps"
	"os"
	"path"
	"path/filepath"
	"slices"
	"strings"
	"testing"

	"github.com/stretchr/testify/suite"
	"helm.sh/helm/v3/pkg/chartutil"
)

const (
	chartsRootDir = "../../."
)

type helmRepoSuite struct {
	suite.Suite
}

func TestHelmRepository(t *testing.T) {
	suite.Run(t, new(helmRepoSuite))
}

func (s *helmRepoSuite) TestChartTemplateWithDefaultValues() {
	charts := s.getChartsInDirectory(chartsRootDir)

	for _, chartName := range charts {
		s.Run(chartName, func() {
			chartDir := s.getChartDirectory(chartName)
			chartDirFullPath, err := filepath.Abs(chartDir)
			s.NoError(err)
			defaultValuesFilePath := path.Join(chartDir, "values.yaml")

			runGoldenHelmTest(s.T(), &goldenHelmTest{
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

func (s *helmRepoSuite) TestChartTemplatesWithCustomValues() {
	testFiles, err := os.ReadDir("testfiles")
	s.NoError(err)

	for _, testFile := range testFiles {
		testFileName := testFile.Name()

		s.Run(testFileName, func() {
			chartName := strings.Split(strings.Split(testFileName, ".")[0], "_")[0]
			chartDir := s.getChartDirectory(chartName)

			chartDirFullPath, err := filepath.Abs(chartDir)
			s.NoError(err)

			valuesFilePath := path.Join("testfiles", testFileName)
			runGoldenHelmTest(s.T(), &goldenHelmTest{
				ChartPath: chartDirFullPath,
				Release:   "release-test",
				Namespace: "release-helm-namespace",
				// remove .yaml from the test file name
				GoldenFileName:     strings.TrimSuffix(testFileName, ".yaml"),
				ValuesFile:         valuesFilePath,
				GoldenSubDirectory: "custom",
			})
		})
	}
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
