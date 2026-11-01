package openlistlib

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"math/big"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/OpenListTeam/OpenList/v4/internal/conf"
)

func TestApplyExposure(t *testing.T) {
	cases := []struct {
		mode, addr, ftp, wantAddr, wantFTP string
	}{
		{ModeLocal, "0.0.0.0", ":5221", "127.0.0.1", "127.0.0.1:5221"},
		{ModeLocal, "192.168.1.2", "0.0.0.0:5221", "127.0.0.1", "127.0.0.1:5221"},
		{ModeLan, "127.0.0.1", "127.0.0.1:5221", "0.0.0.0", ":5221"},
		{ModeLan, "192.168.1.2", ":5221", "192.168.1.2", ":5221"},
		{ModePublic, "", "", "0.0.0.0", ""},
	}
	for _, tc := range cases {
		c := &conf.Config{}
		c.Scheme.Address = tc.addr
		c.FTP.Listen = tc.ftp
		applyExposure(c, tc.mode)
		if c.Scheme.Address != tc.wantAddr || c.FTP.Listen != tc.wantFTP {
			t.Errorf("%s(%q,%q) = %q,%q; want %q,%q", tc.mode, tc.addr, tc.ftp,
				c.Scheme.Address, c.FTP.Listen, tc.wantAddr, tc.wantFTP)
		}
	}
}

func TestNormalizeMode(t *testing.T) {
	for in, want := range map[string]string{"": ModeLocal, "bogus": ModeLocal, "lan": ModeLan, "public": ModePublic} {
		if got := normalizeMode(in); got != want {
			t.Errorf("normalizeMode(%q) = %q; want %q", in, got, want)
		}
	}
}

func TestLocalModeHasNoChecks(t *testing.T) {
	r := buildSecurityReport(&conf.Config{}, ModeLocal)
	if r.Blocked || len(r.Checks) != 0 {
		t.Fatalf("local mode should not run checks: %+v", r)
	}
}

func writeCert(t *testing.T, dir string, notAfter time.Time) (string, string) {
	t.Helper()
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	tpl := &x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject:      pkix.Name{CommonName: "openlist.test"},
		NotBefore:    notAfter.Add(-48 * time.Hour),
		NotAfter:     notAfter,
	}
	der, err := x509.CreateCertificate(rand.Reader, tpl, tpl, &key.PublicKey, key)
	if err != nil {
		t.Fatal(err)
	}
	keyDer, err := x509.MarshalECPrivateKey(key)
	if err != nil {
		t.Fatal(err)
	}
	certPath := filepath.Join(dir, fmt.Sprintf("cert-%d.pem", notAfter.Unix()))
	keyPath := filepath.Join(dir, fmt.Sprintf("key-%d.pem", notAfter.Unix()))
	_ = os.WriteFile(certPath, pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der}), 0o600)
	_ = os.WriteFile(keyPath, pem.EncodeToMemory(&pem.Block{Type: "EC PRIVATE KEY", Bytes: keyDer}), 0o600)
	return certPath, keyPath
}

func TestCheckCert(t *testing.T) {
	dir := t.TempDir()
	c := &conf.Config{}
	c.Scheme.HttpsPort = -1
	if checkCert(c) == nil {
		t.Error("disabled HTTPS must fail")
	}
	c.Scheme.HttpsPort = 5245
	if checkCert(c) == nil {
		t.Error("missing cert must fail")
	}
	c.Scheme.CertFile, c.Scheme.KeyFile = writeCert(t, dir, time.Now().Add(24*time.Hour))
	if err := checkCert(c); err != nil {
		t.Errorf("valid cert failed: %v", err)
	}
	c.Scheme.CertFile, c.Scheme.KeyFile = writeCert(t, dir, time.Now().Add(-time.Hour))
	if checkCert(c) == nil {
		t.Error("expired cert must fail")
	}
}

type nopEvent struct{}

func (nopEvent) OnStartError(string, string) {}
func (nopEvent) OnShutdown(string)           {}
func (nopEvent) OnProcessExit(int)           {}

type nopLog struct{}

func (nopLog) OnLog(int16, int64, string) {}

func freePort(t *testing.T) int {
	t.Helper()
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()
	return l.Addr().(*net.TCPAddr).Port
}

// TestCoreLifecycle boots the real core in a temp data dir and verifies the
// default local mode, the public-mode guard, status reporting and shutdown.
func TestCoreLifecycle(t *testing.T) {
	if testing.Short() {
		t.Skip("integration test")
	}
	SetConfigData(t.TempDir())
	if err := Init(nopEvent{}, nopLog{}); err != nil {
		t.Fatal(err)
	}
	port := freePort(t)
	conf.Conf.Scheme.HttpPort = port
	conf.Conf.Scheme.HttpsPort = -1

	if err := StartWithOptions(`{"mode":"public"}`); err == nil {
		t.Fatal("public mode without TLS must be refused")
	}
	if err := StartWithOptions(`{"mode":"local"}`); err != nil {
		t.Fatal(err)
	}
	defer Shutdown(5000)
	if conf.Conf.Scheme.Address != "127.0.0.1" {
		t.Fatalf("local mode bound to %q", conf.Conf.Scheme.Address)
	}

	url := fmt.Sprintf("http://127.0.0.1:%d/ping", port)
	var resp *http.Response
	var err error
	for i := 0; i < 50; i++ {
		if resp, err = http.Get(url); err == nil {
			break
		}
		time.Sleep(100 * time.Millisecond)
	}
	if err != nil {
		t.Fatalf("ping failed: %v", err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("ping status %d", resp.StatusCode)
	}

	var st runtimeStatus
	if err := json.Unmarshal([]byte(RuntimeStatus()), &st); err != nil || !st.Running || !st.Endpoints["http"] {
		t.Fatalf("unexpected status %+v (%v)", st, err)
	}
	if tok, err := AdminToken(); err != nil || tok == "" {
		t.Fatalf("admin token: %q %v", tok, err)
	}
	var rep securityReport
	if err := json.Unmarshal([]byte(SecurityReport(ModePublic)), &rep); err != nil || !rep.Blocked {
		t.Fatalf("public report should be blocked: %+v %v", rep, err)
	}
	if conf.Conf.Scheme.Address != "127.0.0.1" {
		t.Fatal("SecurityReport must not mutate the live config")
	}
}
