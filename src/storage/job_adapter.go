package storage

import (
	"LocalSignTools/src/builders"
	"io"
)

// JobStorageAdapter adapts the Jobs resolver to the builders.JobStorage interface
type JobStorageAdapter struct{}

func (a *JobStorageAdapter) TakeLastJob(writer io.Writer) error {
	return Jobs.TakeLastJob(writer)
}

func (a *JobStorageAdapter) GetById(id string) (builders.ReturnJob, bool) {
	job, ok := Jobs.GetById(id)
	if !ok {
		return nil, false
	}
	return &ReturnJobAdapter{job: job}, true
}

func (a *JobStorageAdapter) DeleteById(id string) bool {
	return Jobs.DeleteById(id)
}

// ReturnJobAdapter adapts *ReturnJob to builders.ReturnJob interface
type ReturnJobAdapter struct {
	job *ReturnJob
}

func (a *ReturnJobAdapter) GetAppId() string {
	return a.job.AppId
}

// AppStorageAdapter adapts the Apps resolver to the builders.AppStorage interface
type AppStorageAdapter struct{}

func (a *AppStorageAdapter) Get(id string) (builders.App, bool) {
	app, ok := Apps.Get(id)
	if !ok {
		return nil, false
	}
	return &AppAdapter{app: app}, true
}

// AppAdapter adapts storage.App to builders.App interface
type AppAdapter struct {
	app App
}

func (a *AppAdapter) GetFile(name string) (io.ReadCloser, error) {
	// Map string names to FSName constants
	var fsName FSName
	switch name {
	case "unsigned":
		fsName = AppUnsignedFile
	case "signed":
		fsName = AppSignedFile
	default:
		fsName = FSName(name)
	}
	return a.app.GetFile(fsName)
}

func (a *AppAdapter) SetFile(name string, file io.ReadSeeker) error {
	// Map string names to FSName constants
	var fsName FSName
	switch name {
	case "unsigned":
		fsName = AppUnsignedFile
	case "signed":
		fsName = AppSignedFile
	case "bundle_id":
		fsName = AppBundleId
	default:
		fsName = FSName(name)
	}
	return a.app.SetFile(fsName, file)
}

func (a *AppAdapter) SetString(name string, value string) error {
	// Map string names to FSName constants
	var fsName FSName
	switch name {
	case "bundle_id":
		fsName = AppBundleId
	default:
		fsName = FSName(name)
	}
	return a.app.SetString(fsName, value)
}
