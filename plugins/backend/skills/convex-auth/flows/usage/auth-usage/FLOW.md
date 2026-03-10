# Auth Patterns

## Get Current User

Use the `getCurrentUser` service with `useSuspenseQuery`:

```tsx
import { Suspense } from "react";
import { useSuspenseQuery } from "@tanstack/react-query";
import { Skeleton } from "@/components/ui/skeleton";
import { getCurrentUser } from "@/services/auth";

function UserGreeting() {
  const { data: user } = useSuspenseQuery(getCurrentUser());
  return <p>Hello, {user?.name ?? user?.email}</p>;
}

// Wrap with Suspense + Skeleton
<Suspense fallback={<Skeleton className="h-5 w-32" />}>
  <UserGreeting />
</Suspense>
```

## Sign Out

```ts
import { logout } from "@/services/auth";

<button onClick={() => logout()} type="button">Sign out</button>
```

`logout` calls `authClient.signOut` and reloads the page. The reload is required because `expectAuth: true` means authenticated queries may fire before the auth state clears.
