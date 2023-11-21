local telescope = require('telescope')
local builtin = require('telescope.builtin')

telescope.setup({
    pickers = {
        find_files = {
            theme = 'ivy'
       }
    }
})

vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '[f]ind [F]iles' })
vim.keymap.set('n', '<leader>fr', builtin.git_files, { desc = '[f]ind repo [F]iles' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[f]ind via [G]grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = '[f]ind [B]uffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '[f]ind [H]elp tags' })
vim.keymap.set('n', '<leader>fo', builtin.oldfiles, { desc = '[f]ind [O]ld files' })
