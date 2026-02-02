import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getCurrentUser, slugify, generateId } from '$lib/server/auth';

export const GET: RequestHandler = async ({ platform, cookies }) => {
	const env = platform?.env;
	if (!env) return json({ error: 'Platform env not available' }, { status: 500 });

	const user = await getCurrentUser(cookies, env.DB, env.JWT_SECRET);
	if (!user) return json({ error: 'Unauthorized' }, { status: 401 });

	const { results } = await env.DB.prepare('SELECT id, slug, name, description, base_preset, is_public, alias, updated_at FROM configs WHERE user_id = ? ORDER BY updated_at DESC')
		.bind(user.id)
		.all();

	return json({ configs: results, username: user.username });
};

export const POST: RequestHandler = async ({ platform, cookies, request }) => {
	const env = platform?.env;
	if (!env) return json({ error: 'Platform env not available' }, { status: 500 });

	const user = await getCurrentUser(cookies, env.DB, env.JWT_SECRET);
	if (!user) return json({ error: 'Unauthorized' }, { status: 401 });

	let body;
	try {
		body = await request.json();
	} catch {
		return json({ error: 'Invalid request body' }, { status: 400 });
	}

	const { name, description, base_preset, packages, custom_script, is_public, alias, dotfiles_repo } = body;

	if (!name) return json({ error: 'Name is required' }, { status: 400 });

	const slug = slugify(name);
	if (!slug) return json({ error: 'Invalid name' }, { status: 400 });

	const existing = await env.DB.prepare('SELECT id FROM configs WHERE user_id = ? AND slug = ?').bind(user.id, slug).first();
	if (existing) return json({ error: 'Config with this name already exists' }, { status: 409 });

	let cleanAlias = null;
	if (alias) {
		cleanAlias = alias
			.toLowerCase()
			.replace(/[^a-z0-9-]/g, '')
			.substring(0, 20);
		if (cleanAlias.length < 2) return json({ error: 'Alias must be at least 2 characters' }, { status: 400 });
		if (['api', 'install', 'dashboard', 'login', 'logout'].includes(cleanAlias)) {
			return json({ error: 'This alias is reserved' }, { status: 400 });
		}
		const aliasExists = await env.DB.prepare('SELECT id FROM configs WHERE alias = ?').bind(cleanAlias).first();
		if (aliasExists) return json({ error: 'This alias is already taken' }, { status: 409 });
	}

	const configCount = await env.DB.prepare('SELECT COUNT(*) as count FROM configs WHERE user_id = ?').bind(user.id).first<{ count: number }>();
	if (configCount && configCount.count >= 20) {
		return json({ error: 'Maximum 20 configs per user' }, { status: 400 });
	}

	const id = generateId();

	try {
		await env.DB.prepare(
			`
			INSERT INTO configs (id, user_id, slug, name, description, base_preset, packages, custom_script, is_public, alias, dotfiles_repo)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`
		)
			.bind(id, user.id, slug, name, description || '', base_preset || 'developer', JSON.stringify(packages || []), custom_script || '', is_public !== false ? 1 : 0, cleanAlias, dotfiles_repo || '')
			.run();
	} catch (e) {
		return json({ error: 'Database error: ' + (e as Error).message }, { status: 500 });
	}

	const installUrl = cleanAlias ? `${env.APP_URL}/${cleanAlias}` : `${env.APP_URL}/${user.username}/${slug}/install`;

	return json({ id, slug, alias: cleanAlias, install_url: installUrl }, { status: 201 });
};
