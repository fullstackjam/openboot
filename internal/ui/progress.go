package ui

import (
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/charmbracelet/lipgloss"
)

var (
	progressBarStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#22c55e"))

	progressBgStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#333"))

	progressTextStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#888"))

	currentPkgStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#60a5fa"))

	etaStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#666"))
)

type ProgressTracker struct {
	total       int
	completed   int
	active      map[string]bool
	width       int
	startTime   time.Time
	mu          sync.Mutex
	spinnerIdx  int
	spinnerStop chan bool
}

var spinnerFrames = []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}

func NewProgressTracker(total int) *ProgressTracker {
	p := &ProgressTracker{
		total:       total,
		width:       40,
		startTime:   time.Now(),
		active:      make(map[string]bool),
		spinnerStop: make(chan bool),
	}

	go func() {
		ticker := time.NewTicker(80 * time.Millisecond)
		defer ticker.Stop()
		for {
			select {
			case <-p.spinnerStop:
				return
			case <-ticker.C:
				p.mu.Lock()
				p.spinnerIdx = (p.spinnerIdx + 1) % len(spinnerFrames)
				if len(p.active) > 0 {
					p.render()
				}
				p.mu.Unlock()
			}
		}
	}()

	return p
}

func (p *ProgressTracker) SetCurrent(pkgName string) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.active[pkgName] = true
	p.render()
}

func (p *ProgressTracker) Complete(pkgName string) {
	p.mu.Lock()
	defer p.mu.Unlock()
	delete(p.active, pkgName)
	p.completed++
	p.render()
}

func (p *ProgressTracker) render() {
	percent := float64(p.completed) / float64(p.total)
	filled := int(percent * float64(p.width))
	empty := p.width - filled

	bar := progressBarStyle.Render(strings.Repeat("█", filled)) +
		progressBgStyle.Render(strings.Repeat("░", empty))

	status := fmt.Sprintf(" %d/%d (%.0f%%)", p.completed, p.total, percent*100)

	eta := p.estimateRemaining()

	spinner := ""
	activeDisplay := ""
	activeCount := len(p.active)
	if activeCount > 0 {
		spinner = currentPkgStyle.Render(spinnerFrames[p.spinnerIdx]) + " "
		for pkg := range p.active {
			if len(pkg) > 15 {
				pkg = pkg[:12] + "..."
			}
			activeDisplay = pkg
			break
		}
		if activeCount > 1 {
			activeDisplay = fmt.Sprintf("%s +%d", activeDisplay, activeCount-1)
		}
	}

	fmt.Printf("\r\033[K%s%s %s %s%s",
		bar,
		progressTextStyle.Render(status),
		etaStyle.Render(eta),
		spinner,
		currentPkgStyle.Render(activeDisplay))
}

func (p *ProgressTracker) estimateRemaining() string {
	if p.completed == 0 {
		return ""
	}

	elapsed := time.Since(p.startTime)
	avgPerPkg := elapsed / time.Duration(p.completed)
	remaining := p.total - p.completed
	eta := avgPerPkg * time.Duration(remaining)

	if eta < time.Second {
		return "< 1s"
	}

	if eta < time.Minute {
		return fmt.Sprintf("~%ds", int(eta.Seconds()))
	}

	mins := int(eta.Minutes())
	secs := int(eta.Seconds()) % 60
	if secs > 0 {
		return fmt.Sprintf("~%dm%ds", mins, secs)
	}
	return fmt.Sprintf("~%dm", mins)
}

func (p *ProgressTracker) Finish() {
	close(p.spinnerStop)

	p.mu.Lock()
	defer p.mu.Unlock()

	elapsed := time.Since(p.startTime)
	fmt.Printf("\n  Completed in %s\n", formatDuration(elapsed))
}

func formatDuration(d time.Duration) string {
	if d < time.Minute {
		return fmt.Sprintf("%.1fs", d.Seconds())
	}
	mins := int(d.Minutes())
	secs := int(d.Seconds()) % 60
	return fmt.Sprintf("%dm%ds", mins, secs)
}

func (p *ProgressTracker) GetProgress() (int, int) {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.completed, p.total
}
