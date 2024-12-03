package tests

import (
	"os"
	"path"
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

		valueFiles, err := os.ReadDir(path.Join(testFilesDirectory, chartName))
		s.NoError(err)

		for _, valueFileEnt := range valueFiles {
			valueFileName := valueFileEnt.Name()
			s.Run(path.Join(chartName, valueFileName), func() {
				valuesFilePath := path.Join(testFilesDirectory, chartName, valueFileName)
				runGoldenHelmTest(s.T(), &goldenHelmTest{
					ChartPath: path.Join(s.localizedChartsDir, chartName),
					Release:   "release-test",
					Namespace: "release-helm-namespace",
					// remove .yaml from the test file name
					GoldenFileName:     strings.TrimSuffix(valueFileName, ".yaml"),
					ValueFiles:         []string{valuesFilePath},
					GoldenSubDirectory: path.Join(chartName),
				})
			})
		}
	}
}
