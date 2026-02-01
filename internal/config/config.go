package config

type Config struct {
	Preset       string
	Silent       bool
	DryRun       bool
	Update       bool
	Rollback     bool
	Resume       bool
	Shell        string
	Macos        string
	Dotfiles     string
	GitName      string
	GitEmail     string
	SelectedPkgs map[string]bool
}

type Preset struct {
	Name        string
	Description string
	CLI         []string
	Cask        []string
}

var Presets = map[string]Preset{
	"minimal": {
		Name:        "minimal",
		Description: "Essential CLI tools + modern replacements (fastest)",
		CLI: []string{
			"curl", "wget", "jq", "yq",
			"ripgrep", "fd", "bat", "eza", "fzf", "zoxide",
			"htop", "btop", "tree", "watch", "tldr",
			"gh", "git-delta", "lazygit", "stow",
			"ssh-copy-id", "rsync",
		},
		Cask: []string{
			"warp", "raycast", "maccy", "scroll-reverser", "stats",
		},
	},
	"standard": {
		Name:        "standard",
		Description: "General development (Node, Go, Rust, Docker)",
		CLI: []string{
			"curl", "wget", "jq", "yq",
			"ripgrep", "fd", "bat", "eza", "fzf", "zoxide",
			"htop", "btop", "tree", "watch", "tldr",
			"gh", "git-delta", "lazygit", "stow",
			"ssh-copy-id", "rsync",
			"node", "go", "rustup",
			"tmux", "neovim", "httpie", "jless",
			"docker", "docker-compose",
			"redis", "sqlite",
		},
		Cask: []string{
			"warp", "raycast", "maccy", "scroll-reverser", "stats",
			"visual-studio-code", "orbstack",
			"google-chrome", "arc",
			"postman", "proxyman",
			"notion", "typora",
		},
	},
	"full": {
		Name:        "full",
		Description: "Everything including office & communication apps",
		CLI: []string{
			"curl", "wget", "jq", "yq",
			"ripgrep", "fd", "bat", "eza", "fzf", "zoxide",
			"htop", "btop", "tree", "watch", "tldr",
			"gh", "git-delta", "lazygit", "stow",
			"ssh-copy-id", "rsync",
			"node", "go", "rustup",
			"tmux", "neovim", "httpie", "jless",
			"docker", "docker-compose",
			"redis", "sqlite",
			"kubectl", "helm", "argocd", "awscli", "terraform",
			"wireguard-tools", "mtr", "nmap", "wrk", "telnet",
			"python", "pipx", "uv",
			"zola", "ffmpeg", "imagemagick", "pandoc",
		},
		Cask: []string{
			"warp", "raycast", "maccy", "scroll-reverser", "stats",
			"visual-studio-code", "orbstack",
			"google-chrome", "arc",
			"postman", "proxyman",
			"notion", "typora",
			"feishu", "wechat", "telegram", "discord", "slack",
			"microsoft-office", "obsidian",
			"microsoft-edge", "firefox",
			"neteasemusic", "iina", "keka",
			"betterdisplay", "balenaetcher", "clash-verge-rev", "aldente",
		},
	},
	"devops": {
		Name:        "devops",
		Description: "Kubernetes, Terraform, cloud CLIs, GitOps",
		CLI: []string{
			"curl", "wget", "jq", "yq",
			"ripgrep", "fd", "bat", "eza", "fzf", "zoxide",
			"htop", "btop", "tree", "watch", "tldr",
			"gh", "git-delta", "lazygit", "stow",
			"ssh-copy-id", "rsync",
			"kubectl", "helm", "kustomize", "k9s", "kubectx", "stern",
			"argocd", "flux",
			"awscli", "azure-cli", "google-cloud-sdk",
			"terraform", "pulumi", "ansible",
			"vault", "sops", "age",
			"istioctl", "cilium-cli",
			"docker", "docker-compose", "crane", "dive",
			"k6", "trivy",
		},
		Cask: []string{
			"warp", "raycast", "maccy", "scroll-reverser", "stats",
			"visual-studio-code", "orbstack", "lens", "aws-vault",
		},
	},
	"frontend": {
		Name:        "frontend",
		Description: "Web development (Node, pnpm, Bun, browsers, Figma)",
		CLI: []string{
			"curl", "wget", "jq", "yq",
			"ripgrep", "fd", "bat", "eza", "fzf", "zoxide",
			"htop", "btop", "tree", "watch", "tldr",
			"gh", "git-delta", "lazygit", "stow",
			"ssh-copy-id", "rsync",
			"node", "pnpm", "yarn", "bun", "fnm", "deno",
			"vite",
			"tmux", "neovim", "httpie",
			"playwright",
		},
		Cask: []string{
			"warp", "raycast", "maccy", "scroll-reverser", "stats",
			"visual-studio-code", "cursor",
			"google-chrome", "firefox", "arc", "microsoft-edge",
			"figma", "sketch",
			"postman", "proxyman", "imageoptim",
		},
	},
	"data": {
		Name:        "data",
		Description: "Data science (Python, R, Julia, DuckDB, databases)",
		CLI: []string{
			"curl", "wget", "jq", "yq",
			"ripgrep", "fd", "bat", "eza", "fzf", "zoxide",
			"htop", "btop", "tree", "watch", "tldr",
			"gh", "git-delta", "lazygit", "stow",
			"ssh-copy-id", "rsync",
			"python", "pipx", "uv", "pyenv",
			"duckdb", "postgresql", "sqlite", "mysql",
			"csvkit", "miller", "xsv",
			"r", "julia",
			"jupyterlab",
		},
		Cask: []string{
			"warp", "raycast", "maccy", "scroll-reverser", "stats",
			"visual-studio-code",
			"dbeaver-community", "db-browser-for-sqlite", "tableplus", "rstudio",
		},
	},
	"mobile": {
		Name:        "mobile",
		Description: "iOS & Android development (Xcode tools, Android Studio)",
		CLI: []string{
			"curl", "wget", "jq", "yq",
			"ripgrep", "fd", "bat", "eza", "fzf", "zoxide",
			"htop", "btop", "tree", "watch", "tldr",
			"gh", "git-delta", "lazygit", "stow",
			"ssh-copy-id", "rsync",
			"cocoapods", "fastlane", "swiftlint", "xcode-build-server",
			"node", "yarn", "watchman",
			"openjdk@17", "gradle",
			"scrcpy",
		},
		Cask: []string{
			"warp", "raycast", "maccy", "scroll-reverser", "stats",
			"visual-studio-code", "android-studio",
			"sf-symbols", "zeplin", "figma", "proxyman",
		},
	},
	"ai": {
		Name:        "ai",
		Description: "AI/ML development (Ollama, LLM tools, Cursor)",
		CLI: []string{
			"curl", "wget", "jq", "yq",
			"ripgrep", "fd", "bat", "eza", "fzf", "zoxide",
			"htop", "btop", "tree", "watch", "tldr",
			"gh", "git-delta", "lazygit", "stow",
			"ssh-copy-id", "rsync",
			"python", "pipx", "uv", "pyenv",
			"ollama", "llm",
			"duckdb", "sqlite",
			"node", "tmux", "neovim",
		},
		Cask: []string{
			"warp", "raycast", "maccy", "scroll-reverser", "stats",
			"visual-studio-code", "cursor",
			"lm-studio", "chatgpt", "jan",
		},
	},
}

func GetPreset(name string) (Preset, bool) {
	p, ok := Presets[name]
	return p, ok
}

func GetPresetNames() []string {
	return []string{"minimal", "standard", "full", "devops", "frontend", "data", "mobile", "ai"}
}
