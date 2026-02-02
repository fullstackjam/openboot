import { redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { signToken, generateId } from '$lib/server/auth';

const GITHUB_TOKEN_URL = 'https://github.com/login/oauth/access_token';
const GITHUB_USER_URL = 'https://api.github.com/user';

export const GET: RequestHandler = async ({ url, platform, cookies }) => {
	const env = platform?.env;
	if (!env) throw new Error('Platform env not available');

	const code = url.searchParams.get('code');
	if (!code) {
		redirect(302, `${env.APP_URL}?error=no_code`);
	}

	const tokenResponse = await fetch(GITHUB_TOKEN_URL, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
		body: JSON.stringify({
			client_id: env.GITHUB_CLIENT_ID,
			client_secret: env.GITHUB_CLIENT_SECRET,
			code
		})
	});

	const tokenData = await tokenResponse.json();
	if (tokenData.error || !tokenData.access_token) {
		redirect(302, `${env.APP_URL}?error=token_failed`);
	}

	const headers = {
		Authorization: `Bearer ${tokenData.access_token}`,
		Accept: 'application/json',
		'User-Agent': 'OpenBoot'
	};

	const userResponse = await fetch(GITHUB_USER_URL, { headers });
	const githubUser = await userResponse.json();
	if (!githubUser.id || !githubUser.login) {
		redirect(302, `${env.APP_URL}?error=user_failed`);
	}

	let email = githubUser.email || '';
	if (!email) {
		const emailsResponse = await fetch('https://api.github.com/user/emails', { headers });
		const emails = await emailsResponse.json();
		const primary = emails.find((e: { primary: boolean; email: string }) => e.primary);
		email = primary?.email || emails[0]?.email || '';
	}

	const userId = String(githubUser.id);

	await env.DB.prepare(
		`
		INSERT INTO users (id, username, email, avatar_url, updated_at)
		VALUES (?, ?, ?, ?, datetime('now'))
		ON CONFLICT(id) DO UPDATE SET
			username = excluded.username,
			email = excluded.email,
			avatar_url = excluded.avatar_url,
			updated_at = datetime('now')
	`
	)
		.bind(userId, githubUser.login, email, githubUser.avatar_url || '')
		.run();

	const existingConfig = await env.DB.prepare('SELECT id FROM configs WHERE user_id = ? AND slug = ?').bind(userId, 'default').first();

	if (!existingConfig) {
		await env.DB.prepare(
			`
			INSERT INTO configs (id, user_id, slug, name, description, base_preset, packages)
			VALUES (?, ?, 'default', 'Default', 'My default configuration', 'developer', '[]')
		`
		)
			.bind(generateId(), userId)
			.run();
	}

	const thirtyDays = 30 * 24 * 60 * 60;
	const token = await signToken({ userId, username: githubUser.login, exp: Date.now() + thirtyDays * 1000 }, env.JWT_SECRET);

	cookies.set('session', token, {
		path: '/',
		httpOnly: true,
		secure: true,
		sameSite: 'lax',
		maxAge: thirtyDays
	});

	redirect(302, '/dashboard');
};
