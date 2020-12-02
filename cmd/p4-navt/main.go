package main

import (
	"log"
	"os"

	"github.com/takehaya/p4-navt/internal"
	"github.com/takehaya/p4-navt/pkg/version"
)

func main() {
	app := internal.NewApp(version.Version)
	if err := app.Run(os.Args); err != nil {
		log.Fatalf("%+v", err)
	}
}
