package util

import (
	"context"
	"fmt"
	"github.com/pkg/errors"
	"github.com/rs/zerolog/log"
	"net/http"
	"net/url"
	"os"
	"path"
	"path/filepath"
	"strings"
	"time"
)

func SafeJoinFilePaths(basePath string, unsafePath ...string) string {
	return filepath.Join(basePath, filepath.Clean("/"+filepath.Join(unsafePath...)))
}

func JoinUrlsFatal(fullBaseUrl string, relativeUrl ...string) string {
	result, err := JoinUrls(fullBaseUrl, relativeUrl...)
	if err != nil {
		log.Fatal().Err(err).Send()
	}
	return result
}

func JoinUrls(fullBaseUrl string, relativeUrl ...string) (string, error) {
	parsedBase, err := url.Parse(fullBaseUrl)
	if err != nil {
		return "", err
	}
	return JoinUrlsParsed(parsedBase, relativeUrl...)
}

func JoinUrlsParsed(parsedBase *url.URL, relativeUrl ...string) (string, error) {
	parsedRelative, err := url.Parse(path.Join(relativeUrl...))
	if err != nil {
		return "", err
	}
	return parsedBase.ResolveReference(parsedRelative).String(), nil
}

func Check2xxCode(code int) error {
	if code < 200 || code > 299 {
		return errors.New(fmt.Sprintf("non-2xx code: %d", code))
	}
	return nil
}

func WaitForServer(url string, timeout time.Duration) error {
	ctx, cancelFunc := context.WithTimeout(context.Background(), timeout)
	defer cancelFunc()
	for {
		select {
		case <-ctx.Done():
			return errors.New("reach server timed out: " + url)
		default:
			if _, err := http.Get(url); err == nil {
				return nil
			}
			time.Sleep(100 * time.Millisecond)
		}
	}
}

// Just like os.ReadDir but ignores hidden files starting with '.' such as macOS '.DS_Store'.
func RemoveHiddenDirs(dirs []os.DirEntry) []os.DirEntry {
	var nonHiddenDirs []os.DirEntry
	for _, dir := range dirs {
		if !strings.HasPrefix(dir.Name(), ".") {
			nonHiddenDirs = append(nonHiddenDirs, dir)
		}
	}
	return nonHiddenDirs
}

// TrimWhitespace removes leading and trailing whitespace characters
// (spaces, tabs, newlines, carriage returns) from a string.
// This is more aggressive than strings.TrimSpace as it handles all common whitespace characters.
func TrimWhitespace(s string) string {
	// Trim leading whitespace
	for len(s) > 0 && (s[0] == ' ' || s[0] == '\t' || s[0] == '\n' || s[0] == '\r') {
		s = s[1:]
	}
	// Trim trailing whitespace
	for len(s) > 0 {
		last := len(s) - 1
		if s[last] == ' ' || s[last] == '\t' || s[last] == '\n' || s[last] == '\r' {
			s = s[:last]
		} else {
			break
		}
	}
	return s
}
