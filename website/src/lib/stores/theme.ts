import { writable } from 'svelte/store';
import { browser } from '$app/environment';

type Theme = 'light' | 'dark';

function createThemeStore() {
	const getInitialTheme = (): Theme => {
		if (!browser) return 'dark';
		const saved = localStorage.getItem('theme') as Theme | null;
		if (saved) return saved;
		return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
	};

	const { subscribe, set, update } = writable<Theme>(getInitialTheme());

	return {
		subscribe,
		toggle: () => {
			update((current) => {
				const next = current === 'light' ? 'dark' : 'light';
				if (browser) {
					localStorage.setItem('theme', next);
					document.documentElement.setAttribute('data-theme', next === 'light' ? 'light' : '');
				}
				return next;
			});
		},
		set: (theme: Theme) => {
			if (browser) {
				localStorage.setItem('theme', theme);
				document.documentElement.setAttribute('data-theme', theme === 'light' ? 'light' : '');
			}
			set(theme);
		},
		init: () => {
			if (browser) {
				const theme = getInitialTheme();
				document.documentElement.setAttribute('data-theme', theme === 'light' ? 'light' : '');
				set(theme);
			}
		}
	};
}

export const theme = createThemeStore();
