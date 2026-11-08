package openlistlib

import (
	"github.com/OpenListTeam/OpenList/v4/cmd"
	"github.com/OpenListTeam/OpenList/v4/cmd/flags"
	"github.com/OpenListTeam/OpenList/v4/internal/op"
	"github.com/OpenListTeam/OpenList/v4/pkg/utils"
)

func SetConfigData(path string) {
	flags.DataDir = path
}

func SetConfigLogStd(b bool) {
	flags.LogStd = b
}

func SetConfigDebug(b bool) {
	flags.Debug = b
}

func SetConfigNoPrefix(b bool) {
	flags.NoPrefix = b
}

func SetAdminPassword(pwd string) {
	admin, err := op.GetAdmin()
	if err != nil {
		utils.Log.Errorf("failed get admin user: %+v", err)
		return
	}
	admin.SetPassword(pwd)
	if err := op.UpdateUser(admin); err != nil {
		utils.Log.Errorf("failed update admin user: %+v", err)
		return
	}
	// Never log the password: logs are shown in the app and can be exported.
	utils.Log.Infof("admin password has been updated for user %s", admin.Username)
	cmd.DelAdminCacheOnline()
}
