# Resend Email Patterns

## Sending from a Mutation

`sendEmail` accepts `RunMutationCtx` — call it directly from mutations. The component enqueues the email transactionally and handles batching, retries, and rate limiting automatically.

```ts
import { z } from "zod";
import { zim } from "./utils";
import { resend } from "./email";

export const sendWelcomeEmail = zim({
  args: { email: z.string().email(), name: z.string() },
  handler: async (ctx, { email, name }) => {
    await resend.sendEmail(ctx, {
      from: "App <no-reply@example.com>",
      to: email,
      subject: `Welcome, ${name}!`,
      html: `<h1>Welcome, ${name}!</h1><p>Thanks for signing up.</p>`,
    });
  },
});
```

## Sending from an Action

Actions don't have `RunMutationCtx`. Use `sendEmailManually` for direct SDK access:

```ts
import { Resend as ResendSdk } from "resend";
import { zia } from "./utils";
import { resend } from "./email";

export const sendWithTags = zia({
  args: { to: z.string().email(), subject: z.string(), html: z.string() },
  handler: async (ctx, args) => {
    const sdk = new ResendSdk(String(process.env.RESEND_API_KEY));

    await resend.sendEmailManually(
      ctx,
      { from: "App <no-reply@example.com>", to: args.to, subject: args.subject },
      async (emailId) => {
        const { data, error } = await sdk.emails.send({
          from: "App <no-reply@example.com>",
          to: [args.to],
          subject: args.subject,
          html: args.html,
          headers: { "Idempotency-Key": emailId },
          tags: [{ name: "category", value: "transactional" }],
        });
        if (error) throw new Error(error.message);
        return data!.id!;
      },
    );
  },
});
```

Use `sendEmailManually` only when you need features the batch API doesn't support (tags, custom headers). For standard emails, prefer `sendEmail`.

## With Templates

```ts
await resend.sendEmail(ctx, {
  from: "App <no-reply@example.com>",
  to: "user@example.com",
  template: {
    id: "my-template-id",
    variables: { PRODUCT: "Pro Plan", PRICE: 29 },
  },
});
```

## With React Email

React Email requires the Node.js runtime. Use `"use node"` and `internalAction`:

```ts
"use node";

import { render } from "@react-email/render";
import { z } from "zod";
import { internalAction } from "./_generated/server";
import { resend } from "./email";
import { WelcomeEmail } from "../components/emails/welcome";

export const sendWelcomeEmail = internalAction({
  args: { to: { type: "string" }, name: { type: "string" } },
  handler: async (ctx, { to, name }) => {
    const html = await render(WelcomeEmail({ name }));

    await resend.sendEmail(ctx, {
      from: "App <no-reply@example.com>",
      to,
      subject: "Welcome!",
      html,
    });
  },
});
```

React Email actions bypass zodvex builders because `"use node"` files need direct `internalAction` from `_generated/server`.

## sendEmail Options

```ts
await resend.sendEmail(ctx, {
  from: "Name <email@domain.com>",   // required
  to: "user@example.com",            // string or string[]
  subject: "Subject line",           // required (unless using template)
  html: "<p>HTML body</p>",          // optional
  text: "Plain text body",           // optional
  cc: "cc@example.com",              // string or string[]
  bcc: ["bcc@example.com"],          // string or string[]
  replyTo: ["reply@example.com"],    // string[]
  headers: [{ name: "X-Custom", value: "val" }],
});
```

## Email Status Tracking

`sendEmail` returns an `EmailId` for tracking:

```ts
const emailId = await resend.sendEmail(ctx, { /* ... */ });

// Check status later
const status = await resend.status(ctx, emailId);
// status.status: "waiting" | "queued" | "cancelled" | "sent" | "bounced" | "delivered" | "delivery_delayed"

// Get full email details
const email = await resend.get(ctx, emailId);

// Cancel a pending email
await resend.cancelEmail(ctx, emailId);
```

## Webhooks

### 1. Create the HTTP route

In `convex/http.ts`:

```ts
import { httpAction } from "./_generated/server";
import { resend } from "./email";

http.route({
  path: "/resend-webhook",
  method: "POST",
  handler: httpAction(async (ctx, req) => {
    return await resend.handleResendEventWebhook(ctx, req);
  }),
});
```

### 2. Configure the webhook in Resend

Point it to `https://<project>.convex.site/resend-webhook` and set the `RESEND_WEBHOOK_SECRET` env var.

### 3. Handle events (optional)

Pass `onEmailEvent` when creating the Resend instance:

```ts
import { Resend, vOnEmailEventArgs } from "@convex-dev/resend";
import { components, internal } from "./_generated/api";
import { internalMutation } from "./_generated/server";

export const resend = new Resend(components.resend, {
  testMode: false,
  onEmailEvent: internal.resend.handleEmailEvent,
});

export const handleEmailEvent = internalMutation({
  args: vOnEmailEventArgs,
  handler: async (ctx, { id, event }) => {
    console.log(`Email ${id}: ${event.type}`);
    // event.type: "email.delivered" | "email.bounced" | "email.complained" |
    //             "email.delivery_delayed" | "email.opened" | "email.clicked"
  },
});
```

## Data Cleanup

Set up a cron job to remove old email records:

```ts
// convex/crons.ts
import { cronJobs } from "convex/server";
import { components, internal } from "./_generated/api";
import { internalMutation } from "./_generated/server";

const crons = cronJobs();

const ONE_WEEK_MS = 7 * 24 * 60 * 60 * 1000;

export const cleanupResend = internalMutation({
  handler: async (ctx) => {
    await ctx.scheduler.runAfter(0, components.resend.lib.cleanupOldEmails, {
      olderThan: ONE_WEEK_MS,
    });
    await ctx.scheduler.runAfter(0, components.resend.lib.cleanupAbandonedEmails, {
      olderThan: ONE_WEEK_MS,
    });
  },
});

crons.interval("Cleanup old resend emails", { hours: 1 }, internal.crons.cleanupResend);

export default crons;
```

## Testing

Mock `@convex-dev/resend` with `vi.mock`. Create the spy **before** the mock so it's available inside the mock factory:

```ts
import { convexTest } from "convex-test";
import { describe, expect, test, vi } from "vitest";
import { internal } from "./_generated/api";
import schema from "./schema";

const sendEmailSpy = vi.fn();

vi.mock("@convex-dev/resend", () => ({
  Resend: class MockResend {
    sendEmail = sendEmailSpy;
  },
}));

const modules = import.meta.glob("./**/*.ts");

describe("sendOtp", () => {
  test("rejects invalid email via Zod validation", async () => {
    const t = convexTest(schema, modules);
    await expect(
      t.action(internal.email.sendOtp, {
        email: "not-an-email",
        otp: "123456",
        subject: "Sign in code",
      })
    ).rejects.toThrow();
  });

  test("calls resend.sendEmail with correct arguments", async () => {
    const t = convexTest(schema, modules);
    sendEmailSpy.mockResolvedValue(undefined);

    await t.action(internal.email.sendOtp, {
      email: "test@example.com",
      otp: "123456",
      subject: "Sign in code",
    });

    expect(sendEmailSpy).toHaveBeenCalledOnce();
    const [, options] = sendEmailSpy.mock.calls[0];
    expect(options.from).toBe("App <no-reply@example.com>");
    expect(options.to).toBe("test@example.com");
    expect(options.subject).toBe("Sign in code");
    expect(options.html).toContain("123456");
  });
});
```

Key points:
- The mock replaces the `Resend` class so `new Resend(...)` returns an instance with the spied `sendEmail`
- `sendEmail` receives `(ctx, options)` — assert on the second element of `mock.calls[0]`
- Test Zod validation separately by passing invalid input

## Quick Reference

| Task | Pattern |
|------|---------|
| Send from mutation | `resend.sendEmail(ctx, { from, to, subject, html })` |
| Send with template | `resend.sendEmail(ctx, { from, to, template: { id, variables } })` |
| Send with SDK features | `resend.sendEmailManually(ctx, opts, async (emailId) => { ... })` |
| Check delivery status | `resend.status(ctx, emailId)` |
| Get full email record | `resend.get(ctx, emailId)` |
| Cancel pending email | `resend.cancelEmail(ctx, emailId)` |
| Handle webhook events | `resend.handleResendEventWebhook(ctx, req)` |
| React to events | `onEmailEvent: internal.module.handler` in constructor |
| Clean up old records | `components.resend.lib.cleanupOldEmails({ olderThan })` |
