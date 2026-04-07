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
- Forms inside Dialogs must use `render` prop on `DialogContent` — see [Forms in Dialogs](#forms-in-dialogs)
- Forms inside Dialogs must reset on close — see [Form Reset](#form-reset)

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

## Forms in Dialogs

When a form lives inside a `DialogContent` or `AlertDialogContent`, use the `render` prop to make the dialog content render **as** the form. This ensures fields and footer inherit the dialog's grid layout (`gap-6`) instead of being nested inside a separate form element.

```tsx
// Correct — DialogContent renders as the form
<DialogContent render={<form.Root form={form} />}>
  <DialogHeader>
    <DialogTitle>Add Item</DialogTitle>
  </DialogHeader>
  <FieldGroup>
    <form.AppField name="name">
      {(field) => (
        <field.Root>
          <field.Label>Name</field.Label>
          <field.Control render={<Input />} />
          <field.ErrorMessage />
        </field.Root>
      )}
    </form.AppField>
  </FieldGroup>
  <DialogFooter>
    <form.Submit>Create</form.Submit>
  </DialogFooter>
</DialogContent>
```

```tsx
// Wrong — form.Root nested inside DialogContent breaks grid spacing
<DialogContent>
  <form.Root form={form}>
    ...
  </form.Root>
</DialogContent>
```

If the `render` prop is not viable (e.g. the form is a child of a non-polymorphic container), use `className="contents"` on `form.Root` so it doesn't generate its own CSS box and children participate directly in the parent's grid.

## Form Reset

Forms inside Dialogs **must** call `form.reset()` when the container closes. This prevents stale data and validation errors from persisting if the user reopens the modal.

- Call `form.reset()` in the `onOpenChange` callback of the Dialog
- Call `form.reset()` in the `onSubmit` handler after the async operation succeeds
- If a form has nested sub-forms (e.g. an OTP step inside a dialog), each sub-form must reset independently

```tsx
const form = useAppForm({
  defaultValues: { name: "" },
  validators: { onSubmit: schema },
  onSubmit: async ({ value }) => {
    await createItem(value);
    form.reset();
    setOpen(false);
  },
});

<Dialog
  open={open}
  onOpenChange={(isOpen) => {
    if (!isOpen) form.reset();
    setOpen(isOpen);
  }}
>
  <DialogContent render={<form.Root form={form} />}>
    ...
  </DialogContent>
</Dialog>
```

**Do NOT reset** forms that persist on the page (e.g. settings cards, inline edit forms) — reset only applies when the form's container is unmounted or hidden.

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
- [ ] Dialog forms use `render={<form.Root />}` on `DialogContent`/`AlertDialogContent`
- [ ] Dialog forms call `form.reset()` on close via `onOpenChange`
- [ ] Nested sub-forms inside modals also reset independently
