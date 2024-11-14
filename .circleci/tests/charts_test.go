package tests

import (
	"os"
	"path"
	"path/filepath"
	"strings"
)

func (s *helmRepoSuite) TestCharts() {
	testFilesDirectory := "testfiles"
	testChartsDirectory, err := os.ReadDir(testFilesDirectory)
	s.NoError(err)

	for _, testChart := range testChartsDirectory {
		if !testChart.IsDir() {
			continue
		}

		chartName := testChart.Name()

		chartDirectory, err := os.ReadDir(path.Join(testFilesDirectory, chartName))
		s.NoError(err)

		for _, testFile := range chartDirectory {
			testFileName := testFile.Name()
			s.Run(path.Join(chartName, testFileName), func() {
				chartDir := s.getChartDirectory(chartName)

				chartDirFullPath, err := filepath.Abs(chartDir)
				s.NoError(err)

				valuesFilePath := path.Join(testFilesDirectory, chartName, testFileName)
				runGoldenHelmTest(s.T(), &goldenHelmTest{
					ChartPath: chartDirFullPath,
					Release:   "release-test",
					Namespace: "release-helm-namespace",
					// remove .yaml from the test file name
					GoldenFileName:     strings.TrimSuffix(testFileName, ".yaml"),
					ValueFiles:         []string{valuesFilePath},
					GoldenSubDirectory: path.Join(chartName),
				})
			})
		}
	}
}
