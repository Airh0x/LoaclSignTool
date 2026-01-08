package server

import (
	"fmt"
	"github.com/pkg/errors"
	"github.com/rs/zerolog/log"
	"net"
	"strings"
)

// BindPort attempts to bind to the specified port.
// If the port is already in use, it automatically tries to bind to a random available port.
// Returns the listener, the actual port used, and any error encountered.
func BindPort(host string, port uint64) (net.Listener, uint64, error) {
	address := fmt.Sprintf("%s:%d", host, port)
	if host == "" {
		address = fmt.Sprintf(":%d", port)
	}

	listener, err := net.Listen("tcp", address)
	if err != nil {
		errStr := err.Error()
		// Check for various "port in use" error messages (macOS, Linux, Windows)
		if isPortInUseError(errStr) {
			log.Warn().Uint64("port", port).Str("error", errStr).Msg("port already in use, trying random port")
			// Use port 0 to get a random available port
			randomAddress := fmt.Sprintf("%s:0", host)
			if host == "" {
				randomAddress = ":0"
			}
			listener, err = net.Listen("tcp", randomAddress)
			if err != nil {
				return nil, 0, errors.WithMessage(err, "failed to bind to random port")
			}
			actualPort := uint64(listener.Addr().(*net.TCPAddr).Port)
			log.Info().Uint64("original_port", port).Uint64("actual_port", actualPort).Msg("using random port")
			return listener, actualPort, nil
		}
		return nil, 0, errors.WithMessage(err, "failed to start server")
	}

	return listener, port, nil
}

// isPortInUseError checks if the error indicates that the port is already in use
func isPortInUseError(errStr string) bool {
	return strings.Contains(errStr, "address already in use") ||
		strings.Contains(errStr, "bind: address already in use") ||
		strings.Contains(errStr, "bind: Address already in use") ||
		strings.Contains(errStr, "Only one usage of each socket address")
}
