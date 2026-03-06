# Email OTP Plugin Setup

Add the Better Auth email OTP plugin for passwordless sign-in, email verification, and password reset via one-time codes.

## Step 1: Add the email OTP plugin to the server

Update `convex/auth.ts` — add `emailOTP` to the plugins array inside `createAuthOptions` (or `createAuth` if not using local install):

```ts
import { emailOTP } from "better-auth/plugins";
import { requireActionCtx } from "@convex-dev/better-auth/utils";

export function createAuthOptions(ctx: GenericCtx<DataModel>) {
  return {
    baseURL: String(process.env.SITE_URL),
    database: authComponent.adapter(ctx),
    plugins: [
      convex({ authConfig }),
      emailOTP({
        async sendVerificationOTP({ email, otp, type }) {
          const actionCtx = requireActionCtx(ctx);
          const subjects = {
            "sign-in": "Sign in code",
            "email-verification": "Verify your email",
            "forget-password": "Reset your password",
          } as const;
          if (!process.env.RESEND_API_KEY) {
            console.log(`[OTP] ${email}: ${otp}`);
            return;
          }
          await actionCtx.runAction(internal.email.sendOtp, {
            email,
            otp,
            subject: subjects[type],
          });
        },
      }),
    ],
  } satisfies BetterAuthOptions;
}
```

Key details:
- `requireActionCtx(ctx)` narrows the `GenericCtx` union to an action context with `runAction`. Must be called **inside** the callback, not at the top of `createAuthOptions` — Better Auth calls the function with an empty context during module analysis to extract `basePath`.
- The `RESEND_API_KEY` check provides a console fallback for local development without an email provider. The OTP is persisted in the database before this callback runs.

## Step 2: Create convex/email.ts

Stub action referenced in step 1. Replace with a real email provider (see `resend` skill):

```ts
import { z } from "zod";
import { zia } from "./utils";

export const sendOtp = zia({
  args: {
    email: z.string().email(),
    otp: z.string(),
    subject: z.string(),
  },
  handler: async (ctx, { email, otp, subject }) => {
    console.log(`[EMAIL] To: ${email} | Subject: ${subject} | OTP: ${otp}`);
  },
});
```

## Step 3: Add the email OTP plugin to the client

Update `src/lib/auth-client.ts`:

```ts
import { convexClient } from "@convex-dev/better-auth/client/plugins";
import { emailOTPClient } from "better-auth/client/plugins";
import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient({
  plugins: [convexClient(), emailOTPClient()],
});
```

## Step 4: Install shadcn components

```bash
bunx shadcn@latest add input input-otp
```

## Step 5: Update the login page

Add `OtpLoginEmail` and `OtpLoginCode` components to `src/routes/login.tsx`. Place `<OtpLoginEmail />` inside the `CardContent` fallback (the `<>` fragment). The flow uses `LoginContext` to transition between email entry and OTP verification:

```tsx
import { useNavigate } from "@tanstack/react-router";
import { REGEXP_ONLY_DIGITS } from "input-otp";
import { use, useEffect, useState, useTransition } from "react";
import { z } from "zod";
import { useAppForm } from "@/components/form";
import { Button } from "@/components/ui/button";
import { Field, FieldGroup } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { InputOTP, InputOTPGroup, InputOTPSlot } from "@/components/ui/input-otp";
import { authClient } from "@/lib/auth-client";
import { LoginContext } from "./login";

function OtpLoginEmail() {
  const { setTitle, setDescription, setContent } = use(LoginContext);

  const form = useAppForm({
    defaultValues: { email: "" },
    validators: {
      onSubmit: z.object({
        email: z.string().email("Enter a valid email"),
      }),
    },
    onSubmit: async ({ value }) => {
      await authClient.emailOtp.sendVerificationOtp({ email: value.email, type: "sign-in" });
      setTitle("Verify your email");
      setDescription(
        <>
          We sent a verification code to{" "}
          <span className="font-medium text-foreground">{value.email}</span>
        </>
      );
      setContent(<OtpLoginCode email={value.email} />);
    },
  });

  return (
    <form.Root className="contents" form={form}>
      <FieldGroup>
        <form.AppField name="email">
          {(field) => (
            <field.Root>
              <field.Label>Email</field.Label>
              <field.Control
                render={<Input autoFocus placeholder="you@example.com" type="email" />}
              />
              <field.ErrorMessage />
            </field.Root>
          )}
        </form.AppField>
        <form.Submit>Continue</form.Submit>
      </FieldGroup>
    </form.Root>
  );
}

function OtpLoginCode({ email }: { email: string }) {
  const RESEND_COOLDOWN = 30;
  const navigate = useNavigate();
  const { setTitle, setDescription, setContent } = use(LoginContext);
  const [countdown, setCountdown] = useState(RESEND_COOLDOWN);
  const [isSendingCode, startSendingCode] = useTransition();

  useEffect(() => {
    if (countdown <= 0) {
      return;
    }
    const timer = setTimeout(() => setCountdown((c) => c - 1), 1000);
    return () => clearTimeout(timer);
  }, [countdown]);

  function sendOtp() {
    startSendingCode(async () => {
      await authClient.emailOtp.sendVerificationOtp({ email, type: "sign-in" });
      setCountdown(RESEND_COOLDOWN);
    });
  }

  function goBack() {
    setTitle(undefined);
    setDescription(undefined);
    setContent(undefined);
  }

  const form = useAppForm({
    defaultValues: { otp: "" },
    onSubmit: async ({ value, formApi }) => {
      const result = await authClient.signIn.emailOtp({ email, otp: value.otp });
      if (result.error) {
        formApi.setFieldMeta("otp", (prev) => ({
          ...prev,
          isTouched: true,
          errorMap: {
            ...prev.errorMap,
            onSubmit: { message: result.error?.message ?? "Invalid code" },
          },
        }));
        return;
      }
      await navigate({ to: "/" });
    },
  });

  return (
    <form.Root className="contents" form={form}>
      <FieldGroup>
        <form.AppField name="otp">
          {(field) => (
            <field.Root>
              <field.Control
                render={
                  <InputOTP
                    autoFocus
                    containerClassName="justify-center"
                    maxLength={6}
                    onComplete={(value) => {
                      field.setValue(value);
                      form.handleSubmit();
                    }}
                    pattern={REGEXP_ONLY_DIGITS}
                  >
                    <InputOTPGroup>
                      <InputOTPSlot index={0} />
                      <InputOTPSlot index={1} />
                      <InputOTPSlot index={2} />
                      <InputOTPSlot index={3} />
                      <InputOTPSlot index={4} />
                      <InputOTPSlot index={5} />
                    </InputOTPGroup>
                  </InputOTP>
                }
              />
              <field.ErrorMessage />
            </field.Root>
          )}
        </form.AppField>
        <Field>
          <Button
            disabled={countdown > 0 || isSendingCode}
            onClick={sendOtp}
            type="button"
            variant="secondary"
          >
            {countdown > 0 ? `Resend code in ${countdown}s` : "Resend code"}
          </Button>
          <Button onClick={goBack} type="button" variant="outline">
            Use a different email
          </Button>
        </Field>
      </FieldGroup>
    </form.Root>
  );
}
```

If other auth method components already exist in the `CardContent`, add `<OtpLoginEmail />` alongside them.

`signIn.emailOtp` automatically registers unregistered users unless `disableSignUp: true` is set in the plugin options.

## Step 6: Create convex/e2e.ts

Internal action to read OTP codes from Better Auth's `verification` table for E2E tests:

```ts
import { z } from "zod";
import { components } from "./_generated/api";
import { zia } from "./utils";

export const getLatestOtp = zia({
  args: {
    email: z.string(),
  },
  handler: async (ctx, { email }) => {
    const results = await ctx.runQuery(
      components.betterAuth.adapter.findMany,
      {
        model: "verification",
        where: [{ field: "identifier", value: email }],
        sortBy: { field: "createdAt", direction: "desc" },
        limit: 1,
      }
    );

    if (!results || results.length === 0) {
      return null;
    }

    return results[0].value;
  },
});
```

## Step 7: Add getOtp helper to e2e/utils.ts

Add to the existing `e2e/utils.ts`. Reads OTP codes from Convex via `npx convex run`:

```ts
import { execSync } from "node:child_process";

export function getOtp(email: string): string {
  for (let attempt = 0; attempt < 20; attempt++) {
    try {
      const output = execSync(
        `npx convex run e2e:getLatestOtp '{"email":"${email}"}'`,
        {
          encoding: "utf-8",
          stdio: ["pipe", "pipe", "pipe"],
          timeout: 10_000,
        }
      ).trim();

      if (!output) {
        execSync("sleep 1");
        continue;
      }

      const result = JSON.parse(output);
      if (result) {
        return result;
      }
    } catch {
      // Command failed or JSON parse failed — retry
    }

    execSync("sleep 1");
  }

  throw new Error(`Could not get OTP for ${email}`);
}
```

Key details:
- `npx convex run` returns nothing (not `"null"`) when a Convex function returns `null`
- `stdio: ["pipe", "pipe", "pipe"]` suppresses stderr from polluting test output
- 20 retries with 1s intervals — OTP creation involves async Better Auth callback → Convex action

## Step 8: Create e2e/login.spec.ts

```ts
import { expect } from "@playwright/test";
import { getOtp, test } from "./utils";
import user from "./seeds/user.json" with { type: "json" };

test.describe("login", () => {
  test("shows login page with email form", async ({ page }) => {
    await page.goto("/login");
    await expect(page.getByRole("heading")).toBeVisible();
    await expect(page.getByLabel("Email")).toBeVisible();
    await expect(page.getByRole("button", { name: "Continue" })).toBeVisible();
  });

  test("validates invalid email", async ({ page }) => {
    await page.goto("/login");

    await page.getByLabel("Email").fill("not-an-email");
    await page.getByRole("button", { name: "Continue" }).click();

    await expect(page.getByText("Enter a valid email")).toBeVisible();
  });

  test("submitting email transitions to OTP screen", async ({ page }) => {
    await page.goto("/login");

    await page.getByLabel("Email").fill(user.email);
    await page.getByRole("button", { name: "Continue" }).click();

    await expect(page.getByText("Verify your email")).toBeVisible();
    await expect(page.getByText("We sent a verification code to")).toBeVisible();
  });

  test("'Use a different email' goes back to email form", async ({ page }) => {
    await page.goto("/login");

    await page.getByLabel("Email").fill(user.email);
    await page.getByRole("button", { name: "Continue" }).click();
    await expect(page.getByText("Verify your email")).toBeVisible();

    await page.getByRole("button", { name: "Use a different email" }).click();
    await expect(page.getByLabel("Email")).toBeVisible();
  });

  test("resend code button is disabled during countdown", async ({ page }) => {
    await page.goto("/login");

    await page.getByLabel("Email").fill(user.email);
    await page.getByRole("button", { name: "Continue" }).click();
    await expect(page.getByText("Verify your email")).toBeVisible();

    const resendButton = page.getByRole("button", { name: "Resend code" });
    await expect(resendButton).toBeDisabled();
    await expect(resendButton).toContainText("Resend code in");
  });

  test("invalid OTP shows error", async ({ page }) => {
    await page.goto("/login");

    await page.getByLabel("Email").fill(user.email);
    await page.getByRole("button", { name: "Continue" }).click();
    await expect(page.getByText("Verify your email")).toBeVisible();

    const otpInput = page.locator("input[data-input-otp]");
    await otpInput.pressSequentially("000000");

    await expect(page.getByText("Invalid code")).toBeVisible();
  });

  test("successful login redirects to /", async ({ page }) => {
    await page.goto("/login");

    await page.getByLabel("Email").fill(user.email);
    await page.getByRole("button", { name: "Continue" }).click();
    await expect(page.getByText("Verify your email")).toBeVisible();

    const otp = getOtp(user.email);
    const otpInput = page.locator("input[data-input-otp]");
    await otpInput.pressSequentially(otp);

    await expect(page).toHaveURL("/");
  });
});
```

## Acceptance checklist

- [ ] `emailOTP` plugin added to `createAuthOptions` in `convex/auth.ts`
- [ ] `convex/email.ts` stub action created
- [ ] `emailOTPClient()` added to `src/lib/auth-client.ts`
- [ ] shadcn `input` and `input-otp` components installed
- [ ] Login page updated with `OtpLoginEmail` and `OtpLoginCode` components
- [ ] `convex/e2e.ts` with `getLatestOtp` created
- [ ] `getOtp` helper added to `e2e/utils.ts`
- [ ] `e2e/login.spec.ts` created
