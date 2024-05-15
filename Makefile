GREEN="\033[00;32m"
RESTORE="\033[0m"

# make the output of the message appear green
define style_calls
	$(eval $@_msg = $(1))
	echo ${GREEN}${$@_msg}
	echo ${RESTORE}
endef

.PHONY: test test-nvim test-all

test:
	@$(call style_calls,"Running vusted tests")
	@SUPERMAVEN_TESTING="testing" vusted ./tests

test-nvim:
	@$(call style_calls,"Running tests using nvim")
	@nvim --headless --noplugin -u ./tests/minimal_init.lua -c "PlenaryBustedDirectory ./tests {minimal_init = './tests/minimal_init.lua'}"

test-all: test test-nvim
