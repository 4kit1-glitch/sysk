{
    total_memory: $total_mem,
    available_memory: $available_mem,
    used_memory: $used_mem,
    cache: {
        total_cache: $cached_mem,
        buffer: $buffer,
        swap_cache: $swap_cache
    },
    swap: {
        swap_total: $swap_mem,
        swap_used: $swap_used,
        swap_free: $swap_free
    },
    virtual: {
        total_virtual: $virtual_mem,
        virtual_used: $uvirtual,
        virtual_free: $free_virtual
    },
    corrupted: $corrupted,
    balloon: $balloon,
    dirty: $dirty,
    unevicted: $unevicted,
    anon_pages: $anon_pages
}