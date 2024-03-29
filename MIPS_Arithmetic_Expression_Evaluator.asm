#Data Declaration section

.data 
input: .space 400 #Space for 400 bytes or 100 words
postFixArray: .space 400 
promptExpression: .asciiz "Expression to be evaluated:\n"
.text

main: 
add $s6, $zero, $ra
#Print expression to be evaluated:
addi $v0, $zero, 4
#Loads the address of the promptExpression string into register $a0 to be printed
la $a0, promptExpression
syscall

#This syscall 8 is to read in a string from console
addi $v0, $zero, 8
#Loads the address of the array to store the expression
la $a0, input
#Register $a1, is maximum number of characters to read
li $a1, 100
add $t2, $zero, $a0
syscall


#Closed parens in ascii
addi $t6, $zero, 41
#Open parens in ascii
addi $t3, $zero, 40
#Whitespace in ascii
addi $t4, $zero, 32
#Newline character in ascii
addi $s4, $zero, 10

#Loads the addresses of the two arrays
la $s2, input
la $s0, postFixArray

parseInputLoop: 

#Loads the character of input into register $t0
lb $t0, 0($s2)

#If input == newLine, then branch to postFix label
beq $t0, $s4, postFix
#If input == whitespace, then skip and get next element in the input array
beq $t0, $t4, skipWhiteSpace

slti $t7, $t0, 47
 #If ascii value greater than 47, it's a number
 beq $t7, $zero, addNumToPostFixArray 
 
 	#If character is closed parens, go to popTwice
 	beq $t0, $t6, popTwice
 		#Push +, -, ( to stack
 		subu $sp, $sp, 1
 		sb $t0, 0($sp)
 		#Get next element in input array
 		addi $s2, $s2, 1
 	j parseInputLoop
 	
 	
 	popTwice:
 	#If character is closed parens, pop twice (and add both to the postFixArray):
 	#Unless the character is '(' then discard
 	lb $t5, 0($sp)
 	addu $sp, $sp, 1
 	#Store the first pop in postFix array, unless '(' 
 	beq $t5, $t3, skip 
 		sb $t5, 0($s0)
 		addi $s0, $s0, 1
 	skip:
 	lb $t5, 0($sp)
 	addu $sp, $sp, 1
 	#store the second pop in postFix array, unless '('
 	beq $t5, $t3, skip2 
 		sb $t5, 0($s0)
 		addi $s0, $s0, 1
 	skip2:
 	#Get next element in input array
 	addi $s2, $s2, 1
 	j parseInputLoop
 	

 addNumToPostFixArray:

#Stores the number in the postFix array
 sb $t0, 0($s0) 
#Increments the postFix array index by one
 addi $s0, $s0, 1
 
 #Get next element in input array
 addi $s2, $s2, 1
 j parseInputLoop
 
 #If the character is a whitespace, then skip and get next element
 skipWhiteSpace:
 #Get next element in input array
 addi $s2, $s2, 1
 j parseInputLoop


#When this label has been reached, the expression is now in postfix notation
postFix:

#Print the postFix array
li $v0, 4
la $a0, postFixArray
syscall

#This is to null-terminate the postfix
addi $t0, $zero, 10
sb $t0, 0($s0)

#Adding '+' to register $t3
addi $t3, $zero, 43
#Adding '-' to register $t6
addi $t6, $zero, 45
 
 
la $s2, postFixArray

#### Start of new Assignment_3 code ####

#Newline character in ascii
addi $s4, $zero, 10

#Use $t7, to determine if it's an operand or operator
#Values less than 47 are either operators or newline char
addi $t7, $zero, 47
createNodeAndPushToStackLoop:

#Loads the character of postFixArray into register $t0
lb $t0, 0($s2)

#If null-character then exit loop, postfix array completely read abd tree created
beq $t0, $s4, tree_Created

#If $t0 is less than 47, it's an operator or null character 
blt $t0, $t7, doNotConvert
#Else, convert the value to it's decimal equivalent
addi $t0, $t0, -48

doNotConvert:

#Create the Node 
#Allocates 12 bytes for the node (3 words)
addi $a0, $zero, 12 
#Syscall 9 is sbrk (dynamically allocate memory) in mips
addi $v0, $zero, 9  
syscall

#Now $s3 contains the address of the node
add $s0, $zero, $v0 #$v0 contains the address of allocated memory

#store the character from postfix array into the node value
sw $t0, 0($s0)

#Push the node to the stack
#IF '+' don't push right away!
beq $t0, $t3, skipOperator
#IF '-' don't push right away!
beq $t0, $t6, skipOperator
#If OPERAND then push immediately to stack
sub $sp, $sp, 4
#Push the operand node on the stack
sw $s0, 0($sp) 
#Get the next character from postfix
addi $s2, $s2, 1
j createNodeAndPushToStackLoop

skipOperator:

#First pop, link to right child
lw $t4, 0($sp)                     
add $sp, $sp, 4 

#Second pop, link to left child
lw $t5, 0($sp)                       
add $sp, $sp, 4 

#Store in the left child reference
sw $t5, 4($s0) 
#Store in the right child reference
sw $t4, 8($s0) 

#Push the operator to the stack
sub $sp, $sp, 4
sw $s0, 0($sp) 

#Get next byte/char from PostFix array
addi $s2, $s2, 1 

j createNodeAndPushToStackLoop

#The binary/expression tree has been created
tree_Created: 

#Pop the root node of the tree off the stack
#It's the last thing left on the stack
lw $a0, 0($sp)
add $sp, $sp, 4
#Store the root node in $s3
add $s3, $zero, $a0


#Beginning of In-Order Tree Traversal Recursion function
in_Order_Traversal:
#Open 8 bytes on the stack
addi $sp, $sp, -8
#Store the return address of the call
sw $ra, 0($sp)
#Store the root node on the stack
sw $s3, 4($sp)

#Move the method call argument (node in $a0) to $s3
add $s3, $zero, $a0

#If $s3 is null, then go next
beq $s3, $zero, null_child

#Recurse to the left child
lw $a0, 4($s3)
jal in_Order_Traversal

#add $s6, $s6, 1
#When visiting the node, call the calculateFunction to see...
#If a calculation needs to be done 
jal calculateFunction

#Recurse to the right child
lw $a0, 8($s3)
jal in_Order_Traversal

#If the child is null, load the parent node reference...
#and the return address, and then restore the stack...
#before returning to the where the function/method was called
#If $ra is 'main address', then branch becuase tree traversal is complete
null_child:
lw $s3, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
beq $ra, $s6, traverseComplete
jr $ra

calculateFunction:

#Register $t5 holds addition (+)
#Register $t6 holds subtraction (-)
addi $t5, $zero, 43
addi $t6, $zero, 45

#$t1 contains memory address of left child
lw $t1, 4($s3) 

#$t2 contains memory address of right child
lw $t2, 8($s3)

#If any child is empty, then skip...
beq $t1, $zero, skipTheCalculation
beq $t2, $zero, skipTheCalculation


#Gets the value of the right child node, stores in $t3
lw $t3, 0($t2) 
#Gets the value of the left child node, stores in $t4
lw $t4, 0($t1) 


#If right child equal to + or - don't do calculation yet
#Since this is an in-order tree traveral, you get cases...
#Where you need to wait for another calculation before doing this calc
beq $t3, $t5, skipTheCalculation
beq $t3, $t6, skipTheCalculation

#load the value of the node (+ or -) 
#Note: nodes that have children are always operator (either + or -)
lw $t7, 0($s3)

#If $t7 is '+' then branch to do the sum calculation
beq $t7, $t5, performAddition
#Else, find the difference because it's a - operator
sub $t7, $t4, $t3

#Replace the operator with the value of the calculation
sw $t7, 0($s3)

#If subtraction, calculation complete and jump to end of the calculate function
j exitCalculation

performAddition:
#Finds the sum
add $t7, $t4, $t3
#Replace the operator with the value of the sum calculation
sw $t7, 0($s3)

exitCalculation:

skipTheCalculation:
#Return to where the calculateFunction was called
jr $ra


#Getting to this label means the tree traversal is complete
traverseComplete:

#Load the value of root node
lw $t0, 0($s3)

#If it is equal to either + or - then perform one last calculation
beq $t0, $t5, lastCalculation
beq $t0, $t6, lastCalculation

#Else, all calculations already done, jump to label
j alreadyComputed

lastCalculation:
jal calculateFunction

#Loads the final value of the expression
lw $t0, 0($s3)

alreadyComputed:

#Print whitespace between postfix and '='
li $v0, 11
addi $a0, $zero, 32
syscall

#Print equals sign '='
li $v0, 11
addi $a0, $zero, 61
syscall

#Print whitespace between '=' and value of expression
li $v0, 11
addi $a0, $zero, 32
syscall

#Print the value of the expression
li $v0, 1
add $a0, $zero, $t0
syscall

#Program is complete
programComplete:
li $v0, 10
syscall
