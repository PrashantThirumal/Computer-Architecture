/*
 * student.c
 * Multithreaded OS Simulation for CS 2200 and ECE 3058
 *
 * This file contains the CPU scheduler for the simulation.
 */

#include <assert.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "os-sim.h"

/** Function prototypes **/
extern void idle(unsigned int cpu_id);
extern void preempt(unsigned int cpu_id);
extern void yield(unsigned int cpu_id);
extern void terminate(unsigned int cpu_id);
extern void wake_up(pcb_t *process);


/*
 * current[] is an array of pointers to the currently running processes.
 * There is one array element corresponding to each CPU in the simulation.
 *
 * current[] should be updated by schedule() each time a process is scheduled
 * on a CPU.  Since the current[] array is accessed by multiple threads, you
 * will need to use a mutex to protect it.  current_mutex has been provided
 * for your use.
 */
static pcb_t **current;

// For threads
static pthread_mutex_t current_mutex;
static pthread_mutex_t ready_mutex;
static pthread_cond_t not_idle;

// Global static variables
static pcb_t* head;
static int time_slice;
static unsigned int cpu_count;

/*
* alg = 0 -> FIFO scheduling
* alg = 1 -> RR scheduling
* alg = 2 -> LTRF scheduling
*/
static int alg;

/**
 * Linked List queue. 
 * This queue is a shared variable so everytime we modify the queue
 * We must invoke a mutex
 */

// Push process to queue
static void push(pcb_t* process){
    // Lock the queue
    pthread_mutex_lock(&ready_mutex);

    // Null LL so set head to the process that was just pushed in
    if(!head){
        head = process;
    }
    else{
        // Find the first available node to push process to
        pcb_t* temp = head;
        while(temp -> next != NULL){
            temp = temp->next;
        }

        // Set the node to current process
        temp->next = process; 
    }

    // Ensure that the current process that just got pushed into is at the tail of the LL
    process->next = NULL;

    // Broadcast queue is no longer empty
    pthread_cond_broadcast(&not_idle);

    // Unlock the queue
    pthread_mutex_unlock(&ready_mutex);
}

// Pop the head of the queuq (FIFO)
static pcb_t* pop(){
    pcb_t* temp = head;

    // Lock the mutex since we need to update the position of the head
    pthread_mutex_lock(&ready_mutex);
    if(temp){
        // Shift head to next node
        head = temp -> next;
    }

    // Unlock the mutex
    pthread_mutex_unlock(&ready_mutex);

    // Get the head of the queue
    return temp;
}

// Get the LTRF node from the queue
static pcb_t* pop_LTRF(){
    unsigned int max_time_remaining = 0;
    pcb_t* temp;
    pcb_t *curr;
    pcb_t *prev;

    // Cycle through the queue and find the LTRF node
    pthread_mutex_lock(&ready_mutex);

    // Empty queue?
    if(head == NULL){
        temp = NULL;
    }

    else {
        curr = head;
        while (curr){
            // Find node with the longest time remaining
            if(curr->time_remaining > max_time_remaining){
                max_time_remaining = curr->time_remaining;
            }
            curr = curr -> next;
        }

        // Reset current to head
        curr = head;
        prev = head;

        /* We need to loop through a second time so we can find the previous node
        * This is important as we need to remove the node with the LTRF from the
        * queue
        * */
       while(curr){
           if (curr -> time_remaining == max_time_remaining){
               temp = curr;

               // Are we at the head?
               if(curr == head){
                   // move the head
                   head = curr -> next;
               }
               else{
                   // Remove the node from the queue
                   prev -> next = curr -> next;
               }

               // Exit out of the loop
               break;
           }
           
           // move the node pointers accordingly
           prev = curr;
           curr = curr -> next;
       }
    }

    // Unlock the mutex
    pthread_mutex_unlock(&ready_mutex);
    return temp;
}
/*
 * schedule() is your CPU scheduler.  It should perform the following tasks:
 *
 *   1. Select and remove a runnable process from your ready queue which 
 *	you will have to implement with a linked list or something of the sort.
 *
 *   2. Set the process state to RUNNING
 *
 *   3. Call context_switch(), to tell the simulator which process to execute
 *      next on the CPU.  If no process is runnable, call context_switch()
 *      with a pointer to NULL to select the idle process.
 *	The current array (see above) is how you access the currently running process indexed by the cpu id. 
 *	See above for full description.
 *	context_switch() is prototyped in os-sim.h. Look there for more information 
 *	about it and its parameters.
 */
static void schedule(unsigned int cpu_id)
{
    /* FIX ME */
    pcb_t* temp = NULL;

    // Get LTRF Node if that is the algorithm
    if(alg == 2){
        temp = pop_LTRF();
    }
    else {
        // Get the head of the queue (FIFO)
        temp = pop();
    }
    

    // Run the process at the top of the queue
    if(temp){
        temp->state = PROCESS_RUNNING;
    }

    /**if(!temp){
        printf("Something went wrong when popping from queue");
    }**/

    // Lock the mutex since we need to update current array
    // Note: current is a shared variable
    pthread_mutex_lock(&current_mutex);
    current[cpu_id] = temp;
    pthread_mutex_unlock(&current_mutex);
    
    // Finally call the context switch
    context_switch(cpu_id, temp, time_slice);
}


/*
 * idle() is your idle process.  It is called by the simulator when the idle
 * process is scheduled.
 *
 * This function should block until a process is added to your ready queue.
 * It should then call schedule() to select the process to run on the CPU.
 */
extern void idle(unsigned int cpu_id)
{
    /*
     * REMOVE THE LINE BELOW AFTER IMPLEMENTING IDLE()
     *
     * idle() must block when the ready queue is empty, or else the CPU threads
     * will spin in a loop.  Until a ready queue is implemented, we'll put the
     * thread to sleep to keep it from consuming 100% of the CPU time.  Once
     * you implement a proper idle() function using a condition variable,
     * remove the call to mt_safe_usleep() below.
     */
    
    // Lock the mutex 
    pthread_mutex_lock(&ready_mutex);

    // If the head of the queue is null we know queue is empty
    // Wait until head is not null (queue has atleast 1 valid node)
    while(head == NULL){
        pthread_cond_wait(&not_idle, &ready_mutex);
    }

    // Unlock the mutex
    pthread_mutex_unlock(&ready_mutex);

    // Schedule the cpu_id
    schedule(cpu_id);
}


/*
 * preempt() is the handler called by the simulator when a process is
 * preempted due to its timeslice expiring.
 *
 * This function should place the currently running process back in the
 * ready queue, and call schedule() to select a new runnable process.
 */
extern void preempt(unsigned int cpu_id)
{
    // Lock the mutex since we are modifying a shared variable
    pthread_mutex_lock(&current_mutex);

    // Change the current cpu_id state to no longer running
    current[cpu_id] -> state = PROCESS_READY;

    // Unlock the mutex
    pthread_mutex_unlock(&current_mutex);

    // push the current running process back onto the stack 
    // schedule the next process to be run
    push(current[cpu_id]);
    schedule(cpu_id);
}


/*
 * yield() is the handler called by the simulator when a process yields the
 * CPU to perform an I/O request.
 *
 * It should mark the process as WAITING, then call schedule() to select
 * a new process for the CPU.
 */
extern void yield(unsigned int cpu_id)
{
    // Lock the mutex since we are modifying a shared variable
    pthread_mutex_lock(&current_mutex);

    // Change the current cpu_id state to now waiting
    current[cpu_id] -> state = PROCESS_WAITING;

    // Unlock the mutex
    pthread_mutex_unlock(&current_mutex);
 
    // schedule the next process to be run
    schedule(cpu_id);
}


/*
 * terminate() is the handler called by the simulator when a process completes.
 * It should mark the process as terminated, then call schedule() to select
 * a new process for the CPU.
 */
extern void terminate(unsigned int cpu_id)
{
    // Lock the mutex since we are modifying a shared variable
    pthread_mutex_lock(&current_mutex);

    // Change the current cpu_id state to completed
    current[cpu_id] -> state = PROCESS_TERMINATED;

    // Unlock the mutex
    pthread_mutex_unlock(&current_mutex);
 
    // schedule the next process to be run
    schedule(cpu_id);
}


/*
 * wake_up() is the handler called by the simulator when a process's I/O
 * request completes.  It should perform the following tasks:
 *
 *   1. Mark the process as READY, and insert it into the ready queue.
 *
 *   2. If the scheduling algorithm is LRTF, wake_up() may need
 *      to preempt the CPU with lower remaining time left to allow it to
 *      execute the process which just woke up with higher reimaing time.
 * 	However, if any CPU is currently running idle,
* 	or all of the CPUs are running processes
 *      with a higher remaining time left than the one which just woke up, wake_up()
 *      should not preempt any CPUs.
 *	To preempt a process, use force_preempt(). Look in os-sim.h for 
 * 	its prototype and the parameters it takes in.
 */
extern void wake_up(pcb_t *process)
{
    // Lock the mutex since we are modifying a shared variable
    pthread_mutex_lock(&current_mutex);

    // Set the current process state to read
    process -> state = PROCESS_READY;

    // Unlock the mutex
    pthread_mutex_unlock(&current_mutex);
 
    // push this ready process into the queue
    push(process);

    // For LTRF alg find any idle CPU
    if (alg == 2){
       // Lock the mutex since we are modifying a shared variable
        pthread_mutex_lock(&current_mutex); 

        int low_id = -1;
        unsigned int lowest_time_remaining = __INT_MAX__;

        // Loop through all the CPUs and find an idle CPU
        for(unsigned int i = 0; i < cpu_count; i++){
            if(current[i] == NULL){
                // Found an idle cpu so break (no need to force preempt)
                low_id = -1;
                break;
            }

            // Find the process with the lowest time remaining
            if((current[i] -> time_remaining) < lowest_time_remaining){
                lowest_time_remaining = current[i] -> time_remaining;
                low_id = i;
            }
        }

        // Unlock the mutex
        pthread_mutex_unlock(&current_mutex);

        // Call force preepmt if the process found has a lower time remaining
        if((low_id != -1) && (lowest_time_remaining < (process -> time_remaining))){
            force_preempt(low_id);
        }
    }
}


/*
 * main() simply parses command line arguments, then calls start_simulator().
 * You will need to modify it to support the -l and -r command-line parameters.
 */
int main(int argc, char *argv[])
{
    //unsigned int cpu_count;

    /* Parse command-line arguments */
    if (argc < 2 || argc > 5)
    {
        fprintf(stderr, "Multithreaded OS Simulator\n"
            "Usage: ./os-sim <# CPUs> [ -l | -r <time slice> ]\n"
            "    Default : FIFO Scheduler\n"
	    "         -l : Longest Remaining Time First Scheduler\n"
            "         -r : Round-Robin Scheduler\n\n");
        return -1;
    }
    cpu_count = strtoul(argv[1], NULL, 0);

    /* FIX ME - Add support for -l and -r parameters*/
    // Get the algorithm type and the timeslice value
    for(int i = 0; i < argc; i++){
        if (strcmp(argv[i], "-r") == 0){
            alg = 1; // RR
            time_slice = atoi(argv[i+1]);
        }
        else if(strcmp(argv[i], "-l") == 0){
            alg = 2; // LTRF
            time_slice = -1;
        }
        else{
            alg = 0; // FIFO
            time_slice = -1;
        }
    }
    

    /* Allocate the current[] array and its mutex */
    current = malloc(sizeof(pcb_t*) * cpu_count);
    assert(current != NULL);
    pthread_mutex_init(&current_mutex, NULL);
    head = NULL;
    //time_slice = -1;
    pthread_mutex_init(&ready_mutex, NULL);
    pthread_cond_init(&not_idle, NULL);

    /* Start the simulator in the library */
    start_simulator(cpu_count);

    return 0;
}


