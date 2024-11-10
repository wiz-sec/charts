package tests

import (
	"os"
	"path"
	"path/filepath"
	"strings"
)

func (s *helmRepoSuite) TestChartWithCustomValues() {
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
