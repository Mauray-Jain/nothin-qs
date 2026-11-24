// Package shell carries the QML so an installed nothin needs no repo checkout.
package shell

import "embed"

//go:embed *
var FS embed.FS
