package openlistlib

import (
	"errors"

	"github.com/OpenListTeam/OpenList/v4/internal/model"
	"github.com/OpenListTeam/OpenList/v4/internal/op"
	"github.com/OpenListTeam/OpenList/v4/pkg/utils"
	"github.com/OpenListTeam/OpenList/v4/pkg/utils/random"
	"gorm.io/gorm"
)

// ensureAdmin creates the admin user on a fresh data dir. Since v4.2.7 the
// core leaves that to the web setup wizard, but the native client needs an
// admin to mint its local token. The random password is never logged; users
// set their own through SetAdminPassword.
func ensureAdmin() error {
	_, err := op.GetAdmin()
	if err == nil || !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}
	admin := &model.User{
		Username: "admin",
		Role:     model.ADMIN,
		BasePath: "/",
		Authn:    "[]",
		// Same permission set the core grants its initial admin.
		Permission: 0x71FF,
	}
	admin.SetPassword(random.String(32))
	if err := op.CreateUser(admin); err != nil {
		return err
	}
	utils.Log.Info("created the admin user for the native client")
	return nil
}
