# Who:  Jay Chen
# What: proj3.asm
# Why:  Project 3 for CS2640, insertion into a sorted array & recursive binary search algorithm
# When: Due 4/2
# How:  List the uses of registers
#saved values
    #$s0 - array length (number of integers entered by user)
    #$s1 - saved counter value for loop to accept user integers for array, reserved on stack when calling insert subroutine
#temp values
    #$t0 - counter for loops, search subroutine - mid address of array
    #$t1 - print - counter for array index, insert - holds previous element for comparison, search - holds value at mid address
    #$t2 - print - holds value to be printed
#arg values
    #$a0 - used for syscall fns, insert subroutine arg - new value to be inserted, search subroutine arg - value to search for
    #$a1 - insert subroutine arg - first empty address in array ("last" pointer), search subroutine arg - "start" address in array
    #$a2 - search subroutine arg - "end" address in array
#return values
    #$v0 - used for syscall fns, return value true(1)/false(0) for search function (binarysearch)

.data
    prompt:     .asciiz     "\n\n> integers will be inserted\n> into array in ascending order\nhow many signed ints?\n==> "
    in_prt:     .asciiz     "int to insert\n==> "
    sc_info:    .asciiz     "\n\n> binarysearch test\n> will prompt for input indefinitely\n> stop using MARS stop button\n\n" 
    sc_prt:     .asciiz     "\nint to search for\n==> "
    sc_found:   .asciiz     "RESULT (TRUE(1)/FALSE(0)) == "

.align 2
    array:      .space      160                 #array of 40 words

.text
.globl main

#program entry
main:

    init_prompt:
        la $a0, prompt                    #prompt for num of ints
        li $v0, 4
        syscall
        li $v0, 5                         #accept user input
        syscall
        move $s0, $v0                     #move user input to s0, save num ints for later
        #endprompt

        la $a1, array                     #load starting array address into a1 (insert fn arg as first empty eddress)
        li $s1, 0
        in_prompt: 
        beq $s1, $s0, end_init_prompt     #loop for the number of ints to enter
        la $a0, in_prt                    #prompt user for integer
        li $v0, 4
        syscall
        li $v0, 5                         #accept user input
        syscall

        move $a0, $v0                     #copy user input to argument register
        jal insert                        #call subroutine insert into array
        addi $a1, $a1, 4                  #increment last address argument by 1 word bc new element inserted
        addi $s1, $s1, 1                  #increment loop counter for number of ints in array
        j in_prompt
    end_init_prompt:

    print:
        move $t0, $s0               #copy array length to $t0
        la $t1, array               #copy starting array address to $t1
        printloop:
        beq $t0, 0, end_print       #print for only the number of ints entered
        lw $t2, 0($t1)              #load int value at current array pos into t2
        
        #print integer
        move $a0, $t2
        li $v0, 1
        syscall

        #print space after int
        li $a0, 32                  #ascii 32 for whitespace
        li $v0, 11                  #syscall code for printing character
        syscall

        addi $t0, $t0, -1            #decrement counter
        addi $t1, $t1, 4             #increment array pointer to next address

        j printloop
    end_print:

    search_prompt:
        #search prompt info
        la $a0, sc_info
        li $v0, 4
        syscall

        

        search_loop:
            la $a1, array                         #set starting address 
            move $a2, $s0                         #set ending idx arg $a2 to array length
            sll $a2, $a2, 2                       #shift by 2^2 for addressing
            add $a2, $a2, $a1                     #now a2 is address after end address
            #prompt for int to search
            
            la $a0, sc_prt
            li $v0, 4
            syscall
            li $v0, 5                     #accept user input
            syscall
            move $a0, $v0                 #move user input to $a0 arg for target search value

            jal binarysearch                    #args: $a0, $a1, $a2 (target, start, end)

            move $t0, $v0
            la $a0, sc_found
            li $v0, 4
            syscall
            move $a0, $t0
            li $v0, 1
            syscall
            j search_loop             #loop indefinitely to ask for another search value
            
            end_search_prompt:

    j exit                      #unreachable because of requirements for how search must loop indefinitely. here just for testing.

.text
    # Insertion subroutine that stores the integer at correct 
    # sorted position in array, & shifts the other elements as needed
    # args
        #$a0 - receive n, int value to be inserted in array
        #$a1 - first empty address of array in memory (effective "last" position)
    # returns
        #no return values, the program only updates the array

insert:
    #stack $ra + end array address (a0 value doesnt hv to be saved, wont be used outside fn)
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s1, 4($sp)
    sw $a1, 0($sp)

    la $t0, array               #starting address of array (will be different from $a1 unless array empty)
    sw $a0, 0($a1)              #store new value at last index of array
    
    insertloop:
    addi $a1, $a1, -4           #decrement end element for comparison
    blt $a1, $t0, end_inloop    #means a0 is only element
    
    lw $t1, 0($a1)              #load element before newly inserted a0 into t1
                                
    bge $a0, $t1, end_inloop    #if a0 greater than element before, branch; (a0>a1[i])
                                #else swap position of a0 and value before it in array
    sw $a0, 0($a1)              #a1[i] = a0
    sw $t1, 4($a1)              #store what was in a1[i] before in next slot
    
    j insertloop
    end_inloop:

    #unstack all values & deallocate stack space
    lw $ra, 8($sp)
    lw $s1, 4($sp)
    lw $a1, 0($sp)
    addiu $sp, $sp, 12

    jr $ra #jump to return address
end_insert:

.text
    # Search subroutine that accepts array address range and target value,
    # performs recursive binarysearch algorithm to find the value in $a0
    # args
        #$a0 - signed int value to search for
        #$a1 - starting address
        #$a2 - ending address

    # returns
        #$v0 - returns 1 (true) if found, else 0 (false)
binarysearch:
    #save $ra to stack
    addiu $sp, $sp, -4 
    sw $ra, 0($sp) 

    bge $a1, $a2, returnzero #check if base case & value not yet found

    subu $t0, $a2, $a1      #end-start
    sra $t0, $t0, 3         #end-start/2
    sll $t0, $t0, 2         #shift to address offset
    add $t0, $t0, $a1       #start+(end-start)/2
    lw $t1, 0($t0)          #t1 = array[t0]
    beq $t1, $a0, returnone

    blt $a0, $t1, left      #tgt value less than mid
        right:              #else tgt value > mid
        addiu $a1, $t0, 4   #start = mid+1
        jal binarysearch    #recursive call
        b end               #finished, skip left & branch to end
        
        left:
        addiu $a2, $t0, 0   #end = mid
        jal binarysearch    #recursive call
        b end               #finished, branch to end
    
    returnone:
        li $v0, 1
        b end
    
    returnzero:
        li $v0, 0

    end:
    #restore return address & deallocate stack space 
    lw $ra, 0($sp) 
    addiu $sp, $sp, 4
    jr $ra 

end_search:

#binarySearch(&array, start, end, searchVal)
    #   if (start > end)
    #   return false
    #   mid = start + (end - start)/2;
    #   if (array[mid] == searchVal)
    #   return true;
    #   if (array[mid] > searchVal)
    #   return binarySearch(array, start, mid-1, searchVal);
    #   return binarySearch(array, mid+1, end, searchVal);


exit:
    li $v0, 10		# terminate the program
    syscall


