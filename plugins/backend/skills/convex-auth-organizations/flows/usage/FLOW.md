# Organization API Patterns

## Organizations

```ts
await authClient.organization.create({ name: "Acme", slug: "acme" });
await authClient.organization.update({ data: { name: "Acme Inc." } });
await authClient.organization.delete({ organizationId: "org-id" });

const { data: orgs } = await authClient.organization.list({});
await authClient.organization.setActive({ organizationId: "org-id" });
```

## Members

```ts
const { data: members } = await authClient.organization.listMembers({});
await authClient.organization.updateMemberRole({ memberId: "m-id", role: "admin" });
await authClient.organization.removeMember({ memberIdOrEmail: "user@example.com" });
await authClient.organization.leave({ organizationId: "org-id" });
```

## Invitations

```ts
await authClient.organization.inviteMember({ email: "user@example.com", role: "member" });
await authClient.organization.acceptInvitation({ invitationId: "inv-id" });
await authClient.organization.rejectInvitation({ invitationId: "inv-id" });
await authClient.organization.cancelInvitation({ invitationId: "inv-id" });
const { data: invitations } = await authClient.organization.listInvitations({});
```

## React Hooks

```ts
const { data: activeOrg } = authClient.useActiveOrganization();
const { data: orgs } = authClient.useListOrganizations();
```

## Access Control

### Default roles

| Role | Permissions |
|------|------------|
| owner | Full control, can delete organization |
| admin | Full control except delete organization and change owner |
| member | Read-only |

### Custom roles and permissions

Define a permission statement and create roles:

```ts
// convex/permissions.ts
import { createAccessControl } from "better-auth/plugins/access";

const statement = {
  project: ["create", "read", "update", "delete"],
  organization: ["update", "delete"],
} as const;

export const ac = createAccessControl(statement);

export const roles = {
  owner: ac.newRole({
    project: ["create", "read", "update", "delete"],
    organization: ["update", "delete"],
  }),
  admin: ac.newRole({
    project: ["create", "read", "update"],
    organization: ["update"],
  }),
  member: ac.newRole({
    project: ["read"],
  }),
};
```

Register on the server:

```ts
import { ac, roles } from "./permissions";

organization({ ac, roles }),
```

Register on the client:

```ts
import { ac, roles } from "@convex/permissions";

organizationClient({ ac, roles }),
```

### Check permissions

```ts
const { data: allowed } = await authClient.organization.hasPermission({
  permissions: { project: ["create"] },
});
```
