.PHONY: update-stack delete-stack describe-stack _is_user_authenticated _check-params _check-component

STACK_NAME = ""
ifdef PROJECT
	STACK_NAME = $(PROJECT)-$(COMPONENT)-$(ENV)
else
	STACK_NAME = $(COMPONENT)-$(ENV)
endif

ifndef PROFILE
	ifndef AWS_ACCESS_KEY_ID
		$(error PROFILE is undefined; the profile is used to connect to the correct AWS Account, sample configuration can be seen in .README.md )
	else
		PROFILEX = ""
	endif
else
	PROFILE = $(PROFILEX)
endif


_is_user_authenticated:
	@aws sts get-caller-identity > /dev/null

_check-params:
ifndef ENV
	$(error ENV is undefined; set to the appropriate directory from ./parameters/ (without extension) )
endif

_check-component:
ifndef COMPONENT
	$(error COMPONENT is undefined; set to the appropriate file from ./components/ (without extension) )
endif

update-stack: _check-params _check-component _is_user_authenticated
	chmod +x ./make_scripts/update_stack.sh
	export STACK_NAME=$(STACK_NAME) && export PROFILE=$(PROFILE) && ./make_scripts/update_stack.sh

delete-stack: _check-params _is_user_authenticated
	aws cloudformation delete-stack \
	  --profile $(PROFILE) \
	  --stack-name $(STACK_NAME)

describe-stack: _check-params _is_user_authenticated
	aws cloudformation describe-stacks \
	  --profile $(PROFILE) \
	  --stack-name $(STACK_NAME)
