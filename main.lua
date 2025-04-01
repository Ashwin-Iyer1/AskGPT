local Device = require("device")
local InputContainer = require("ui/widget/container/inputcontainer")
local NetworkMgr = require("ui/network/manager")
local _ = require("gettext")
local UIManager = require("ui/uimanager")
local queryChatGPT = require("gpt_query")

local showChatGPTDialog = require("dialogs")
local UpdateChecker = require("update_checker")


local AskGPT = InputContainer:new {
  name = "askgpt",
  is_doc_only = true,
}

-- Flag to ensure the update message is shown only once per session
local updateMessageShown = false

function AskGPT:init()
  self.ui.highlight:addToHighlightDialog("askgpt_ChatGPT", function(_reader_highlight_instance)
    return {
      text = _("Ask ChatGPT"),
      enabled = Device:hasClipboard(),
      callback = function()
        NetworkMgr:runWhenOnline(function()
          if not updateMessageShown then
            UpdateChecker.checkForUpdates()
            updateMessageShown = true -- Set flag to true so it won't show again
          end
          showChatGPTDialog(self.ui, _reader_highlight_instance.selected_text.text)
        end)
      end,
    }
  end)
end

function AskGPT:onDictButtonsReady(dict_popup, buttons)
  if dict_popup.is_wiki_fullpage then
    return
  else
    if buttons[2] then
      table.insert(buttons[2], 1, {  -- Insert inside the first button group
          id = "GPTDefinition",
          text = _("askChat"),
          font_bold = true,
          callback = function()
            NetworkMgr:runWhenOnline(function()
              if not updateMessageShown then
                UpdateChecker.checkForUpdates()
                updateMessageShown = true
              end
              local InfoMessage = require("ui/widget/infomessage")
              local queryWord = dict_popup.word
              local systemDialog = {
                role = "system",
                content = "You are a helpful translation assistant. Provide direct translations without additional commentary."
              }
              local queryDialog = {systemDialog, {
                role = "user",
                content = "What is the definition of this word: ".. queryWord.. " given that the name of the book is: " .. self.ui.document:getProps().title
              }}
              local loading = InfoMessage:new{
                text = _("Loading..."),
                timeout = 0.1
              }
              UIManager:show(loading)
              UIManager:scheduleIn(0.1, function()
                UIManager:show(InfoMessage:new{
                  text = _(queryChatGPT(queryDialog)),
              })
              end)
            end)
          end
      })
    end  
  end
end
return AskGPT