#!/bin/bash

# Enhanced Claude.nvim Installation Script
# This script copies the enhanced Claude plugin to your Neovim configuration

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Enhanced Claude.nvim Installation Script${NC}"
echo -e "${BLUE}=============================================${NC}"

# Get the current directory (should be the claude-nvim repo)
SOURCE_DIR="$(pwd)"
NVIM_CONFIG_DIR="$HOME/.config/nvim"
PLUGIN_DIR="$NVIM_CONFIG_DIR/lua/claude-enhanced"

echo -e "${YELLOW}📁 Source directory: $SOURCE_DIR${NC}"
echo -e "${YELLOW}📁 Neovim config: $NVIM_CONFIG_DIR${NC}"
echo -e "${YELLOW}📁 Plugin destination: $PLUGIN_DIR${NC}"

# Check if we're in the right directory
if [[ ! -f "lua/claude/init.lua" ]]; then
    echo -e "${RED}❌ Error: This script must be run from the claude-nvim repository directory${NC}"
    echo -e "${RED}   Current directory: $SOURCE_DIR${NC}"
    echo -e "${RED}   Expected to find: lua/claude/init.lua${NC}"
    exit 1
fi

# Check if Neovim config directory exists
if [[ ! -d "$NVIM_CONFIG_DIR" ]]; then
    echo -e "${RED}❌ Error: Neovim config directory not found: $NVIM_CONFIG_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Validation passed${NC}"

# Create the plugin directory structure
echo -e "${BLUE}📂 Creating directory structure...${NC}"
mkdir -p "$PLUGIN_DIR/utils"
mkdir -p "$NVIM_CONFIG_DIR/lua/plugins"

# Copy the enhanced plugin files
echo -e "${BLUE}📋 Copying enhanced plugin files...${NC}"

# Check if files exist before copying
if [[ ! -f "lua/claude/init.lua" ]]; then
    echo -e "${RED}❌ Error: lua/claude/init.lua not found${NC}"
    exit 1
fi

# Copy main files
cp "lua/claude/init.lua" "$PLUGIN_DIR/init.lua"
echo -e "${GREEN}  ✅ Copied init.lua${NC}"

# Copy utils directory (check if each file exists)
if [[ -f "lua/claude/utils/context.lua" ]]; then
    cp "lua/claude/utils/context.lua" "$PLUGIN_DIR/utils/context.lua"
    echo -e "${GREEN}  ✅ Copied utils/context.lua${NC}"
fi

if [[ -f "lua/claude/utils/render.lua" ]]; then
    cp "lua/claude/utils/render.lua" "$PLUGIN_DIR/utils/render.lua"
    echo -e "${GREEN}  ✅ Copied utils/render.lua${NC}"
fi

if [[ -f "lua/claude/utils/session.lua" ]]; then
    cp "lua/claude/utils/session.lua" "$PLUGIN_DIR/utils/session.lua"
    echo -e "${GREEN}  ✅ Copied utils/session.lua${NC}"
fi

if [[ -f "lua/claude/utils/actions.lua" ]]; then
    cp "lua/claude/utils/actions.lua" "$PLUGIN_DIR/utils/actions.lua"
    echo -e "${GREEN}  ✅ Copied utils/actions.lua${NC}"
fi

if [[ -f "lua/claude/utils/debug.lua" ]]; then
    cp "lua/claude/utils/debug.lua" "$PLUGIN_DIR/utils/debug.lua"
    echo -e "${GREEN}  ✅ Copied utils/debug.lua${NC}"
fi

# Copy other files
if [[ -f "README.md" ]]; then
    cp "README.md" "$PLUGIN_DIR/README.md"
    echo -e "${GREEN}  ✅ Copied README.md${NC}"
fi

# Fix require paths in the copied files
echo -e "${BLUE}🔧 Fixing require paths...${NC}"

# Fix init.lua require paths
sed -i.bak 's/require('\''claude\.utils\./require('\''claude-enhanced.utils./g' "$PLUGIN_DIR/init.lua"
echo -e "${GREEN}  ✅ Fixed init.lua require paths${NC}"

# Fix debug.lua require paths
sed -i.bak 's/require('\''claude\.utils\./require('\''claude-enhanced.utils./g' "$PLUGIN_DIR/utils/debug.lua"
echo -e "${GREEN}  ✅ Fixed debug.lua require paths${NC}"

# Remove backup files
rm -f "$PLUGIN_DIR/init.lua.bak"
rm -f "$PLUGIN_DIR/utils/debug.lua.bak"

# Create the lazy.nvim plugin configuration
echo -e "${BLUE}⚙️  Creating plugin configuration...${NC}"

cat > "$NVIM_CONFIG_DIR/lua/plugins/claude-enhanced.lua" << 'EOF'
return {
  dir = vim.fn.stdpath("config") .. "/lua/claude-enhanced",
  name = "claude-enhanced",
  event = "VeryLazy",
  config = function()
    require("claude-enhanced").setup({
      -- Enhanced Claude.nvim Configuration

      -- Smart context features (all automatic)
      smart_context = {
        auto_include_file = true,    -- 🎯 Include current file automatically
        auto_include_errors = true,  -- 🐛 Include LSP errors
        remember_per_project = true, -- 💾 Remember conversations per project
        max_context_lines = 50,      -- Limit context size
        show_line_numbers = true,    -- Include line numbers
      },

      -- Quick actions in Claude window
      quick_actions = {
        enabled = true,              -- ⚡ Enable y/p/n shortcuts
        return_to_source = true,     -- 🔄 Return focus after actions
        auto_copy_code = true,       -- Auto-copy code suggestions
      },

      -- Float window settings (35% width - perfect for coding)
      float = {
        width = 0.35,                -- 35% of screen width
        height = 0.8,                -- 80% of screen height
        border = "rounded",
        title_dynamic = true,        -- 📝 Show project + file in title
      },

      -- UI enhancements
      ui = {
        syntax_highlight = true,     -- Syntax highlighting
        markdown_render = true,      -- Markdown rendering
        show_context_info = true,    -- Show context notifications
      },

      -- Keymaps (customize if needed)
      keymaps = {
        execute = "<leader>CC",      -- Execute in split
        execute_float = "<leader>CF", -- Execute in float (recommended)
        execute_right = "<leader>CR", -- Execute in right split
        send_selection = "<leader>CS", -- Send selection
        send_buffer = "<leader>CB",  -- Send buffer
        send_git_diff = "<leader>CG", -- Send git diff
        debug = "<leader>CT",        -- Debug mode
        quick_review = "<leader>CQ", -- Quick code review
        explain_code = "<leader>CE", -- Explain current code
      },
    })
  end,

  -- 🎮 Usage:
  -- <leader>CF - Open enhanced floating window (recommended)
  -- <leader>CR - Open enhanced right split (35% width)
  -- <leader>CQ - Quick code review
  -- <leader>CE - Explain current code
  -- <leader>CT - Run debug diagnostics
  --
  -- In Claude window:
  -- y - Yank code suggestion
  -- p - Paste to source file
  -- n - Create new file
  -- ? - Show help
  --
  -- Commands:
  -- :ClaudeFloat, :ClaudeRight, :ClaudeDebug
  -- :ClaudeReview, :ClaudeExplain, :ClaudeRefactor
}
EOF

echo -e "${GREEN}  ✅ Created lazy.nvim configuration${NC}"

# Create a quick reference file
cat > "$PLUGIN_DIR/QUICK_REFERENCE.md" << 'EOF'
# 🚀 Enhanced Claude.nvim - Quick Reference

## Basic Usage
- `<leader>CF` - Open enhanced floating window (recommended)
- `<leader>CR` - Open enhanced right split (35% width)
- `<leader>CC` - Open horizontal split

## Enhanced Features
- `<leader>CQ` - Quick code review of current file/selection
- `<leader>CE` - Explain current code in detail
- `<leader>CT` - Run debug diagnostics
- `<leader>CG` - Send git diff to Claude

## In Claude Window (Quick Actions)
- `y` - Yank code suggestion to clipboard
- `p` - Paste code directly to source file
- `n` - Create new file with Claude's code
- `?` - Show available actions

## Commands
- `:ClaudeFloat` - Open enhanced floating window
- `:ClaudeRight` - Open enhanced right split
- `:ClaudeDebug` - Run comprehensive diagnostics
- `:ClaudeReview` - Start code review session
- `:ClaudeExplain` - Explain selected/current code
- `:ClaudeRefactor` - Get refactoring suggestions

## Smart Features (Automatic)
✅ Auto-include current file context
✅ Smart error detection from LSP
✅ Project awareness with git info
✅ Session persistence per project
✅ Dynamic window titles
✅ Clean exits (no sourcemap messages)
✅ Syntax highlighting in responses

## Troubleshooting
Run `:ClaudeDebug` to check all features and system requirements.
EOF

echo -e "${GREEN}  ✅ Created quick reference${NC}"

# Show installation summary
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo -e "${GREEN}======================${NC}"
echo ""
echo -e "${BLUE}📁 Installed files:${NC}"
echo -e "   $PLUGIN_DIR/init.lua"
echo -e "   $PLUGIN_DIR/utils/ (5 files)"
echo -e "   $NVIM_CONFIG_DIR/lua/plugins/claude-enhanced.lua"
echo ""
echo -e "${YELLOW}🚀 Next Steps:${NC}"
echo -e "   1. Restart Neovim or run ${BLUE}:Lazy reload claude-enhanced${NC}"
echo -e "   2. Press ${BLUE}<leader>CF${NC} to open enhanced Claude"
echo -e "   3. Use ${BLUE}<leader>CQ${NC} for quick code review"
echo -e "   4. Run ${BLUE}:ClaudeDebug${NC} to test all features"
echo ""
echo -e "${YELLOW}📚 Documentation:${NC}"
echo -e "   Quick reference: ${BLUE}$PLUGIN_DIR/QUICK_REFERENCE.md${NC}"
echo -e "   Full docs: ${BLUE}$PLUGIN_DIR/README.md${NC}"
echo ""
echo -e "${GREEN}✨ Enhanced Claude.nvim is ready to use! ✨${NC}"
