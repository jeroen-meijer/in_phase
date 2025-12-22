# InPhase Desktop App - UI Design Prompts

This document provides prompts for generating UI mockups for the InPhase desktop application using AI design tools.

---

## App Context (Reference Only)

**What is InPhase?**
A desktop application for DJs that bridges Spotify and Rekordbox. It syncs playlists, discovers new music, and searches the user's music library.

**Target Users:** DJs and music collectors who use Rekordbox for performances

**Platforms:** macOS, Windows, Linux desktop (minimum 800×600 window)

---

## Initial App Prompt (High-Level)

Start with this prompt to establish the overall app concept and vibe:

```
A professional desktop app for DJs to manage their music libraries between Spotify and Rekordbox.

Modern, clean, and efficient design with a dark theme option. Music-forward aesthetic that feels connected to audio culture without being flashy. 

Sidebar navigation on the left, content area on the right. Material Design 3 style with compact desktop density.

Primary color: deep purple. Use green for success states (matched tracks), red for errors (missing tracks).
```

---

## Screen-by-Screen Prompts

### 1. Splash Screen

```
Splash screen for a desktop music management app called "InPhase."

Centered layout on a subtle dark gradient background. Large app icon (abstract audio waveform or vinyl record) prominently displayed. App name "InPhase" in a clean sans-serif font below the icon. Circular loading spinner beneath the name.

Minimal and professional. No clutter.
```

---

### 2. Onboarding - Welcome Step

```
First step of a 3-step onboarding wizard for a desktop app.

Linear progress indicator at the top showing step 1 of 3. Centered content area.

Large welcome illustration: abstract geometric shapes suggesting music or audio waves, using deep purple and soft grays.

Headline: "Welcome to InPhase"
Subtext: "Bridge your Spotify library with Rekordbox. Sync playlists, discover new music, and manage your DJ library."

Primary button at bottom: "Continue"

Warm, inviting, and encouraging tone.
```

---

### 3. Onboarding - Rekordbox Setup Step

```
Second step of onboarding wizard for a desktop app.

Progress indicator at top showing step 2 of 3. Back button in top left.

Centered content with folder icon at top.

Headline: "Locate Rekordbox Database"
Explanation text: "InPhase needs access to your Rekordbox database to sync tracks."

Large outlined button with folder icon: "Select Database Folder"

Below the button, show a success state card: green checkmark icon, text showing a file path, styled as a subtle confirmation.

Text link at bottom: "Where is my Rekordbox database?" in muted color.

Clean and instructional. Desktop file picker aesthetic.
```

---

### 4. Onboarding - Complete Step

```
Final step of onboarding wizard.

Progress indicator at top showing step 3 of 3 complete.

Large success illustration: green checkmark in a circle with subtle celebration confetti or particles.

Headline: "You're all set!"
Subtext: "Next, you'll log in with your Spotify account to start syncing."

Primary button: "Get Started"

Celebratory but professional. Ready to move forward.
```

---

### 5. Login Screen

```
Login screen for a desktop app requiring Spotify authentication.

Centered card on a subtle gradient background. Card has soft rounded corners and subtle shadow.

App logo at top of card. 

Headline: "Connect with Spotify"
Subtext: "InPhase needs access to your Spotify account to read your playlists."

Large primary button with Spotify green (#1DB954): "Login with Spotify" with small Spotify logo icon.

Small muted text below: "We only request read access to your playlists."

Clean, focused, single action. Trust-building and simple.
```

---

### 6. Main App Shell (Sidebar + Content Area)

```
Desktop app layout with persistent sidebar navigation.

Left sidebar (240px wide, dark surface color):
- App logo and name "InPhase" at top
- Navigation items with icons: Dashboard, Sync, Crawl, Search, Config
- Divider line
- Settings item at bottom
- User avatar, display name, and small "Logout" text link at very bottom

Right content area (light or dark surface based on theme):
- Top bar with screen title on left, action buttons on right
- Main content below with comfortable padding

Modern desktop application. Sidebar feels like VS Code or Slack. Clean iconography.
```

---

### 7. Dashboard Screen

```
Dashboard home screen for a DJ music management app.

Three feature cards in a horizontal row at the top:
- Card 1: Sync icon, title "Sync," description "Sync Spotify playlists to Rekordbox," arrow button
- Card 2: Spider/crawl icon, title "Crawl," description "Discover new music from sources," arrow button  
- Card 3: Search icon, title "Search," description "Search your Rekordbox library," arrow button

Cards have subtle borders, hover state, and feel clickable.

Below cards, a "Quick Stats" section:
Horizontal strip with three metrics: "Last sync: 2 days ago" | "Playlists: 47" | "Crawl jobs: 5"
Use small icons next to each metric.

Below stats, "Recent Activity" section:
List of 4-5 recent items with status icons:
- Green checkmark: "Synced 'Weekend Vibes' - 23 tracks"
- Green checkmark: "Crawl completed - 156 new tracks"  
- Yellow warning: "Sync 'House Mix' - 3 tracks missing"

Each item shows relative timestamp on the right: "2 hours ago"

Informative dashboard that gives quick overview. Professional and scannable.
```

---

### 8. Sync Screen - Playlist Selection

```
Sync screen for selecting Spotify playlists to sync to Rekordbox.

Title "Sync Playlists" with primary "Start Sync" button in top right.

Search/filter input field below title: "Search playlists..."

Scrollable list of playlists with checkboxes:
Each row shows:
- Checkbox on left
- Playlist name (primary text)
- Track count: "47 tracks"
- Last sync info: "Last: 2 days ago" or "Never synced" in muted text

Example rows:
☑ Weekend Vibes - 47 tracks - Last: 2 days ago
☑ House Mix - 89 tracks - Last: 1 week ago
☐ Chill Beats - 124 tracks - Never synced

"Select All" text button aligned right above the list.

Footer shows: "Selected: 3 playlists (192 tracks)"

Clean data table aesthetic. Easy to scan and select.
```

---

### 9. Sync Screen - Running State

```
Sync in progress screen showing real-time updates.

Title "Sync Playlists" with "Cancel" button (red/destructive style) in top right.

Progress section at top:
- Text: "Syncing playlist 2 of 3..."
- Full-width progress bar at 67%, purple fill
- Current playlist name: "House Mix"

Live results section below:
Scrollable list showing track processing in real-time:
- Green checkmark: "Deep House Track" by Artist Name - "matched"
- Green checkmark: "Another Banger" by DJ Someone - "matched"  
- Red X: "Rare Import" by Unknown Artist - "not found"
- Green checkmark: "Classic Tune" by Legend - "matched"

Stats bar at bottom:
"Matched: 45 | Not Found: 3 | Processing: 12"

Dynamic and informative. User can see exactly what's happening.
```

---

### 10. Sync Screen - Completed State

```
Sync completed summary screen.

Large success icon (green checkmark in circle) centered at top.

Headline: "Sync Complete"
Subtext: "Duration: 2 minutes 34 seconds"

Summary card below:
- "192 tracks processed"
- "✓ 185 matched (96%)" in green
- "✗ 7 not found" in red/muted

Playlist breakdown list:
- ✓ Weekend Vibes - 47/47 matched
- ✓ House Mix - 86/89 matched (3 missing)
- ✓ Tech House Bangers - 52/56 matched (4 missing)

Two buttons at bottom: "View Report" (outlined) and "Done" (primary)

Celebratory but informative. Clear next actions.
```

---

### 11. Crawl Screen - Job List

```
Crawl jobs management screen for discovering new music.

Title "Crawl Jobs" with "Run Selected" button and "+ New" button in top right.

List of crawl job cards with checkboxes:

Each card shows:
- Checkbox on left
- Spider/crawl icon
- Job name as title: "New House Releases"
- Source summary: "Sources: 3 playlists, 2 labels"
- Last run info: "Last run: Yesterday - 45 tracks found"
- Overflow menu (three dots) on right for Edit/Delete

Cards have subtle borders and feel selectable.

"Run All Jobs" text button at bottom.

Clean job management interface. Each job is a distinct card.
```

---

### 12. Crawl Job Editor

```
Editor screen for creating or editing a crawl job.

Back arrow and "Edit Job" title on left, "Save" primary button on right.

Form layout:

"Job Name" label with text input: "New House Releases"

"Playlist Name Template" label with text input: "{job_name} - {month} {year}"
Helper text below: 'Preview: "New House Releases - December 2024"'

Divider line.

"Sources" section header with "+ Add" button on right.

List of source items, each with icon, type, name, and X remove button:
- 📋 Spotify Playlist: "Beatport Top 100" [✕]
- 📋 Spotify Playlist: "Hype Machine Popular" [✕]
- 🏷️ Label: "Dirtybird Records" [✕]
- 👤 Artist: "Claude VonStroke" [✕]

Divider line.

"Date Range" section:
Radio button group: ○ Last 30 days ● Last 90 days ○ This year ○ Custom

Form-based editor. Clear sections and input fields.
```

---

### 13. Search Screen

```
Search screen for Rekordbox library.

Title "Search Rekordbox" at top.

Large search input with magnifying glass icon: "Search tracks by name, artist, or ID..."
Clear X button appears when text is entered.

Results table below:
Column headers: Track Name | Artist | BPM | Key | Duration

Example rows:
Deep House Track | Artist Name | 124 | Am | 6:42
Another Banger | DJ Someone | 128 | Fm | 5:15
Classic Tune | Legend | 118 | Dm | 7:30

Rows are hoverable and selectable.

Results count at bottom: "47 results"

Clean data table. Fast and scannable search results.
```

---

### 14. Search - Track Detail Panel

```
Side panel showing track details when a search result is selected.

Panel slides in from right (300px wide) or appears as a card.

Close X button in top right corner.

Track name as large title: "Deep House Track"
Artist as subtitle: "by Artist Name"

Details list:
- BPM: 124.00
- Key: Am (8A)
- Duration: 6:42

"Cues" section:
- 🔴 Hot Cue A - 0:32
- 🟡 Hot Cue B - 1:45
- 🟢 Hot Cue C - 3:12
- 🔵 Hot Cue D - 5:00

"Memory Cues: 2"

File path in muted small text: "/Music/Tracks/deep_house_track.mp3"
"Added: January 15, 2024"

Informative detail panel. All track metadata visible at a glance.
```

---

### 15. Settings Screen

```
Settings screen with multiple sections.

Title "Settings" at top.

"Account" section:
Card with user avatar, display name, email, and "Logout" button on right.

Divider.

"Rekordbox Database" section:
Card showing current path with "Change" button. Green checkmark with "Connected" status.

Divider.

"Appearance" section:
Theme selector with three options: ○ System ● Light ○ Dark
Styled as segmented button group or radio buttons.

Divider.

"Cache" section:
Card showing "Cache size: 12.4 MB"
Three buttons: "Clear Sync Cache" | "Clear Crawl Cache" | "Clear All"
Buttons are outlined/secondary style.

Divider.

"About" section:
"InPhase v1.0.0"
Text links: "View on GitHub" | "Report Issue" | "Keyboard Shortcuts"

Organized settings with clear sections. Standard preferences layout.
```

---

### 16. Empty State - No Results

```
Empty state for when a search returns no results.

Centered content in the main area.

Large muted icon: music note with slash or empty search icon.

Headline: "No tracks found"
Subtext: "Try a different search term"

Subtle and helpful. Not alarming.
```

---

### 17. Empty State - First Time Dashboard

```
Empty state for dashboard when user has no activity yet.

Centered content.

Illustration: abstract shapes suggesting getting started, in brand purple.

Headline: "No activity yet"
Subtext: "Start by syncing your playlists!"

Primary button: "Go to Sync"

Encouraging and action-oriented. Points user to next step.
```

---

### 18. Error State

```
Error state for when an operation fails.

Centered content.

Large red/orange warning icon.

Headline: "Something went wrong"
Subtext: "Unable to connect to Rekordbox database. Please check the path in Settings."

Primary button: "Try Again"
Secondary text link: "Go to Settings"

Helpful error with clear recovery options. Not scary.
```

---

### 19. Confirmation Dialog

```
Modal dialog for confirming destructive action.

Overlay dimming the background.

Centered dialog card (400px wide):
- Title: "Clear Cache?"
- Body text: "This will delete all cached data. You'll need to re-sync your playlists."
- Two buttons aligned right: "Cancel" (text) and "Clear Cache" (destructive red)

Standard confirmation pattern. Clear consequences stated.
```

---

## Theme Variations

### Light Theme Prompt

```
Update the app to use a light theme:
- White/light gray backgrounds
- Dark text for readability
- Purple primary color for accents and buttons
- Subtle shadows and borders for depth
- Light sidebar with darker text

Professional and bright. Good contrast.
```

### Dark Theme Prompt

```
Update the app to use a dark theme:
- Dark gray/near-black backgrounds
- Light text for readability  
- Purple primary color that pops against dark background
- Subtle borders instead of shadows
- Dark sidebar that blends with main content

Modern and easy on the eyes. Reduce eye strain.
```

---

## Refinement Prompts

Use these follow-up prompts to refine specific elements:

### Colors
```
Change the primary accent color from purple to deep blue (#1E3A8A).
```

### Typography
```
Use a modern sans-serif font for all text. Headings should be semibold, body text regular weight.
```

### Buttons
```
Make all primary buttons have fully rounded corners (pill shape). Secondary buttons should have subtle rounded corners.
```

### Spacing
```
Reduce padding throughout the app for a more compact, desktop-appropriate density. Less whitespace between elements.
```

### Sidebar
```
Make the sidebar collapsible. When collapsed, show only icons. Add a toggle button at the bottom of the sidebar.
```

### Progress Bars
```
Style progress bars with rounded ends and a subtle gradient from purple to lighter purple.
```

---

## Notes for Using These Prompts

1. **Start with the Initial App Prompt** to establish the overall vibe
2. **Generate one screen at a time** using the screen-specific prompts
3. **Use refinement prompts** to adjust specific elements after initial generation
4. **Be incremental** - make one or two changes per follow-up prompt
5. **Save your progress** - screenshot or export after each successful generation
6. **Iterate** - if a result isn't right, rephrase and try again

Reference: These prompts follow the structure recommended in the [Stitch Prompt Guide](https://discuss.ai.google.dev/t/stitch-prompt-guide/83844).

---

*Document version: 2.0*
*Updated: December 2024*
