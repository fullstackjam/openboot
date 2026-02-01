import { redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

const INSTALL_SCRIPT_URL = 'https://raw.githubusercontent.com/fullstackjam/openboot/main/scripts/install.sh';

export const GET: RequestHandler = async () => {
	redirect(302, INSTALL_SCRIPT_URL);
};
