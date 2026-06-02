#!/bin/bash

# RhoeLiquid Native Service Installation Script
# Installs the service as a macOS Launch Agent for auto-start capability

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVICE_NAME="com.rhoeliquid.service"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PLIST="$LAUNCH_AGENT_DIR/$SERVICE_NAME.plist"
LOG_DIR="$HOME/Library/Logs/RhoeLiquid"
INSTALL_DIR="$HOME/Library/Application Support/RhoeLiquid/bin"
SOURCE_BINARY="$REPO_DIR/.build/release/RhoeLiquidService"
INSTALLED_BINARY="$INSTALL_DIR/RhoeLiquidService"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

ensure_binary_installed() {
    if [[ ! -x "$SOURCE_BINARY" ]]; then
        log_info "Release binary not found; building RhoeLiquidService..."
        (
            cd "$REPO_DIR"
            swift build -c release --product RhoeLiquidService
        )
    fi

    if [[ ! -x "$SOURCE_BINARY" ]]; then
        log_error "Failed to build RhoeLiquidService at $SOURCE_BINARY"
        exit 1
    fi

    if [[ ! -d "$INSTALL_DIR" ]]; then
        log_info "Creating install directory at $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
    fi

    cp "$SOURCE_BINARY" "$INSTALLED_BINARY"
    chmod +x "$INSTALLED_BINARY"
    log_success "Installed RhoeLiquidService to $INSTALLED_BINARY"
}

create_log_directory() {
    if [[ ! -d "$LOG_DIR" ]]; then
        log_info "Creating log directory at $LOG_DIR"
        mkdir -p "$LOG_DIR"
        log_success "Log directory created"
    else
        log_info "Log directory already exists"
    fi
}

create_launch_agent_directory() {
    if [[ ! -d "$LAUNCH_AGENT_DIR" ]]; then
        log_info "Creating Launch Agent directory at $LAUNCH_AGENT_DIR"
        mkdir -p "$LAUNCH_AGENT_DIR"
        log_success "Launch Agent directory created"
    else
        log_info "Launch Agent directory already exists"
    fi
}

install_launch_agent() {
    log_info "Installing Launch Agent..."
    
    local plist_content=$(cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Service Identity -->
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    
    <!-- Program Configuration -->
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALLED_BINARY</string>
        <string>--service-mode</string>
        <string>--port</string>
        <string>13480</string>
        <string>--mode</string>
        <string>balanced</string>
        <string>--log-level</string>
        <string>info</string>
    </array>
    
    <!-- Service Behavior -->
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <dict>
        <key>Crashed</key>
        <true/>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    
    <!-- Process Management -->
    <key>ProcessType</key>
    <string>Interactive</string>
    
    <key>LimitLoadToSessionType</key>
    <array>
        <string>Aqua</string>
    </array>
    
    <!-- Resource Limits -->
    <key>SoftResourceLimits</key>
    <dict>
        <key>NumberOfFiles</key>
        <integer>1024</integer>
        <key>NumberOfProcesses</key>
        <integer>100</integer>
    </dict>
    
    <!-- Logging Configuration -->
    <key>StandardOutPath</key>
    <string>$LOG_DIR/service.log</string>
    
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/service-error.log</string>
    
    <!-- Environment Variables -->
    <key>EnvironmentVariables</key>
    <dict>
        <key>RHOELIQUID_SERVICE_MODE</key>
        <string>production</string>
        <key>RHOELIQUID_AUTO_START</key>
        <string>true</string>
    </dict>
    
    <!-- Working Directory -->
    <key>WorkingDirectory</key>
    <string>$REPO_DIR</string>
    
    <!-- Security -->
    <key>EnableGlobbing</key>
    <false/>
    
    <key>EnableTransactions</key>
    <false/>
    
    <!-- Throttling -->
    <key>ThrottleInterval</key>
    <integer>10</integer>
    
    <!-- Service Description -->
    <key>ServiceDescription</key>
    <string>RhoeLiquid Native Service - Revolutionary template processing engine for macOS</string>
</dict>
</plist>
EOF
)
    
    echo "$plist_content" > "$LAUNCH_AGENT_PLIST"
    log_success "Launch Agent plist created at $LAUNCH_AGENT_PLIST"
}

load_launch_agent() {
    log_info "Loading Launch Agent..."
    
    # Unload if already loaded (for updates)
    if launchctl list | grep -q "$SERVICE_NAME"; then
        log_info "Unloading existing service..."
        launchctl unload "$LAUNCH_AGENT_PLIST" 2>/dev/null || true
    fi
    
    # Load the service
    launchctl load "$LAUNCH_AGENT_PLIST"
    
    # Verify it's loaded
    if launchctl list | grep -q "$SERVICE_NAME"; then
        log_success "Launch Agent loaded successfully"
    else
        log_error "Failed to load Launch Agent"
        exit 1
    fi
}

check_service_status() {
    log_info "Checking service status..."
    
    sleep 3  # Give the service time to start
    
    # Check if the service is responding
    if curl -s -f http://localhost:13480/health > /dev/null 2>&1; then
        log_success "🚀 RhoeLiquid Native Service is running!"
        log_success "📍 Service URL: http://localhost:13480"
        log_success "📊 Health Check: http://localhost:13480/health"
        echo
        log_info "You can test the service with:"
        echo "  curl http://localhost:13480/"
    else
        log_warning "Service may still be starting up..."
        log_info "Check the logs at: $LOG_DIR/service.log"
    fi
}

show_usage() {
    echo "RhoeLiquid Native Service Installation Script"
    echo
    echo "Usage: $0 [OPTION]"
    echo
    echo "Options:"
    echo "  install     Build or refresh the release binary, install it, and start the service"
    echo "  uninstall   Stop and remove the service"
    echo "  status      Check service status"
    echo "  logs        Show service logs"
    echo "  restart     Restart the service"
    echo "  help        Show this help message"
    echo
}

uninstall_service() {
    log_info "Uninstalling RhoeLiquid Native Service..."
    
    if launchctl list | grep -q "$SERVICE_NAME"; then
        log_info "Stopping service..."
        launchctl unload "$LAUNCH_AGENT_PLIST"
        log_success "Service stopped"
    fi
    
    if [[ -f "$LAUNCH_AGENT_PLIST" ]]; then
        log_info "Removing Launch Agent plist..."
        rm "$LAUNCH_AGENT_PLIST"
        log_success "Launch Agent removed"
    fi

    if [[ -f "$INSTALLED_BINARY" ]]; then
        log_info "Removing installed binary..."
        rm "$INSTALLED_BINARY"
        log_success "Installed binary removed"
    fi
    
    log_success "RhoeLiquid Native Service uninstalled"
}

show_status() {
    log_info "Checking RhoeLiquid Native Service status..."
    
    if launchctl list | grep -q "$SERVICE_NAME"; then
        log_success "✅ Launch Agent is loaded"
        
        if curl -s -f http://localhost:13480/health > /dev/null 2>&1; then
            log_success "✅ Service is responding on port 13480"
            
            # Get service info
            local service_info=$(curl -s http://localhost:13480/ 2>/dev/null || echo "{}")
            echo
            echo "Service Information:"
            echo "$service_info" | python3 -m json.tool 2>/dev/null || echo "$service_info"
        else
            log_warning "⚠️  Service is not responding on port 13480"
        fi
    else
        log_error "❌ Launch Agent is not loaded"
    fi
}

show_logs() {
    log_info "Showing RhoeLiquid Native Service logs..."
    
    if [[ -f "$LOG_DIR/service.log" ]]; then
        echo
        echo "=== Service Output Log ==="
        tail -n 50 "$LOG_DIR/service.log"
    else
        log_warning "No service log found at $LOG_DIR/service.log"
    fi
    
    if [[ -f "$LOG_DIR/service-error.log" ]]; then
        echo
        echo "=== Service Error Log ==="
        tail -n 50 "$LOG_DIR/service-error.log"
    else
        log_info "No error log found (this is good!)"
    fi
}

restart_service() {
    log_info "Restarting RhoeLiquid Native Service..."
    
    if launchctl list | grep -q "$SERVICE_NAME"; then
        launchctl unload "$LAUNCH_AGENT_PLIST"
        sleep 2
        launchctl load "$LAUNCH_AGENT_PLIST"
        log_success "Service restarted"
        check_service_status
    else
        log_error "Service is not installed"
        exit 1
    fi
}

# Main execution
case "${1:-install}" in
    install)
        log_info "🚀 Installing RhoeLiquid Native Service..."
        echo
        
        ensure_binary_installed
        create_log_directory
        create_launch_agent_directory
        install_launch_agent
        load_launch_agent
        check_service_status
        
        echo
        log_success "🎉 Installation complete!"
        log_info "The service will automatically start when you log in."
        log_info "Use './Scripts/install-service.sh status' to inspect the running service."
        ;;
    
    uninstall)
        uninstall_service
        ;;
    
    status)
        show_status
        ;;
    
    logs)
        show_logs
        ;;
    
    restart)
        restart_service
        ;;
    
    help|--help|-h)
        show_usage
        ;;
    
    *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac
