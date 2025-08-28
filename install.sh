#!/bin/bash

# Claude Code Agents Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/yourusername/cc-agents/main/install.sh | bash
# Or: curl -fsSL https://raw.githubusercontent.com/yourusername/cc-agents/main/install.sh | bash -s -- --stack work

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/buzzwordmojo/cc-agents.git"
RAW_URL="https://raw.githubusercontent.com/buzzwordmojo/cc-agents/main"
AGENT_DIR=".claude/agents"

# Print colored output
print_color() {
    printf "${1}${2}${NC}\n"
}

print_header() {
    echo
    print_color "$BLUE" "=============================================="
    print_color "$BOLD$BLUE" "  Claude Code Agents Installer"
    print_color "$BLUE" "=============================================="
    echo
}

print_success() {
    print_color "$GREEN" "✅ $1"
}

print_warning() {
    print_color "$YELLOW" "⚠️  $1"
}

print_error() {
    print_color "$RED" "❌ $1"
}

print_info() {
    print_color "$BLUE" "ℹ️  $1"
}

# Check if we're in a valid project directory
check_project() {
    if [[ ! -f "package.json" ]]; then
        print_error "No package.json found. Please run this in a Next.js project directory."
        exit 1
    fi
    
    print_success "Found Next.js project"
}

# Create .claude/agents directory if it doesn't exist
setup_directory() {
    if [[ ! -d "$AGENT_DIR" ]]; then
        mkdir -p "$AGENT_DIR"
        print_success "Created $AGENT_DIR directory"
    else
        print_info "$AGENT_DIR directory already exists"
    fi
}

# Download agent file
download_agent() {
    local agent_name="$1"
    local agent_file="$2"
    local url="${RAW_URL}/agents/${agent_name}/${agent_file}"
    
    print_info "Installing $agent_name..."
    
    if curl -fsSL "$url" -o "$AGENT_DIR/$agent_file"; then
        print_success "Installed $agent_name"
    else
        print_error "Failed to download $agent_name"
        return 1
    fi
}

# Install agents based on stack
install_stack() {
    local stack="$1"
    local stack_file="${RAW_URL}/stacks/${stack}-stack.json"
    
    print_info "Fetching $stack stack configuration..."
    
    # Download stack configuration
    local stack_config=$(curl -fsSL "$stack_file")
    if [[ $? -ne 0 ]]; then
        print_error "Failed to fetch $stack stack configuration"
        exit 1
    fi
    
    # Parse agents from JSON (extract only from agents array)  
    local agents=$(echo "$stack_config" | sed -n '/"agents":/,/]/p' | grep -o '"[^"]*"' | grep -v '"agents"' | sed 's/"//g' | grep -v '^$')
    
    # Count agents properly
    local agent_count=$(echo "$agents" | wc -w)
    print_info "Installing $agent_count agents for $stack stack..."
    
    # Debug output
    if [[ "$DEBUG" == "1" ]]; then
        print_info "Agents to install: $agents"
    fi
    echo
    
    # Install each agent
    for agent in $agents; do
        case $agent in
            "spec-writer")
                download_agent "spec-writer" "prd-writer.md"
                ;;
            "fastapi-engineer")
                download_agent "fastapi-engineer" "python-backend-dev.md"
                ;;
            "nextjs-developer")
                download_agent "nextjs-developer" "react-typescript-specialist.md"
                ;;
            "convex-engineer")
                download_agent "convex-engineer" "convex-engineer.md"
                ;;
            "clerk-auth-specialist")
                download_agent "clerk-auth-specialist" "clerk-auth-specialist.md"
                ;;
            "shadcn-specialist")
                download_agent "tailwind-stylist" "shadcn-specialist.md"
                ;;
            *)
                download_agent "$agent" "${agent}.md"
                ;;
        esac
    done
}

# Show available stacks
show_stacks() {
    echo
    print_color "$BOLD" "Available Stacks:"
    echo
    print_color "$GREEN" "work     - FastAPI + Next.js + PostgreSQL + Azure (AI Focus)"
    print_color "$BLUE" "personal - Next.js + Convex + Clerk (Rapid Prototyping)"
    echo
    print_info "Usage examples:"
    echo "  curl -fsSL $RAW_URL/install.sh | bash -s -- --stack work"
    echo "  curl -fsSL $RAW_URL/install.sh | bash -s -- --stack personal"
    echo "  curl -fsSL $RAW_URL/install.sh | bash -s -- --interactive"
    echo
}

# Interactive stack selection
interactive_selection() {
    echo
    print_color "$BOLD" "Select your stack:"
    echo
    print_color "$GREEN" "1) Work Stack (FastAPI + Next.js + PostgreSQL + Azure)"
    print_color "$BLUE" "2) Personal Stack (Next.js + Convex + Clerk)" 
    print_color "$YELLOW" "3) Show all available agents"
    echo
    
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            install_stack "work"
            ;;
        2)
            install_stack "personal"
            ;;
        3)
            show_all_agents
            ;;
        *)
            print_error "Invalid choice. Please run again."
            exit 1
            ;;
    esac
}

# Show all available agents
show_all_agents() {
    print_info "Available agents:"
    echo
    
    # List all agents with descriptions
    agents=(
        "spec-writer:Product Requirements & Documentation"
        "fastapi-engineer:FastAPI + Pydantic + SQLAlchemy Backend"
        "nextjs-developer:React + TypeScript Frontend" 
        "convex-engineer:Convex Full-Stack TypeScript"
        "clerk-auth-specialist:Clerk Authentication Integration"
        "database-architect:Database Design & Optimization"
        "shadcn-specialist:shadcn/ui Component Implementation"
        "playwright-tester:End-to-End Testing Setup"
        "api-tester:FastAPI Testing with pytest"
        "bug-investigator:Systematic Debugging & Analysis"
        "clickup-manager:ClickUp API Integration"
        "pydantic-validator:Data Validation & Schemas"
    )
    
    for agent in "${agents[@]}"; do
        name="${agent%%:*}"
        desc="${agent##*:}"
        print_color "$GREEN" "  $name - $desc"
    done
    
    echo
    print_info "Install individual agents:"
    print_info "curl -fsSL $RAW_URL/agents/[agent-name]/[agent-name].md -o .claude/agents/[agent-name].md"
}

# Main installation logic
main() {
    print_header
    
    # Parse command line arguments
    STACK=""
    INTERACTIVE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --stack)
                STACK="$2"
                shift 2
                ;;
            --interactive|-i)
                INTERACTIVE=true
                shift
                ;;
            --help|-h)
                show_stacks
                exit 0
                ;;
            --list)
                show_all_agents
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_stacks
                exit 1
                ;;
        esac
    done
    
    # Check if we're in a valid project
    check_project
    
    # Setup directory structure
    setup_directory
    
    # Determine installation method
    if [[ "$INTERACTIVE" == true ]]; then
        interactive_selection
    elif [[ -n "$STACK" ]]; then
        install_stack "$STACK"
    else
        print_info "No stack specified. Starting interactive mode..."
        interactive_selection
    fi
    
    echo
    print_success "Installation complete! 🎉"
    echo
    print_info "Your Claude Code agents are now available in $AGENT_DIR"
    print_info "Use 'claude agents list' to see installed agents"
    print_info "Use 'claude agents [agent-name]' to activate an agent"
    echo
}

# Run main function
main "$@"