# Update Log:

UPDATE #1:
          Version 2.0 applied, changes: Gameplay and UI design.
UPDATE #2:
          **1. Audio Engine Integration:**
                Installed audioplayers package.
                Implemented real audio playback for background sound and SFX in asset_helpers.dart.
                Added canzed_intro.mp3 asset and configured asset paths in pubspec.yaml.
          **2. 3D Court and Perspective Fix (gameplay_screen.dart):**
                Fixed camera perspective math so the player side is no longer visually compressed or shorter than the opponent side.
                Added 3D court slab with beveled edges and floor drop shadow.
                Added 3D pickleball net with realistic center sag, metallic posts, and dynamic shadow over the kitchen.
                Added stadium LED ribbon boards and venue-specific lighting.
          **3. New VS. AI Match Setup Screen (vs_ai_setup_screen.dart):**
                Created a dedicated pre-match setup screen instead of launching immediately.
                Added an interactive 3D rotating court turntable carousel that changes screen theme colors based on the selected venue.
                Added match length selection cards for 5 PTS, 11 PTS, and 15 PTS with estimated match durations.
                Added AI difficulty threat cards for Rookie (2.5 DUPR), Pro Tour (4.0 DUPR), and Titan (5.5+ DUPR).
          **4. Lobby Battle Tab Overhaul (lobby_screen.dart):**
                Removed old venue pills and point selectors from the main tab.
                Replaced the old exhibition button with two side-by-side buttons: VS. AI (opens setup screen) and VS. PLAYER (1v1 placeholder).
                Added Equipped Combat Loadout card showing active athlete, paddle, and calculated team OVR rating with quick links to roster and locker tabs.
                Added Pro Tour campaign progress bar.
                Added 4-slot match reward chest vault.
          **5. Company Intro Screen (company_intro_screen.dart):**
                Updated to an 11-second two-stage Valve-style intro matched to audio timing.
                Added initial black screen pause, slow fade-in, and transition to a procedural Flutter & Dart engine logo screen.
                Added tap-to-skip functionality.
