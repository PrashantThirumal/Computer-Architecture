/**
 * @author ECE 3058 TAs
 */

#include <stdlib.h>
#include "lrustack.h"
#include <stdio.h>

/**
 * This file contains some starter code to get you started on your LRU implementation. 
 * You are free to implement it however you see fit. You can design it to emulate how this
 * would be implemented in hardware, or design a purely software stack. 
 * 
 * We have broken down the LRU stack's
 * job/interface into two parts:
 *  - get LRU: gets the current index of the LRU block
 *  - set MRU: sets a certain block's index as the MRU. 
 * If you implement it using these suggestions, you will be able to test your LRU implementation
 * using lrustacktest.c
 * 
 * NOTES: 
 *      - You are not required to use this LRU interface. Feel free to design it from scratch if 
 *      that is better for you.
 *      - This will not behave like your traditional LIFO stack  
 */

/**
 * Function to initialize an LRU stack for a cache set with a given <size>. This function
 * creates the LRU stack. 
 * 
 * @param size is the size of the LRU stack to initialize. 
 * @return the dynamically allocated stack. 
 */
lru_stack_t* init_lru_stack(int size) {
    //  Use malloc to dynamically allocate a lru_stack_t
	lru_stack_t* stack = (lru_stack_t*) malloc(sizeof(lru_stack_t));
    //  Set the stack size the caller passed in
	stack->size = size;

    ////////////////////////////////////////////////////////////////////
    //  TODO: Write any other code needed to initialize your LRU Stack. 
    //  Essentially write any initializations needed for anything you
    //  added to lru_stack_t.
    ////////////////////////////////////////////////////////////////////

    // init the priority bits array for the lru
    stack -> priority_bits = (int*)malloc(sizeof(int)*size);
    for(int i = 0; i < stack->size; i++){
        stack->priority_bits[i] = i;
    }

	return stack;
}

/**
 * Function to get the index of the least recently used cache block, as indicated by <stack>.
 * This operation should not change/mutate your LRU stack. 
 * 
 * @param stack is the stack to run the operation on.
 * @return the index of the LRU cache block.
 */
int lru_stack_get_lru(lru_stack_t* stack) {
    ////////////////////////////////////////////////////////////////////
    //  TODO: Write code to get the index of the LRU block from the LRU 
    //  Stack. 
    ////////////////////////////////////////////////////////////////////

    // Index that contains the value(size-1) is our LRU
    for(int i = 0; i < stack->size; i++){
        if(stack->priority_bits[i] == (stack->size - 1)){
            return i;
        }
    }
}

/**
 * Function to mark the cache block with index <n> as MRU in <stack>. This operation should
 * change/mutate the LRU stack.
 * 
 * @param stack is the stack to run the operation on.
 * @param n the index to promote to MRU.  
 */
void lru_stack_set_mru(lru_stack_t* stack, int n) {
	////////////////////////////////////////////////////////////////////
    //  TODO: Write code to set the passed in block index  as the MRU 
    //  element in the LRU Stack. 
    ////////////////////////////////////////////////////////////////////

    // We run through each index that was not passed into the block 
    // And increment their value
   for(int i = 0; i < stack->size; i++){
       if(stack->priority_bits[i] < stack->priority_bits[n]){
           stack->priority_bits[i]++;
       }
   }

    // Set the index passed in to 0 as this is now our MRU
   stack -> priority_bits[n] = 0;
}

/**
 * Function to free up any memory you dynamically allocated for <stack>
 * 
 * @param stack the stack to free
 */
void lru_stack_cleanup(lru_stack_t* stack) {
    ////////////////////////////////////////////////////////////////////
    //  TODO: Write any code if you need to do additional heap allocation
    //  cleanup
    ////////////////////////////////////////////////////////////////////
    free(stack->priority_bits);
    free(stack);        // Free the stack struct we malloc'd
}