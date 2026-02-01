# Deploying openboot.dev to Cloudflare Pages

## Prerequisites

- Cloudflare account with the domain `openboot.dev` configured
- GitHub repository secrets configured

## Setup Steps

### 1. Create Cloudflare API Token

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Use the "Edit Cloudflare Workers" template or create custom:
   - **Permissions**:
     - Account > Cloudflare Pages > Edit
     - Zone > Zone > Read (for custom domains)
   - **Account Resources**: Include your account
   - **Zone Resources**: Include openboot.dev
4. Copy the token

### 2. Get Cloudflare Account ID

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Select any zone or go to Workers & Pages
3. Find "Account ID" in the right sidebar
4. Copy the Account ID

### 3. Add GitHub Secrets

Go to your repository Settings > Secrets and variables > Actions, add:

| Secret Name | Value |
|-------------|-------|
| `CLOUDFLARE_API_TOKEN` | Your API token from step 1 |
| `CLOUDFLARE_ACCOUNT_ID` | Your Account ID from step 2 |

### 4. Create Cloudflare Pages Project (First Time)

Run manually or let the first deployment create it:

```bash
npx wrangler pages project create openboot
```

### 5. Configure Custom Domain

1. Go to Cloudflare Dashboard > Pages > openboot
2. Click "Custom domains" tab
3. Add `openboot.dev`
4. Cloudflare will automatically configure DNS

## Deployment

Deployments happen automatically when:
- Push to `main` branch with changes in `website/` directory
- Manual trigger via "Run workflow" in GitHub Actions

## Manual Deployment

```bash
cd website
npx wrangler pages deploy . --project-name=openboot
```

## Directory Structure

```
website/
├── index.html      # Main page
├── _redirects      # Cloudflare Pages redirects
├── _headers        # Security headers
└── DEPLOY.md       # This file
```

## Redirects

The `/install` path redirects to the raw `boot.sh` script:

```
/install → https://raw.githubusercontent.com/fullstackjam/openboot/main/boot.sh
```

This enables:
```bash
curl -fsSL https://openboot.dev/install | bash
```
