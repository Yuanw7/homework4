/*
         Copyright (C) 2000-2019 the YAMBO team
               http://www.yambo-code.org
 
  Authors (see AUTHORS file for details): AM
  
  This file is distributed under the terms of the GNU 
  General Public License. You can redistribute it and/or 
  modify it under the terms of the GNU General Public 
  License as published by the Free Software Foundation; 
  either version 2, or (at your option) any later version.
 
  This program is distributed in the hope that it will 
  be useful, but WITHOUT ANY WARRANTY; without even the 
  implied warranty of MERCHANTABILITY or FITNESS FOR A 
  PARTICULAR PURPOSE.  See the GNU General Public License 
  for more details.
 
  You should have received a copy of the GNU General Public 
  License along with this program; if not, write to the Free 
  Software Foundation, Inc., 59 Temple Place - Suite 330,Boston, 
  MA 02111-1307, USA or visit http://www.gnu.org/copyleft/gpl.txt.

*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <kind.h>
#include <usage.h>
#include <load_environments.h>

void substring(char [], char[], int, int);


struct yambo_seed_struct command_line_short(int argc, char *argv[], short_options_struct *opts,  struct tool_struct t, int *use_editor, int *use_mpi)
{
 int io,i,c,j,k,nf,lnr,lnc,ttd,iv[4],lni,nr=0;
 double rv[4];
 char *cv[4]; 
 char *fmt=NULL,*env_file=NULL;
 char string[500]={'\0'},edit_line[100]={'\0'},ch[500]={'\0'};
 
 yambo_seed_struct y;

 while(opts[nr].ln!=NULL) {nr++;};
 fmt = malloc(sizeof(char)*nr+1);
 /* 
   strcat needs fmt to be initialized 
 */
 fmt[0] = '\0' ;
 for(i=0;i<=nr-1;i++) {
   strcat(fmt,opts[i].sn);
 }
 while ((c = getopt(argc, argv, fmt)) != -1) {
   io=optind;
   if (io==1) {io++;};
   for(i=0;i<=nr-1;i++) {
     if (strstr(argv[io-1],opts[i].sn)!=0 && opts[i].st==0) { 
      j=i;
      break;};
   };
#if defined _NO_OPTIONS_CHECK 
   if (c=='?') {break;};
   nf=opts[j].ni+opts[j].nr+opts[j].nc;
   if (optind+nf>argc) {break;};
#else
   if (c=='?') {
    usage(opts,1,t);
    exit(0);
   };
#endif
  /* Upper Case actions */
  
  /* Help...*/
   if (strcmp(opts[j].ln,"help")==0)  {usage(opts,1,t);exit(0);};
   if (strcmp(opts[j].ln,"lhelp")==0) {usage(opts,2,t);exit(0);};
  /*
   ...switch off MPI_init for non-parallel options ...
  */
   if (opts[j].mp==0)  {*use_mpi=-1;};
  /*
   ...or for an explicit request
  */
   if (strcmp(opts[j].ln,"nompi")==0) {*use_mpi=-1;};
  /*
   ...switch off launch editor
  */
   if (strcmp(opts[j].ln,"quiet")==0)  {*use_editor=-2;};
   opts[j].st++; 
   lni=0;
   lnr=0;
   lnc=0;
   nf=opts[j].ni+opts[j].nr+opts[j].nc;
   if (optind+nf>argc) {
     fprintf(stderr,"\n%s : invalid option -- %s\n",t.tool,opts[j].sn); usage(opts,1,t);exit(0);
   };
   for(i=1;i<=nf;i++) {
     k=0;
     if (strspn(argv[optind-1+i],"-")==1) {
#if defined _NO_OPTIONS_CHECK 
       break;
#else
       fprintf(stderr,"\n%s : invalid option -- %s\n",t.tool,opts[j].sn); usage(opts,1,t);exit(0);
#endif
     };
     if (opts[j].ni!=0 && k==0) {lni++;iv[lni]=atoi(argv[optind-1+i]);opts[j].ni--;k=1;};
     if (opts[j].nr!=0 && k==0) {lnr++;rv[lnr]=atof(argv[optind-1+i]);opts[j].nr--;k=1;};
     if (opts[j].nc!=0 && k==0) {lnc++;cv[lnc]=argv[optind-1+i];opts[j].nc--;k=1; };
   };
   /*
    ...Parallel environments
   */
   if (strcmp(opts[j].ln,"parenv")==0) {
     free(env_file);
     env_file = malloc(strlen(cv[1])+1);
     strcpy(env_file,cv[1]);
     load_environments(env_file,t.editor);
   };
   /*
   Input File, i/o directory 
   */
   if (strcmp(opts[j].ln,"ifile")==0) {
     strcpy(y.in_file,cv[1]);
     y.in_file_N=strlen(y.in_file);
   };
   if (strcmp(opts[j].ln,"idir")==0) {
     strcpy(y.in_dir,cv[1]);
     y.in_dir_N=strlen(y.in_dir);
   };
   if (strcmp(opts[j].ln,"odir")==0) {
     strcpy(y.out_dir,cv[1]);
     y.out_dir_N=strlen(y.out_dir);
   };
   if (strcmp(opts[j].ln,"cdir")==0) {
     strcpy(y.com_dir,cv[1]);
     y.com_dir_N=strlen(y.com_dir);
   };
   if (strcmp(opts[j].ln,"jobstr")==0) {
     strcpy(y.job,cv[1]);
     y.job_N=strlen(y.job);
   };
   strcat(string," ");
   strcat(string,opts[j].ln);
   strcpy(y.string,string);
   y.string_N=strlen(y.string);
   for(i=1;i<=lni;i++) {
    substring(y.string, ch,1, y.string_N);
    sprintf(string,"%s %d ",ch,iv[i]);
    strcpy(y.string,string);
    y.string_N=strlen(y.string);
   };
   for(i=1;i<=lnr;i++) {
    substring(y.string, ch,1, y.string_N);
    sprintf(string,"%s %f ",ch,rv[i]);
    strcpy(y.string,string);
    y.string_N=strlen(y.string);
   };
   for(i=1;i<=lnc;i++) {
    substring(y.string, ch,1, y.string_N);
    sprintf(string,"%s %s ",ch,cv[i]);
    strcpy(y.string,string);
    y.string_N=strlen(y.string);
   };

 };
 y.string_N=strlen(y.string);
 free(fmt);
 /* 
  Filling of empty input files
 */
 if (y.in_file_N==0){
  strcpy(y.in_file,t.tool);
  strcat(y.in_file,".in");
  y.in_file_N=strlen(y.in_file);
 };
 if (y.in_dir_N==0) { 
  strcpy(y.in_dir,".");
  y.in_dir_N=1;
 };
 if (y.out_dir_N==0) { 
  strcpy(y.out_dir,".");
  y.out_dir_N=1;
 }
 if (y.com_dir_N==0) { 
  strcpy(y.com_dir,".");
  y.com_dir_N=1;
 }
 if (y.job_N==0) { 
  strcpy(y.job,"");
  y.job_N=0;
 }
 if (y.string_N==0) { 
  strcpy(y.string,"");
  y.string_N=0;
 }
 /* */
 return(y);
};

void substring(char s[], char sub[], int p, int l) {
   int c = 0;
   
   while (c < l) {
      sub[c] = s[p+c-1];
      c++;
   }
   sub[c] = '\0';
}
