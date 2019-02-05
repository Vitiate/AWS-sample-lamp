#!/bin/bash
# If a cloudformation stack exists update it, otherwise create a new one.


#if [[ ${stackStatus} == *"ROLLBACK_COMPLETE"* ]] ; then
#	echo "Stack exists in a ROLLBACK_COMPLETE state, deleting it"
#	aws cloudformation delete-stack \
#		$PROFILE \
#		--stack-name $STACK_NAME
#	echo "Waiting for stack to delete, an error here indicates the stack no longer exists"
#	output=$(aws cloudformation wait stack-create-complete $PROFILE --stack-name $STACK_NAME 2>&1)
#	echo ${output}
#    echo "Stack deleted"
#    # Make the script create the stack again.
#    stackStatus="does not exist"
#fi

function create_stack {
	echo "	Stack does not exist, creating it:"
	output=$(aws cloudformation create-stack \
		$PROFILE \
		--stack-name $STACK_NAME \
		--template-body file://./components/$COMPONENT.yaml \
    	--parameters file://./environments/$ENV/$COMPONENT.json \
    	--capabilities CAPABILITY_IAM 2>&1)
    echo $output
    echo "	Waiting for create-stack to complete"
    output=$(aws cloudformation wait stack-create-complete $PROFILE --stack-name $STACK_NAME 2>&1)
	if [[ ${output} == *"Waiter encountered a terminal failure state"* ]] ; then
		echo "	Create Stack Failed!"
		stackStatus=$(aws cloudformation describe-stack-events $PROFILE --stack-name $STACK_NAME --no-paginate --output table  2>&1)
		echo ${stackStatus}
		exit 1
	fi
	exit $?
}

function delete_stack {
	aws cloudformation delete-stack \
		$PROFILE \
		--stack-name $STACK_NAME
	echo "	Waiting for stack to delete, an error here indicates the stack no longer exists"
	output=$(aws cloudformation wait stack-create-complete $PROFILE --stack-name $STACK_NAME 2>&1)
	echo ${output}
    echo "	Stack deleted"
}

function update_stack {
	echo "	Updating Stack"
	output=$(aws cloudformation update-stack \
			$PROFILE \
			--stack-name $STACK_NAME \
			--template-body file://./components/$COMPONENT.yaml \
	    	--parameters file://./environments/$ENV/$COMPONENT.json \
	    	--capabilities CAPABILITY_IAM 2>&1)
	if [[ ${output} == *"No updates are to be performed."* ]] ; then
		echo "	Stack is current, no updates to be performed."
		exit 0
	fi
	if [[ ${output} == *"is in ROLLBACK_COMPLETE state and can not be updated"* ]] ; then
		echo ${output}
			echo "	Stack exists in a ROLLBACK_COMPLETE state, deleting it"
			delete_stack
			create_stack
	fi
	echo "	Waiting for update-stack to complete"
	echo $output
	output=$(aws cloudformation wait stack-update-complete $PROFILE --stack-name $STACK_NAME 2>&1)
	if [[ ${output} == *"Waiter encountered a terminal failure state"* ]] ; then
		echo "	Update Stack Failed!"
		stackStatus=$(aws cloudformation describe-stack-events $PROFILE --stack-name $STACK_NAME --no-paginate --output table 2>&1)
		echo ${stackStatus}
		exit 1
	fi
	exit $?
}

echo "Checking if stack $STACK_NAME exists."
stackStatus=$(aws cloudformation describe-stacks $PROFILE --stack-name $STACK_NAME 2>&1)

if [[ ${stackStatus} == *"does not exist"* ]] ; then
	create_stack
fi

if [[ ${stackStatus} == *"CREATE_COMPLETE"* ]] || [[ ${stackStatus} == *"UPDATE_COMPLETE"* ]] || [[ ${stackStatus} == *"ROLLBACK_COMPLETE"* ]] ; then
	echo "Stack exists, updating it:"
	update_stack	
fi
echo ${stackStatus}
exit 0