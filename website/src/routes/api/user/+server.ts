import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getCurrentUser } from '$lib/server/auth';

export const GET: RequestHandler = async ({ platform, cookies }) => {
	const env = platform?.env;
	if (!env) return json({ error: 'Platform env not available' }, { status: 500 });

	const user = await getCurrentUser(cookies, env.DB, env.JWT_SECRET);
	if (!user) return json({ error: 'Unauthorized' }, { status: 401 });

	return json({ user });
};
