# Basic Form

Simple form with Zod validation and submission handler.

```tsx
import { z } from "zod";
import { useAppForm } from "@/components/form";
import { Input } from "@/components/ui/input";

function ContactForm() {
  const form = useAppForm({
    defaultValues: {
      email: "",
      name: "",
    },
    validators: {
      onSubmit: z.object({
        email: z.string().email("Invalid email"),
        name: z.string().min(2, "Name too short"),
      }),
    },
    onSubmit: ({ value }) => {
      console.log(value);
    },
  });

  return (
    <form.Root form={form}>
      <form.AppField name="name">
        {(field) => (
          <field.Root>
            <field.Label>Name</field.Label>
            <field.Control render={<Input />} />
            <field.ErrorMessage />
          </field.Root>
        )}
      </form.AppField>
      <form.AppField name="email">
        {(field) => (
          <field.Root>
            <field.Label>Email</field.Label>
            <field.Control render={<Input />} />
            <field.ErrorMessage />
          </field.Root>
        )}
      </form.AppField>
      <form.Submit>Submit</form.Submit>
    </form.Root>
  );
}
```
