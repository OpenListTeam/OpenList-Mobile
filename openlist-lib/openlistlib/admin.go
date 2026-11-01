package openlistlib

import (
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"os"
	"path/filepath"

	"github.com/OpenListTeam/OpenList/v4/cmd/flags"
	"github.com/OpenListTeam/OpenList/v4/internal/model"
	"github.com/OpenListTeam/OpenList/v4/internal/op"
	"github.com/OpenListTeam/OpenList/v4/pkg/utils"
	"github.com/OpenListTeam/OpenList/v4/pkg/utils/random"
	"gorm.io/gorm"
)

// generatedPwdMarker records the salt of the password ensureAdmin generated.
// SetPassword always draws a new salt, so a mismatch means the password was
// changed afterwards, from the app or the web UI.
const generatedPwdMarker = "native_admin_generated"

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
	// Without the marker the app only skips its password prompt.
	if err := os.WriteFile(markerPath(), []byte(saltDigest(admin.Salt)), 0o600); err != nil {
		utils.Log.Warnf("failed to record the generated admin password: %v", err)
	}
	return nil
}

// adminPasswordGenerated reports whether the admin still has the password
// ensureAdmin generated. Data dirs created before the marker existed report
// false, so upgrades are never asked to set a password again.
func adminPasswordGenerated() bool {
	want, err := os.ReadFile(markerPath())
	if err != nil {
		return false
	}
	admin, err := op.GetAdmin()
	if err != nil {
		return false
	}
	return subtle.ConstantTimeCompare(want, []byte(saltDigest(admin.Salt))) == 1
}

func markerPath() string {
	return filepath.Join(flags.DataDir, generatedPwdMarker)
}

// saltDigest stores a hash rather than the salt itself.
func saltDigest(salt string) string {
	sum := sha256.Sum256([]byte(salt))
	return hex.EncodeToString(sum[:])
}
