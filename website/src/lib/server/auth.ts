import type { Cookies } from '@sveltejs/kit';

interface TokenPayload {
	userId: string;
	username: string;
	exp: number;
}

export async function signToken(payload: TokenPayload, secret: string): Promise<string> {
	const encoder = new TextEncoder();
	const data = JSON.stringify(payload);
	const key = await crypto.subtle.importKey('raw', encoder.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
	const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(data));
	const sigBase64 = btoa(String.fromCharCode(...new Uint8Array(signature)));
	return `${btoa(data)}.${sigBase64}`;
}

export async function verifyToken(token: string, secret: string): Promise<TokenPayload | null> {
	try {
		const [dataBase64, sigBase64] = token.split('.');
		if (!dataBase64 || !sigBase64) return null;

		const data = atob(dataBase64);
		const encoder = new TextEncoder();
		const key = await crypto.subtle.importKey('raw', encoder.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']);

		const signature = Uint8Array.from(atob(sigBase64), (c) => c.charCodeAt(0));
		const valid = await crypto.subtle.verify('HMAC', key, signature, encoder.encode(data));

		if (!valid) return null;

		const payload = JSON.parse(data) as TokenPayload;
		if (payload.exp && Date.now() > payload.exp) return null;

		return payload;
	} catch {
		return null;
	}
}

export function getCookie(cookies: Cookies, name: string): string | undefined {
	return cookies.get(name);
}

export async function getCurrentUser(cookies: Cookies, db: D1Database, secret: string) {
	const token = getCookie(cookies, 'session');
	if (!token) return null;

	const payload = await verifyToken(token, secret);
	if (!payload) return null;

	const user = await db.prepare('SELECT id, username, email, avatar_url FROM users WHERE id = ?').bind(payload.userId).first();
	return user;
}

export function slugify(text: string): string {
	return text
		.toLowerCase()
		.replace(/[^a-z0-9-]/g, '-')
		.replace(/-+/g, '-')
		.replace(/^-|-$/g, '')
		.substring(0, 50);
}

export function generateId(): string {
	return crypto.randomUUID();
}
