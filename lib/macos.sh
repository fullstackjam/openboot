#!/bin/bash

# OpenBoot macOS Configuration Module
# Applies sensible macOS defaults for developers

# Check if running on macOS
macos_is_supported() {
    [[ "$(uname)" == "Darwin" ]]
}

# Configure Dock settings
macos_configure_dock() {
    local dry_run="${1:-false}"
    
    echo "Configuring Dock..."
    
    if $dry_run; then
        echo "  [DRY-RUN] Would configure Dock settings"
        return 0
    fi
    
    # Dock behavior
    defaults write com.apple.dock autohide -bool false
    defaults write com.apple.dock "show-recents" -bool false
    defaults write com.apple.dock tilesize -int 42
    defaults write com.apple.dock magnification -bool false
    defaults write com.apple.dock mineffect -string "scale"
    defaults write com.apple.dock launchanim -bool false
    
    # Minimize windows into application icon
    defaults write com.apple.dock minimize-to-application -bool true
    
    echo "  Dock configured"
}

# Set up Dock apps based on what's installed
macos_setup_dock_apps() {
    local dry_run="${1:-false}"
    
    echo "Setting up Dock apps..."
    
    # Apps to add to Dock (in order) - only if installed
    local dock_apps=(
        "/Applications/Arc.app"
        "/Applications/Google Chrome.app"
        "/System/Applications/Messages.app"
        "/Applications/Warp.app"
        "/Applications/Visual Studio Code.app"
        "/Applications/Cursor.app"
        "/Applications/Notion.app"
        "/Applications/Obsidian.app"
    )
    
    if $dry_run; then
        echo "  [DRY-RUN] Would set Dock apps:"
        for app in "${dock_apps[@]}"; do
            [[ -d "$app" ]] && echo "    - $(basename "$app" .app)"
        done
        return 0
    fi
    
    # Clear existing Dock apps
    defaults delete com.apple.dock persistent-apps 2>/dev/null || true
    
    # Add apps that exist
    for app in "${dock_apps[@]}"; do
        if [[ -d "$app" ]]; then
            defaults write com.apple.dock persistent-apps -array-add \
                "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
            echo "  Added: $(basename "$app" .app)"
        fi
    done
}

# Configure trackpad for tap-to-click and gestures
macos_configure_trackpad() {
    local dry_run="${1:-false}"
    
    echo "Configuring Trackpad..."
    
    if $dry_run; then
        echo "  [DRY-RUN] Would enable tap-to-click and gestures"
        return 0
    fi
    
    # Enable tap to click
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    
    # Enable three-finger drag (accessibility feature)
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
    
    # Natural scrolling
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true
    
    echo "  Trackpad configured (tap-to-click, three-finger drag)"
}

# Configure Finder preferences
macos_configure_finder() {
    local dry_run="${1:-false}"
    
    echo "Configuring Finder..."
    
    if $dry_run; then
        echo "  [DRY-RUN] Would configure Finder preferences"
        return 0
    fi
    
    # Show file extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    
    # Show hidden files
    defaults write com.apple.finder AppleShowAllFiles -bool true
    
    # Show path bar
    defaults write com.apple.finder ShowPathbar -bool true
    
    # Show status bar
    defaults write com.apple.finder ShowStatusBar -bool true
    
    # Default to list view
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    
    # Search current folder by default
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    
    # Disable warning when changing file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    
    # Avoid creating .DS_Store on network/USB volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
    
    echo "  Finder configured"
}

# Configure keyboard settings
macos_configure_keyboard() {
    local dry_run="${1:-false}"
    
    echo "Configuring Keyboard..."
    
    if $dry_run; then
        echo "  [DRY-RUN] Would configure keyboard preferences"
        return 0
    fi
    
    # Fast key repeat
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    
    # Disable auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    
    # Disable auto-capitalization
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    
    # Disable smart quotes and dashes (annoying for coding)
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    
    echo "  Keyboard configured (fast repeat, no auto-correct)"
}

# Configure login items for installed apps
macos_configure_login_items() {
    local dry_run="${1:-false}"
    
    echo "Configuring Login Items..."
    
    # Apps to start at login (only if installed)
    local login_apps=(
        "Maccy:/Applications/Maccy.app"
        "Scroll Reverser:/Applications/Scroll Reverser.app"
        "Stats:/Applications/Stats.app"
        "Raycast:/Applications/Raycast.app"
    )
    
    local items_to_add=()
    for item in "${login_apps[@]}"; do
        IFS=":" read -r name path <<< "$item"
        if [[ -d "$path" ]]; then
            items_to_add+=("$name:$path")
            if $dry_run; then
                echo "  [DRY-RUN] Would add: $name"
            fi
        fi
    done
    
    if $dry_run || [[ ${#items_to_add[@]} -eq 0 ]]; then
        return 0
    fi
    
    # Build AppleScript
    local osascript_items=""
    for item in "${items_to_add[@]}"; do
        IFS=":" read -r name path <<< "$item"
        [[ -n "$osascript_items" ]] && osascript_items+=", "
        osascript_items+="{name:\"$name\", path:\"$path\", hidden:false}"
        echo "  Adding: $name"
    done
    
    osascript <<OSA 2>/dev/null || true
tell application "System Events"
    set desiredItems to {$osascript_items}
    repeat with itemProps in desiredItems
        set itemName to name of itemProps
        if exists login item itemName then delete login item itemName
    end repeat
    repeat with itemProps in desiredItems
        make new login item with properties itemProps
    end repeat
end tell
OSA
    
    echo "  Login items configured"
}

# Configure Stage Manager / Desktop
macos_configure_desktop() {
    local dry_run="${1:-false}"
    
    echo "Configuring Desktop..."
    
    if $dry_run; then
        echo "  [DRY-RUN] Would configure desktop preferences"
        return 0
    fi
    
    # Disable click-to-show-desktop in Stage Manager
    defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false 2>/dev/null || true
    
    # Don't show recent applications in Dock
    defaults write com.apple.dock show-recents -bool false
    
    echo "  Desktop configured"
}

# Apply all configurations
macos_configure_all() {
    local dry_run="${1:-false}"
    
    if ! macos_is_supported; then
        echo "macOS configuration is only available on macOS"
        return 1
    fi
    
    echo ""
    echo "Applying macOS developer preferences..."
    echo ""
    
    macos_configure_dock "$dry_run"
    macos_configure_trackpad "$dry_run"
    macos_configure_finder "$dry_run"
    macos_configure_keyboard "$dry_run"
    macos_configure_desktop "$dry_run"
    macos_configure_login_items "$dry_run"
    
    if ! $dry_run; then
        # Restart affected applications
        echo ""
        echo "Restarting Dock and Finder..."
        killall Dock 2>/dev/null || true
        killall Finder 2>/dev/null || true
    fi
    
    echo ""
    echo "macOS preferences applied!"
    echo "Note: Some changes may require logout/restart to take effect."
}

# Setup Dock apps (separate function for post-install)
macos_setup_dock() {
    local dry_run="${1:-false}"
    
    if ! macos_is_supported; then
        echo "macOS configuration is only available on macOS"
        return 1
    fi
    
    macos_setup_dock_apps "$dry_run"
    
    if ! $dry_run; then
        killall Dock 2>/dev/null || true
    fi
}
