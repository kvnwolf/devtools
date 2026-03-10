# Cookies — GET/POST with getCookie/setCookie

## Server function

```ts
// src/lib/theme.ts
import { createServerFn } from "@tanstack/react-start";
import { getCookie, setCookie } from "@tanstack/react-start/server";
import { z } from "zod";

const STORAGE_KEY = "app-theme";

export const THEME_VALUES = ["light", "dark", "auto"] as const;
export const themeSchema = z.enum(THEME_VALUES);

export const getTheme = createServerFn().handler(() => {
  return themeSchema.parse(getCookie(STORAGE_KEY) ?? "auto");
});

export const setTheme = createServerFn()
  .inputValidator(themeSchema)
  .handler(({ data }) => setCookie(STORAGE_KEY, data));
```

## Test

```ts
// src/lib/theme.test.ts
import { afterEach, describe, expect, test, vi } from "vitest";

const mockGetCookie = vi.fn<(name: string) => string | undefined>();
const mockSetCookie = vi.fn<(name: string, value: string) => void>();

vi.mock("@tanstack/react-start/server", () => ({
  getCookie: (...args: Parameters<typeof mockGetCookie>) => mockGetCookie(...args),
  setCookie: (...args: Parameters<typeof mockSetCookie>) => mockSetCookie(...args),
}));

const { getTheme, setTheme, themeSchema } = await import("./theme");

afterEach(() => {
  vi.clearAllMocks();
});

describe("themeSchema", () => {
  test.each(["light", "dark", "auto"] as const)('accepts "%s"', (value) => {
    expect(themeSchema.parse(value)).toBe(value);
  });

  test.each(["purple", "", "system", 42])('rejects "%s"', (value) => {
    expect(() => themeSchema.parse(value)).toThrow();
  });
});

describe("getTheme", () => {
  test("returns the theme from the cookie", () => {
    mockGetCookie.mockReturnValue("dark");
    expect(getTheme()).toBe("dark");
  });

  test('defaults to "auto" when no cookie exists', () => {
    mockGetCookie.mockReturnValue(undefined);
    expect(getTheme()).toBe("auto");
  });

  test("throws when cookie has an invalid value", () => {
    mockGetCookie.mockReturnValue("purple");
    expect(() => getTheme()).toThrow();
  });
});

describe("setTheme", () => {
  test.each(["light", "dark", "auto"] as const)('sets cookie to "%s"', (value) => {
    setTheme({ data: value });
    expect(mockSetCookie).toHaveBeenCalledWith("app-theme", value);
  });

  test("rejects invalid theme values", () => {
    expect(() => setTheme({ data: "purple" as never })).toThrow();
    expect(mockSetCookie).not.toHaveBeenCalled();
  });
});
```

## Key patterns

- Mock `@tanstack/react-start/server` — external boundary
- Test default fallback when cookie is missing
- Test that invalid cookie values throw (defense against tampered cookies)
- Test that `inputValidator` rejects bad input before handler runs
