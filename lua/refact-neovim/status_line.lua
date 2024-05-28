local completion = require("refact-neovim.completion")

return function()
  if completion.processing then
    local time = os.time()
    local animation = { "", "", "" }
    return animation[1 + time % 3] .. "  Refact.ai"
  else
    return "[( Refact.ai"
  end
end
