--- Completion types that can be displayed to the user
---@class CompletionBase
---@field is_incomplete boolean
---@field source_state_id integer
---@field completion_index integer | nil

---@class TextCompletion : CompletionBase
---@field kind "text"
---@field text string
---@field dedent string
---@field should_retry boolean | nil
---@field is_incomplete boolean
---@field source_state_id integer
---@field completion_index integer | nil

---@class JumpCompletion : CompletionBase
---@field kind "jump"
---@field file_name string
---@field line_number integer
---@field verify string | nil
---@field precedede string[]
---@field follow string[]
---@field is_create_file boolean

---@class DeleteCompletion : CompletionBase
---@field kind "delete"
---@field lines string[]
---@field completion_index integer
---@field source_state_id integer

---@class SkipCompletion : CompletionBase
---@field kind "skip"
---@field n integer
---@field completion_index integer
---@field source_state_id integer

---@alias AnyCompletion TextCompletion | JumpCompletion | DeleteCompletion | SkipCompletion


---@class CompletionParams
---@field line_before_cursor string
---@field line_after_cursor string
---@field get_following_line fun(line: string): string
---@field dust_strings string[]
---@field can_show_partial_line boolean
---@field can_retry boolean
---@field source_state_id integer


--- Response types that can be received from the server
---@alias ResponseItem CompletionTextResponse | DeleteResponse | DedentResponse | EndResponse | BarrierResponse | FinishEditResponse | SkipResponse | JumpResponse

---@class CompletionTextResponse
---@field kind "text"
---@field text string

---@class DeleteResponse
---@field kind "delete"
---@field text string

---@class DedentResponse
---@field kind "dedent"
---@field text string

---@class EndResponse
---@field kind "end"

---@class BarrierResponse
---@field kind "barrier"

---@class FinishEditResponse
---@field kind "finish_edit"

---@class SkipResponse
---@field kind "skip"
---@field n integer

---@class JumpResponse
---@field kind "jump"
---@field fileName string
---@field lineNumber integer
---@field verify string
---@field precede string[]
---@field follow string[]
---@field isCreateFile boolean

