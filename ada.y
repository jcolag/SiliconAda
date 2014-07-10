%{
/* Parser for the Ada => VHDL compiler */
/* Written for Berkeley YACC (byacc) */
#include <stdio.h>
#include <string.h>
#include "symtab.h"
#include "graph.h"

int     stmtct = 0, cvar, tcount = 0;
float   numval;
extern  char    *yytext, strlit[];
extern  stmt    *now;
stmt    *prev,  *other;
char    textbuf[128], lastvar[32];

#define YYDEBUG 1
%}

%token ABORT_ ABS_ ACCEPT_ ACCESS_ ALL_ AND_ ARRAY_ AT_
%token BEGIN_ BODY_
%token CASE_ CONSTANT_
%token DECLARE_ DELAY_ DELTA_ DIGITS_ DO_
%token ELSE_ ELSIF_ END_ ENTRY_ EXCEPTION_ EXIT_
%token FOR_ FUNCTION_
%token GENERIC_ GOTO_
%token IF_ IN_ IS_
%token LIMITED_ LOOP_
%token MOD_
%token NEW_ NOT_ NULL_
%token OF_ OR_ OTHERS_ OUT_
%token PACKAGE_ PRAGMA_ PRIVATE_ PROCEDURE_
%token RAISE_ RANGE_ RECORD_ REM_ RENAMES_ RETURN_ REVERSE_
%token SELECT_ SEPARATE_ SUBTYPE_
%token TASK_ TERMINATE_ THEN_ TYPE_
%token USE_
%token WHEN_ WHILE_ WITH_
%token XOR_

%token identifier numeric_literal string_literal character_literal
%token ARROW_ DBLDOT_ EXP_ ASSIGN_ NOTEQL_ GTEQL_ LTEQ_ L_LBL_ R_LBL_ BOX_

%start compilation

%%
/* 3.1 */
basic_d :
	object_d |
	ty_d |
	subty_d |
	subprg_d |
	pkg_d |
	task_d |
	gen_d |
	excptn_d |
	gen_inst |
	renaming_d |
	number_d |
	error ';';


/* 3.2 */
object_d        :
	idents colon subty_ind ._ASN_expr. ';' { now->type = DECL; } |
	idents colon CONSTANT_ subty_ind ._ASN_expr. ';' { now->type = DECL; } |
	idents colon c_arr_def ._ASN_expr. ';' { now->type = DECL; } |
	idents colon CONSTANT_ c_arr_def ._ASN_expr. ';' { now->type = DECL; } ;

number_d        : idents colon CONSTANT_ gets expr ';';

idents  : identifier { strcat (textbuf, lastvar); } ...ident..;


/* 3.3.1 */
ty_d    :
	full_ty_d |
	incomplete_ty_d |
	priv_ty_d;

full_ty_d       :
	TYPE_ identifier IS_ ty_def ';' |
	TYPE_ identifier discr_part IS_ ty_def ';';

ty_def  :
	enum_ty_def |
	integer_ty_def |
	real_ty_def |
	array_ty_def |
	rec_ty_def |
	access_ty_def |
	derived_ty_def;


/* 3.3.2 */
subty_d : SUBTYPE_ identifier IS_ subty_ind ';';

subty_ind       : ty_mk .constrt.;

ty_mk   : expanded_n;

constrt :
	rng_c |
	fltg_point_c |
	fixed_point_c |
	aggr;


/* 3.4 */
derived_ty_def  : NEW_ subty_ind;


/* 3.5 */
rng_c   : RANGE_ rng;

rng     :
	name |
	sim_expr DBLDOT_ sim_expr;


/* 3.5.1 */
enum_ty_def     : openparen enum_lit_spec ...enum_lit_spec.. ')';

enum_lit_spec   : enum_lit;

enum_lit        :
	identifier |
	character_literal { strcat (textbuf, yytext); } ;


/* 3.5.4 */
integer_ty_def  : rng_c;


/* 3.5.6 */
real_ty_def     :
	fltg_point_c |
	fixed_point_c;


/* 3.5.7 */
fltg_point_c    : fltg_accuracy_def .rng_c.;

fltg_accuracy_def       : DIGITS_ sim_expr;


/* 3.5.9 */
fixed_point_c   : fixed_accuracy_def .rng_c.;

fixed_accuracy_def      : DELTA_ sim_expr;


/* 3.6 */
array_ty_def    :
	uncnstrnd_array_def |
	c_arr_def;

uncnstrnd_array_def     : ARRAY_ openparen idx_subty_def ...idx_subty_def.. ')' OF_ subty_ind;

c_arr_def       : ARRAY_ idx_c OF_ subty_ind;

idx_subty_def   : name RANGE_ BOX_;

idx_c   : openparen dscr_rng ...dscr_rng.. ')';

dscr_rng        :
	rng |
	name rng_c;


/* 3.7 */
rec_ty_def      :
	RECORD_
	  cmpons
	END_ RECORD_;

cmpons  :
	 ..cmpon_d.. cmpon_d  |
	 ..cmpon_d.. variant_part  |
	 NULL_ ';' ;

cmpon_d : idents colon cmpon_subty_def ._ASN_expr. ';';

cmpon_subty_def : subty_ind;


/* 3.7.1 */
discr_part      : openparen discr_spec ...discr_spec.. ')';

discr_spec      : idents colon ty_mk ._ASN_expr.;


/* 3.7.2 */

/*
 * included under aggr
 *
 * discr_c      : openparen discr_asc ... discr_asc.. ')';
 * discr_asc    : .discr_sim_n ..or_discrim_sim_n.. ARROW. expression;
 */

/* 3.7.3 */
variant_part    :
	CASE_ sim_n IS_
	   variant ..variant..
	END_ CASE_ ';';

variant :
	WHEN_ choice ..or_choice.. ARROW_
	  cmpons;

choice  :
	sim_expr { strcat (textbuf, " "); } |
	name rng_c { strcat (textbuf, " "); } |
	sim_expr DBLDOT_ sim_expr { strcat (textbuf, " "); } |
	OTHERS_ { strcat (textbuf, " "); } ;


/* 3.8 */
access_ty_def   : ACCESS_ subty_ind;


/* 3.8.1 */
incomplete_ty_d :
	TYPE_ identifier ';' |
	TYPE_ identifier discr_part ';';


/* 3.9 */
decl_part       :
	..basic_decl_item.. |
	..basic_decl_item.. body ..later_decl_item..;

basic_decl_item :
	basic_d |
	rep_cl ;

later_decl_item :
	body |
	subprg_d |
	pkg_d |
	task_d |
	gen_d |
	gen_inst;

body    :
	proper_body |
	body_stub;

proper_body     :
	subprg_body |
	pkg_body |
	task_body;


/* 4.1 */
name    :
	sim_n |
	character_literal |
	op_symbol |
	idxed_cmpon |
	selected_cmpon |
	attribute;

sim_n   : identifier { strcat (textbuf, lastvar); } ;

prefix  : name;


/* 4.1.1 */
idxed_cmpon     : prefix aggr;


/* 4.1.2 */

/*
 * included under idxed_cmpon
 *
 * slice        : prefix openparen dscr_rng ')';
 */


/* 4.1.3 */
selected_cmpon  : prefix '.' selector;

selector        :
	sim_n |
	character_literal |
	op_symbol |
	ALL_;


/* 4.1.4 */
/* prefix can be an attribute, idxed cmpon, slice, or subprg call. */
attribute       : prefix '\'' attribute_designator;

attribute_designator    :
	sim_n |
	DIGITS_ |
	DELTA_ |
	RANGE_;


/* 4.3 */
aggr    : openparen cmpon_asc ...cmpon_asc.. ')'
		{ strcat (textbuf, ")"); } ;

cmpon_asc       :
	expr |
	choice ..or_choice.. ARROW_ expr |
	sim_expr DBLDOT_ sim_expr |
	name rng_c ;


/* 4.4 */
expr    :
	rel..AND__rel.. { tcount += LOGTIME; } |
	rel..OR__rel.. { tcount += LOGTIME; } |
	rel..XOR__rel.. { tcount += LOGTIME; } ;

rel     :
	sim_expr .relal_op__sim_expr. |
	sim_expr.NOT.IN__rng_or_sim_expr.NOT.IN__ty_mk;

sim_expr        : .unary_add_op.term..binary_add_op__term..;

term    : factor..mult_op__factor..;

factor  :
	pri ._EXP___pri. |
	ABS_ { strcat (textbuf, " abs "); } pri |
	NOT_ { strcat (textbuf, " not "); } pri;

pri     :
	numeric_literal { sprintf (lastvar, "%g", numval);
			strcat (textbuf, lastvar); } |
	NULL_ |
	allocator |
	qualified_expr |
	name |
	aggr;

/* "openparen expr ')'" is included under aggr */


/* 4.5 */

/*
 * logical_op   :
 *      AND_
 *      OR_
 *      XOR_;
 *
 * This is an unused syntactic class.
 */

relal_op        :
	'=' { strcat (textbuf, " = "); } |
	NOTEQL_ { strcat (textbuf, " /= "); } |
	'<' { strcat (textbuf, " < "); } |
	LTEQ_ { strcat (textbuf, " <= "); } |
	'>' { strcat (textbuf, " > "); } |
	GTEQL_ { strcat (textbuf, " >= "); } ;

binary_add_op   :
	'+' { strcat (textbuf, " + "); tcount += ADDTIME; } |
	'-' { strcat (textbuf, " - "); tcount += ADDTIME; } |
	'&' { strcat (textbuf, " & "); tcount += ADDTIME; } ;

unary_add_op    :
	'+' { strcat (textbuf, " + "); tcount += ADDTIME; } |
	'-' { strcat (textbuf, " - "); tcount += ADDTIME; } ;

mult_op :
	'*' { strcat (textbuf, " * "); tcount += MULTIME; } |
	'/' { strcat (textbuf, " / "); tcount += MULTIME; } |
	MOD_ { strcat (textbuf, " mod "); tcount += MULTIME; } |
	REM_ { strcat (textbuf, " rem "); tcount += MULTIME; } ;

/*
 * highest_precedence_op        :
 *      EXP_
 *      ABS_
 *      NOT_;
 *
 * This is an unused syntactic class.
 */


/* 4.6 */

/*
 * included under name
 *
 * ty_cnvr      : ty_mk openparen expr ')';
 */


/* 4.7  */
qualified_expr  : ty_mkaggr_or_ty_mkPexprP_;


/* 4.8 */
allocator       :
	NEW_ ty_mk |
	NEW_ ty_mk aggr |
	NEW_ ty_mk '\'' aggr;


/* 5.1 */
seq_of_stmts    :  stmt ..stmt..;

stmt    :
	..label.. sim_stmt { strcat (textbuf, ";"); ++stmtct;
			insert (textbuf, now); now->type = SIMP;
			/*printf (":\t%s\t:\n", textbuf);*/
			strcpy (textbuf, "\000"); tcount = 0; } |
	..label.. compound_stmt { ++stmtct; tcount = 0; } |
	error ';' { ++stmtct; } ;

/* procedure and ent call stmts are included under name */
sim_stmt        :
	null_stmt |
	assignment_stmt |
	exit_stmt |
	return_stmt |
	delay_stmt |
	abort_stmt |
	raise_stmt |
	code_stmt |
	name ';';

compound_stmt   :
	if_stmt |
	case_stmt |
	loop_stmt |
	block_stmt |
	accept_stmt |
	select_stmt;

label   : L_LBL_ sim_n R_LBL_;

null_stmt       : NULL_ ';' { tcount += NULLTIME; strcat (textbuf, "null"); } ;


/* 5.2 */
assignment_stmt : name { cvar = lookup (lastvar); tcount += ASGNTIME;
			 writevar (cvar); } gets expr ';';


/* 5.3 */
if_stmt :
	IF_ { strcat (textbuf, "if "); } cond
	THEN_ { tcount += TESTTIME; prev = now;
	strcat (textbuf, " then "); }
	stmt ';' { ++stmtct; insert (textbuf, now);
	strcpy (textbuf, "\000"); } ;

cond    : expr;


/* 5.4 */
case_stmt       :
	CASE_ { strcat (textbuf, " archtmp0 := "); tcount += ASGNTIME; } expr
		IS_ { insert (textbuf, now); now->type = SIMP;
			strcpy (textbuf, "\000"); }
	  case_stmt_alt..case_stmt_alt..
	END_ CASE_ ';';

case_stmt_alt   :
	WHEN_ { strcpy ( textbuf, "if archtmp0 = "); tcount += TESTTIME; }
		choice ..ored_choices.. ARROW_ { strcat (textbuf, "then "); }
	  seq_of_stmts { now->type = COND; } ;


..ored_choices.. :
	/* empty */ |
	..ored_choices.. '|' { strcat (textbuf, "or archtmp0 = ");
			tcount += LOGTIME; } choice;

/* 5.5  */
loop_stmt       :
	.sim_nC.
	  .iteration_scheme. LOOP_
		{ prev = now; strcat (textbuf, "loop"); ++stmtct;
			insert (textbuf, now); now->type = LOOP;
			strcpy (textbuf, "\000"); }
	  seq_of_stmts
	  END_ LOOP_ .sim_n. ';';

iteration_scheme        :
	WHILE_ { strcat (textbuf, "while "); } cond |
	FOR_ { strcat (textbuf, "for "); } loop_prm_spec;

loop_prm_spec   :
	identifier IN_ { strcat (textbuf, "in "); } .REVERSE. dscr_rng;


/* 5.6 */
block_stmt      :
	.sim_nC.
	  .DECLARE__decl_part.
	  BEGIN_
	    seq_of_stmts
	  .EXCEPTION__excptn_handler..excptn_handler...
	  END_ .sim_n. ';';


/* 5.7 */
exit_stmt       : exit .expanded_n. .WHEN__cond. ';' ;

/* 5.8 */
return_stmt     : RETURN_ { strcat (textbuf, "return "); } .expr. ';';


/* 6.1 */
subprg_d        : subprg_spec ';';

subprg_spec     :
	PROCEDURE_ { strcat (textbuf, "procedure "); } identifier
			{ strcat (textbuf, lastvar); } .fml_part. |
	FUNCTION_ designator .fml_part. RETURN_ ty_mk;

designator      :
	identifier { strcat (textbuf, "function ");
			strcat (textbuf, lastvar); } |
	op_symbol;

op_symbol       : string_literal { strcat (textbuf, strlit); } ;

fml_part        : openparen prm_spec .._.prm_spec.. ')'
			{ strcat (textbuf, ") "); } ;

prm_spec        : idents colon mode ty_mk ._ASN_expr.;

mode    :
	.IN. { strcat (textbuf, " in "); } |
	IN_ OUT_ { strcat (textbuf, " inout ");
		cvar = lookup (lastvar); writevar (cvar); } |
	OUT_ { strcat (textbuf, " out ");
		cvar = lookup (lastvar); writevar (cvar); } ;


/* 6.3 */
subprg_body     :
	subprg_spec IS_ 
	{ strcat (textbuf, " is"); ++stmtct;
			insert (textbuf, now);
			/*printf (":\t%s\t:\n", textbuf);*/
			strcpy (textbuf, "\000"); }
	  .decl_part.
	BEGIN_
	  seq_of_stmts
	.EXCEPTION__excptn_handler..excptn_handler...
	END_ .designator. ';';


/* 6.4 */

/*
 * procedure_call_stmt  : procedure_n .act_prm_part. ';';
 *
 * func_call    : func_n .act_prm.;
 *
 * act_prm_part : openparen prm_asc ... prm_asc .._paren;
 *
 * prm_asc      : .fml_prm ARROW. act_prm;
 *
 * fml_prm      : sim_n;
 *
 * act_prm      :
 *      expr |
 *      name |
 *      ty_mk openparen name ')';
 *
 * procedure_call_stmt and func_call are included under name
 */


/* 7.1 */
pkg_d   : pkg_spec ';';

pkg_spec        :
	PACKAGE_ identifier IS_
	  ..basic_decl_item..
	  .PRIVATE..basic_decl_item...
	END_ .sim_n.;

pkg_body        :
	PACKAGE_ BODY_ sim_n IS_
	  .decl_part.
	  .BEGIN__seq_of_stmts.EXCEPTION__excptn_handler..excptn_handler...
	END_ .sim_n. ';';


/* 7.4  */
priv_ty_d       :
	TYPE_ identifier IS_ .LIMITED. PRIVATE_ ';' |
	TYPE_ identifier discr_part IS_ .LIMITED. PRIVATE_ ';';

/*
 * included under object_d
 *
 * defer_const_d        : idents : CONSTANT_ ty_mk ';';
 */


/* 8.5 */
/* idents in the following rule must contain only one identifier */
renaming_d      :
	idents colon ty_mk RENAMES_ name ';' |
	idents colon EXCEPTION_ RENAMES_ expanded_n ';' |
	PACKAGE_ identifier RENAMES_ expanded_n ';' |
	subprg_spec RENAMES_ name ';';


/* 9.1 */
task_d  : task_spec ';';

task_spec       :
	TASK_ .TYPE. identifier
	.IS..ent_d_..rep_cl_END.sim_n.;

task_body       :
	TASK_ BODY_ sim_n IS_
	  .decl_part.
	BEGIN_
	  seq_of_stmts
	.EXCEPTION__excptn_handler..excptn_handler...
	END_ .sim_n. ';';


/* 9.5 */
ent_d   :
	ENTRY_ identifier .fml_part. ';' |
	ENTRY_ identifier openparen dscr_rng ')' .fml_part. ';';

ent_call_stmt   :  name ';';

accept_stmt     :
	ACCEPT_ sim_n .Pent_idx_P..fml_part.
	  .DO__seq_of_stmts__END.sim_n.. ';';

ent_idx : expr;


/* 9.6 */
delay_stmt      : DELAY_ { strcat (textbuf, "wait for "); } sim_expr ';';


/* 9.7 */
select_stmt     :
	selec_wait |
	condal_ent_call |
	timed_ent_call;


/* 9.7.1 */
selec_wait      :
	SELECT_
	  select_alt
	..OR__select_alt..
	END_ SELECT_ ';';

select_alt      :
	.WHEN__condARROW.selec_wait_alt;

selec_wait_alt  :
	accept_alt |
	delay_alt |
	terminate_alt;

accept_alt      : accept_stmt.seq_of_stmts.;

delay_alt       : delay_stmt.seq_of_stmts.;

terminate_alt   : TERM_stmt;


/* 9.7.2 */
condal_ent_call :
	SELECT_
	  ent_call_stmt
	  .seq_of_stmts.
	END_ SELECT_ ';';


/* 9.7.3 */
timed_ent_call  :
	SELECT_
	  ent_call_stmt
	  .seq_of_stmts.
	OR_
	  delay_alt
	END_ SELECT_ ';';


/* 9.10 */
abort_stmt      : ABORT_ name { strcat (textbuf, ".halt <= 1"); } ';';


/* 10.1 */
compilation     : ..compilation_unit..;

compilation_unit        :
	library_unit |
	secondary_unit ;

library_unit    :
	subprg_d |
	pkg_d |
	gen_d |
	gen_inst |
	subprg_body;

secondary_unit  :
	library_unit_body |
	subunit;

library_unit_body       : pkg_body_or_subprg_body;


/* 10.2 */
body_stub       :
	subprg_spec IS_ SEPARATE_ ';' |
	PACKAGE_ BODY_ sim_n IS_ SEPARATE_ ';' |
	TASK_ BODY_ sim_n IS_ SEPARATE_ ';';

subunit : SEPARATE_ openparen expanded_n ')' proper_body;


/* 11.1 */
excptn_d        : idents colon EXCEPTION_ ';';


/* 11.2 */
excptn_handler  :
	WHEN_ excptn_choice ..or_excptn_choice.. ARROW_
	  seq_of_stmts;

excptn_choice   :
	expanded_n |
	OTHERS_ ;


/* 11.3 */
raise_stmt      : RAISE_ expanded_n ';'
			{ strcat (textbuf, ".reset <= 1"); tcount += SENDTIME; } ;


/* 12.1 */
gen_d   : gen_spec ';';

gen_spec        :
	gen_fml_part subprg_spec |
	gen_fml_part pkg_spec;

gen_fml_part    : GENERIC_ ..gen_prm_d..;

gen_prm_d       :
	idents colon .IN.OUT.. ty_mk ._ASN_expr. ';' |
	TYPE_ identifier IS_ gen_ty_def ';' |
	priv_ty_d ;
/*
 * this rule is included in the previous one
 *      WITH_ subprg_spec .IS_ name. ';'
 */

gen_ty_def      :
	openparen BOX_ ')' |
	RANGE_ BOX_ |
	DIGITS_ BOX_ |
	DELTA_ BOX_ |
	array_ty_def |
	access_ty_def;


/* 12.3 */
gen_inst        :
	PACKAGE_ identifier IS_ NEW_ expanded_n .gen_act_part. ';' |
	PROCEDURE__ident__IS_ NEW_ expanded_n .gen_act_part. ';' |
	FUNCTION_ designator IS_ NEW_ expanded_n .gen_act_part. ';';

gen_act_part    : openparen gen_asc ...gen_asc.. ')';

gen_asc : .gen_fml_prmARROW.gen_act_prm;

gen_fml_prm     :
	sim_n |
	op_symbol;

gen_act_prm     : expr_or_name_or_subprg_n_or_ent_n_or_ty_mk;


/* 13.1 */
rep_cl  :
	ty_rep_cl |
	address_cl;

ty_rep_cl       :
	length_cl |
	enum_rep_cl |
	rec_rep_cl;


/* 13.2 */
length_cl       : FOR_ attribute USE_ sim_expr ';';


/* 13.3 */
enum_rep_cl     : FOR__ty_sim_n__USE_ aggr ';';


/* 13.4 */
rec_rep_cl      :
	FOR__ty_sim_n__USE_ RECORD_ .algt_cl.
	  ..cmpon_cl..
	END_ RECORD_ ';';

algt_cl : AT_ MOD_ sim_expr ';';

cmpon_cl        : name AT_ sim_expr RANGE_ rng ';';


/* 13.5 */
address_cl      : FOR_ sim_n USE_ AT_ sim_expr ';';


/* 13.8 */
code_stmt       : ty_mk_rec_aggr ';';


/*
 * The following rules define semantically qualified symbols under more
 * general categories.
 *
 * ty_n_or_subty_n      : expanded_n;
 *
 * An expanded_n is used for names that can be written using only selectors.
 *
 * ... these have been replaced logically to reduce the number of YACC_
 * nonterminal "rules".
 *
 * The following rules expand the concatenated constructs and define the
 * specially added syntactical classes.
 */


/* 3.1 */

/* defer_const_d is included under object_d */

._ASN_expr.     :
	/* empty */ |
	gets expr;

...ident..      :
	/* empty */ |
	...ident.. comma identifier ;

.constrt.       :
	/* empty */ |
	constrt;

/* idx_cg and discr_c are included under aggr */

expanded_n      :
	identifier { strcat (textbuf, lastvar); } ;
/** /    expanded_n '.' identifier ; / * May eliminate for VHDL simplicity */

/*
 * This expansion generalizes rng so that it may include ty and
 * subty names.
 */

...enum_lit_spec..      :
	/* empty */ |
	...enum_lit_spec.. ',' enum_lit_spec;
.rng_c. :
	/* empty */ |
	rng_c;

/* To avoid conflicts, the more general class name is used. */
...idx_subty_def..      :
	/* empty */ |
	...idx_subty_def.. ',' idx_subty_def;

/* A_ dscr subty ind given as a ty mk is included under rng */
...dscr_rng..   :
	/* empty */ |
	...dscr_rng.. ',' dscr_rng;

..cmpon_d..     :
	/* empty */ |
	..cmpon_d.. cmpon_d ;

...discr_spec.. :
	/* empty */ |
	...discr_spec.. ';' discr_spec;

/*
 * Pragmas that can appear between two consecutive variants are
 * picked up in the cmpons part of the variants themselves.
 */

..variant..     :
	/* empty */ |
	..variant.. variant;

..or_choice..   :
	/* empty */ |
	..or_choice.. '|' choice;

/*
 * The sim_expr by itself may be a dscr_rng or a "cmpon_sim_n".
 *
 * A_ body is the only later_decl_item that is not also a
 * basic_decl_item. It is therefore used as the dividing
 * point between the two lists of decl items.
 */

..basic_decl_item..     :
	/* empty */ |
	..basic_decl_item.. basic_decl_item
			{ strcat (textbuf, ";"); ++stmtct;
				insert (textbuf, now);
				/*printf (":\t%s\t:\n", textbuf);*/
				strcpy (textbuf, "\000"); } ;

..later_decl_item..     :
	 |
	..later_decl_item.. later_decl_item ;


/* 4.1 */

/* slice is included under idxed_cmpon */

/*
 * The def of name includes func_call.
 *
 * A prmless func call is recognized as a sim name or a selected cmpon.
 * A func call with prms is recognized as an idxed cmpon.
 *
 * Reserved word attribute designators are included in the rules as a
 * convenience. Alternativly, since an attribute designator is always preceded
 * by an apostrophe, as noted in the RR_ 4.1.4, such usage may be detected
 * during lexical analysis thus obviating the need for special rules.
 *
 * The univ static expr of an attribute designator is reduced as an idxed_cmpon.
 */

/*
 * Component ascs are generalized to include dscr rngs.
 * Thus, an aggr can be used for slices and idx and discr constrts.
 */
...cmpon_asc..  :
	/* empty */ |
	...cmpon_asc.. ',' cmpon_asc;

rel..AND__rel.. :
	rel AND_ rel { tcount += LOGTIME; } |
	rel..AND__rel.. AND_ rel { tcount += LOGTIME; } ;

rel..OR__rel..  :
	rel OR_ rel { tcount += LOGTIME; } |
	rel..OR__rel.. OR_ rel { tcount += LOGTIME; } ;

rel..XOR__rel.. :
	rel |
	..XOR__rel..;

..XOR__rel..    :
	rel XOR_ rel { tcount += LOGTIME; } |
	..XOR__rel.. XOR_ rel { tcount += LOGTIME; } ;

.relal_op__sim_expr.    :
	/* empty */ |
	relal_op sim_expr { tcount += TESTTIME; } ;

/* ty_mk is included under rng */
sim_expr.NOT.IN__rng_or_sim_expr.NOT.IN__ty_mk  : sim_expr .NOT. IN_ rng;

.NOT.   :
	/* empty */ |
	NOT_;

.unary_add_op.term..binary_add_op__term..       :
	term |
	unary_add_op term |
	.unary_add_op.term..binary_add_op__term.. binary_add_op term;

factor..mult_op__factor..       :
	factor |
	factor..mult_op__factor.. mult_op factor;

/* stringsit is included under name as op_symbol */
/* func_call is included under name */
/* ty_cnvr is included under name */
._EXP___pri.    :
	/* empty */ |
	EXP_ { strcat (textbuf, " ** "); tcount += EXPTIME; } pri;

/* The "prefix must be a "ty_mk". The "PexprP_" is an "aggr". */
ty_mkaggr_or_ty_mkPexprP_       : prefix '\'' aggr;

/*
 * Here the qualified_expr can be given exactly
 *
 * We use the fact that the constrt must be an idx or discr
 * constrt.
 */


/* 5.1 */
..stmt..        :
	 |
	..stmt.. stmt ;

..label..       :
	/* empty */ |
	..label.. label;

case_stmt_alt..case_stmt_alt..  :
	
	case_stmt_alt
	..case_stmt_alt..;

..case_stmt_alt..       :
	/* empty */ |
	..case_stmt_alt.. case_stmt_alt;

.sim_nC.        :
	/* empty */ |
	sim_n ':' { strcat (textbuf, ":\n"); /*printf ("%s\n", textbuf);*/
			strcpy (textbuf, "\000"); } ;

.sim_n. :
	/* empty */ |
	sim_n {/* printf ("END %s\n", textbuf);*/ strcpy (textbuf, "\000"); } ;

.iteration_scheme.      :
	/* empty */ |
	iteration_scheme;

.REVERSE.       :
	/* empty */ |
	REVERSE_ { strcat (textbuf, "reverse "); } ;

.DECLARE__decl_part.    :
	/* empty */ |
	DECLARE_
	  decl_part;

.EXCEPTION__excptn_handler..excptn_handler...   :
	/* empty */ |
	EXCEPTION_
	   excptn_handlers;

excptn_handlers :
	excptn_handler |
	excptn_handlers excptn_handler;

.expr.  :
	/* empty */ |
	expr;


/* 6.1 */
.fml_part.      :
	/* empty */ |
	fml_part;

.._.prm_spec..  :
	/* empty */ |
	.._.prm_spec.. ';' prm_spec;

.IN.    :
	/* empty */ |
	IN_;

/* A "decl_part" may be empty, from ..basic_decl_item.. */
.decl_part.     :
		decl_part;

.designator.    :
	/* empty */ |
	designator;


/* 7.1  */
.PRIVATE..basic_decl_item...    :
	/* empty */ |
	PRIVATE_
	  ..basic_decl_item..;

.BEGIN__seq_of_stmts.EXCEPTION__excptn_handler..excptn_handler...       :
	/* empty */ |
	BEGIN_
	  seq_of_stmts
	.EXCEPTION__excptn_handler..excptn_handler...;

.LIMITED.       :
	/* empty */ |
	LIMITED_;


/* 9.1 */
.TYPE.  :
	/* empty */ |
	TYPE_;

.IS..ent_d_..rep_cl_END.sim_n.  :
	/* empty */ |
	IS_
	  ..ent_d..
	  ..rep_cl..
	END_ .sim_n.;

..ent_d..       :
	 |
	..ent_d.. ent_d ;

..rep_cl..      :
	/* empty */ |
	..rep_cl.. rep_cl ;

.Pent_idx_P..fml_part.  :
	.fml_part. |
	openparen ent_idx ')' .fml_part.;

.DO__seq_of_stmts__END.sim_n..  :
	/* empty */ |
	DO_
	  seq_of_stmts
	END_ .sim_n.;

..OR__select_alt..      :
	/* empty */ |
	..OR__select_alt.. OR_ select_alt;

.WHEN__condARROW.selec_wait_alt :
	selec_wait_alt |
	WHEN_ cond ARROW_ selec_wait_alt;

accept_stmt.seq_of_stmts.       :  accept_stmt .seq_of_stmts.;

delay_stmt.seq_of_stmts.        :  delay_stmt .seq_of_stmts.;

TERM_stmt       :  TERMINATE_ ';'
			{ strcat (textbuf, "wait on reset;"); } ;

.seq_of_stmts.  :
	 |
	seq_of_stmts;

/* 10.1 */
..compilation_unit..    :
	 |
	..compilation_unit..
	compilation_unit ;

/* "subprg_body" is already contained in the class "library_unit". */
pkg_body_or_subprg_body : pkg_body;


/* 11.1 */
..or_excptn_choice..    :
	/* empty */ |
	..or_excptn_choice.. '|' excptn_choice;


/* 12.1 */
..gen_prm_d..   :
	/* empty */ |
	..gen_prm_d.. gen_prm_d;

.IN.OUT..       :
	.IN. |
	IN_ OUT_;

/* To avoid conflicts, the more general "subprg_spec" is used. */
PROCEDURE__ident__IS_   : subprg_spec IS_;

.gen_act_part.  :
	/* empty */ |
	gen_act_part;

...gen_asc..    :
	/* empty */ |
	...gen_asc.. ',' gen_asc;

.gen_fml_prmARROW.gen_act_prm   :
	gen_act_prm |
	gen_fml_prm ARROW_ gen_act_prm;

/* The below alts are included under expr */
expr_or_name_or_subprg_n_or_ent_n_or_ty_mk      : expr;


/* 13.1 */
/* The "sim_n" must be a "ty_sim_n". */
FOR__ty_sim_n__USE_     : FOR_ sim_n USE_;

.algt_cl.       :
	 |
	 algt_cl ;

..cmpon_cl..    :
	/* empty */ |
	..cmpon_cl.. cmpon_cl ;

/* The qualified expr must contain a rec aggr. */
ty_mk_rec_aggr  : qualified_expr;

colon : ':' { strcat (textbuf, ":  "); } ;

comma : ',' { strcat (textbuf, ", "); } ;

openparen : '(' { strcat (textbuf, " ("); } ;

gets : ASSIGN_ { strcat (textbuf, " := "); } ;

exit : EXIT_ { strcat (textbuf, "exit "); } ;

when : WHEN_ { strcat (textbuf, "when "); } ;

.WHEN__cond. :   /* empty */ |
		when cond;

.expanded_n. :  /* empty */ |
		expanded_n;
