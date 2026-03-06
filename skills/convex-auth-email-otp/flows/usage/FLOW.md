# Email OTP API Patterns

## Sign In

```ts
await authClient.emailOtp.sendVerificationOtp({ email, type: "sign-in" });
await authClient.signIn.emailOtp({ email, otp });
```

`signIn.emailOtp` automatically registers unregistered users unless `disableSignUp: true` is set in the plugin options.

## Email Verification

```ts
await authClient.emailOtp.sendVerificationOtp({ email, type: "email-verification" });
await authClient.emailOtp.verifyEmail({ email, otp });
```

## Password Reset

```ts
await authClient.emailOtp.requestPasswordReset({ email });
await authClient.emailOtp.resetPassword({ email, otp, password: newPassword });
```

## Configuration Options

```ts
emailOTP({
  otpLength: 6,                   // OTP digit count (default: 6)
  expiresIn: 300,                 // Expiry in seconds (default: 300)
  sendVerificationOnSignUp: false, // Auto-send OTP after registration
  disableSignUp: false,           // Prevent auto-registration on sign-in
  allowedAttempts: 3,             // Max verification attempts before error
  sendVerificationOTP: async ({ email, otp, type }) => {
    // Required — deliver the OTP to the user
  },
})
```

Exceeding `allowedAttempts` returns a `TOO_MANY_ATTEMPTS` error.
