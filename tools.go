// +build tools

package main

import (
	_ "github.com/brancz/locutus"
	_ "github.com/observatorium/observatorium/test/tls"
	_ "sigs.k8s.io/controller-tools/cmd/controller-gen"
)
