APP_NAME   := TimeTracker
BUNDLE_ID  := com.szymonels.timetracker
CONFIG     ?= release
BIN        := .build/$(CONFIG)/$(APP_NAME)
APP        := build/$(APP_NAME).app

.PHONY: all build app run install uninstall icon clean

all: app

## Compile the binary alone - fastest way to see whether the code is valid.
build:
	swift build -c $(CONFIG)

## Assemble the .app bundle around that binary and sign it.
app: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp $(BIN) $(APP)/Contents/MacOS/$(APP_NAME)
	cp Resources/Info.plist $(APP)/Contents/Info.plist
	cp Resources/AppIcon.icns $(APP)/Contents/Resources/AppIcon.icns
# Ad-hoc signature (-s -). Free, local-only, and enough for macOS to keep the
# app's identity stable between rebuilds - which is what permissions are
# remembered against. Distribution needs a Developer ID instead.
	codesign --force --sign - --identifier $(BUNDLE_ID) $(APP)
	@echo "Built $(APP)"

## Rebuild and relaunch, replacing a copy that is already running.
run: app
	@killall $(APP_NAME) 2>/dev/null || true
	open $(APP)

## Put it in /Applications, where Login Items can find it.
install: app
	rm -rf /Applications/$(APP_NAME).app
	cp -R $(APP) /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

uninstall:
	@killall $(APP_NAME) 2>/dev/null || true
	rm -rf /Applications/$(APP_NAME).app

## Redraw the app icon from Tools/make-icon.swift. Only needed when the brand
## changes - the .icns it produces is committed.
icon:
	swiftc -O Tools/make-icon.swift -o /tmp/make-icon
	/tmp/make-icon Resources/AppIcon.iconset
	iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
	rm -rf Resources/AppIcon.iconset /tmp/make-icon

clean:
	swift package clean
	rm -rf build
