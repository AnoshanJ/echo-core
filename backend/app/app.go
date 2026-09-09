package app

import (
	"encoding/json"
	"log"
	"net/http"
	"runtime/debug"
	"time"
)

const ModulePath = "github.com/AnoshanJ/echo-core/backend"

var (
	Version = "dev"
	Commit  = "none"
)

// Deps is the live core state handed to wrapper-supplied routes.
type Deps struct {
	Started  time.Time
	Greeting string
}

type Options struct {
	Addr        string
	ExtraRoutes func(mux *http.ServeMux, deps *Deps)
}

type CoreModule struct {
	Path       string `json:"path"`
	Version    string `json:"version"`
	Sum        string `json:"sum,omitempty"`
	ReplacedBy string `json:"replaced_by,omitempty"`
}

func Register(mux *http.ServeMux, deps *Deps) {
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"status":     "ok",
			"uptime_sec": int(time.Since(deps.Started).Seconds()),
		})
	})

	mux.HandleFunc("GET /api/v1/echo", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"msg":    r.URL.Query().Get("msg"),
			"source": deps.Greeting,
		})
	})

	mux.HandleFunc("GET /api/v1/version", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"source":      deps.Greeting,
			"version":     Version,
			"commit":      Commit,
			"core_module": coreModule(),
		})
	})
}

// coreModule reports how this binary actually resolved the core module, so a
// wrapper build cannot misreport which core it linked against.
func coreModule() CoreModule {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return CoreModule{Path: ModulePath, Version: "unknown"}
	}
	for _, dep := range info.Deps {
		if dep.Path != ModulePath {
			continue
		}
		m := CoreModule{Path: dep.Path, Version: dep.Version, Sum: dep.Sum}
		if dep.Replace != nil {
			m.ReplacedBy = dep.Replace.Path
			if dep.Replace.Version != "" {
				m.ReplacedBy += "@" + dep.Replace.Version
			}
		}
		return m
	}
	return CoreModule{Path: ModulePath, Version: "(main module)"}
}

func Run(opts Options) error {
	deps := &Deps{Started: time.Now().UTC(), Greeting: "core"}

	mux := http.NewServeMux()
	Register(mux, deps)
	if opts.ExtraRoutes != nil {
		opts.ExtraRoutes(mux, deps)
	}

	addr := opts.Addr
	if addr == "" {
		addr = ":8080"
	}
	log.Printf("listening on %s (version=%s commit=%s core=%s)", addr, Version, Commit, coreModule().Version)

	srv := &http.Server{Addr: addr, Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	return srv.ListenAndServe()
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(body); err != nil {
		log.Printf("encode response: %v", err)
	}
}
