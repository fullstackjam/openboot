<script lang="ts">
	import type { Snippet } from 'svelte';

	interface Props {
		variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
		href?: string;
		type?: 'button' | 'submit';
		onclick?: () => void;
		children: Snippet;
	}

	let { variant = 'secondary', href, type = 'button', onclick, children }: Props = $props();
</script>

{#if href}
	<a {href} class="btn btn-{variant}">
		{@render children()}
	</a>
{:else}
	<button {type} class="btn btn-{variant}" {onclick}>
		{@render children()}
	</button>
{/if}

<style>
	.btn {
		display: inline-flex;
		align-items: center;
		gap: 8px;
		padding: 8px 16px;
		border-radius: 6px;
		font-size: 0.9rem;
		font-weight: 500;
		cursor: pointer;
		border: none;
		transition: all 0.2s;
		text-decoration: none;
		font-family: inherit;
	}

	.btn-primary {
		background: var(--accent);
		color: #000;
	}

	.btn-primary:hover {
		background: var(--accent-hover);
	}

	.btn-secondary {
		background: var(--bg-tertiary);
		color: var(--text-primary);
		border: 1px solid var(--border);
	}

	.btn-secondary:hover {
		background: var(--bg-hover);
		border-color: var(--border-hover);
	}

	.btn-danger {
		background: var(--danger);
		color: white;
	}

	.btn-danger:hover {
		background: var(--danger-hover);
	}

	.btn-ghost {
		background: transparent;
		color: var(--text-secondary);
	}

	.btn-ghost:hover {
		color: var(--text-primary);
		background: var(--bg-tertiary);
	}
</style>
