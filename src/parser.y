%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "tree.h"
// Reference to the line number generated by the scanner
extern int yylineno;
// Reference to the yylex function to quiet a compiler warning
int yylex();

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
%token <boolval> tBOOLVAL
%token <runeval> tRUNEVAL
%token <stringval> tSTRINGVAL
%token <identifier> tIDENTIFIER

/* Keywords */
%token tBREAK tCASE tCHAN tCONST tCONTINUE tDEFAULT tDEFER
%token tELSE tFALLTHROUGH tFOR tFUNC tGO tGOTO tIF tIMPORT tINTERFACE
%token tMAP tPACKAGE tRANGE tRETURN tSELECT tSTRUCT tSWITCH tTYPE tVAR
%token tPRINT tPRINTLN tAPPEND tLEN tCAP
/* Types */
%token tINT tFLOAT tSTRING tRUNE tBOOLEAN
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

%left tOR
%left tAND
%left tEQ tNOTEQ
%left tLTEQ tGTEQ tLESS tGREATER
%left tPLUS tMINUS
%left tTIMES tDIV
%left tBANG UNARY

%nonassoc ENDIF
%nonassoc tELSE

%start prog
%%
prog : PackageDecl TopLevelDeclList  
     ; 

PackageDecl: tPACKAGE tIDENTIFIER
    ;

TopLevelDeclList : %empty
    | VarDecl TopLevelDeclList
    | TypeDecl TopLevelDeclList
    | FuncDecl TopLevelDeclList

VarDecl : tVAR VarSpec
        | tVAR tLPAREN VarSpecList tRPAREN

VarSpec : IdentifierList Type tASSIGN ExpressionList
    | IdentifierList tASSIGN ExpressionList

VarSpecList : VarSpec
    | VarSpec VarSpecList

Type : ElementType
    | CompoundType

ElementType : tINT 
    | tFLOAT 
    | tSTRING 
    | tRUNE 
    | tBOOLEAN

CompoundType : ArrayType
    | SliceType
    | StructType

IdentifierList : tIDENTIFIER
    | tIDENTIFIER tCOMMA IdentifierList

ExpressionList : Expression
    | Expression tCOMMA ExpressionList

Expression : tBANG tCOLON

TypeDecl : tTYPE TypeSpec
    | tTYPE tLPAREN TypeSpecList tRPAREN

TypeSpec : tIDENTIFIER Type

TypeSpecList : TypeSpec
    | TypeSpec TypeSpecList

FuncDecl : tFUNC tIDENTIFIER Signature Block

Block : tLCBRACE StatementList tRCBRACE

StatementList : Statement
    | Statement StatementList 

Statement : VarDecl
    | TypeDecl

Signature : Parameters
    | Parameters Type

Parameters : tLPAREN ParameterList tRPAREN

ParameterList : ParameterDecl 
    | ParameterDecl ParameterList

ParameterDecl : IdentifierList Type

SliceType : tLSBRACE tRSBRACE ElementType

ArrayType : tLSBRACE Expression tRSBRACE ElementType

StructType : tSTRUCT tLCBRACE FieldDeclList tRCBRACE

FieldDeclList : FieldDecl
    | FieldDecl FieldDeclList

FieldDecl : IdentifierList Type
%%
