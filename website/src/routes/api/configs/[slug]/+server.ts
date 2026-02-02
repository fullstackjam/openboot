import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getCurrentUser, slugify } from '$lib/server/auth';

export const GET: RequestHandler = async ({ platform, cookies, params }) => {
	const env = platform?.env;
	if (!env) return json({ error: 'Platform env not available' }, { status: 500 });

	const user = await getCurrentUser(cookies, env.DB, env.JWT_SECRET);
	if (!user) return json({ error: 'Unauthorized' }, { status: 401 });

	const config = await env.DB.prepare('SELECT * FROM configs WHERE user_id = ? AND slug = ?').bind(user.id, params.slug).first();
	if (!config) return json({ error: 'Config not found' }, { status: 404 });

	const installUrl = config.alias ? `${env.APP_URL}/${config.alias}` : `${env.APP_URL}/${user.username}/${params.slug}/install`;

	return json({
		config: {
			...config,
			packages: JSON.parse((config.packages as string) || '[]')
		},
		install_url: installUrl
	});
};

export const PUT: RequestHandler = async ({ platform, cookies, params, request }) => {
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
	const slug = params.slug;

	const existing = await env.DB.prepare('SELECT id, alias FROM configs WHERE user_id = ? AND slug = ?').bind(user.id, slug).first<{ id: string; alias: string | null }>();
	if (!existing) return json({ error: 'Config not found' }, { status: 404 });

	let newSlug = slug;
	if (name && slugify(name) !== slug) {
		newSlug = slugify(name);
		const conflict = await env.DB.prepare('SELECT id FROM configs WHERE user_id = ? AND slug = ? AND id != ?').bind(user.id, newSlug, existing.id).first();
		if (conflict) return json({ error: 'Config with this name already exists' }, { status: 409 });
	}

	let newAlias = existing.alias;
	if (alias !== undefined) {
		if (alias === '' || alias === null) {
			newAlias = null;
		} else {
			newAlias = alias
				.toLowerCase()
				.replace(/[^a-z0-9-]/g, '')
				.substring(0, 20);
			if (newAlias.length < 2) return json({ error: 'Alias must be at least 2 characters' }, { status: 400 });
			if (['api', 'install', 'dashboard', 'login', 'logout'].includes(newAlias)) {
				return json({ error: 'This alias is reserved' }, { status: 400 });
			}
			const aliasExists = await env.DB.prepare('SELECT id FROM configs WHERE alias = ? AND id != ?').bind(newAlias, existing.id).first();
			if (aliasExists) return json({ error: 'This alias is already taken' }, { status: 409 });
		}
	}

	try {
		await env.DB.prepare(
			`
			UPDATE configs SET
				slug = ?,
				name = COALESCE(?, name),
				description = COALESCE(?, description),
				base_preset = COALESCE(?, base_preset),
				packages = COALESCE(?, packages),
				custom_script = COALESCE(?, custom_script),
				is_public = COALESCE(?, is_public),
				alias = ?,
				dotfiles_repo = COALESCE(?, dotfiles_repo),
				updated_at = datetime('now')
			WHERE user_id = ? AND slug = ?
		`
		)
			.bind(
				newSlug,
				name || null,
				description !== undefined ? description : null,
				base_preset || null,
				packages ? JSON.stringify(packages) : null,
				custom_script !== undefined ? custom_script : null,
				is_public !== undefined ? (is_public ? 1 : 0) : null,
				newAlias,
				dotfiles_repo !== undefined ? dotfiles_repo : null,
				user.id,
				slug
			)
			.run();
	} catch (e) {
		return json({ error: 'Database error: ' + (e as Error).message }, { status: 500 });
	}

	const installUrl = newAlias ? `${env.APP_URL}/${newAlias}` : `${env.APP_URL}/${user.username}/${newSlug}/install`;

	return json({ success: true, slug: newSlug, alias: newAlias, install_url: installUrl });
};

export const DELETE: RequestHandler = async ({ platform, cookies, params }) => {
	const env = platform?.env;
	if (!env) return json({ error: 'Platform env not available' }, { status: 500 });

	const user = await getCurrentUser(cookies, env.DB, env.JWT_SECRET);
	if (!user) return json({ error: 'Unauthorized' }, { status: 401 });

	if (params.slug === 'default') {
		return json({ error: 'Cannot delete default config' }, { status: 400 });
	}

	await env.DB.prepare('DELETE FROM configs WHERE user_id = ? AND slug = ?').bind(user.id, params.slug).run();

	return json({ success: true });
};
