-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result + center" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search result + center" })

-- ============================================================================
-- Navigazione finestre stile schede browser (Alt+1..8 = finestra N, Alt+9 = ultima)
-- ============================================================================
-- Salta direttamente alla finestra (split) numero N contando da sinistra.
-- Funziona da Normal mode e anche da dentro il terminale (esce in automatico).

local function go_to_window(n)
  return function()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    -- Ordina le finestre per posizione (colonna, poi riga) cosi' "1" e' sempre
    -- la piu' a sinistra/in alto, come ci si aspetta visivamente.
    table.sort(wins, function(a, b)
      local pa = vim.api.nvim_win_get_position(a)
      local pb = vim.api.nvim_win_get_position(b)
      if pa[2] ~= pb[2] then
        return pa[2] < pb[2]
      end
      return pa[1] < pb[1]
    end)
    local target = (n == 9) and wins[#wins] or wins[n]
    if target then
      vim.api.nvim_set_current_win(target)
    end
  end
end

for i = 1, 9 do
  -- Normal mode: Alt+i salta alla finestra i (9 = ultima)
  vim.keymap.set("n", "<M-" .. i .. ">", go_to_window(i), { desc = "Vai alla finestra " .. (i == 9 and "ultima" or i) })
  -- Terminal mode: esce prima dal terminale, poi salta alla finestra
  vim.keymap.set("t", "<M-" .. i .. ">", function()
    vim.cmd("stopinsert")
    go_to_window(i)()
  end, { desc = "Vai alla finestra " .. (i == 9 and "ultima" or i) .. " (da terminale)" })
end

-- ============================================================================
-- Uscita dal terminale con doppio Esc (al posto di Ctrl-\ Ctrl-n)
-- ============================================================================
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Esci dalla modalita' terminale" })

-- ============================================================================
-- Navigazione finestre comoda con Ctrl+h/j/k/l (senza il prefisso Ctrl-w)
-- ============================================================================
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Vai alla finestra a sinistra" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Vai alla finestra in basso" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Vai alla finestra in alto" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Vai alla finestra a destra" })
