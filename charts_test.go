package helm

import (
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
	"helm.sh/helm/pkg/lint/support"
	"helm.sh/helm/v3/pkg/chartutil"
	"helm.sh/helm/v3/pkg/lint"
)

const (
	chartsRootDir = "."
)

var defaultValuesKnownIssues = []string{
	"Missing required value: git.path is required",
	"Missing required value: storageService is required",
	"icon is recommended",
}

var generatedValuesKnownIssues = []string{
	"icon is recommended",
}

func isLinterIssue(supportMessage support.Message, knownIssues []string) bool {
	if supportMessage.Severity < support.InfoSev {
		return false
	}

	for _, knownIssue := range knownIssues {
		if strings.Contains(supportMessage.Err.Error(), knownIssue) {
			return false
		}
	}

	return true
}

func TestChartsWithDefaultValues(t *testing.T) {
	files, err := ioutil.ReadDir(chartsRootDir)
	require.NoError(t, err)

	for _, fileInfo := range files {
		if !fileInfo.IsDir() {
			continue
		}
		chartDir := path.Join(chartsRootDir, fileInfo.Name())
		chartFilePath := path.Join(chartDir, "Chart.yaml")
		if _, err := os.Stat(chartFilePath); os.IsNotExist(err) {
			continue
		}

		_, err := chartutil.IsChartDir(chartDir)
		require.NoError(t, err)

		chartDirFullPath, err := filepath.Abs(chartDir)
		require.NoError(t, err)
		t.Run(chartDir, func(t *testing.T) {
			fmt.Println(chartDirFullPath)
			chart, err := chartutil.LoadChartfile(chartFilePath)
			require.NoError(t, err)
			require.NoError(t, chart.Validate())
			defaultValuesFilePath := path.Join(chartDir, "values.yaml")
			values, err := chartutil.ReadValuesFile(defaultValuesFilePath)
			require.NoError(t, err)
			linter := lint.All(chartDir, values.AsMap(), "", true)
			fmt.Println(linter.Messages)

			for _, supportMessage := range linter.Messages {
				require.False(t, isLinterIssue(support.Message(supportMessage), defaultValuesKnownIssues), supportMessage.Error())
			}
		})
	}
}

func TestChartsWithGeneratedValues(t *testing.T) {
	files, err := ioutil.ReadDir(chartsRootDir)
	require.NoError(t, err)

	for _, fileInfo := range files {
		if !fileInfo.IsDir() {
			continue
		}
		chartDir := path.Join(chartsRootDir, fileInfo.Name())
		chartName := fileInfo.Name()
		chartFilePath := path.Join(chartDir, "Chart.yaml")
		if _, err := os.Stat(chartFilePath); os.IsNotExist(err) {
			continue
		}

		_, err := chartutil.IsChartDir(chartDir)
		require.NoError(t, err)

		chartDirFullPath, err := filepath.Abs(chartDir)
		require.NoError(t, err)
		t.Run(chartDirFullPath, func(t *testing.T) {
			fmt.Println(chartDirFullPath)
			chartFilePath := path.Join(chartDir, "Chart.yaml")
			chart, err := chartutil.LoadChartfile(chartFilePath)
			require.NoError(t, err)
			require.NoError(t, chart.Validate())

			realValuesPath := path.Join("testfiles", chartName+".yaml")
			values, err := chartutil.ReadValuesFile(realValuesPath)

			if len(values.AsMap()) == 0 {
				fmt.Println("No values")
				return
			}

			require.NoError(t, err)
			values, err = values.Table("values")
			require.NoError(t, err)
			linter := lint.All(chartDir, values.AsMap(), "", true)
			for _, supportMessage := range linter.Messages {
				fmt.Println(supportMessage)
			}

			for _, supportMessage := range linter.Messages {
				require.False(t, isLinterIssue(support.Message(supportMessage), generatedValuesKnownIssues), supportMessage.Error())
			}
		})
	}
}
