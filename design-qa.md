# Design QA

**Source visual truth:** user-supplied retail UI inspiration screenshots (Images #1–#3 in this conversation).

**Implementation target:** catalog, product-detail, and checkout views after the retail visual-layer refresh.

**Viewport and state:** desktop; implementation needs browser-rendered captures at a matching desktop viewport before visual QA can pass.

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
