# Test Suite: User Registration Validation (TS_REG_001)

- **Target URL:** `https://staging.app.example/register`
- **API Endpoint:** `POST /api/v1/auth/register`
- **Environment:** Windows 11 | Chrome / Opera | Staging Build v2.4.1

---

## 1. Happy Path: Standard Valid Input
*Goal: Confirm that standard, valid user credentials successfully create an account and initiate a session.*

* **Test Case ID:** `TC_REG_01_HP`
* **Preconditions:** User is on `/register`; email address is not already registered.
* **Test Data:**
  * Username: `AlexTester26` (12 chars, valid alphanumeric)
  * Email: `alex.tester@example.com` (valid format)
  * Password: `SecurePass2026!` (15 chars, meets complexity criteria)
* **Execution Steps:**
  1. Navigate to `/register`.
  2. Input test data into Username, Email, and Password fields.
  3. Click the **"Create Account"** button.
* **Expected Result:**
  * HTTP status returns `201 Created` in DevTools Network tab.
  * User is redirected to `/dashboard` or `/welcome`.
  * An authentication session token (`auth_token`) is stored in cookies/localStorage.
  * A success toast notification displays: *"Account created successfully."*
* **Status:** Pass

---

## 2. Boundary Value Analysis (BVA): Character Limits
*Goal: Validate the exact edges of input length constraints (Username min: 3, max: 20; Password min: 8).*

* **Test Case ID:** `TC_REG_02_BVA`
* **Preconditions:** User is on `/register`.
* **Test Matrix:**

| Sub-Test | Field | Test Value | Length | Boundary State | Expected Result |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_BVA_01** | Username | `Al` | 2 chars | Just below min (3) | Submission blocked; Inline error: *"Username must be between 3 and 20 characters."* |
| **TC_BVA_02** | Username | `Dan` | 3 chars | Exactly at min (3) | Input accepted; Green validation checkmark. |
| **TC_BVA_03** | Username | `UserTwentyCharsLong1` | 20 chars | Exactly at max (20) | Input accepted; Green validation checkmark. |
| **TC_BVA_04** | Username | `UserTwentyOneCharsLng1` | 21 chars | Just above max (20) | Input truncated or error: *"Username cannot exceed 20 characters."* |
| **TC_BVA_05** | Password | `Pass12!` | 7 chars | Just below min (8) | Submission blocked; Inline checklist highlights: *"At least 8 characters"* in red. |
| **TC_BVA_06** | Password | `Pass123!` | 8 chars | Exactly at min (8) | Input accepted; Meets minimum complexity. |

* **Status:** Pass

---

## 3. Negative / Input Validation: Special Characters, Whitespace & Formats
*Goal: Confirm that malicious, malformed, or blank inputs are rejected gracefully without system crashes.*

* **Test Case ID:** `TC_REG_03_NEG`
* **Preconditions:** User is on `/register`.
* **Test Matrix:**

| Sub-Test | Target Field | Input Data | Expected Result | Actual Result |
| :--- | :--- | :--- | :--- | :--- |
| **TC_NEG_01** | All Fields | Blank / Empty strings | Form highlights required fields with *"This field is required."* No API request dispatched. | As expected |
| **TC_NEG_02** | Email | `plainaddress` (Missing `@` and domain) | HTML5 / Inline regex error: *"Please enter a valid email address."* | As expected |
| **TC_NEG_03** | Email | `user@.com` or `@domain.com` | Inline error: *"Invalid email format."* | As expected |
| **TC_NEG_04** | Username | `User<script>alert(1)</script>` | Input sanitized or blocked; error: *"Username can only contain letters and numbers."* No XSS script execution. | As expected |
| **TC_NEG_05** | Username | `   JohnDoe   ` (Leading/trailing spaces) | Whitespace trimmed automatically on blur, or validation rejects spaces. | As expected |

* **Status:** Pass

---

## 4. Security / State: Session Expiry, Double Submission & Navigation
*Goal: Ensure system state remains resilient when interrupted, duplicated, or timed out.*

* **Test Case ID:** `TC_REG_04_STATE`
* **Preconditions:** Browser DevTools open (`F12`); Network throttling set to **"Slow 3G"** to simulate latency.

### Scenario A: Rapid Double Submission (Idempotency)
1. Fill all registration fields with valid unique data.
2. Rapidly double-click or triple-click the **"Create Account"** button within ~200ms.
* **Expected Result:**
  * The button disables immediately upon the first click and shows a spinner.
  * Only one single `POST /api/v1/auth/register` call is processed by the server.
  * The database does not throw a duplicate key error or create orphaned records.

### Scenario B: Session / Token Expiry
1. Open the registration form and wait for the temporary CSRF token to expire (or manually delete the `XSRF-TOKEN` cookie via DevTools Application tab).
2. Attempt to submit valid form data.
* **Expected Result:**
  * System rejects the submission gracefully with `HTTP 403 Forbidden` or `HTTP 419 Page Expired`.
  * The UI presents a clean message: *"Your session has timed out. Please refresh and try again."*
  * No raw backend stack trace is exposed to the user.

### Scenario C: Browser Back-Navigation Post-Registration
1. Successfully complete registration and land on the `/dashboard` page.
2. Click the browser's native **Back** button (`Alt + Left Arrow`).
* **Expected Result:**
  * The browser does NOT resubmit the form.
  * If the user lands back on `/register`, the system automatically detects the active session and redirects them back to `/dashboard`, or shows the form cleared without exposing submitted password data.

* **Status:** Pass
