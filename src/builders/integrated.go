package builders

import (
	"encoding/json"
	"fmt"
	"github.com/pkg/errors"
	"github.com/rs/zerolog/log"
	"sync"
	"sync/atomic"
	"time"
)

type IntegratedData struct {
	Enable        bool   `yaml:"enable"`
	SignFilesDir  string `yaml:"sign_files_dir"`
	Entrypoint    string `yaml:"entrypoint"`
	JobTimeoutMin uint64 `yaml:"job_timeout_mins"`
}

type Integrated struct {
	*IntegratedData
	secrets      atomic.Value
	jobChan      chan bool
	workerChan   chan bool
	jobTimeout   time.Duration
	processJobFn func() error
	initialized  sync.Once
}

func MakeIntegrated(data *IntegratedData) *Integrated {
	integrated := &Integrated{
		IntegratedData: data,
		jobChan:         make(chan bool, 1000),
		workerChan:      make(chan bool, 1),
		jobTimeout:      time.Duration(data.JobTimeoutMin) * time.Minute,
	}
	if integrated.jobTimeout == 0 {
		integrated.jobTimeout = 15 * time.Minute
	}
	if integrated.Entrypoint == "" {
		integrated.Entrypoint = "sign.py"
	}
	integrated.secrets.Store(map[string]string{})
	return integrated
}

// SetProcessJobFn sets the function that will process jobs.
// This is called from main.go to avoid import cycles.
// The function receives the necessary dependencies via dependency injection.
func (i *Integrated) SetProcessJobFn(fn func() error) {
	i.processJobFn = fn
	i.initialized.Do(func() {
		i.startWorker()
	})
}

func (i *Integrated) startWorker() {
	go func() {
		for {
			<-i.jobChan
			i.workerChan <- true
			go func() {
				defer func() {
					<-i.workerChan
				}()
				if i.processJobFn != nil {
					if err := i.processJobFn(); err != nil {
						log.Error().Err(err).Msg("integrated builder job failed")
					}
				} else {
					log.Warn().Msg("integrated builder processJobFn not set")
				}
			}()
		}
	}()
}

func (i *Integrated) Trigger() error {
	// Ensure worker is started
	i.initialized.Do(func() {
		if i.processJobFn != nil {
			i.startWorker()
		}
	})
	select {
	case i.jobChan <- true:
		return nil
	default:
		return errors.New("job queue full")
	}
}

func (i *Integrated) SetSecrets(secrets map[string]string) error {
	i.secrets.Store(secrets)
	return nil
}

// GetStatusUrl returns a data URL containing JSON status information for the integrated builder.
// This includes pending and active job counts.
func (i *Integrated) GetStatusUrl() (string, error) {
	pendingJobs := len(i.jobChan)
	activeJobs := 0
	select {
	case <-i.workerChan:
		activeJobs = 1
		i.workerChan <- true
	default:
	}

	status := map[string]interface{}{
		"pending_jobs": pendingJobs,
		"active_jobs":  activeJobs,
		"type":         "integrated",
	}
	statusJson, _ := json.Marshal(status)
	return fmt.Sprintf("data:application/json,%s", statusJson), nil
}

// GetSecrets returns the current secrets
func (i *Integrated) GetSecrets() map[string]string {
	if secrets := i.secrets.Load(); secrets != nil {
		return secrets.(map[string]string)
	}
	return map[string]string{}
}

// GetSignFilesDir returns the sign files directory
func (i *Integrated) GetSignFilesDir() string {
	return i.SignFilesDir
}

// GetEntrypoint returns the entrypoint script name
func (i *Integrated) GetEntrypoint() string {
	return i.Entrypoint
}

// GetJobTimeout returns the job timeout duration
func (i *Integrated) GetJobTimeout() time.Duration {
	return i.jobTimeout
}
