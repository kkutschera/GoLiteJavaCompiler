%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "tree.h"

// Reference to the line number generated by the scanner
extern int yylineno;
// Reference to the yylex function to quiet a compiler warning
int yylex();

// Root of the AST
extern PROG *root;

void yyerror(const char *s) {
  fprintf(stderr, "Error: (line %d) %s\n", yylineno, s);
  exit(1);
}
%}


%locations
%code requires{
  #include<stdbool.h>
}
%union {
  int intval;
  float floatval;
  bool boolval;
  char runeval;
  char *stringval;
  char *identifier;
}

%token <intval> tINTVAL
%token <floatval> tFLOATVAL
%token <runeval> tRUNEVAL
%token <stringval> tSTRINGVAL
%token <identifier> tIDENTIFIER

/* Keywords */
%token tBREAK tCASE tCHAN tCONST tCONTINUE tDEFAULT tDEFER
%token tELSE tFALLTHROUGH tFOR tFUNC tGO tGOTO tIF tIMPORT tINTERFACE
%token tMAP tPACKAGE tRANGE tRETURN tSELECT tSTRUCT tSWITCH tTYPE tVAR
%token tPRINT tPRINTLN tAPPEND tLEN tCAP

/* Operators */
%token tPLUS tMINUS tTIMES tDIV tMOD
%token tBITAND tBITOR tBITXOR tLEFTSHIFT tRIGHTSHIFT tBITCLEAR
%token tPLUSEQ tMINUSEQ tTIMESEQ tDIVEQ tMODEQ
%token tBITANDEQ tBITOREQ tBITXOREQ tBITDIVEQ tLEFTSHIFTEQ tRIGHTSHIFTEQ tBITCLEAREQ
%token tAND tOR tCHANNEL tINC tDEC
%token tEQ tLESS tGREATER tASSIGN tBANG
%token tNOTEQ tLTEQ tGTEQ tDECL tELIP
%token tLPAREN tRPAREN tLSBRACE tRSBRACE tLCBRACE tRCBRACE
%token tCOMMA tPERIOD tCOLON tSEMICOLON

/* Types */
%union {
    char *id;
    struct PROG *prog;
    struct PACKAGE *package;
    struct DECL *decl;
    struct TYPE_SPECS *typeSpecs;
    struct VAR_SPECS *varSpecs;
    struct SIGNATURE *signature;
    struct PARAM_LIST *paramList;
    struct ID_LIST *idList;
    struct STMT *stmt;
    struct STMT_LIST *stmtList;
    struct FOR_CLAUSE *forClause;
    struct CASE_CLAUSE_LIST *caseClauseList;
    struct CASE_CLAUSE *caseClause;
    struct EXP_LIST *exprList;
    struct EXP *exp;
    struct TYPE *type;
    struct FIELD_DECLS *fieldDecls;
};


%type <prog> prog
%type <package> PackageDecl
%type <decl> TopLevelDeclList FuncDecl Declaration TypeDecl VarDecl ShortVarDecl
%type <varSpecs> VarSpec VarSpecList
%type <typeSpecs> TypeSpec TypeSpecList
%type <paramList> Parameters ParameterList ParameterDecl
%type <idList> IdentifierList
%type <signature> Signature
%type <stmt> Statement Block SimpleStatement IncDecStatement AssignStatement PrintStatement PrintlnStatement ReturnStatement ContinueStatement BreakStatement IfStatement ElseStatement ExprSwitchStatement ForStatement
%type <stmtList> StatementList
%type <forClause> ForClause
%type <caseClauseList> ExprCaseClauseList
%type <caseClause> ExprCaseClause
%type <exprList> ExpressionList
%type <exp> Expression ExpressionOrEmpty PrimaryExpression AppendExpression LenExpression CapExpression UnaryExpression
%type <type> Type CompoundType CompoundTypeParen ArrayType SliceType StructType
%type <fieldDecls> FieldDecl FieldDeclList


%left tOR
%left tAND
%left tEQ tNOTEQ
%left tLTEQ tGTEQ tLESS tGREATER
%left tPLUS tMINUS tBITOR tBITXOR
%left tTIMES tDIV tMOD tBITAND tLEFTSHIFT tRIGHTSHIFT tBITCLEAR
%left tBANG
%left UNARY BINARY

%nonassoc tELSE

%start prog
%%
prog: PackageDecl TopLevelDeclList { root = makeProg($1, $2, @1.first_line); }
    ;

PackageDecl: tPACKAGE tIDENTIFIER tSEMICOLON { $$ = makePackage($2, @2.first_line); }
    ;

TopLevelDeclList: %empty {$$ = NULL;}
    | Declaration tSEMICOLON TopLevelDeclList   { $$ = makeDecls($1, $3); }
    | FuncDecl tSEMICOLON TopLevelDeclList  { $$ = makeDecls($1, $3); }
    ;

Declaration: TypeDecl   { $$ = $1; }
    | VarDecl       { $$ = $1; }
    ;

VarDecl: tVAR VarSpec  { $$ = makeVarDecl($2, @2.first_line); }
    | tVAR tLPAREN VarSpecList tRPAREN  { $$ = makeVarDecl($3, @3.first_line); }
    ;

ShortVarDecl: ExpressionList tDECL ExpressionList   { $$ = makeShortVarDecl($1, $3, @1.first_line); }
    ;

VarSpec: IdentifierList Type tASSIGN ExpressionList { $$ = makeVarSpecs($1, $4, $2, @1.first_line); }
    | IdentifierList tASSIGN ExpressionList     { $$ = makeVarSpecs($1, $3, NULL, @1.first_line); }
    | IdentifierList Type   { $$ = makeVarSpecs($1, NULL, $2, @1.first_line); }
    ;

VarSpecList: %empty     { $$ = NULL; }
    | VarSpecList VarSpec tSEMICOLON    { $$ = addVarSpec($1, $2); }
    ;

Type: tIDENTIFIER   { $$ = makeType($1, @1.first_line); }
    | CompoundType  { $$ = $1; }
    | tLPAREN Type tRPAREN { $$ = $2; }
    ;

CompoundType: ArrayType
    | SliceType
    | StructType
    ;

CompoundTypeParen: CompoundType { $$ = $1; }
    | tLPAREN CompoundTypeParen tRPAREN { $$ = $2; }
    ;

IdentifierList: tIDENTIFIER     { $$ = makeIdList(NULL, $1); }
    | IdentifierList tCOMMA tIDENTIFIER     { $$ = makeIdList($1, $3); }
    ;

Expression: UnaryExpression %prec UNARY     { $$ = $1; }
    | Expression tOR Expression    { $$ = makeBinaryExp(ek_or, $1, $3, @1.first_line); }
    | Expression tAND Expression    { $$ = makeBinaryExp(ek_and, $1, $3, @1.first_line); }
    | Expression tEQ Expression   { $$ = makeBinaryExp(ek_eq, $1, $3, @1.first_line); }
    | Expression tNOTEQ Expression    { $$ = makeBinaryExp(ek_ne, $1, $3, @1.first_line); }
    | Expression tLESS Expression   { $$ = makeBinaryExp(ek_lt, $1, $3, @1.first_line); }
    | Expression tLTEQ Expression   { $$ = makeBinaryExp(ek_le, $1, $3, @1.first_line); }
    | Expression tGREATER Expression   { $$ = makeBinaryExp(ek_gt, $1, $3, @1.first_line); }
    | Expression tGTEQ Expression    { $$ = makeBinaryExp(ek_ge, $1, $3, @1.first_line); }
    | Expression tPLUS Expression   { $$ = makeBinaryExp(ek_plus, $1, $3, @1.first_line); }
    | Expression tMINUS Expression   { $$ = makeBinaryExp(ek_minus, $1, $3, @1.first_line); }
    | Expression tBITOR Expression  { $$ = makeBinaryExp(ek_bitOr, $1, $3, @1.first_line); }
    | Expression tBITXOR Expression   { $$ = makeBinaryExp(ek_bitXor, $1, $3, @1.first_line); }
    | Expression tTIMES Expression   { $$ = makeBinaryExp(ek_times, $1, $3, @1.first_line); }
    | Expression tDIV Expression  { $$ = makeBinaryExp(ek_div, $1, $3, @1.first_line); }
    | Expression tMOD Expression   { $$ = makeBinaryExp(ek_mod, $1, $3, @1.first_line); }
    | Expression tLEFTSHIFT Expression   { $$ = makeBinaryExp(ek_bitLeftShift, $1, $3, @1.first_line); }
    | Expression tRIGHTSHIFT Expression   { $$ = makeBinaryExp(ek_bitRightShift, $1, $3, @1.first_line); }
    | Expression tBITAND Expression   { $$ = makeBinaryExp(ek_bitAnd, $1, $3, @1.first_line); }
    | Expression tBITCLEAR Expression   { $$ = makeBinaryExp(ek_bitClear, $1, $3, @1.first_line); }
    ;

ExpressionList: Expression  { $$ = makeExpList(NULL, $1); }
    | ExpressionList tCOMMA Expression  { $$ = makeExpList($1, $3); }
    ;

UnaryExpression: PrimaryExpression  { $$ = $1; }
    | tPLUS UnaryExpression   { $$ = makeUnaryExp(ek_uplus,$2, @1.first_line); }
    | tMINUS UnaryExpression   { $$ = makeUnaryExp(ek_uminus,$2, @1.first_line); }
    | tBANG UnaryExpression   { $$ = makeUnaryExp(ek_bang,$2, @1.first_line); }
    | tBITXOR UnaryExpression   { $$ = makeUnaryExp(ek_ubitXor,$2, @1.first_line); }
    ;

PrimaryExpression: tIDENTIFIER  { $$ = makeIdentifierExp($1, @1.first_line); }
    | tINTVAL   { $$ = makeIntValExp($1, @1.first_line); }
    | tFLOATVAL { $$ = makeFloatValExp($1, @1.first_line); }
    | tSTRINGVAL    { $$ = makeStringValExp($1, @1.first_line); }
    | tRUNEVAL  { $$ = makeRuneValExp($1, @1.first_line); }
    | tLPAREN Expression tRPAREN    { $$ = makeParenExp($2, @1.first_line); }
    | PrimaryExpression tPERIOD tIDENTIFIER     { $$ = makeStructFieldAccess($1, $3, @1.first_line); }
    | PrimaryExpression tLSBRACE Expression tRSBRACE    { $$ = makeIndexExp($1, $3, @1.first_line); }  
    | PrimaryExpression tLPAREN ExpressionList tRPAREN { $$ = makeArgumentExp($1, $3, NULL, @1.first_line); }
    | PrimaryExpression tLPAREN tRPAREN { $$ = makeArgumentExp($1 , NULL, NULL, @1.first_line); }
    | CompoundTypeParen tLPAREN ExpressionList tRPAREN { $$ = makeArgumentExp(NULL, $3, $1, @1.first_line); }
    | AppendExpression  { $$ = $1; }
    | LenExpression { $$ = $1; }
    | CapExpression { $$ = $1; }
    ;

AppendExpression: tAPPEND tLPAREN Expression tCOMMA Expression tRPAREN  { $$ = makeAppendCall($3, $5, @1.first_line); }
    ;

LenExpression: tLEN tLPAREN Expression tRPAREN  { $$ = makeLenCall($3, @1.first_line); }
    ;

CapExpression: tCAP tLPAREN Expression tRPAREN  { $$ = makeCapCall($3, @1.first_line); }
    ;

TypeDecl: tTYPE TypeSpec    { $$ = makeTypeDecl($2, @2.first_line); }
    | tTYPE tLPAREN TypeSpecList tRPAREN    { $$ = makeTypeDecl($3, @1.first_line); }
    ;

TypeSpec: tIDENTIFIER Type { $$ = makeTypeSpec($1, $2); }
    ;

TypeSpecList: %empty    { $$ = NULL; }
    | TypeSpecList TypeSpec tSEMICOLON  { $$ = makeTypeSpecList($1, $2); }
    ;

FuncDecl: tFUNC tIDENTIFIER Signature Block     { $$ = makeFuncDecl($2, $3, $4, @1.first_line); }
    ;

Block: tLCBRACE StatementList tRCBRACE  { $$ = makeBlockStmt($2, @2.first_line); }
    | tLCBRACE tRCBRACE { $$ = makeBlockStmt(NULL, @1.first_line);}
    ;

StatementList: Statement tSEMICOLON         { $$ = makeStmtList($1, NULL); }
    | Statement tSEMICOLON StatementList    { $$ = makeStmtList($1, $3); }
    ;

Statement: Declaration { $$ = makeDeclStmt($1, @1.first_line); }
    | Block { $$ = $1; }
    | SimpleStatement   { $$ = $1; }
    | PrintStatement    { $$ = $1; }
    | PrintlnStatement  { $$ = $1; }
    | ReturnStatement   { $$ = $1; }
    | IfStatement   { $$ = $1; }
    | ExprSwitchStatement   { $$ = $1; }
    | ForStatement      { $$ = $1; }
    | ContinueStatement     { $$ = $1; }
    | BreakStatement    { $$ = $1; }
    ;

SimpleStatement: %empty     { $$ = makeEmptyStmt(@0.first_line); }
    | Expression    { $$ = makeExpStmt($1, @1.first_line); }
    | IncDecStatement   { $$ = $1; }
    | AssignStatement   { $$ = $1; }
    | ShortVarDecl  { $$ = makeShortDeclStmt($1, @1.first_line); }
    ;

Signature: Parameters   { $$ = makeSignature($1, NULL); }
    | Parameters Type   { $$ = makeSignature($1, $2); }
    ;

Parameters: tLPAREN ParameterList tRPAREN   { $$  = $2; }
    | tLPAREN tRPAREN   { $$ = NULL; }
    ;

ParameterList: ParameterDecl    { $$ = $1; }
    | ParameterDecl tCOMMA ParameterList    { $$ = makeParamList($1, $3); }
    ;

ParameterDecl: IdentifierList Type  { $$ = makeParamListFromIdList($1, $2, @1.first_line); }
    ;

SliceType: tLSBRACE tRSBRACE Type    { $$ = makeSliceType($3, @3.first_line); }
    ;

ArrayType: tLSBRACE tINTVAL tRSBRACE Type { $$ = makeArrayType($2, $4, @2.first_line); }
    ;

StructType: tSTRUCT tLCBRACE FieldDeclList tRCBRACE { $$ = makeStructType($3, @3.first_line); }
    ;

FieldDeclList: %empty { $$ = NULL; }
    | FieldDecl tSEMICOLON FieldDeclList    { $$ = makeFieldDeclsList($1, $3); }
    ;

FieldDecl: IdentifierList Type  { $$ = makeFieldDecls($1, $2, @1.first_line); }
    ;

AssignStatement: ExpressionList tASSIGN ExpressionList  { $$ = makeAssignStmt($1, $3, @1.first_line); }
    | Expression tPLUSEQ Expression    { $$ = makeAssignOpStmt($1, $3, aok_plus, @1.first_line); }
    | Expression tMINUSEQ Expression    { $$ = makeAssignOpStmt($1, $3, aok_minus, @1.first_line); }
    | Expression tTIMESEQ Expression    { $$ = makeAssignOpStmt($1, $3, aok_times, @1.first_line); }
    | Expression tDIVEQ Expression        { $$ = makeAssignOpStmt($1, $3, aok_div, @1.first_line); }
    | Expression tMODEQ Expression    { $$ = makeAssignOpStmt($1, $3, aok_mod, @1.first_line); }
    | Expression tBITANDEQ Expression    { $$ = makeAssignOpStmt($1, $3, aok_bitAnd, @1.first_line); }
    | Expression tBITOREQ Expression    { $$ = makeAssignOpStmt($1, $3, aok_bitOr, @1.first_line); }
    | Expression tBITXOREQ Expression    { $$ = makeAssignOpStmt($1, $3, aok_bitXor, @1.first_line); }
    | Expression tLEFTSHIFTEQ Expression    { $$ = makeAssignOpStmt($1, $3, aok_bitLeftShift, @1.first_line); }
    | Expression tRIGHTSHIFTEQ Expression    { $$ = makeAssignOpStmt($1, $3, aok_bitRightShift, @1.first_line); }
    | Expression tBITCLEAREQ Expression    { $$ = makeAssignOpStmt($1, $3, aok_bitClear, @1.first_line); }
    ;

IncDecStatement: Expression tINC   { $$ = makeIncrStmt($1, @1.first_line); }
    | Expression tDEC   { $$ = makeDecrStmt($1, @1.first_line); }
    ;

PrintStatement: tPRINT tLPAREN ExpressionList tRPAREN   { $$ = makePrintStmt($3, @1.first_line); }
    | tPRINT tLPAREN tRPAREN    { $$ = makePrintStmt(NULL, @1.first_line); }
    ;

PrintlnStatement: tPRINTLN tLPAREN ExpressionList tRPAREN   { $$ = makePrintlnStmt($3, @1.first_line); }
    | tPRINTLN tLPAREN tRPAREN  { $$ = makePrintlnStmt(NULL, @1.first_line); }
    ;

ReturnStatement: tRETURN { $$ = makeReturnStmt(NULL, @1.first_line); }
    | tRETURN Expression    { $$ = makeReturnStmt($2, @1.first_line); }
    ;

IfStatement: tIF Expression Block ElseStatement   { $$ = makeIfStmt(NULL, $2, $3, $4, @2.first_line); }
    | tIF SimpleStatement tSEMICOLON Expression Block ElseStatement   { $$ = makeIfStmt($2, $4, $5, $6, @2.first_line); }
    ;

ElseStatement: %empty { $$ = NULL; }
    | tELSE IfStatement { $$ = makeElseStmt($2, @2.first_line); }
    | tELSE Block   { $$ = makeElseStmt($2, @2.first_line); }
    ;

ExprSwitchStatement: tSWITCH tLCBRACE ExprCaseClauseList tRCBRACE   { $$ = makeSwitchStmt(NULL, NULL, $3, @1.first_line); }
    | tSWITCH SimpleStatement tSEMICOLON tLCBRACE ExprCaseClauseList tRCBRACE   { $$ = makeSwitchStmt($2, NULL, $5, @1.first_line); }
    | tSWITCH Expression tLCBRACE ExprCaseClauseList tRCBRACE   { $$ = makeSwitchStmt(NULL, $2, $4, @1.first_line); }
    | tSWITCH SimpleStatement tSEMICOLON Expression tLCBRACE ExprCaseClauseList tRCBRACE    { $$ = makeSwitchStmt($2, $4, $6, @1.first_line); }
    ;

ExprCaseClauseList: %empty  { $$ = NULL; }
    | ExprCaseClause ExprCaseClauseList { $$ = makeCaseClauseList($1, $2); }
    ;

ExprCaseClause: tCASE ExpressionList tCOLON StatementList { $$ = makeCaseClause($2, $4, @2.first_line); }
    | tDEFAULT tCOLON StatementList { $$ = makeDefaultClause($3, @3.first_line); }
    | tCASE ExpressionList tCOLON  { $$ = makeCaseClause($2, NULL, @2.first_line); }
    | tDEFAULT tCOLON  { $$ = makeDefaultClause(NULL, @1.first_line); }
    ;

ForStatement: tFOR Block    { $$ = makeForStmt(NULL, NULL, $2, @2.first_line); }
    | tFOR ForClause Block  { $$ = makeForStmt(NULL, $2, $3, @2.first_line); }
    | tFOR Expression Block { $$ = makeForStmt($2, NULL, $3, @2.first_line); }
    ;

ForClause: SimpleStatement tSEMICOLON ExpressionOrEmpty tSEMICOLON SimpleStatement  { $$ = makeForClause($1, $3, $5); }
    ;

ExpressionOrEmpty: %empty   { $$ = NULL; }
    | Expression    { $$ = $1; }
    ;

BreakStatement: tBREAK  { $$ = makeBreakStmt(@1.first_line); }
    ;

ContinueStatement: tCONTINUE    { $$ = makeContinueStmt(@1.first_line); }
    ;
%%
