package perf

import (
	"bufio"
	"bytes"
	"context"
	"fmt"
	"os/exec"
	"strings"
	"time"
)

// probeNvidiaSmi runs a single nvidia-smi query and returns an error unless it
// exits cleanly with at least one parseable GPU line. A stray nvidia-smi on a
// machine without a working NVIDIA driver exits immediately with an error, and
// without this check it would block the fallback GPU monitors.
func probeNvidiaSmi(ctx context.Context, name string, args ...string) error {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	args = append(args,
		"--query-gpu=index,name,uuid,temperature.gpu,utilization.gpu,memory.used,memory.total,fan.speed,power.draw",
		"--format=csv,noheader,nounits",
	)
	out, err := exec.CommandContext(ctx, name, args...).Output()
	if err != nil {
		return fmt.Errorf("nvidia-smi probe failed: %w", err)
	}

	scanner := bufio.NewScanner(bytes.NewReader(out))
	for scanner.Scan() {
		if ParseNvidiaSmiLine(strings.TrimSpace(scanner.Text())) != nil {
			return nil
		}
	}
	return fmt.Errorf("nvidia-smi probe returned no GPUs: %q", strings.TrimSpace(string(out)))
}
