(** This file contains the basic definitions for Copland terms, Core terms, 
   Evidence Types, and Copland events. *)

(*
   These definitions have been adapted from an earlier version, archived 
   here:  https://ku-sldg.github.io/copland/resources/coplandcoq.tar.gz
*)

(* LICENSE NOTICE

Copyright (c) 2018 The MITRE Corporation.
All Rights Reserved.

This proof script is free software: you can redistribute it and/or
modify it under the terms of the BSD License as published by the
University of California.  See license.txt for details. *)

Require Export BS.
Require Import String.

Require Import List.
Import List.ListNotations.

(*
Set Nested Proofs Allowed.
*)


(** * Terms and Evidence

    A term is either an atomic ASP, a remote call, a sequence of terms
    with data a dependency, a sequence of terms with no data
    dependency, or parallel terms. *)

(** [Plc] represents a place (or attestation domain). *)
Definition Plc: Set := nat.
(** [N_ID] represents a nonce identifier.  *)
Definition N_ID: Set := nat.
(** [Event_ID] represents Event identifiers *)
Definition Event_ID: Set := nat.

(** [ASP_ID], [TARG_ID], and [Arg] are all string-typed parameters to ASPs 
    [ASP_ID] identifies the procedure invoked.
    [TARG_ID] identifies the target (when a target makes sense).
    [Arg] represents a custom argument for a given ASP 
          (defined and interpreted per-scenario/implementaiton).
*)
Definition ASP_ID: Set := string.
Definition TARG_ID: Set := string.
Definition Arg: Set := string.

(** Grouping ASP parameters into one constructor *)
Inductive ASP_PARAMS: Set :=
| asp_paramsC: ASP_ID -> (list Arg) -> Plc -> TARG_ID -> ASP_PARAMS.

(** The structure of evidence. *)
Inductive Evidence: Set :=
| mt: Evidence
| nn: N_ID -> Evidence
| gg: Plc -> ASP_PARAMS -> Evidence -> Evidence
| hh: Plc -> ASP_PARAMS -> Evidence -> Evidence
| ss: Evidence -> Evidence -> Evidence.

(** Evidene routing types:  
      ALL:   pass through all evidence
      NONE   pass through empty evidence
*)
Inductive SP: Set :=
| ALL
| NONE.

(** Evidence extension types:
      COMP:  Compact evidence down to a single value.
      EXTD:  Extend evidence by appending a new value.
*)
Inductive FWD: Set :=
| COMP
| EXTD.


(** Primitive Copland phases *)
Inductive ASP: Set :=
| NULL: ASP
| CPY: ASP
| ASPC: SP -> FWD -> ASP_PARAMS -> ASP
| SIG: ASP
| HSH: ASP.

(** Pair of evidence splitters that indicate routing evidence to subterms 
    of branching phrases *)
Definition Split: Set := (SP * SP).

(** Main Copland phrase datatype definition *)
Inductive Term: Set :=
| asp: ASP -> Term
| att: Plc -> Term -> Term
| lseq: Term -> Term -> Term
| bseq: Split -> Term -> Term -> Term
| bpar: Split -> Term -> Term -> Term.

(* Adapted from Imp language Notation in Software Foundations (Pierce) *)
Declare Custom Entry copland_entry.
Declare Scope cop_ent_scope.
Notation "<{ e }>" := e (at level 0, e custom copland_entry at level 99) : cop_ent_scope.
Notation "( x )" := x (in custom copland_entry, x at level 99) : cop_ent_scope.
Notation "x" := x (in custom copland_entry at level 0, x constr at level 0) : cop_ent_scope.
(* Branches*)
Notation "x -<- y" := (bseq (NONE, NONE) x y) (in custom copland_entry at level 70, right associativity).
Notation "x +<- y" := (bseq (ALL, NONE) x y) (in custom copland_entry at level 70, right associativity).
Notation "x -<+ y" := (bseq (NONE, ALL) x y) (in custom copland_entry at level 70, right associativity).
Notation "x +<+ y" := (bseq (ALL, ALL) x y) (in custom copland_entry at level 70, right associativity).
Notation "x -~- y" := (bpar (NONE, NONE) x y) (in custom copland_entry at level 70, right associativity).
Notation "x +~- y" := (bpar (ALL, NONE) x y) (in custom copland_entry at level 70, right associativity).
Notation "x -~+ y" := (bpar (NONE, ALL) x y) (in custom copland_entry at level 70, right associativity).
Notation "x +~+ y" := (bpar (ALL, ALL) x y) (in custom copland_entry at level 70, right associativity).
(* ARROW sequences *)
Notation "x -> y" := (lseq x y) (in custom copland_entry at level 99, right associativity).
(* ASP's *)
Notation "!" := (asp SIG) (in custom copland_entry at level 98).
Notation "#" := (asp HSH) (in custom copland_entry at level 98).
Notation "'__'" := (asp CPY) (in custom copland_entry at level 98).
Notation "'{}'" := (asp NULL) (in custom copland_entry at level 98).
Notation "'<<' x y z '>>'" := (asp (ASPC ALL EXTD (asp_paramsC x nil y z))) 
                      (in custom copland_entry at level 98).
(* @ plc phrase *)
Notation "@ p [ ph ]" := (att p ph) (in custom copland_entry at level 50).

Open Scope cop_ent_scope.
Definition test1 := <{ __ -> {} }>.
Example test1ex : test1 = (lseq (asp CPY) (asp NULL)). reflexivity. Defined.


(** Copland Core_Term primitive datatypes *)
Inductive ASP_Core: Set :=
| NULLC: ASP_Core
| CLEAR: ASP_Core
| CPYC: ASP_Core
| ASPCC: FWD -> ASP_PARAMS -> ASP_Core.

(** Abstract Location identifiers used to aid in management and execution 
    of parallel Copland phrases. *)
Definition Loc: Set := nat.
Definition Locs: Set := list Loc.

(** Copland Core_Term definition.  Compilation target of the Copland Compiler, 
    execution language of the Copland VM (CVM). *)
Inductive Core_Term: Set :=
| aspc: ASP_Core -> Core_Term
| attc: Plc -> Term -> Core_Term
| lseqc: Core_Term -> Core_Term -> Core_Term
| bseqc: Core_Term -> Core_Term -> Core_Term
| bparc: Loc -> Core_Term -> Core_Term -> Core_Term.

Declare Custom Entry core_copland_entry.
Declare Scope core_cop_ent_scope.
Notation "<<core>{ e }>" := e (at level 0, e custom core_copland_entry at level 99) : core_cop_ent_scope.
Notation "( x )" := x (in custom core_copland_entry, x at level 99) : core_cop_ent_scope.
Notation "x" := x (in custom core_copland_entry at level 0, x constr at level 0) : core_cop_ent_scope.
(* Branches*)
Notation "x < y" := (bseqc x y) (in custom core_copland_entry at level 70, right associativity).
Notation "x ~ l y" := (bparc l x y) (in custom core_copland_entry at level 70, right associativity).
(* ARROW sequences *)
Notation "x -> y" := (lseqc x y) (in custom core_copland_entry at level 99, right associativity).
(* ASP_CORE's *)
Notation "'__'" := (aspc CPYC) (in custom core_copland_entry at level 98).
Notation "'{}'" := (aspc NULLC) (in custom core_copland_entry at level 98).
Notation "'CLR'" := (aspc CLEAR) (in custom core_copland_entry at level 98).
Notation "'<<' F x y z '>>'" := (aspc (ASPCC F (asp_paramsC x nil y z))) 
                      (in custom core_copland_entry at level 98).
(* @ plc phrase *)
Notation "@ p [ ph ]" := (attc p ph) (in custom core_copland_entry at level 50).


Open Scope core_cop_ent_scope.
Definition test2 := <<core>{ __ -> {} }>.
Example test2ex : test2 = (lseqc (aspc CPYC) (aspc NULLC)). reflexivity. Defined.
Example test3 : <<core>{ CLR -> {}}> = (lseqc (aspc CLEAR) (aspc NULLC)). reflexivity. Defined.