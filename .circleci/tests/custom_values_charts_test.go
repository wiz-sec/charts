package tests

import (
	"os"
	"path"
	"path/filepath"
	"strings"
)

func (s *helmRepoSuite) TestChartWithCustomValues() {
	testFilesDirectory := path.Join("testfiles", "custom_values")
	testFiles, err := os.ReadDir(testFilesDirectory)
	s.NoError(err)

	for _, testFile := range testFiles {
		testFileName := testFile.Name()

		s.Run(testFileName, func() {
			chartName := strings.Split(strings.Split(testFileName, ".")[0], "_")[0]
			chartDir := s.getChartDirectory(chartName)

			chartDirFullPath, err := filepath.Abs(chartDir)
			s.NoError(err)

			valuesFilePath := path.Join(testFilesDirectory, testFileName)
			runGoldenHelmTest(s.T(), &goldenHelmTest{
				ChartPath: chartDirFullPath,
				Release:   "release-test",
				Namespace: "release-helm-namespace",
				// remove .yaml from the test file name
				GoldenFileName:     strings.TrimSuffix(testFileName, ".yaml"),
				ValueFiles:         []string{valuesFilePath},
				GoldenSubDirectory: "custom",
			})
		})
	}
}
