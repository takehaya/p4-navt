package internal

import (
	"fmt"
	"log"

	"github.com/ebiken/gop4d-dev/pkg/config"
	"github.com/ebiken/gop4d-dev/pkg/utils"

	"github.com/urfave/cli"
)

func NewApp(version string) *cli.App {
	app := cli.NewApp()
	app.Name = "p4navt"
	app.Version = version

	app.Usage = "Network Address Vlan Translation. \n e.g. VID:100, 192.168.0.1(inside) <=> 10.1.0.1 (outside)"

	app.EnableBashCompletion = true
	app.Flags = []cli.Flag{
		cli.StringFlag{
			Name:  "bmv2json",
			Value: "./build.bmv2/switch.json",
			Usage: "BMv2 JSON file from p4c",
		},
		cli.StringFlag{
			Name:  "p4info",
			Value: "./build.bmv2/switch.p4.p4info.txt",
			Usage: "p4info proto in text format from p4c",
		},
		cli.StringFlag{
			Name:  "grpcaddr",
			Value: "127.0.0.1:50051",
			Usage: "grpc conn addr format:<addr>:<port>",
		},
	}
	app.Action = run
	return app
}

func run(ctx *cli.Context) error {
	bmv2json := ctx.String("bmv2json")
	p4info := ctx.String("p4info")
	grpcaddr := ctx.String("grpcaddr")

	if !utils.FileExists(bmv2json) {
		log.Fatalf("p4info file not found: %s\nHave you run 'make'?", bmv2json)
	} else if !utils.FileExists(p4info) {
		log.Fatalf("BMv2 JSON file not found: %s\nHave you run 'make?", p4info)
	}

	conf := config.BuildPresetConfig()
	conf.Gop4dConfig.Bmv2json = "./build.bmv2/main.json"
	conf.Gop4dConfig.P4info = "./build.bmv2/main.p4.p4info.txt"
	fmt.Println(grpcaddr)
	// var cancel context.CancelFunc
	// sw, err := p4switch.New(conf, &cancel)
	// if err != nil {
	// 	log.Fatal("failed")
	// }
	// defer cancel()

	return nil
}
