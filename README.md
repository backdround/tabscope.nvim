# Tabscope.nvim
It's a neovim plugin that turns `global` buffers into `tab-local` buffers.
So you can use buffers while have different contexts in different tabs.


### Preview
![tabscope-preview](https://user-images.githubusercontent.com/17349169/224853800-0d79e1fa-d200-4a10-a41e-1a4f2524a1a7.gif)


### Launching
```lua
require("tabscope").setup({})
```

### Session limitation
There is no way to get info about hidden buffers that loaded by session. So all
hidden buffers are dropped after session loaded.


### Inspired by
[scope.nvim](https://github.com/tiagovla/scope.nvim)
