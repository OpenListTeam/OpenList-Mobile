package openlistlib

import (
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"runtime"
	"strings"
	"sync/atomic"
	"time"

	"github.com/OpenListTeam/OpenList/v4/internal/bootstrap"
	"github.com/OpenListTeam/OpenList/v4/internal/conf"
	"github.com/OpenListTeam/OpenList/v4/internal/op"
	"github.com/OpenListTeam/OpenList/v4/server/common"
)

// Network exposure modes. The app-level mode is authoritative for the bind
// address so that the embedded server listens on loopback unless the user
// explicitly opts into LAN or public access.
const (
	ModeLocal  = "local"
	ModeLan    = "lan"
	ModePublic = "public"
)

const (
	checkOK    = "ok"
	checkWarn  = "warn"
	checkBlock = "block"
)

type startOptions struct {
	Mode string `json:"mode"`
}

type securityCheck struct {
	ID     string `json:"id"`
	Level  string `json:"level"`
	Detail string `json:"detail,omitempty"`
}

type securityReport struct {
	Mode    string          `json:"mode"`
	Address string          `json:"address"`
	Blocked bool            `json:"blocked"`
	Checks  []securityCheck `json:"checks"`
}

var startedAt atomic.Int64

func normalizeMode(mode string) string {
	switch mode {
	case ModeLan, ModePublic:
		return mode
	}
	return ModeLocal
}

// StartWithOptions applies the exposure mode to the loaded config and starts
// the server. Init must be called first. Public mode refuses to start while
// any blocking security check fails.
func StartWithOptions(optionsJSON string) error {
	if conf.Conf == nil {
		return errors.New("openlist is not initialized")
	}
	var opts startOptions
	if optionsJSON != "" {
		if err := json.Unmarshal([]byte(optionsJSON), &opts); err != nil {
			return fmt.Errorf("invalid start options: %w", err)
		}
	}
	mode := normalizeMode(opts.Mode)
	applyExposure(conf.Conf, mode)
	if report := buildSecurityReport(conf.Conf, mode); report.Blocked {
		return fmt.Errorf("public access blocked by security checks: %s", blockedIDs(report))
	}
	Start()
	return nil
}

// SecurityReport returns the security checks for the given mode as JSON,
// evaluated against the current config without changing it.
func SecurityReport(mode string) string {
	if conf.Conf == nil {
		return `{"blocked":true,"checks":[{"id":"not_initialized","level":"block"}]}`
	}
	mode = normalizeMode(mode)
	preview := *conf.Conf
	applyExposure(&preview, mode)
	data, _ := json.Marshal(buildSecurityReport(&preview, mode))
	return string(data)
}

func applyExposure(c *conf.Config, mode string) {
	if mode == ModeLocal {
		c.Scheme.Address = "127.0.0.1"
		c.FTP.Listen = rebindHost(c.FTP.Listen, "127.0.0.1")
		c.SFTP.Listen = rebindHost(c.SFTP.Listen, "127.0.0.1")
		return
	}
	// Keep a user-pinned interface address; otherwise listen on all interfaces.
	if isLoopbackOrEmpty(c.Scheme.Address) {
		c.Scheme.Address = "0.0.0.0"
	}
	if host, _, err := net.SplitHostPort(c.FTP.Listen); err == nil && isLoopbackOrEmpty(host) {
		c.FTP.Listen = rebindHost(c.FTP.Listen, "")
	}
	if host, _, err := net.SplitHostPort(c.SFTP.Listen); err == nil && isLoopbackOrEmpty(host) {
		c.SFTP.Listen = rebindHost(c.SFTP.Listen, "")
	}
}

func isLoopbackOrEmpty(host string) bool {
	if host == "" || host == "localhost" {
		return true
	}
	ip := net.ParseIP(host)
	return ip != nil && ip.IsLoopback()
}

func rebindHost(listen, host string) string {
	if listen == "" {
		return listen
	}
	_, port, err := net.SplitHostPort(listen)
	if err != nil {
		return listen
	}
	return net.JoinHostPort(host, port)
}

func buildSecurityReport(c *conf.Config, mode string) securityReport {
	report := securityReport{Mode: mode, Address: c.Scheme.Address, Checks: []securityCheck{}}
	if mode == ModeLocal {
		return report
	}
	// Public exposure must not proceed on any failed check; LAN only warns.
	failLevel := checkWarn
	if mode == ModePublic {
		failLevel = checkBlock
	}
	add := func(id string, ok bool, detail string) {
		level := checkOK
		if !ok {
			level = failLevel
			if level == checkBlock {
				report.Blocked = true
			}
		}
		report.Checks = append(report.Checks, securityCheck{ID: id, Level: level, Detail: detail})
	}

	tlsErr := checkCert(c)
	add("tls", tlsErr == nil, errDetail(tlsErr))
	add("force_https", c.Scheme.HttpPort <= 0 || c.Scheme.ForceHttps, "")
	if guest, err := op.GetGuest(); err != nil {
		add("guest_disabled", false, err.Error())
	} else {
		add("guest_disabled", guest.Disabled, "")
	}
	if c.S3.Enable && c.S3.Port > 0 {
		add("s3_tls", c.S3.SSL, "")
	}
	if c.FTP.Enable && c.FTP.Listen != "" {
		add("ftp_plaintext", false, "FTP transfers credentials in plain text")
	}
	if admin, err := op.GetAdmin(); err == nil {
		// 2FA is strongly recommended but not required.
		level := checkOK
		if admin.OtpSecret == "" {
			level = checkWarn
		}
		report.Checks = append(report.Checks, securityCheck{ID: "admin_2fa", Level: level})
	}
	return report
}

func checkCert(c *conf.Config) error {
	if c.Scheme.HttpsPort <= 0 {
		return errors.New("HTTPS port is disabled")
	}
	if c.Scheme.CertFile == "" || c.Scheme.KeyFile == "" {
		return errors.New("certificate or key file is not configured")
	}
	pair, err := tls.LoadX509KeyPair(c.Scheme.CertFile, c.Scheme.KeyFile)
	if err != nil {
		return err
	}
	leaf, err := x509.ParseCertificate(pair.Certificate[0])
	if err != nil {
		return err
	}
	if time.Now().After(leaf.NotAfter) {
		return fmt.Errorf("certificate expired at %s", leaf.NotAfter.Format(time.RFC3339))
	}
	return nil
}

func errDetail(err error) string {
	if err == nil {
		return ""
	}
	return err.Error()
}

func blockedIDs(r securityReport) string {
	var ids []string
	for _, c := range r.Checks {
		if c.Level == checkBlock {
			ids = append(ids, c.ID)
		}
	}
	return strings.Join(ids, ",")
}

type runtimeStatus struct {
	Running    bool            `json:"running"`
	UptimeSec  int64           `json:"uptime_sec"`
	Address    string          `json:"address"`
	HttpPort   int             `json:"http_port"`
	HttpsPort  int             `json:"https_port"`
	ForceHttps bool            `json:"force_https"`
	Endpoints  map[string]bool `json:"endpoints"`
	Goroutines int             `json:"goroutines"`
	HeapAlloc  uint64          `json:"heap_alloc"`
	HeapSys    uint64          `json:"heap_sys"`
	Sys        uint64          `json:"sys"`
	NumGC      uint32          `json:"num_gc"`
}

// RuntimeStatus returns listener state and Go runtime resource usage as JSON.
func RuntimeStatus() string {
	var ms runtime.MemStats
	runtime.ReadMemStats(&ms)
	st := runtimeStatus{
		Endpoints:  map[string]bool{},
		Goroutines: runtime.NumGoroutine(),
		HeapAlloc:  ms.HeapAlloc,
		HeapSys:    ms.HeapSys,
		Sys:        ms.Sys,
		NumGC:      ms.NumGC,
	}
	for _, t := range []string{"http", "https", "unix", "quic", "s3", "ftp", "sftp"} {
		if bootstrap.IsRunning(t) {
			st.Endpoints[t] = true
			st.Running = true
		}
	}
	if ts := startedAt.Load(); st.Running && ts > 0 {
		st.UptimeSec = time.Now().Unix() - ts
	}
	if conf.Conf != nil {
		st.Address = conf.Conf.Scheme.Address
		st.HttpPort = conf.Conf.Scheme.HttpPort
		st.HttpsPort = conf.Conf.Scheme.HttpsPort
		st.ForceHttps = conf.Conf.Scheme.ForceHttps
	}
	data, _ := json.Marshal(st)
	return string(data)
}

// LocalAddresses returns non-loopback IPv4 addresses joined by commas.
// Android 11+ may deny netlink access; callers there should enumerate
// interfaces natively and use this only as a fallback.
func LocalAddresses() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return ""
	}
	var ips []string
	for _, a := range addrs {
		if ipNet, ok := a.(*net.IPNet); ok && !ipNet.IP.IsLoopback() && ipNet.IP.To4() != nil {
			ips = append(ips, ipNet.IP.String())
		}
	}
	return strings.Join(ips, ",")
}

// AdminToken issues an admin JWT for the in-app native client. It must only
// be reachable through private app IPC, never through a network endpoint.
func AdminToken() (string, error) {
	if len(common.SecretKey) == 0 {
		return "", errors.New("server is not started")
	}
	admin, err := op.GetAdmin()
	if err != nil {
		return "", err
	}
	return common.GenerateToken(admin)
}
