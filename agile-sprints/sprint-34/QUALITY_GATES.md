# Team Quality Gates

### Definition of Ready (DoR) - Before QA Starts Testing
A story can only be moved to `In Testing` when:
- [ ] Acceptance criteria are clearly documented with specific boundary values.
- [ ] UI designs/wireframes are attached in Figma/Jira.
- [ ] Developer has deployed the code to the `Staging` environment.
- [ ] Developer completed unit tests and basic smoke tests (passed locally).

### Definition of Done (DoD) - Before Feature is Released to Customers
A story is only marked `Done` when:
- [ ] All AC scenarios (Happy, Boundary, Negative) are tested and marked PASS.
- [ ] API responses and database state changes have been verified.
- [ ] No Open Blocker, Critical, or Major bugs exist against this story.
- [ ] Regression suite executed on adjacent features with zero new failures.
- [ ] QA sign-off comment posted on the Jira ticket.
