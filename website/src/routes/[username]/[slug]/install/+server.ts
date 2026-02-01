import type { RequestHandler } from './$types';

function generateInstallScript(username: string, configName: string, preset: string, packages: string[], customScript: string): string {
	const packagesArg = packages.length > 0 ? `--packages "${packages.join(',')}"` : '';

	return `#!/bin/bash
set -e

echo "========================================"
echo "  OpenBoot - Custom Install"
echo "  Config: @${username}/${configName}"
echo "========================================"
echo ""

ARCH="$(uname -m)"
if [ "$ARCH" = "arm64" ]; then
  ARCH="arm64"
else
  ARCH="amd64"
fi

OPENBOOT_URL="https://github.com/fullstackjam/openboot/releases/latest/download/openboot-darwin-\${ARCH}"
TMPDIR="\${TMPDIR:-/tmp}"
OPENBOOT_BIN="\$TMPDIR/openboot-\$\$"

cleanup() { rm -f "\$OPENBOOT_BIN"; }
trap cleanup EXIT

echo "Downloading OpenBoot..."
curl -fsSL "\$OPENBOOT_URL" -o "\$OPENBOOT_BIN"
chmod +x "\$OPENBOOT_BIN"

echo "Running with preset: ${preset}"
"\$OPENBOOT_BIN" --preset ${preset} ${packagesArg} "\$@"

${
	customScript
		? `
echo ""
echo "=== Running Custom Post-Install Script ==="
${customScript}
`
		: ''
}

echo ""
echo "Installation complete!"
`;
}

export const GET: RequestHandler = async ({ platform, params }) => {
	const env = platform?.env;
	if (!env) {
		return new Response('Platform env not available', { status: 500 });
	}

	const user = await env.DB.prepare('SELECT id FROM users WHERE username = ?').bind(params.username).first<{ id: string }>();
	if (!user) {
		return new Response('User not found', { status: 404 });
	}

	const config = await env.DB.prepare('SELECT base_preset, packages, custom_script, is_public FROM configs WHERE user_id = ? AND slug = ?')
		.bind(user.id, params.slug)
		.first<{ base_preset: string; packages: string; custom_script: string; is_public: number }>();

	if (!config) {
		return new Response('Config not found', { status: 404 });
	}

	if (!config.is_public) {
		return new Response('Config is private', { status: 403 });
	}

	const packages = JSON.parse(config.packages || '[]');
	const script = generateInstallScript(params.username, params.slug, config.base_preset, packages, config.custom_script);

	return new Response(script, {
		headers: {
			'Content-Type': 'text/plain; charset=utf-8',
			'Cache-Control': 'no-cache'
		}
	});
};
