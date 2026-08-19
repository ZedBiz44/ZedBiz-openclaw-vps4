# Website Screenshots

Use this skill whenever the user asks for an actual visual screenshot of a public webpage or a web page visible through the configured browser profile.

## Required Behavior

- Do not claim that `web_fetch` or text extraction is a screenshot.
- For a public webpage, use Bash with `/home/openclaw/bin/openclaw-screenshot` to create the PNG. This is the required default route on Rocky.
- Use the managed `browser` tool only for interactive or authenticated pages. Navigate first, then confirm the target page is loaded before requesting a screenshot.
- Do not use `browser` action `screenshot` as the sole public-page capture route. On Rocky it can return a blank initial-tab image even when a URL is supplied.
- Send the resulting image file to the user as media. Do not merely describe the capture.

## Public Website Capture

Create an artifact directory inside the workspace and use the verified wrapper. It launches the managed Playwright Chromium binary with a clean, unique browser profile to avoid Snap confinement and profile-lock errors.

```bash
artifact_dir="$HOME/.openclaw/workspace/artifacts/site-screenshots/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$artifact_dir"
/home/openclaw/bin/openclaw-screenshot \
  "https://example.com/" \
  "$artifact_dir/page.png" \
  2500
file "$artifact_dir/page.png"
```

For a taller landing page, pass a larger third argument such as `9000`. The verified Rocky route generates a rendered 1440-pixel-wide PNG. Do not install arbitrary packages during an ordinary capture request.

## Delivery and Verification

- Confirm the output file exists and is a PNG before sending it.
- Attach the PNG in the final reply using the platform media path syntax.
- State the page URL and whether the screenshot is viewport-sized or tall-page.
- If a site requires login, ask the user to authorize the available browser session. Do not ask for passwords in chat.

## Limits

- Never use a screenshot to bypass authentication, payment walls, CAPTCHAs, or access restrictions.
- Never publish a screenshot externally without the user’s explicit direction.
- Treat screenshot files as ordinary user data and keep them in the workspace artifact folder.
