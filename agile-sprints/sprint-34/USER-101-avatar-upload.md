# [USER-101] User Profile Avatar Upload

**User Story:**
*As a registered user, I want to upload a profile avatar (JPEG/PNG) so that other players can recognize me.*

### Acceptance Criteria (AC) Defined by Product Owner
1. File formats supported: JPG, JPEG, PNG.
2. File size limit: Maximum 2MB.
3. Aspect ratio: Image cropped to 1:1 square.
4. Non-image files (e.g., .exe, .pdf, .svg) must be rejected with an inline error.

---

### QA Scenario Extraction (Gherkin Syntax)

#### Scenario 1: Happy Path Upload
- **Given** an authenticated user is on the "Account Settings" page
- **When** the user selects a valid 1.2MB `.png` image and clicks "Save Avatar"
- **Then** the image preview updates immediately to the new avatar
- **And** the server returns status `200 OK`
- **And** the database record `users.avatar_url` updates with the new CDN path.

#### Scenario 2: File Size Boundary Exceeded (Negative)
- **Given** an authenticated user is on the "Account Settings" page
- **When** the user attempts to upload a 2.1MB `.jpeg` file
- **Then** the upload is blocked before dispatching network request
- **And** an error message displays: *"File size exceeds 2MB limit."*

#### Scenario 3: Malicious File Type Rejection (Security)
- **Given** an authenticated user is on the "Account Settings" page
- **When** the user renames a script `malware.exe` to `avatar.png` and submits
- **Then** the backend file-type parser checks MIME header and rejects the upload
- **And** status code `415 Unsupported Media Type` or `400 Bad Request` is returned.
