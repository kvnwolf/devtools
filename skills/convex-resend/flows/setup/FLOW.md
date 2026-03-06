# Resend Setup

Add transactional email sending to a Convex project using the `@convex-dev/resend` component.

## Prerequisite: Confirm and collect API key

Ask the user: **"Do you want to configure Resend for sending emails locally? This requires a Resend API key."**

- If **no** → stop here, do not continue with this flow.
- If **yes** → ask the user for their `RESEND_API_KEY` value, then follow the `convex` skill's `flows/env-vars/FLOW.md` to add `RESEND_API_KEY=<value>`.

## Step 1: Install dependencies

```bash
bun add @convex-dev/resend
```

For React Email templates, also install:

```bash
bun add @react-email/render react-email
```

## Step 2: Register the component

Add Resend to `convex/convex.config.ts`:

```ts
import resend from "@convex-dev/resend/convex.config";

const app = defineApp();
app.use(resend);
```

If `convex.config.ts` already exists, just add `app.use(resend)`.

## Step 3: Create the Resend client

Create `convex/email.ts`:

```ts
import { Resend } from "@convex-dev/resend";
import { components } from "./_generated/api";

export const resend = new Resend(components.resend, {
  testMode: false,
});
```

`testMode` defaults to `true`, which only allows Resend test addresses (`delivered@resend.dev`, `bounced@resend.dev`, `complained@resend.dev`). Set to `false` for production use.

If `convex/email.ts` already exists (e.g., from email OTP setup), add the Resend instance alongside existing exports and update the `sendOtp` action to use it instead of the console stub.

## Acceptance checklist

- [ ] `@convex-dev/resend` installed
- [ ] Component registered in `convex/convex.config.ts`
- [ ] `RESEND_API_KEY` env var set, added to `.env.example` and `scripts/setup.ts`
- [ ] `convex/email.ts` exports the Resend instance
