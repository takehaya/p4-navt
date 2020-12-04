package controller

import (
	"context"
	"fmt"
	"net"

	"github.com/ebiken/gop4d-dev/pkg/config"
	p4switch "github.com/ebiken/gop4d-dev/pkg/gop4dswitch"
	"github.com/ebiken/gop4d-dev/pkg/p4runtime"
	"github.com/ebiken/gop4d-dev/pkg/tap"
	v1 "github.com/p4lang/p4runtime/go/p4/v1"
	"github.com/pkg/errors"
)

type Controller struct {
	*p4switch.GoP4dSwitch
}

func New(c *config.Config, cfn *context.CancelFunc) (*Controller, error) {
	gop4dsw, err := p4switch.New(c, cfn)
	if err != nil {
		return nil, err
	}

	return &Controller{
		GoP4dSwitch: gop4dsw,
	}, nil
}

func (c *Controller) LoadConfiguration() error {
	var err error
	err = c.loadLocalMac("02:03:04:05:06:fe")
	if err != nil {
		c.Logger.Error(err.Error())
		return err
	}

	return nil
}

func (c *Controller) loadLocalMac(newmac string) error {
	err := c.setupLocalMac(newmac, "SwitchIngress.localmac_hit")
	if err != nil {
		c.Logger.Error(err.Error())
		return err
	}
	err = c.writeCloneCPUPortInsert()
	if err != nil {
		c.Logger.Error(err.Error())
		return err
	}
	err = c.genTaps(newmac)
	if err != nil {
		c.Logger.Error(err.Error())
		return err
	}

	return nil
}

func (c *Controller) setupLocalMac(macaddr string, acname string) error {
	mac, err := net.ParseMAC(macaddr)
	if err != nil {
		return errors.Wrap(err, "failed Parsing MAC address")
	}
	tbuilder, err := p4runtime.NewTableEntry("SwitchIngress.localmac", &c.P4infoHelper)
	if err != nil {
		return err
	}
	mfts := []p4runtime.MatchFieldTuple{
		{
			Mfname: "hdr.ether.dstAddr",
			MatchField: &p4runtime.ExactMatch{
				Value: mac,
			},
		},
	}
	err = tbuilder.SetMatchFields(mfts)
	if err != nil {
		return err
	}
	acts := p4runtime.TableActionTuple{
		AcName: acname,
	}
	err = tbuilder.SetTableActions(acts)
	if err != nil {
		return err
	}
	tableEntry, err := tbuilder.Build()
	if err != nil {
		return err
	}
	err = c.TableEntryExec(tableEntry, p4switch.Insert)
	if err != nil {
		return err
	}
	return nil
}

func (c *Controller) writeCloneCPUPortInsert() error {
	// todo hardcode fix
	cloneEntry := &v1.CloneSessionEntry{
		SessionId: 100,
		Replicas: []*v1.Replica{
			{
				EgressPort: 255,
				Instance:   1,
			},
		},
	}

	return c.SendCloneSession(cloneEntry, p4switch.Insert)
}

func (c *Controller) genTaps(macaddr string) error {
	for vid := 100; vid <= 1500; vid += 100 {
		t, err := tap.New(
			"tap"+fmt.Sprintf("%v", vid),
			&c.P4runtimeClient,
			"172.26.2.254/24",
			macaddr,
			uint32(vid),
			c.Config.Gop4dConfig.Development,
		)
		if err != nil {
			return errors.WithMessage(err, "tap init failed")
		}
		c.Taps = append(c.Taps, t)
	}

	t, err := tap.New(
		"tap0",
		&c.P4runtimeClient,
		"172.27.1.254/24",
		macaddr,
		0,
		c.Config.Gop4dConfig.Development,
	)
	c.Taps = append(c.Taps, t)

	if err != nil {
		return errors.WithMessage(err, "tap init failed")
	}

	return nil
}
