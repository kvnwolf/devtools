# Polymorphic Fields

Using `render` prop to integrate custom UI components with form state binding.

```tsx
import { z } from "zod";
import { useAppForm } from "@/components/form";
import { InputGroup } from "@/components/ui/input-group";
import { Textarea } from "@/components/ui/textarea";

function FeedbackForm() {
  const form = useAppForm({
    defaultValues: {
      email: "",
      message: "",
    },
    validators: {
      onSubmit: z.object({
        email: z.string().email("Invalid email"),
        message: z.string().min(10, "Message too short"),
      }),
    },
    onSubmit: ({ value }) => {
      console.log(value);
    },
  });

  return (
    <form.Root form={form}>
      <form.AppField name="email">
        {(field) => (
          <field.Root render={<InputGroup.Root />}>
            <field.Label>Email</field.Label>
            <field.Control render={<InputGroup.Input placeholder="you@example.com" />} />
            <field.ErrorMessage />
          </field.Root>
        )}
      </form.AppField>
      <form.AppField name="message">
        {(field) => (
          <field.Root>
            <field.Label>Message</field.Label>
            <field.Control render={<Textarea rows={4} />} />
            <field.ErrorMessage />
          </field.Root>
        )}
      </form.AppField>
      <form.Submit>Send Feedback</form.Submit>
    </form.Root>
  );
}
```
