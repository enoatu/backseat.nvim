-- Automatically executed on startup
if vim.g.loaded_backseat then
    return
end
vim.g.loaded_backseat = true

require("backseat").setup()
-- TODO: switch setting
--local fewshot = require("backseat.fewshot") -- The training messages
local fewshot = require("backseat.bugfinder") -- The training messages

-- Create namespace for backseat suggestions
local backseatNamespace = vim.api.nvim_create_namespace("backseat")

local function print(msg)
    _G.print("Backseat > " .. msg)
end

local function get_api_key()
    -- Priority: 1. g:backseat_openai_api_key 2. $OPENAI_API_KEY 3. Prompt user
    local api_key = vim.g.backseat_openai_api_key
    if api_key == nil then
        local key = os.getenv("OPENAI_API_KEY")
        if key ~= nil then
            return key
        end
        local message =
        "No API key found. Please set openai_api_key in the setup table or set the $OPENAI_API_KEY environment variable."
        vim.fn.confirm(message, "&OK", 1, "Warning")
        return nil
    end
    return api_key
end

local function get_api_endpoint()
    local api_endpoint = vim.g.backseat_openai_api_endpoint
    if api_endpoint == nil then
        local endpoint = os.getenv("OPENAI_API_ENDPOINT")
        if endpoint ~= nil then
            return endpoint
        end
        return "https://api.openai.com/v1/chat/completions"
    end
    return api_endpoint
end

local function get_model_id()
    local model = vim.g.backseat_openai_model_id
    if model == nil then
        if vim.g.backseat_model_id_complained == nil then
            local message =
            "No model id specified. Please set openai_model_id in the setup table. Defaulting to gpt-3.5-turbo for now" -- "gpt-4"
            vim.fn.confirm(message, "&OK", 1, "Warning")
            vim.g.backseat_model_id_complained = 1
        end
        return "gpt-3.5-turbo"
    end
    return model
end

local function get_language()
    return vim.g.backseat_language
end

local function get_additional_instruction()
    return vim.g.backseat_additional_instruction or ""
end

local function get_split_threshold()
    return vim.g.backseat_split_threshold
end

local function get_analyze_range_lines()
    return vim.g.backseat_analyze_range_lines
end

local function get_highlight_icon()
    return vim.g.backseat_highlight_icon
end

local function get_highlight_group()
    return vim.g.backseat_highlight_group
end

local function split_long_text(text)
    local lines = vim.split(text, "\n")
    local screenWidth = vim.api.nvim_win_get_width(0) - 20
    local newLines = {}
    for _, line in ipairs(lines) do
        if vim.fn.strdisplaywidth(line) > screenWidth then
            local currentLine = ""
            for _, word in ipairs(vim.split(line, "。")) do
                if vim.fn.strdisplaywidth(currentLine .. " " .. word) > screenWidth then
                    table.insert(newLines, currentLine)
                    currentLine = word
                else
                    currentLine = currentLine == "" and word or currentLine .. " " .. word
                end
            end
            table.insert(newLines, currentLine)
        else
            table.insert(newLines, line)
        end
    end
    return newLines
end

local function gpt_request(dataJSON, callback, callbackTable)
    local api_key = get_api_key()
    if api_key == nil then
        return nil
    end

    -- Check if curl is installed
    if vim.fn.executable("curl") == 0 then
        vim.fn.confirm("curl installation not found. Please install curl to use Backseat", "&OK", 1, "Warning")
        return nil
    end

    local curlRequest

    -- Create temp file
    local tempFilePath = vim.fn.tempname()
    local tempFile = io.open(tempFilePath, "w")
    if tempFile == nil then
        print("Error creating temp file")
        return nil
    end
    -- Write dataJSON to temp file
    tempFile:write(dataJSON)
    tempFile:close()

    -- Escape the name of the temp file for command line
    local tempFilePathEscaped = vim.fn.fnameescape(tempFilePath)

    -- Check if the user is on windows
    local isWindows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

    if isWindows ~= true then
        -- Linux
        curlRequest = string.format(
            "curl -s " .. get_api_endpoint() .. "/v1/chat/completions -H \"Content-Type: application/json\" -H \"Authorization: Bearer " ..
            api_key ..
            "\" --data-binary \"@" .. tempFilePathEscaped .. "\"; rm " .. tempFilePathEscaped .. " > /dev/null 2>&1"
        )
    else
        -- Windows
        curlRequest = string.format(
            "curl -s " .. get_api_endpoint() .. "/v1/chat/completions -H \"Content-Type: application/json\" -H \"Authorization: Bearer " ..
            api_key ..
            "\" --data-binary \"@" .. tempFilePathEscaped .. "\" & del " .. tempFilePathEscaped .. " > nul 2>&1"
        )
    end

    -- vim.fn.confirm(curlRequest, "&OK", 1, "Warning")

    vim.fn.jobstart(curlRequest, {
        stdout_buffered = true,
        on_stdout = function(_, data, _)
            local response = table.concat(data, "\n")
            local success, responseTable = pcall(vim.json.decode, response)

            if success == false or responseTable == nil then
                if response == nil then
                    response = "nil"
                end
                print("Bad or no response: " .. response)
                return nil
            end

            if responseTable.error ~= nil then
                print("OpenAI Error: " .. responseTable.error.message)
                return nil
            end

            -- print(response)
            callback(responseTable, callbackTable)
            -- return response
        end,
        on_stderr = function(_, data, _)
            return data
        end,
        on_exit = function(_, data, _)
            return data
        end,
    })

    -- vim.cmd("sleep 10000m") -- Sleep to give time to read the error messages
end

local function parse_response(response, partNumberString, bufnr)
    -- split response.choices[1].message.content into lines
    local lines = vim.split(response.choices[1].message.content, "\n")
    --Suggestions may span multiple lines, so we need to change the list of lines into a list of suggestions
    local suggestions = {}

    -- Add each line to the suggestions table if it starts with line= or lines=
    for _, line in ipairs(lines) do
        if (string.sub(line, 1, 5) == "line=") or string.sub(line, 1, 6) == "lines=" then
            -- Add this line to the suggestions table
            table.insert(suggestions, line)
        elseif #suggestions > 0 then
            -- Append lines that don't start with line= or lines= to the previous suggestion
            suggestions[#suggestions] = suggestions[#suggestions] .. "\n" .. line
        end
    end

    -- if #suggestions == 0 then
    --     print("AI Says: " ..
    --     response.choices[1].message.content ..
    --     get_model_id() .. partNumberString)
    -- else
    --     print("AI made " ..
    --     #suggestions ..
    --     " suggestion(s) using " ..
    --     get_model_id() .. partNumberString)
    -- end

    -- Clear all existing backseat virtual text and signs

    -- Act on each suggestion
    for _, suggestion in ipairs(suggestions) do
        -- Get the line number
        local lineString = string.sub(suggestion, 6, string.find(suggestion, ":") - 1)
        -- The string may be in the format "line=1-3", so we can extract the first number
        if string.find(lineString, "-") ~= nil then
            lineString = string.sub(lineString, 1, string.find(lineString, "-") - 1)
        end
        local lineNum = tonumber(lineString)

        if lineNum == nil then
            -- print("Bad line number: " .. line)
            -- If the line number is bad, just add the suggestion to the first line
            lineNum = 1
            -- goto continue
        end
        -- Get the message
        local message = string.sub(suggestion, string.find(suggestion, ":") + 1, string.len(suggestion))
        -- If the first character is a space, remove it
        if string.sub(message, 1, 1) == " " then
            message = string.sub(message, 2, string.len(message))
        end
        -- print("Line " .. lineNum .. ": " .. message)

        -- Split suggestion into line, highlight group pairs
        local newLines = split_long_text(message)

        local pairs = {}
        for i, line in ipairs(newLines) do
            local pair = {}
            pair[1] = line
            pair[2] = get_highlight_group()
            pairs[i] = { pair }
        end

        -- check buffer exists
        if not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end

        -- すでに同じ行+2-2にvirtual textがある場合は既存のものを削除
        vim.api.nvim_buf_clear_namespace(bufnr, backseatNamespace, lineNum - 3, lineNum + 2)

        -- Add suggestion virtual text and a lightbulb icon to the sign column
        vim.api.nvim_buf_set_extmark(bufnr, backseatNamespace, lineNum - 1, 0, {
            virt_text_pos = "overlay",
            virt_lines = pairs,
            hl_mode = "combine",
            sign_text = get_highlight_icon(),
            sign_hl_group = get_highlight_group()
        })
        -- ::continue::
    end
end

local function prepare_code_snippet(bufnr, startingLineNumber, endingLineNumber)
    -- print("Preparing code snippet from lines " .. startingLineNumber .. " to " .. endingLineNumber)
    local lines = vim.api.nvim_buf_get_lines(bufnr, startingLineNumber - 1, endingLineNumber, false)

    -- Get the max number of digits needed to display a line number
    local maxDigits = string.len(tostring(#lines + startingLineNumber))
    -- Prepend each line with its line number zero padded to numDigits
    for i, line in ipairs(lines) do
        lines[i] = string.format("%0" .. maxDigits .. "d", i - 1 + startingLineNumber) .. " " .. line
    end

    local text = table.concat(lines, "\n")
    return text
end

local backseat_callback
local function backseat_send_from_request_queue(callbackTable)
    -- Stop if there are no more requests in the queue
    if (#callbackTable.requests == 0) then
        return nil
    end

    -- Get bufname without the path
    local bufname = vim.fn.fnamemodify(vim.fn.bufname(callbackTable.bufnr), ":t")

    -- if callbackTable.requestIndex == 0 then
    --     if callbackTable.startingRequestCount == 1 then
    --         print("Sending " .. bufname .. " (" .. callbackTable.lineCount .. " lines) and waiting for response...")
    --     else
    --         print("Sending " ..
    --         bufname .. " (split into " .. callbackTable.startingRequestCount .. " requests) and waiting for response...")
    --     end
    -- end

    -- Get the first request from the queue
    local requestJSON = table.remove(callbackTable.requests, 1)
    callbackTable.requestIndex = callbackTable.requestIndex + 1

    gpt_request(requestJSON, backseat_callback, callbackTable)
end

-- Callback for a backseat request
function backseat_callback(responseTable, callbackTable)
    if responseTable ~= nil then
        if callbackTable.startingRequestCount == 1 then
            parse_response(responseTable, "", callbackTable.bufnr)
        else
            parse_response(responseTable,
                " (request " .. callbackTable.requestIndex .. " of " .. callbackTable.startingRequestCount .. ")",
                callbackTable.bufnr)
        end
    end

    if callbackTable.requestIndex < callbackTable.startingRequestCount + 1 then
        backseat_send_from_request_queue(callbackTable)
    end
end

-- Send the current buffer to the AI for readability feedback
vim.api.nvim_create_user_command("Backseat", function()
    -- Split the current buffer into groups of lines of size splitThreshold
    local splitThreshold = get_split_threshold()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local execLineNum = 200
    local numRequests = math.ceil(execLineNum / splitThreshold)
    local model = get_model_id()

    local requestTable = {
        model = model,
        messages = fewshot.messages
    }

    local requests = {}
    local startPos = 0
    -- 現在の表示中の範囲だけ取得するためにstartPosを設定
    if vim.api.nvim_buf_line_count(bufnr) > execLineNum then
        local winHeight = vim.api.nvim_win_get_height(0)  -- 現在のウィンドウの高さを取得
        local cursorLine = vim.api.nvim_win_get_cursor(0)[1]  -- カーソルの行番号を取得
        local middleLine = cursorLine + math.floor(winHeight / 2)  -- ウィンドウの中央行の行番号を計算
        startPos = middleLine - execLineNum / 2
        if startPos < 1 then
            startPos = 1
        end
    end
    for i = 1, numRequests do
        local startingLineNumber = startPos + (i - 1) * splitThreshold + 1
        local text = prepare_code_snippet(bufnr, startingLineNumber, startingLineNumber + splitThreshold - 1)

        if get_additional_instruction() ~= "" then
            text = text .. "\n" .. get_additional_instruction()
        end

        if get_language() ~= "" and get_language() ~= "english" then
            text = text .. "\nRespond only in " .. get_language() .. ", but keep the 'line=<num>:' part in english"
        end

        -- Make a copy of requestTable (value not reference)
        local tempRequestTable = vim.deepcopy(requestTable)

        -- Add the code snippet to the request
        table.insert(tempRequestTable.messages, {
            role = "user",
            content = text
        })

        local requestJSON = vim.json.encode(tempRequestTable)
        requests[i] = requestJSON
        -- print(requestJSON)
    end

    backseat_send_from_request_queue({
        requests = requests,
        startingRequestCount = numRequests,
        requestIndex = 0,
        bufnr = bufnr,
        lineCount = execLineNum,
    })
    -- require("backseat.main"):run()
end, {})

-- Use the underlying chat API to ask a question about the current buffer's code
local function backseat_ask_callback(responseTable)
    if responseTable == nil then
        return nil
    end
    local message = "AI Says: " .. responseTable.choices[1].message.content

    -- Split long messages into multiple lines
    message = table.concat(split_long_text(message), "\r\n")

    vim.fn.confirm(message, "&OK", 1, "Generic")
end

vim.api.nvim_create_user_command("BackseatAsk", function(opts)
    local bufnr = vim.api.nvim_get_current_buf()
    local text = prepare_code_snippet(bufnr, 1, -1)

    if get_additional_instruction() ~= "" then
        text = text .. "\n" .. get_additional_instruction()
    end

    if get_language() ~= "" and get_language() ~= "english" then
        text = text .. "\nRespond only in " .. get_language()
    end

    local bufname = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ":t")

    print("Asking AI '" .. opts.args .. "' (in " .. bufname .. ")...")

    gpt_request(vim.json.encode(
        {
            model = get_model_id(),
            messages = {
                {
                    role = "system",
                    content = "You are a helpful assistant who can respond to questions about the following code. You can also act as a regular assistant"
                },
                {
                    role = "user",
                    content = text
                },
                {
                    role = "user",
                    content = opts.args
                }
            },
        }
    ), backseat_ask_callback)
end, { nargs = "+" })

-- Clear all backseat virtual text and signs
vim.api.nvim_create_user_command("BackseatClear", function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, backseatNamespace, 0, -1)
end, {})

-- Clear backseat virtual text and signs for that line
vim.api.nvim_create_user_command("BackseatClearLine", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local lineNum = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_clear_namespace(bufnr, backseatNamespace, lineNum - 1, lineNum)
end, {})

--
-- local last_cursor_position = {0, 0}
-- local last_cursor_time = vim.loop.now()
--
-- -- カーソルの位置を監視するautocmdを設定
-- vim.api.nvim_exec([[
--     autocmd CursorMoved * call luaeval("update_cursor_position()")
-- ]], false)
--
-- -- カーソル位置が更新されたときに呼び出される関数
-- function update_cursor_position()
--     local current_time = vim.loop.now()
--     local current_cursor_position = vim.api.nvim_win_get_cursor(0)
--     -- 前回のカーソル位置と現在のカーソル位置が同じでない場合
--     if current_cursor_position[1] ~= last_cursor_position[1] or current_cursor_position[2] ~= last_cursor_position[2] then
--         local time_difference = (current_time - last_cursor_time) / 1000 -- ミリ秒を秒に変換
--         -- print("カーソルが移動してからの経過時間（秒）: " .. time_difference)
--         last_cursor_position = current_cursor_position
--         last_cursor_time = current_time
--     end
-- end
--
-- -- 5秒以内にカーソルが移動しているかどうかを返す
-- function is_active()
--     local border_time = 30
--     local current_time = vim.loop.now()
--     local time_difference = (current_time - last_cursor_time) / 1000
--     return time_difference < border_time
-- end
--
-- function setup_timer()
--     -- 初回実行(0秒後に実行)
--     vim.fn.timer_start(0, function()
--     --    vim.cmd("Backseat")
--     end)
--     -- 3分ごとに実行するためのタイマーを設定
--     vim.fn.timer_start(20000, function()
--         -- タイマーがトリガーされたときに実行されるコード
--         -- ユーザーがアクティブかどうかを確認
--         if not is_active() then
--             print("ユーザーがアクティブではありません")
--             return
--         end
--     --    vim.cmd("Backseat")
--     end, {["repeat"] = 100})
-- end
-- -- buffer 切り替え時、保存時、ファイル読み込み時にタイマーを設定
-- vim.cmd("autocmd BufEnter,BufWritePost,FileReadPost * lua setup_timer()")

-- スクロール時にタイマーを設定
local timer_id = nil
-- スクロール後に実行される関数
local function on_scroll_stop()
    -- print("1秒経過したので関数を実行します")
    vim.cmd("Backseat")
end
-- タイマーをリセットする関数
function reset_timer()
    -- すでにタイマーが動作している場合はキャンセルする
    if timer_id ~= nil then
        vim.fn.timer_stop(timer_id)
    end
    -- 1秒後に on_scroll_stop 関数を実行するタイマーをセットする
    timer_id = vim.fn.timer_start(1000, function()
        on_scroll_stop()
        timer_id = nil
    end)
end
-- スクロールが停止したときに呼び出されるautocmd
vim.cmd([[
augroup ScrollStop
  autocmd!
  autocmd BufEnter,WinScrolled * lua reset_timer()
augroup END
]])

