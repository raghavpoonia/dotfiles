-- init.lua
-- raghavpoonia/dotfiles
-- LazyVim distribution: https://lazyvim.org

-- ── Bootstrap LazyVim ────────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.lang.yaml" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
  },
  defaults = { lazy = false, version = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})

-- ── Core options ──────────────────────────────────────────────────────────────
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.wrap = false
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.clipboard = "unnamedplus"

-- ── Keymaps ───────────────────────────────────────────────────────────────────
local map = vim.keymap.set

-- Disable arrow keys — forces hjkl muscle memory
map("n", "<Up>",    "<Nop>", { desc = "Use k" })
map("n", "<Down>",  "<Nop>", { desc = "Use j" })
map("n", "<Left>",  "<Nop>", { desc = "Use h" })
map("n", "<Right>", "<Nop>", { desc = "Use l" })

-- Move between splits with Ctrl+hjkl (matches tmux config)
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower split" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper split" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })

-- Save with Ctrl+S
map({ "n", "i" }, "<C-s>", "<Cmd>w<CR>", { desc = "Save file" })

-- Clear search highlight
map("n", "<Esc>", "<Cmd>nohl<CR>", { desc = "Clear search highlight" })
