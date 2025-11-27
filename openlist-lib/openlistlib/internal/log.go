package internal

import log "github.com/sirupsen/logrus"

type MyFormatter struct {
	log.Formatter
	OnLog        func(entry *log.Entry)
	FilterDebug  bool // Filter out debug and trace logs when true
}

// Filter logs based on debug mode
// In non-debug mode, only pass Info and above (Info, Warn, Error, Fatal, Panic)
func (f *MyFormatter) Format(entry *log.Entry) ([]byte, error) {
	// Skip Debug and Trace level logs when not in debug mode
	if f.FilterDebug && (entry.Level == log.DebugLevel || entry.Level == log.TraceLevel) {
		return nil, nil
	}
	f.OnLog(entry)
	return nil, nil
}
