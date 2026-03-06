# Compound Components

Testing composed multi-part components as users see them.

```tsx
import { render } from "vitest-browser-react";
import { page } from "vitest/browser";
import { describe, expect, test } from "vitest";
import { Accordion, AccordionItem, AccordionTrigger, AccordionContent } from "./accordion";

describe("Accordion", () => {
  test("renders all items collapsed by default", async () => {
    await render(
      <Accordion>
        <AccordionItem value="faq-1">
          <AccordionTrigger>What is this?</AccordionTrigger>
          <AccordionContent>An accordion component.</AccordionContent>
        </AccordionItem>
        <AccordionItem value="faq-2">
          <AccordionTrigger>How does it work?</AccordionTrigger>
          <AccordionContent>Click to expand.</AccordionContent>
        </AccordionItem>
      </Accordion>
    );

    await expect.element(page.getByText("What is this?")).toBeInTheDocument();
    await expect.element(page.getByText("An accordion component.")).not.toBeVisible();
  });

  test("expands item on trigger click", async () => {
    await render(
      <Accordion>
        <AccordionItem value="faq-1">
          <AccordionTrigger>What is this?</AccordionTrigger>
          <AccordionContent>An accordion component.</AccordionContent>
        </AccordionItem>
      </Accordion>
    );

    await page.getByText("What is this?").click();
    await expect.element(page.getByText("An accordion component.")).toBeVisible();
  });
});
```
