# Convex Environment Variables

Configure and propagate environment variables to the Convex local backend.

## Step 1: Add variables to env files

Add the variable to `.env.local` and `.env.example`:

```
MY_VAR=my-value
```

Secrets use a dev-safe default (e.g., `better-auth-local-secret`). Production values are set in the deployment environment, not here.

## Step 2: Update scripts/setup.ts

Add the variable name to the `envVars` array so `make setup` propagates it to Convex:

```ts
const envVars = ["SITE_URL", "MY_VAR"];
```

## Step 3: Run make setup

```bash
make setup
```

This starts the local Convex backend, pushes the env vars, seeds the database, and stops the backend.

## Acceptance checklist

- [ ] Variable added to `.env.local` and `.env.example`
- [ ] Variable name added to `envVars` array in `scripts/setup.ts`
- [ ] `make setup` ran successfully
