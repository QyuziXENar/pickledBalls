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

UDATE #3:

          Added Functions of 1v1

UPDATE #4:

          **1. Core Architecture, Constants & Zero-Crash Asset Pipeline:**
                Created centralized type-safe design tokens and asset registries (app_assets.dart, app_colors.dart).
                Mapped complete 192-frame sprite taxonomy across 4 athletes (Aria, Marcus, Elena, Jax), 2 perspective views (front/back), and 6 animation states.
                Integrated runtime AssetManifest checking to eliminate console 404 errors, allowing the game to safely fall back to procedural graphics and audio when files are missing.
                Audited and connected dedicated SFX hooks for every gameplay event (toss, reticle sweet spot, drive/lob serve, shoe squeaks, dink pops, smash spikes, out-of-bounds, and faults).

          **2. Two-Stage Manual Serve System (No Auto-Serve):**
                Removed automated countdown serves in favor of an interactive two-stage skill mechanic.
                Stage 1 (Position & Toss): Player positions along the baseline with the ball physically tethered to their paddle hand before tossing up to apex (Z ≈ 1.55m).
                Stage 2 (Reticle Strike): A contracting timing reticle locks onto the descent, allowing players to execute either a flat bullet [DRIVE SERVE] or an arching defensive [LOB SERVE].
                Implemented strict fault penalties for missed timing, swinging early, or dropping the ball without contact.

          **3. Real-Life Wiffle-Ball Aerodynamics & Ball Physics Remaster:**
                Eliminated artificial "invisible wall" pinball bouncing on court sidelines. Wide balls now travel along natural aerodynamic arcs out-of-bounds with realistic line-call faults.
                Simulated real perforated polymer wiffle-ball drag (explosive exit velocity followed by smooth mid-air deceleration).
                Replaced runaway Magnus curves with bounded aerodynamic drift and angular spin decay.
                Added realistic rotating ball dimples, multi-stage glowing neon speed blur trails, and floor bounce shockwave rings.

          **4. 2D Tactical AI Opponent Engine:**
                Overhauled AI from a basic 1D horizontal tracker into a dynamic 2D opponent that advances to the Non-Volley Zone (NVZ Kitchen line) during dink battles and retreats to the baseline for deep lobs.
                Added human-like reaction lag, unforced error probabilities, and turnaround momentum penalties when wrong-footed.
                Added randomized serve delays and tactical shot selection (dinks, drives, overhead smashes, and deep lobs).

          **5. Articulated 2.5D Humanoid Procedural Rig & Action Animations:**
                Replaced flat colored circle placeholders with fully articulated 2.5D humanoid puppets featuring anatomically connected paddle grips, jerseys, shorts, and court sneakers.
                Added unique headwear and hairstyles per athlete (Aria red ponytail, Marcus headband, Elena lavender ponytail, Jax backward cap).
                Implemented dedicated biomechanical action animations instead of generic 360° spins:
                  - Overhead Smash/Spike (vertical jump off court deck + chest compression).
                  - Forehand Topspin Drive (shoulder coiling + low-to-high follow-through).
                  - Lob Scoop & Underhand Serves.
                  - Sideline Lunging Dives for wide reach saves.
                  - Blitz Super kinetic aura with 45ms impact hitstop.
                  - Conceded point slump.

          **6. Doom-Style 2.5D Atmospheric Stadium Backgrounds:**
                Engineered high-visibility procedural 2.5D background environments extending across the horizon for all court venues:
                  - Tournament Arena: Multi-tiered grandstands packed with cheering pixel crowd spectators, glowing arena Jumbotron, and volumetric floodlight beams.
                  - Midnight Stadium: Dark cyber synthwave horizon, perspective neon skyline, and sweeping spotlights.
                  - Sunlit Beach: Tropical ocean surf, golden sun lens flare, and coastal palm tree silhouettes.

          **7. Tri-Currency Economy & RPG Progression System:**
                Overhauled GameState with tri-currency wallets: Gold Coins (soft), Diamonds (hard), and Upgrade Points (UP).
                Configured level-up progression curve awarding +3 Upgrade Points (UP) per account level.
                Added manual stat allocation system allowing players to distribute UP to permanently boost paddle Power, Control, Spin, and Agility (up to +10 per stat).
                Streamlined catalog into 4 tournament paddles + 2 locked mystery prototypes ("Coming Soon in v3.1").
                Built animated Pro Shop Gacha Crate unboxing ceremonies (Recruit Crate, Tour Pro Chest, Grand Slam Vault) with chest wobbles, radiant light rays, and loot card reveals.

          **8. Cross-Platform Polish & Complete Modular Codebase Refactoring:**
                Configured iOS AVAudioSessionCategory.ambient with mixWithOthers so in-game Foley never interrupts user background music or podcasts.
                Implemented modern PopScope navigation safeguards to prevent accidental match forfeits on back swipes.
                Decomposed monolithic files (gameplay_screen.dart and lobby_screen.dart) into clean, lightweight modules (~150–350 lines each) across dedicated folders (physics/, rendering/, widgets/, tabs/) for rapid maintainability.