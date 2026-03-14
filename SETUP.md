# Knacka På Huset – Xcode-setup (5 minuter)

## Steg 1: Skapa Xcode-projekt

1. Öppna **Xcode** → *Create New Project*
2. Välj **iOS → App**
3. Fyll i:
   - Product Name: `KnackaPaHuset`
   - Bundle ID: `se.dittnamn.knackapaHuset`
   - Interface: **SwiftUI**
   - Language: **Swift**
4. Spara i mappen: `Desktop/tiptap/`

## Steg 2: Radera Xcodes default-filer

I Project Navigator, ta bort (Move to Trash):
- `ContentView.swift` (ersätts av vår)
- `KnackaPaHusetApp.swift` (ersätts av vår)

## Steg 3: Lägg till våra källkodsfiler

1. Högerklicka på projektet i Navigator → *Add Files to "KnackaPaHuset"*
2. Välj hela mappen `KnackaPaHuset/` från Desktop/tiptap
3. Se till att *"Copy items if needed"* är **avbockat** (filerna ligger redan rätt)
4. Klicka **Add**

## Steg 4: iPad-only, Landscape-inställningar

I Project-inställningar (klicka på projektets blå ikon):
- **Supported Destinations**: Ta bort iPhone, behåll bara **iPad**
- **Device Orientation**: Bocka av Portrait, behåll bara **Landscape Left** & **Landscape Right**
- **Requires Full Screen**: Sätt till **YES** (viktigt för App Store)

## Steg 5: Lägg till SpriteKit

Under *Frameworks, Libraries, and Embedded Content*:
- Klicka **+** → sök "SpriteKit" → **Add**

## Steg 6: Importera dina PNG-sprites

1. Klicka på `Assets.xcassets` i Navigator
2. Dra in dina PNG-filer
3. Namnge enligt konventionen: `hus_idle_01`, `hus_idle_02` … `hus_tap_01` osv.

## Namnkonvention för sprites

```
[objekt]_[typ]_[nummer]

Exempel:
  hall_idle_01.png     ← idleloop för hallen, frame 1
  hall_idle_02.png     ← frame 2
  hall_tap_01.png      ← tap-animation, frame 1
  fagel_idle_01.png    ← fågel idle
  fagel_tap_01.png     ← fågel tap
```

## Köra appen

1. Välj simulator: **iPad Pro 12.9" (6th generation)**
2. Tryck **⌘R** (Run)
