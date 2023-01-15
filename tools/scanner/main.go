package main

import (
	"log"
	"os"

	"github.com/kapitanov/code-quality-research/scanner/internal/output"
	"github.com/kapitanov/code-quality-research/scanner/internal/parser"
	"github.com/spf13/cobra"
)

func main() {
	cmd := cobra.Command{
		Use: "scanner",
	}

	inputDir := cmd.Flags().StringP("input", "i", "", "path to input directory")
	outputPath := cmd.Flags().StringP("output", "o", "", "path to output csv file")
	err := cmd.MarkFlagRequired("input")
	if err != nil {
		log.Fatal(err)
	}

	cmd.RunE = func(cmd *cobra.Command, args []string) error {
		w, err := createOutputWriter(*outputPath)
		if err != nil {
			return err
		}
		defer w.Close()

		stats, err := parser.Parse(*inputDir)
		if err != nil {
			return err
		}

		log.Printf("stats: %+v", stats)

		return w.Write(output.Entry{
			Project:      stats.Project,
			Files:        stats.Files,
			TotalLines:   stats.TotalLines,
			CommentLines: stats.CommentLines,
			CommentRate:  stats.CommentRate,
		})
	}

	err = cmd.Execute()
	if err != nil {
		log.Fatal(err)
	}
}

func createOutputWriter(path string) (output.WriterCloser, error) {
	if path == "" {
		return output.NopCloser(output.NewStreamWriter(os.Stdout)), nil
	}

	return output.NewFileWriter(path)
}
