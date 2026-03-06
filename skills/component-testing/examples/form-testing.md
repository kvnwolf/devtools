# Form Testing

Testing form inputs, submission, and validation.

```tsx
import { render } from "vitest-browser-react";
import { page } from "vitest/browser";
import { describe, expect, test, vi } from "vitest";
import { LoginForm } from "./login-form";

describe("LoginForm", () => {
  test("submits form with user input", async () => {
    const onSubmit = vi.fn();
    await render(<LoginForm onSubmit={onSubmit} />);

    await page.getByLabelText("Email").fill("alice@test.com");
    await page.getByLabelText("Password").fill("secret123");
    await page.getByRole("button", { name: "Sign in" }).click();

    expect(onSubmit).toHaveBeenCalledWith({
      email: "alice@test.com",
      password: "secret123",
    });
  });

  test("shows error for invalid email", async () => {
    await render(<LoginForm onSubmit={vi.fn()} />);

    await page.getByLabelText("Email").fill("not-an-email");
    await page.getByRole("button", { name: "Sign in" }).click();

    await expect.element(page.getByText("Invalid email address")).toBeInTheDocument();
  });

  test("disables submit while loading", async () => {
    await render(<LoginForm onSubmit={vi.fn()} loading />);

    await expect.element(page.getByRole("button", { name: "Sign in" })).toBeDisabled();
  });
});
```
