declare global {
	namespace App {
		interface Platform {
			env: {
				DB: D1Database;
				GITHUB_CLIENT_ID: string;
				GITHUB_CLIENT_SECRET: string;
				JWT_SECRET: string;
				APP_URL: string;
			};
		}
	}
}

export {};
