---
name: tanstack-form
description: Builds type-safe, accessible forms with TanStack Form, Base UI Field, and the useAppForm hook. Use when creating forms, adding validation, handling form submission, or working with form fields and form state management.
---

# TanStack Form

TanStack Form with Base UI Field for accessible, type-safe forms. The `useAppForm` hook (from `@/components/form`) provides pre-configured form and field components integrated with shadcn's Button and Label.

## Conventions

- Always use `useAppForm` — never raw TanStack Form hooks
- Validate with Zod schemas via `validators.onSubmit`
- Use `field.Control` with `render` prop to bind UI components
- Every field needs `field.Root`, `field.Label`, `field.Control`, and `field.ErrorMessage`

```tsx
import { z } from "zod";
import { useAppForm } from "@/components/form";
```

## Form API

| Component | Use |
|-----------|-----|
| `form.Root` | Wrapper — provides form context, handles submit |
| `form.AppField` | Creates a field with access to field sub-components |
| `form.Submit` | Submit button — auto-disables when pristine/invalid/submitting |
| `form.Subscribe` | Subscribe to form state for custom rendering |

## Field API

All components available inside `form.AppField` render callback:

| Component | Use |
|-----------|-----|
| `field.Root` | Wraps field, connects `aria-invalid` and `aria-describedby` |
| `field.Label` | Label — auto-connects to input via `for`/`id` |
| `field.Control` | Input wrapper — handles value/onChange binding |
| `field.ErrorMessage` | Shows validation errors |

## Polymorphic Fields

`render` prop customizes the underlying element while keeping form state binding:

```tsx
<field.Root render={<InputGroup.Root />}>
  <field.Control render={<InputGroup.Input placeholder="Email" />} />
</field.Root>
```

## Programmatic Control

| API | Use |
|-----|-----|
| `form.reset()` | Reset to default values |
| `form.setFieldValue("name", value)` | Set field value |
| `form.state.values` | Get current values |
| `form.validate()` | Trigger validation |

## Accessibility

Base UI Field automatically handles — no manual wiring needed:

- `aria-invalid` on invalid fields
- `aria-describedby` linking inputs to error messages
- `for`/`id` linking labels to inputs
- Disabled state during submission

## Examples

See `examples/` for complete form examples by pattern:

| Example | When to use |
|---------|-------------|
| `examples/basic-form.md` | Simple form with validation and submission |
| `examples/polymorphic-fields.md` | Custom UI components with `render` prop |

## Acceptance Checklist

- [ ] Uses `useAppForm` from `@/components/form`
- [ ] Validates with Zod schema via `validators.onSubmit`
- [ ] Every field has `Root`, `Label`, `Control`, `ErrorMessage`
- [ ] Uses `form.Root` as wrapper, `form.Submit` for submit button
- [ ] Polymorphic fields use `render` prop, not manual binding
