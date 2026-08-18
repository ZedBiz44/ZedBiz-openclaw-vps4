# Website Screenshots

Use this skill whenever the user asks for an actual visual screenshot of a public webpage or a web page visible through the configured browser profile.

## Required Behavior

- Do not claim that `web_fetch` or text extraction is a screenshot.
- Use the managed `browser` tool when it is available and appropriate.
- If a direct image file is needed, or the browser tool is unavailable, use the Bash tool to run headless Chromium and create a PNG.
- Send the resulting image file to the user as media. Do not merely describe the capture.

## Public Website Capture

Create an artifact directory inside the workspace and use Chromium. Set a clean, unique user-data directory to avoid profile-lock errors.

```bash
artifact_dir="$HOME/.openclaw/workspace/artifacts/site-screenshots/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$artifact_dir"
chromium --headless --no-sandbox --disable-gpu --disable-dev-shm-usage \
  --hide-scrollbars --window-size=1440,1600 --virtual-time-budget=8000 \
  --user-data-dir="/tmp/openclaw-chromium-$RANDOM" \
  --screenshot="$artifact_dir/page.png" \
  "https://example.com/"
file "$artifact_dir/page.png"
```

For a tall landing page, increase the viewport height such as `--window-size=1440,9000`. For more reliable full-page capture on complex pages, use Playwright through Bash if it is installed. If it is not installed, do not install arbitrary packages in the middle of an ordinary capture request. Use Chromium first and clearly state any rendering limitation.

## Delivery and Verification

- Confirm the output file exists and is a PNG before sending it.
- Attach the PNG in the final reply using the platform media path syntax.
- State the page URL and whether the screenshot is viewport-sized or tall-page.
- If a site requires login, ask the user to authorize the available browser session. Do not ask for passwords in chat.

## Limits

- Never use a screenshot to bypass authentication, payment walls, CAPTCHAs, or access restrictions.
- Never publish a screenshot externally without the user’s explicit direction.
- Treat screenshot files as ordinary user data and keep them in the workspace artifact folder.
