import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

interface Formula {
	name: string;
	full_name: string;
	desc: string;
	homepage: string;
}

interface Cask {
	token: string;
	name: string[];
	desc: string;
	homepage: string;
}

interface SearchResult {
	name: string;
	desc: string;
	type: 'formula' | 'cask';
}

let formulaeCache: Formula[] | null = null;
let casksCache: Cask[] | null = null;
let cacheTimestamp = 0;
const CACHE_TTL = 1000 * 60 * 60;

async function fetchFormulae(): Promise<Formula[]> {
	if (formulaeCache && Date.now() - cacheTimestamp < CACHE_TTL) {
		return formulaeCache;
	}

	const response = await fetch('https://formulae.brew.sh/api/formula.json', {
		cf: { cacheTtl: 3600, cacheEverything: true }
	} as RequestInit);

	if (!response.ok) {
		throw new Error('Failed to fetch formulae');
	}

	const data = (await response.json()) as Formula[];
	formulaeCache = data;
	cacheTimestamp = Date.now();
	return data;
}

async function fetchCasks(): Promise<Cask[]> {
	if (casksCache && Date.now() - cacheTimestamp < CACHE_TTL) {
		return casksCache;
	}

	const response = await fetch('https://formulae.brew.sh/api/cask.json', {
		cf: { cacheTtl: 3600, cacheEverything: true }
	} as RequestInit);

	if (!response.ok) {
		throw new Error('Failed to fetch casks');
	}

	const data = (await response.json()) as Cask[];
	casksCache = data;
	return data;
}

export const GET: RequestHandler = async ({ url }) => {
	const query = url.searchParams.get('q')?.toLowerCase().trim();

	if (!query || query.length < 2) {
		return json({ results: [], error: 'Query must be at least 2 characters' });
	}

	try {
		const [formulae, casks] = await Promise.all([fetchFormulae(), fetchCasks()]);

		const results: SearchResult[] = [];

		for (const f of formulae) {
			if (results.length >= 30) break;
			const nameMatch = f.name.toLowerCase().includes(query);
			const descMatch = f.desc?.toLowerCase().includes(query);
			if (nameMatch || descMatch) {
				results.push({
					name: f.name,
					desc: f.desc || '',
					type: 'formula'
				});
			}
		}

		for (const c of casks) {
			if (results.length >= 50) break;
			const tokenMatch = c.token.toLowerCase().includes(query);
			const nameMatch = c.name?.some((n) => n.toLowerCase().includes(query));
			const descMatch = c.desc?.toLowerCase().includes(query);
			if (tokenMatch || nameMatch || descMatch) {
				results.push({
					name: c.token,
					desc: c.desc || c.name?.[0] || '',
					type: 'cask'
				});
			}
		}

		results.sort((a, b) => {
			const aExact = a.name.toLowerCase() === query;
			const bExact = b.name.toLowerCase() === query;
			if (aExact && !bExact) return -1;
			if (!aExact && bExact) return 1;

			const aStarts = a.name.toLowerCase().startsWith(query);
			const bStarts = b.name.toLowerCase().startsWith(query);
			if (aStarts && !bStarts) return -1;
			if (!aStarts && bStarts) return 1;

			return a.name.length - b.name.length;
		});

		return json({ results: results.slice(0, 30) });
	} catch (error) {
		console.error('Homebrew search error:', error);
		return json({ results: [], error: 'Failed to search Homebrew packages' }, { status: 500 });
	}
};
