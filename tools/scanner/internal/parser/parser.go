package parser

import (
	"bytes"
	"errors"
	"fmt"
	goparser "go/parser"
	gotoken "go/token"
	"io/fs"
	"log"
	"os"
	"path/filepath"

	"github.com/hhatto/gocloc"
	"golang.org/x/mod/modfile"
)

type Stats struct {
	Project      string
	Files        int
	TotalLines   int
	CommentLines int
	BlankLines   int
	CodeLines    int
	CommentRate  float64
}

func Parse(inputDir string) (Stats, error) {
	// Load go.mod to find out project name
	project, err := parseGoMod(inputDir)
	if err != nil {
		return Stats{}, err
	}
	log.Printf("found project %q in %q", project, inputDir)

	// Collect all .go files
	fileSet, err := newFileSet(inputDir)
	if err != nil {
		return Stats{}, err
	}

	// Read files into memory
	err = fileSet.LoadContent()
	if err != nil {
		return Stats{}, err
	}

	// Trim license headers from (in memory) files
	err = fileSet.TrimLicenses()
	if err != nil {
		return Stats{}, err
	}

	// Compute LOCs of files
	stats := fileSet.Cloc()
	stats.Project = project

	return stats, nil
}

func parseGoMod(inputDir string) (string, error) {
	gomodPath := filepath.Join(inputDir, "go.mod")
	gomodData, err := os.ReadFile(gomodPath)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return filepath.Base(inputDir), nil
		}

		return "", err
	}

	gomod, err := modfile.Parse(gomodPath, gomodData, nil)
	if err != nil {
		return "", err
	}

	project := gomod.Module.Mod.Path
	return project, nil
}

type fileInfo struct {
	Path     string
	Name     string
	Content  []byte
	Code     int32
	Comments int32
	Blanks   int32
	Total    int32
}

func (f *fileInfo) LoadContent() error {
	var err error
	f.Content, err = os.ReadFile(f.Path)
	return err
}

type fileSet struct {
	Files []*fileInfo
}

func (f *fileSet) LoadContent() error {
	for _, file := range f.Files {
		err := file.LoadContent()
		if err != nil {
			return err
		}
	}
	return nil
}

func newFileSet(dir string) (*fileSet, error) {
	dir = filepath.Clean(dir)
	dir, err := filepath.Abs(dir)
	if err != nil {
		return nil, err
	}
	log.Printf("scanning %q", dir)

	var files []*fileInfo
	err = filepath.Walk(dir, func(path string, d fs.FileInfo, err error) error {
		if d.IsDir() {
			return nil
		}

		if filepath.Ext(path) != ".go" {
			return nil
		}

		files = append(files, &fileInfo{
			Path: path,
			Name: path[len(dir)+1:],
		})

		return nil
	})
	if err != nil {
		return nil, err
	}

	if len(files) == 0 {
		return nil, fmt.Errorf("no .go files found in %q", dir)
	}

	log.Printf("scanning %q - got %d files", dir, len(files))
	return &fileSet{Files: files}, nil
}

func (f *fileSet) TrimLicenses() error {
	set := gotoken.NewFileSet()
	var files []*fileInfo
	for _, file := range f.Files {
		// Parse a file, then trim the source
		ast, err := goparser.ParseFile(set, file.Name, file.Content, goparser.ParseComments)
		if err != nil {
			log.Printf("unable to parse %q: %v", file.Name, err)
			continue
		}

		// Normally we trim at "package" keyword
		trimAt := set.Position(ast.Package).Offset

		if ast.Doc != nil {
			// But if there is a package comment, trim at the start of it
			trimAt = set.Position(ast.Doc.Pos()).Offset
		}

		if trimAt > 0 {
			trimmed := file.Content[:trimAt]
			file.Content = file.Content[trimAt:]
			str := string(file.Content)
			_ = str
			_ = trimmed
		}

		files = append(files, file)
	}
	f.Files = files

	return nil
}

func (f *fileSet) Cloc() Stats {
	log.Printf("computing loc for %d files", len(f.Files))

	stats := Stats{}

	language := gocloc.NewDefinedLanguages().Langs["Go"]
	opts := gocloc.NewClocOptions()

	for _, file := range f.Files {
		clocfile := gocloc.AnalyzeReader(file.Name, language, bytes.NewReader(file.Content), opts)

		file.Comments = clocfile.Comments
		file.Code = clocfile.Code
		file.Blanks = clocfile.Blanks
		file.Total = clocfile.Code + clocfile.Comments + clocfile.Blanks

		stats.TotalLines += int(file.Total)
		stats.CodeLines += int(file.Code)
		stats.BlankLines += int(file.Blanks)
		stats.CommentLines += int(file.Comments)

		stats.Files++
	}

	stats.CommentRate = 100.0 * float64(stats.CommentLines) / float64(stats.TotalLines)
	return stats
}
