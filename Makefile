GREEN="\033[00;32m"
RESTORE="\033[0m"

# makes the output of the message appear green
define style_calls
	$(eval $@_msg = $(1))
	echo ${GREEN}${$@_msg}
	echo ${RESTORE}
endef

.PHONY: lint format

lint:
	@$(call style_calls,"Linting lua files")
	@selene --display-style quiet --config ./selene.toml lua/supermaven-nvim
	@$(call style_calls,"Running stylua check")
	@stylua --color always -f ./stylua.toml --check .

format:
	@$(call style_calls,"Running stylua format")
	@stylua --color always -f ./stylua.toml .

all: lint format
