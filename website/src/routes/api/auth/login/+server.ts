import { redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

const GITHUB_AUTHORIZE_URL = 'https://github.com/login/oauth/authorize';

export const GET: RequestHandler = async ({ platform }) => {
	const env = platform?.env;
	if (!env) throw new Error('Platform env not available');

	const params = new URLSearchParams({
		client_id: env.GITHUB_CLIENT_ID,
		redirect_uri: `${env.APP_URL}/api/auth/callback`,
		scope: 'read:user user:email',
		state: crypto.randomUUID()
	});

	redirect(302, `${GITHUB_AUTHORIZE_URL}?${params}`);
};
