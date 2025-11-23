/*
 * mycudd_wrap.c
 *
 * Thin C helpers used by the Julia MiniCUDD wrapper to construct raw BDD and
 * ZDD nodes while enforcing ordering constraints and taking a reference in a
 * single step. These functions encapsulate some low‑level CUDD invariants so
 * the higher‑level Julia code can remain more declarative.
 *
 * Overview
 * --------
 * CUDD represents decision diagram nodes with pointers that may carry a
 * complement bit (LSB) for BDD edges. ZDD nodes do not use complemented edges.
 * Node creation must respect the variable ordering: a node for variable i
 * cannot point (through then/else edges) to sub‑graphs whose top variables
 * occur at or above i in the ordering (except terminals). Violating this
 * produces structurally invalid diagrams and may trigger reordering or NULL.
 *
 * Functions provided:
 *   - My_ZddMakeNode: create a ZDD node (index, T, E) after validating levels.
 *   - My_BddMakeNode: create a BDD node (index, T, E) after validating levels.
 *
 * Both return NULL on any invalid condition or allocation failure. On success
 * the returned node has its reference count incremented (cuddRef). The caller
 * is responsible for eventually invoking Cudd_RecursiveDeref* or equivalent
 * (handled on the Julia side via finalizers).
 *
 * Reordering
 * ----------
 * Setting dd->reordered = 0 suppresses immediate reordering side effects for
 * this local construction path (mirrors other internal CUDD patterns). These
 * helpers assume reordering is either disabled or externally managed.
 *
 * Safety Notes
 * ------------
 * - Inputs t and e may be complemented (BDD only). We use Cudd_Regular to
 *   access their canonical nodes when checking indices.
 * - Terminals are identified by index == CUDD_CONST_INDEX.
 * - We compute each child level only if non‑terminal to avoid extraneous calls.
 * - For ZDDs we rely on cuddZddGetNode; for BDDs on cuddUniqueInter which
 *   performs hash‑table insertion / uniqueness enforcement.
 *
 * Threading: These helpers assume single‑threaded access to the manager `dd`.
 * If embedding MiniCUDD in a multithreaded environment ensure external
 * synchronization around CUDD manager operations.
 *
 * License: Mirrors upstream CUDD licensing; this file adds comments only and
 * contains no substantial original logic beyond arrangement of calls.
 */
// Standard headers (kept minimal intentionally)
#include <stddef.h>   // size_t
#include <stdio.h>    // FILE
#include "cudd.h"
#include "cuddInt.h"

/*
 * My_ZddMakeNode
 * ---------------
 * Attempt to create a ZDD node with variable `index` and children `t` (then)
 * and `e` (else). Preconditions:
 *   - `index` must map to a valid ZDD level (Cudd_ReadPermZdd >= 0).
 *   - Neither child may introduce a top variable whose level is <= the level
 *     of `index` (except terminals). This preserves strict ordering.
 * Returns NULL on invalid ordering or allocation failure. On success returns
 * a referenced (cuddRef) node.
 */
DdNode * My_ZddMakeNode(DdManager *dd, int index, DdNode *t, DdNode *e)
{
    dd->reordered = 0;

    int level_index = Cudd_ReadPermZdd(dd, index);
    if (level_index < 0 || level_index == CUDD_CONST_INDEX) {
        return NULL;
    }

    int level_t = Cudd_ReadPermZdd(dd, Cudd_Regular(t)->index);
    int level_e = Cudd_ReadPermZdd(dd, Cudd_Regular(e)->index);

    if ((level_t != CUDD_CONST_INDEX && level_index >= level_t) ||
        (level_e != CUDD_CONST_INDEX && level_index >= level_e)) {
        return NULL;
    }

    DdNode *res = cuddZddGetNode(dd, index, t, e);
    if (res == NULL) {
        return NULL;
    }

    cuddRef(res);
    return res;
}

/*
 * My_BddMakeNode
 * ---------------
 * Attempt to create a BDD node for variable `index` with then child `t` and
 * else child `e`. Handles complemented edges by normalizing via Cudd_Regular
 * for ordering checks. Ordering constraints mirror those in My_ZddMakeNode.
 * Returns NULL on any violation or allocation failure; otherwise returns a
 * unique referenced node from cuddUniqueInter.
 */
DdNode * My_BddMakeNode(DdManager *dd, int index, DdNode *t, DdNode *e)
{
    dd->reordered = 0;

    int level_index = Cudd_ReadPerm(dd, index);
    if (level_index < 0 || index == CUDD_CONST_INDEX) {
        return NULL;
    }

    DdNode *t_reg = Cudd_Regular(t);
    DdNode *e_reg = Cudd_Regular(e);

    int level_t;
    int level_e;

    if (t_reg->index == CUDD_CONST_INDEX) {
        level_t = CUDD_CONST_INDEX;
    } else {
        level_t = Cudd_ReadPerm(dd, t_reg->index);
    }

    if (e_reg->index == CUDD_CONST_INDEX) {
        level_e = CUDD_CONST_INDEX;
    } else {
        level_e = Cudd_ReadPerm(dd, e_reg->index);
    }

    if ((level_t != CUDD_CONST_INDEX && level_index >= level_t) ||
        (level_e != CUDD_CONST_INDEX && level_index >= level_e)) {
        return NULL;
    }

    DdNode *res = cuddUniqueInter(dd, index, t, e);
    if (res == NULL) {
        return NULL;
    }

    cuddRef(res);
    return res;
}