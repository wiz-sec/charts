package tests

import (
	"path"
	"path/filepath"
)

func (s *helmRepoSuite) TestChartWithDefaultValues() {
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
				ValueFiles:         []string{defaultValuesFilePath},
				GoldenSubDirectory: "default",
			})
		})
	}
}
