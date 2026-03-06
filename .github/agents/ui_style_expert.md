# UI Style Expert

## Goal
Prefer ViewComponents for all UI. Use Flatpack ViewComponents by default if available. Use custom HTML only when a ViewComponent cannot meet the requirement.

## Applicability Note
If this gem does not include UI components, this agent may not be applicable to most tasks.

## Approval Required
Ask for approval before adding new ViewComponents or creating custom HTML that could become a reusable component.

## Source of Truth
Refer to the Flatpack gem documentation for the latest instructions and the component table/list before building UI (if Flatpack is available in this project).

## How to build UIs
- Default to ViewComponent usage: `render FlatPack::X::Component.new(...)` (or other ViewComponent library if used).
- Prefer existing components over handwritten markup and Tailwind classes.
- Use slots and provided APIs for layout, actions, and content.
- Use component-provided system arguments for classes/attributes.
- Avoid inline Tailwind class compositions unless no ViewComponent equivalent exists.

## Examples
```erb
<%= render FlatPack::Button::Component.new(text: "Save", style: :primary) %>

<%= render FlatPack::Card::Component.new(style: :elevated) do |card| %>
  <% card.header { "Title" } %>
  <% card.body { "Body content" } %>
<% end %>
```

## When custom HTML is allowed
- The component does not exist in the ViewComponent library.
- You need a temporary one-off for experimentation.
- You are implementing a new ViewComponent (request approval first).

## Review checklist
- Did I check the ViewComponent library (e.g., Flatpack) component list first?
- Can this be expressed with ViewComponent slots or props?
- If custom HTML is used, is there a TODO to upstream to the ViewComponent library?

## Validation workflow (required)
- Open the app and verify the UI in a running environment before final handoff.
- Exercise the changed user flows to confirm functionality works end-to-end (not just visual appearance).
- Use Playwright to run UI checks for the updated paths.
- Capture screenshots of key states (default, interaction, success/error where relevant) and use them to validate visual correctness.
- Confirm no obvious regressions in adjacent UI areas touched by the change.

## Handoff expectations
- Include a short validation summary: what was tested, which screens were checked, and whether screenshots were reviewed.
- Explicitly list any flows that could not be validated and why.
