#pragma once

#include "paging.h"

/*  --------------------------------- PROBLEM 1 --------------------------------------
    Split the virtual address into VPN and offset.
    These macros will be used whenever you get a memory address from the CPU and need
    to translate it.

    HINT: Examine the global defines in pagesim.h, which will be
    necessary in implementing these functions.

    HINT: While these values will be powers of two, allowing you to use bit-wise
    arithmetic, consider using modulus division and integer division for
    an elegant solution.
    -----------------------------------------------------------------------------------
 */

/* Get the virtual page number from a virtual address. */
static inline vpn_t vaddr_vpn(vaddr_t addr) {
    
    return (vpn_t)(addr / PAGE_SIZE);                   /* FIXME */

}

/* Get the offset into the page from a virtual address. */
static inline uint16_t vaddr_offset(vaddr_t addr) {
    
    return (uint16_t)(addr % PAGE_SIZE);                   /* FIXME */
}
