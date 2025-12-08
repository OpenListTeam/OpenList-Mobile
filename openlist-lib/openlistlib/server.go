package openlistlib

import (
	"errors"
	"time"

	"github.com/OpenListTeam/OpenList/v4/internal/bootstrap"
	"github.com/OpenListTeam/OpenList/v4/internal/db"
	"github.com/OpenListTeam/OpenList/v4/openlistlib/internal"
	"github.com/OpenListTeam/OpenList/v4/pkg/utils"
	log "github.com/sirupsen/logrus"
)

type LogCallback interface {
	OnLog(level int16, time int64, message string)
}

type Event interface {
	OnStartError(t string, err string)
	OnShutdown(t string)
	OnProcessExit(code int)
}

var startFailedHookUuid = ""
var shutdownHookUuid = ""
var logFormatter *internal.MyFormatter

func Init(event Event, cb LogCallback) error {
	if startFailedHookUuid != "" {
		bootstrap.RemoveEndpointStartFailedHook(startFailedHookUuid)
		startFailedHookUuid = ""
	}
	if shutdownHookUuid != "" {
		bootstrap.RemoveEndpointShutdownHook(shutdownHookUuid)
		shutdownHookUuid = ""
	}
	bootstrap.Init()
	startFailedHookUuid = bootstrap.RegisterEndpointStartFailedHook(event.OnStartError)
	shutdownHookUuid = bootstrap.RegisterEndpointShutdownHook(event.OnShutdown)
	logFormatter = &internal.MyFormatter{
		OnLog: func(entry *log.Entry) {
			cb.OnLog(int16(entry.Level), entry.Time.UnixMilli(), entry.Message)
		},
	}
	if utils.Log == nil {
		return errors.New("utils.log is nil")
	} else {
		utils.Log.SetFormatter(logFormatter)
		utils.Log.ExitFunc = event.OnProcessExit
	}
	return nil
}

func IsRunning(t string) bool {
	return bootstrap.IsRunning(t)
}

// Start starts the server
func Start() {
	bootstrap.Start()
}

// Shutdown timeout 毫秒
func Shutdown(timeout int64) (err error) {
	timeoutDuration := time.Duration(timeout) * time.Millisecond
	bootstrap.Shutdown(timeoutDuration)

	// Force database sync before shutdown
	ForceDBSync()
	//bootstrap.Release()
	return nil
}

// ForceDBSync forces SQLite WAL checkpoint to sync data to main database file
func ForceDBSync() error {
	log.Info("Forcing database sync (WAL checkpoint)...")

	// Get the database instance and execute WAL checkpoint
	gormDB := db.GetDb()
	if gormDB != nil {
		sqlDB, err := gormDB.DB()
		if err != nil {
			log.Errorf("Failed to get database connection: %v", err)
			return err
		}

		// Execute WAL checkpoint with TRUNCATE mode to force sync and remove WAL files
		_, err = sqlDB.Exec("PRAGMA wal_checkpoint(TRUNCATE)")
		if err != nil {
			log.Errorf("Failed to execute WAL checkpoint: %v", err)
			return err
		}

		// Also execute synchronous commit to ensure data is written to disk
		_, err = sqlDB.Exec("PRAGMA synchronous=FULL")
		if err != nil {
			log.Warnf("Failed to set synchronous mode: %v", err)
		}

		log.Info("Database sync completed successfully")
	} else {
		log.Warn("Database instance is nil, skipping sync")
	}

	return nil
}
