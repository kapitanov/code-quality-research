package output

import (
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
)

type Entry struct {
	Project                  string
	Files                    int
	TotalLines, CommentLines int
	CommentRate              float64
}

type Writer interface {
	Write(e Entry) error
}

type WriterCloser interface {
	Writer

	Close()
}

func NewStreamWriter(w io.Writer) Writer {
	return &streamWriter{w}
}

type streamWriter struct {
	w io.Writer
}

func (w *streamWriter) Write(e Entry) error {
	// Project<tab> Files<tab> TotalLines<tab> CommentLines<tab> CommentRate<lf>
	_, err := fmt.Fprintf(w.w, "%s\t%d\t%d\t%d\t%0.2f\n", e.Project, e.Files, e.TotalLines, e.CommentLines, e.CommentRate)
	return err
}

func NopCloser(w Writer) WriterCloser {
	return &nopCloser{w}
}

type nopCloser struct {
	w Writer
}

func (w *nopCloser) Write(e Entry) error {
	return w.w.Write(e)
}

func (w *nopCloser) Close() {}

func NewFileWriter(path string) (WriterCloser, error) {
	dir, _ := filepath.Split(path)
	err := os.MkdirAll(dir, 0755)
	if err != nil {
		return nil, err
	}

	f, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0755)
	if err != nil {
		return nil, err
	}

	w := &fileWriter{
		f: f,
		w: NewStreamWriter(f),
	}
	return w, nil
}

type fileWriter struct {
	w Writer
	f *os.File
}

func (w *fileWriter) Write(e Entry) error {
	return w.w.Write(e)
}

func (w *fileWriter) Close() {
	err := w.f.Close()
	if err != nil {
		log.Fatalf("unable to close file %q: %v", w.f.Name(), err)
	}
}
