package main

import (
	"errors"
	"flag"
	"log"
	"net/http"

	"github.com/AnoshanJ/echo-core/backend/app"
)

func main() {
	addr := flag.String("addr", ":8080", "listen address")
	flag.Parse()

	if err := app.Run(app.Options{Addr: *addr}); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatal(err)
	}
}
