# Design QA

**Source visual truth:** user-supplied EMI product reference screenshot (Image #1 in this conversation).

**Implementation target:** `/products/iphone-17-pro`, with the first finish and first EMI plan selected.

**Viewport and state:** desktop reference is approximately 724 × 724 px; implementation needs a browser-rendered capture at the same viewport before visual QA can pass.

**Evidence available:**

- `npm run build` passed.
- The local PostgreSQL service is healthy.
- `GET /api/products/iphone-17-pro` returns the product, three variants, and seven plans.
- A browser or approved Playwright capture capability is not available in this environment, so no rendered implementation screenshot or console inspection could be produced.

**Findings**

- [P1] Browser-rendered visual comparison is unavailable.
  Location: whole detail screen.
  Evidence: no browser/capture tool is available; only HTTP and build verification were possible.
  Impact: layout, responsive behavior, image crop, typography, and interactive browser states cannot be visually compared to the reference yet.
  Fix: open the running Vite app in a browser at the reference viewport, test finish selection, plan selection, and the proceed action, capture it, then compare that capture alongside the source image.

**Implementation Checklist**

- Run the local app and capture `/products/iphone-17-pro` at the reference desktop dimensions.
- Check the selected-plan and success-confirmation states.
- Perform a focused comparison of pricing/header, device-image, and EMI-card regions.

**Follow-up Polish**

- None recorded until rendered evidence is available.

final result: blocked
