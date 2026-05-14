# TextLaunch

TextLaunch is a small native macOS launcher inspired by Launchpad. It shows installed applications as a full-screen, text-only, alphabetically sorted grid.

## Build

```sh
./scripts/build_app.sh
```

The app bundle is created at:

```text
build/TextLaunch.app
```

## Use

- Launch the app to show the full-screen application list.
- Type in the search field to filter by name.
- Click an application name to open it.
- Press `Esc` or click `Close` to hide the launcher.
- Click the Dock icon, use the `TextLaunch` menu bar item, or use `TextLaunch > Show TextLaunch` to show it again.
- `Command-L` also shows the launcher while TextLaunch is focused.
- Move the pointer into the selected trigger corner to show it again. The default is top left.
- Change the trigger corner from `TextLaunch > Trigger Corner` or the menu bar item.

The trigger corner is implemented inside TextLaunch, so the app needs to keep running for the corner to work.
