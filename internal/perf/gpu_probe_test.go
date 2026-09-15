package perf

import (
	"context"
	"fmt"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

// TestHelperProcess_NvidiaSmi is not a real test. It is re-executed as a fake
// nvidia-smi binary by the probe tests, behaving according to
// LLAMA_SWAP_FAKE_NVIDIA_SMI.
func TestHelperProcess_NvidiaSmi(t *testing.T) {
	mode := os.Getenv("LLAMA_SWAP_FAKE_NVIDIA_SMI")
	if mode == "" {
		return
	}
	switch mode {
	case "ok":
		fmt.Println("0, NVIDIA GeForce RTX 4090, GPU-abc, 45, 3, 1024, 24564, 30, 35.5")
		os.Exit(0)
	case "no-permission":
		fmt.Println("NVIDIA-SMI has failed because you do not have sufficient permissions. Please try running as an administrator.")
		os.Exit(4)
	case "garbage":
		fmt.Println("No devices were found")
		os.Exit(0)
	}
	os.Exit(2)
}

func fakeNvidiaSmi(t *testing.T, mode string) (string, []string) {
	t.Setenv("LLAMA_SWAP_FAKE_NVIDIA_SMI", mode)
	return os.Args[0], []string{"-test.run=^TestHelperProcess_NvidiaSmi$", "--"}
}

func TestProbeNvidiaSmi_Works(t *testing.T) {
	name, args := fakeNvidiaSmi(t, "ok")
	assert.NoError(t, probeNvidiaSmi(context.Background(), name, args...))
}

func TestProbeNvidiaSmi_NonZeroExit(t *testing.T) {
	name, args := fakeNvidiaSmi(t, "no-permission")
	assert.Error(t, probeNvidiaSmi(context.Background(), name, args...))
}

func TestProbeNvidiaSmi_UnparseableOutput(t *testing.T) {
	name, args := fakeNvidiaSmi(t, "garbage")
	assert.Error(t, probeNvidiaSmi(context.Background(), name, args...))
}

func TestProbeNvidiaSmi_Missing(t *testing.T) {
	assert.Error(t, probeNvidiaSmi(context.Background(), "llama-swap-no-such-nvidia-smi"))
}
