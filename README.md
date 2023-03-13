# Tabscope.nvim
It's a neovim plugin that turns `global` buffers into `tab-local` buffers.
So you can use buffers while have different contexts in different tabs.


### Launching
```lua
require("tabscope").setup({})
```

### Session limitation
There is no way to get info about hidden buffers that loaded by session. So all
hidden buffers are dropped after session loaded.


### Inspired by
[scope.nvim](https://github.com/tiagovla/scope.nvim)
