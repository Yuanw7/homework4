#
#        Copyright (C) 2000-2016 the YAMBO team
#              http://www.yambo-code.org
#
# Authors (see AUTHORS file for details): AM
#
# This file is distributed under the terms of the GNU
# General Public License. You can redistribute it and/or
# modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
#
# This program is distributed in the hope that it will
# be useful, but WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place - Suite 330,Boston,
# MA 02111-1307, USA or visit http://www.gnu.org/copyleft/gpl.txt.
#
cpu         = x86_64
os          = linux
mpi         = -D_MPI
netcdf      = 
scalapack   = 
precision   = 
fft         = -D_FFTW
xcpp        =  -D_MPI -D_FFTW       -D_TIMING
debug       = yes
do_blas     = no
do_lapack   = no
do_fftqe    = 
do_iotk     = no
do_netcdf   = no
do_etsf     = no
do_p2y      = yes
do_e2y      = no
do_libxc    = no
shell       = /bin/bash
make        = make
package_bugreport = yambo@yambo-code.org
prefix      = /home/marini/Yambo/yambo/master
exec_prefix = /home/marini/Yambo/yambo/master
bindir      = ${exec_prefix}/bin
libdir      = /home/marini/Yambo/yambo/master/lib
includedir  = /home/marini/Yambo/yambo/master/include
CFGFILES = config/setup config/Makefile config/report sbin/make_message.pl \
           sbin/make_makefile.sh driver/codever.h src/wf_and_fft/sgfft.F  \
           src/external_c/.objects Makefile driver/version.h \
           sbin/objects_debug.sh driver/editor.h lib/local/.objects
TARGETS  = yambo interfaces ypp
UTILS    = changelog get_extlibs
CLEANS   = clean_fast clean clean_extlibs clean_all distclean
PROJECTS = yambo_ph yambo_magnetic yambo_sc yambo_rt yambo_qed yambo_kerr \
           ypp_ph ypp_sc ypp_rt ypp_magnetic 
BROKEN   = yambo_surf ypp_surf ydb
DEBUG    = 
EXE      = $(TARGETS) $(PROJECTS) $(BROKEN) $(DEBUG)
INTERFCS = a2y p2y e2y c2y
#
# Libraries (ordered for compiling & linking)
#
BASIC_LIBS   = external_c modules parallel parser xc_functionals communicate linear_algebra common io \
               interface stop_and_restart wf_and_fft 
BASIC_SURF_LIBS   = external_c modules surf_modules parallel parser xc_functionals communicate linear_algebra common io \
                    interface stop_and_restart wf_and_fft 

MAIN_LIBS    = $(BASIC_LIBS) coulomb bz_ops qp_control setup \
               collisions tddft pol_function qp acfdt bse

PJ_SURFLIBS  = $(BASIC_SURF_LIBS) surf_modules coulomb bz_ops qp_control surf \
               setup collisions tddft pol_function qp acfdt bse

PJ_QEDLIBS   = $(MAIN_LIBS) 

PJ_SCLIBS    = $(MAIN_LIBS) sc

PJ_RTLIBS    = $(BASIC_LIBS) coulomb bz_ops real_time_control qp_control setup \
               collisions tddft pol_function qp acfdt bse sc real_time_propagation real_time_el-ph real_time_lifetimes real_time_common
#
# Interfaces
#
2YLIBS       = external_c modules parallel parser communicate linear_algebra common io setup interface stop_and_restart bz_ops 
#
# YPP
#
YPP_LIBS        = modules interpolate init qp plotting electrons excitons symmetries k-points bits 
YPPPH_LIBS      = modules interpolate init qp plotting electrons elph excitons symmetries k-points bits 
YPPRT_LIBS      = modules interpolate init qp plotting electrons elph real_time excitons symmetries k-points bits 
#
YPP_MAIN_LIBS      = $(BASIC_LIBS) coulomb bz_ops qp_control setup interface tddft pol_function bse
YPPSC_MAIN_LIBS    = $(YPP_MAIN_LIBS) collisions sc
YPPRT_MAIN_LIBS    = $(BASIC_LIBS) coulomb bz_ops real_time_control qp_control setup interface \
                     pol_function bse sc 
YPPSURF_MAIN_LIBS  = $(BASIC_SURF_LIBS) bz_ops qp_control setup interface surf tddft pol_function bse
YDBLIBS            = $(BASIC_LIBS) 

nothing: 
	@$(make_message)
changelog:
	svn log | perl sbin/svn2cl.pl > ChangeLog
all: $(PROJECTS) $(TARGETS) $(DEBUG)
libs:
	@if test "$(do_libxc)" = yes ; then LIBS2DO="libxc" ; \
	DIR2GO="lib" ; $(mklib_ext) fi
	@LIBS2DO="slatec";  DIR2GO="lib" ; $(mklib)
	@if test "$(do_blas)" = yes ; then LIBS2DO="blas" ; \
	DIR2GO="lib" ; $(mklib); fi
	@if test "$(do_lapack)" = yes ; then LIBS2DO="lapack" ; \
	DIR2GO="lib" ; $(mklib); fi
	@LIBS2DO="local" ; DIR2GO="lib" ; $(mklib) 
	@if test "$(do_fftqe)" = yes ; then LIBS2DO="fftqe" ; \
	DIR2GO="lib" ; $(mklib); fi
	@if test "$(do_iotk)" = yes ; then LIBS2DO="iotk" ; \
	DIR2GO="lib" ; $(mklib_ext); fi
	@if test "$(do_netcdf)" = yes ; then LIBS2DO="netcdf" ; \
	DIR2GO="lib" ; $(mklib_ext); fi
	@if test "$(do_etsf)" = yes ; then LIBS2DO="etsf_io" ; \
	DIR2GO="lib" ; $(mklib_ext); fi
get_extlibs:
	@cd lib/archive; $(make) -f Makefile.loc all;
#
# Yambo #
# 
yambo: libs
	@LIBS2DO="$(MAIN_LIBS)"; XPATH="src" ; $(mksrc)
	@X2DO="yambo"; XPATH="driver";XLIBS="$(MAIN_LIBS)";$(mkx)
#
# Yambo PROJECTS #
# 
yambo_magnetic: libs
	@LIBS2DO="$(PJ_SCLIBS)"; XPATH="src";ADF="-D_MAGNETIC -D_SC"; $(mksrc)
	@X2DO="yambo_magnetic"; XPATH="driver";XLIBS="$(PJ_SCLIBS)";ADF="-D_MAGNETIC -D_SC";$(mkx)
yambo_kerr: libs
	@LIBS2DO="$(PJ_RTLIBS)"; XPATH="src";ADF="-D_RT -D_SC -D_ELPH -D_KERR"; $(mksrc)
	@X2DO="yambo_kerr"; XPATH="driver";XLIBS="$(PJ_RTLIBS)";ADF="-D_RT -D_SC -D_ELPH -D_KERR";$(mkx)
yambo_sc: libs
	@LIBS2DO="$(PJ_SCLIBS)"; XPATH="src";ADF="-D_SC"; $(mksrc)
	@X2DO="yambo_sc"; XPATH="driver";XLIBS="$(PJ_SCLIBS)";ADF="-D_SC";$(mkx)
yambo_rt: libs
	@LIBS2DO="$(PJ_RTLIBS)"; XPATH="src";ADF="-D_RT -D_SC -D_ELPH"; $(mksrc)
	@X2DO="yambo_rt"; XPATH="driver";XLIBS="$(PJ_RTLIBS)";ADF="-D_RT -D_SC -D_ELPH";$(mkx)
yambo_ph: libs
	@LIBS2DO="$(MAIN_LIBS)"; XPATH="src";ADF="-D_ELPH"; $(mksrc)
	@X2DO="yambo_ph"; XPATH="driver";XLIBS="$(MAIN_LIBS)";ADF="-D_ELPH";$(mkx)
yambo_surf: libs
	@LIBS2DO="$(PJ_SURFLIBS)"; XPATH="src";ADF="-D_SURF"; $(mksrc)
	@X2DO="yambo_surf"; XPATH="driver";XLIBS="$(PJ_SURFLIBS)";ADF="-D_SURF";$(mkx)
yambo_qed: libs
	@LIBS2DO="$(PJ_RTLIBS)"; XPATH="src";ADF="-D_QED -D_SC -D_RT -D_ELPH"; $(mksrc)
	@X2DO="yambo_qed"; XPATH="driver";XLIBS="$(PJ_RTLIBS)";ADF="-D_QED -D_SC -D_RT -D_ELPH";$(mkx)
#
# Interfaces #
#
interfaces: libs
	@LIBS2DO="$(2YLIBS)"; XPATH="src" ; $(mksrc)
	@LIBS2DO="int_modules"; DIR2GO="interfaces" ; $(mklib)
	@X2DO="a2y" ;XPATH="interfaces/a2y";XLIBS="$(2YLIBS)";$(mkx)
	@X2DO="c2y" ;XPATH="interfaces/c2y";XLIBS="$(2YLIBS)";$(mkx)
	@if test "$(do_p2y)" = yes ; then X2DO="p2y" ; XPATH="interfaces/p2y" ; \
	XLIBS="$(2YLIBS)"; ADF="-D_P2Y_V50"; $(mkx) ; fi
	@if test "$(do_e2y)" = yes ; then X2DO="e2y" ; XPATH="interfaces/e2y" ; \
	XLIBS="$(2YLIBS)" ; $(mkx) ; fi
#
# Ypp #
#
ypp: libs
	@LIBS2DO="$(YPP_MAIN_LIBS)"; XPATH="src" ; $(mksrc)
	@LIBS2DO="$(YPP_LIBS)"; XPATH="ypp" ; $(mk_ypp_src)
	@X2DO="ypp" ;XPATH="driver";XLIBS="$(YPP_MAIN_LIBS)";X_ypp_LIBS="$(YPP_LIBS)";$(mk_ypp_x)
#
# Ypp projects #
#
ypp_ph: libs
	@LIBS2DO="$(YPP_MAIN_LIBS)"; XPATH="src";ADF="-D_ELPH"; $(mksrc)
	@LIBS2DO="$(YPPPH_LIBS)"; XPATH="ypp" ;  ADF="-D_YPP_ELPH"; $(mk_ypp_src)
	@X2DO="ypp_ph" ;XPATH="driver";XLIBS="$(YPP_MAIN_LIBS)";X_ypp_LIBS="$(YPPPH_LIBS) elph"; ADF="-D_YPP_ELPH";$(mk_ypp_x)
ypp_surf: libs
	@LIBS2DO="$(YPPSURF_MAIN_LIBS)"; XPATH="src" ; ADF="-D_YPP_SURF";$(mksrc)
	@LIBS2DO="$(YPP_LIBS) ras"; XPATH="ypp" ; $(mk_ypp_src)
	@X2DO="ypp_surf" ;XPATH="driver";XLIBS="$(YPPSURF_MAIN_LIBS)";X_ypp_LIBS="$(YPP_LIBS) ras"; ADF="-D_YPP_SURF";$(mk_ypp_x)
ypp_rt: libs
	@LIBS2DO="$(YPPRT_MAIN_LIBS)"; XPATH="src" ; ADF="-D_SC -D_RT -D_ELPH -D_YPP_RT";$(mksrc)
	@LIBS2DO="$(YPPRT_LIBS)"; XPATH="ypp" ; ADF="-D_ELPH -D_YPP_RT -D_YPP_ELPH"; $(mk_ypp_src)
	@X2DO="ypp_rt" ;XPATH="driver";XLIBS="$(YPPRT_MAIN_LIBS)";X_ypp_LIBS="$(YPPRT_LIBS)"; ADF="-D_YPP_RT";$(mk_ypp_x)
ypp_sc: libs
	@LIBS2DO="$(YPPSC_MAIN_LIBS)"; XPATH="src" ; ADF="-D_SC";$(mksrc)
	@LIBS2DO="$(YPP_LIBS)"; XPATH="ypp" ; $(mk_ypp_src)
	@X2DO="ypp_sc" ;XPATH="driver";XLIBS="$(YPPSC_MAIN_LIBS)";X_ypp_LIBS="$(YPP_LIBS)"; ADF="-D_YPP_SC";$(mk_ypp_x)
ypp_magnetic: libs
	@LIBS2DO="$(YPPSC_MAIN_LIBS)"; XPATH="src" ; ADF="-D_SC -D_MAGNETIC";$(mksrc)
	@LIBS2DO="$(YPP_LIBS)"; XPATH="ypp" ; $(mk_ypp_src)
	@X2DO="ypp_magnetic" ;XPATH="driver";XLIBS="$(YPPSC_MAIN_LIBS)";X_ypp_LIBS="$(YPP_LIBS)"; ADF="-D_YPP_MAGNETIC";$(mk_ypp_x)
#
# ydb
#
ydb: libs
	@LIBS2DO="$(YDBLIBS)" ; $(mksrc)
	@X2DO="ydb" ;XPATH="ydb";XLIBS="$(YDBLIBS)";$(mkx)
#
clean_fast: 
	@$(objects_clean)
	@$(lib_mod_clean)
	@$(xclean)
clean:
	@$(objects_clean)
	@$(lib_mod_clean)
	@$(lib_ext_clean)
	@$(conf_clean)
	@$(xclean)
distclean: clean_all
clean_all:
	@$(objects_clean)
	@$(lib_mod_clean)
	@$(lib_ext_clean_all)
	@$(conf_clean)
	@$(xclean)
	
# Functions
define make_message
 echo;echo "YAMBO" 4.0.2 r.13572 targets;echo;\
 echo  " [stable] all";\
 for target in $(TARGETS); do echo  " [stable] $$target" ; done;echo;\
 for target in $(PROJECTS); do echo " [devel] $$target" ; done;echo;\
 for target in $(BROKEN); do echo " [broken] $$target" ; done;echo;\
 for target in $(UTILS); do echo  " [util] $$target" ; done;echo
 for target in $(DEBUG); do echo  " [debug] $$target" ; done;echo
 for target in $(CLEANS); do echo  " [clean] $$target" ; done;echo
endef
define mksrc
 for ldir in $$LIBS2DO; do \
  if test ! -f "$(libdir)/lib$$ldir.a" || test "$(debug)" = yes  ; \
  then rm -f "$(libdir)/lib$$ldir.a" ; \
  echo " " ; \
  echo ">>>[Making $$ldir]<<<" ; \
  ./sbin/make_makefile.sh $$XPATH/$$ldir lib$$ldir.a .objects l $(xcpp) $$ADF ; \
  cd $$XPATH/$$ldir ; $(make) VPATH=$$XPATH/$$ldir || exit "$$?" ; cd ../../; fi \
 done
endef
define mk_ypp_src
 for ldir in $$LIBS2DO; do \
  if test ! -f "$(libdir)/lib_ypp_$$ldir.a" || test "$(debug)" = yes  ; \
  then rm -f "$(libdir)/lib_ypp_$$ldir.a" ; \
  echo " " ; \
  echo ">>>[Making $$ldir]<<<" ; \
  ./sbin/make_makefile.sh $$XPATH/$$ldir lib_ypp_$$ldir.a .objects l $(xcpp) $$ADF ; \
  cd $$XPATH/$$ldir ; $(make) VPATH=$$XPATH/$$ldir || exit "$$?" ; cd ../../; fi \
 done
endef
define mklibxc
  if test ! -f "$(libdir)/libxc.a" ; then \
  echo " " ; \
  echo ">>>[Making libxc]<<<" ; \
  cd $(libdir)/libxc ; $(make) -s VPATH=$(libdir)/libxc  || exit "$$?" ; \
  echo ">>>[Installing libxc]<<<" ; \
  $(make) -s install ; \
  cd ../../; \
  fi
endef
define mklib
 for ldir in $$LIBS2DO; do \
  if test ! -f "$(libdir)/lib$$ldir.a" ; \
  echo " " ; \
  echo ">>>[Making $$ldir]<<<" ; \
  then ./sbin/make_makefile.sh $$DIR2GO/$$ldir lib$$ldir.a .objects l $(precision) $(xcpp) $$ADF ; \
  cd $$DIR2GO/$$ldir ; $(make) VPATH=$$DIR2GO/$$ldir || exit "$$?" ; cd ../../; fi \
 done
endef
define mklib_ext
 for ldir in $$LIBS2DO; do \
  if test ! -f "$(libdir)/lib$$ldir.a" ; then \
  echo " " ; \
  echo ">>>[Making $$ldir]<<<" ; \
  cd $$DIR2GO/$$ldir ; cp Makefile.loc Makefile ; $(make) || exit "$$?" ; cd ../../; fi \
 done
endef
define mkx
 LLIBS="";for exe in $$XLIBS; do LLIBS="$$LLIBS -l$$exe" ; done ; \
 for exe in $$X2DO; do \
  echo " " ; \
  echo ">>>[Linking $$exe]<<<" ; \
  if test ! -f "$(bindir)/$$exe" || test "$(debug)" = yes  ; \
  then ./sbin/make_makefile.sh $$XPATH $$exe .objects x $$LLIBS $(xcpp) $$ADF ; \
  cd $$XPATH ; $(make) VPATH=$$XPATH || exit "$$?" ; fi ; \
  echo " " ; \
 done
endef
define mk_ypp_x
 LLIBS="";for exe in $$XLIBS; do LLIBS="$$LLIBS -l$$exe" ; done ; \
 for exe in $$X_ypp_LIBS; do LLIBS="$$LLIBS -l_ypp_$$exe" ; done ; \
 for exe in $$X2DO; do \
  echo " " ; \
  echo ">>>[Linking $$exe]<<<" ; \
  if test ! -f "$(bindir)/$$exe" || test "$(debug)" = yes  ; \
  then ./sbin/make_makefile.sh $$XPATH $$exe .objects x $$LLIBS $(xcpp) $$ADF ; \
  cd $$XPATH ; $(make) VPATH=$$XPATH || exit "$$?" ; fi ; \
  echo " " ; \
 done
endef
define objects_clean
 find . \( -name '*.o' -o -name 'Makefile' -o -name '*.f90' \
        -o -name '*_cpp.f' -o -name 'ifc*' -o -name '__*' -o -name '*.s' -o -name 'penmp' \) \
        -type f -print | grep -v '\.\/Makefile' | \
        grep -v '.*iotk.*\/Makefile'   | grep -v '.*iotk.*\/*f90' | \
        grep -v '.*etsf_io.*\/Makefile'| grep -v '.*etsf_io.*\/*f90' | \
        grep -v '.*netcdf.*\/Makefile' | grep -v '.*libxc.*\/Makefile' | xargs rm -f
 echo "[CLEAN] Objects ... done"
 echo "[CLEAN] Broken files ... done"
 echo "[CLEAN] Makefiles ... done"
 if test "$(debug)" = yes ; then \
 find . -name '.debug*' | xargs rm -fr ; \
 echo "[CLEAN] Debug locks and directories ... done" ; \
 fi
endef
define lib_ext_clean
 find . \( -name '*.a' -o -name '*.la' -o -name '*.mod' \
           -o -name 'netcdf*h' -o -name 'netcdf*inc' \) -type f -print | xargs rm -f 
 @cd $(libdir)/libxc;   $(make) -s -f Makefile.loc clean > /dev/null ; cd ../..
 @cd $(libdir)/iotk;    $(make) -s -f Makefile.loc clean > /dev/null ; cd ../..
 @cd $(libdir)/netcdf;  $(make) -s -f Makefile.loc clean > /dev/null ; cd ../..
 @cd $(libdir)/etsf_io; $(make) -s -f Makefile.loc clean > /dev/null ; cd ../..
 echo "[CLEAN] Libs EXT (clean) ... done" 
endef
define lib_ext_clean_all
 find . \( -name '*.a' -o -name '*.la' -o -name '*.mod' \
           -o -name 'netcdf*h' -o -name 'netcdf*inc' \) -type f -print | xargs rm -f 
 @cd $(libdir)/install; ( if test -r make_iotk.inc ; then rm -f make_iotk.inc ; fi) ; cd ../..
 find . -name 'xc*.h' -type f -print | xargs rm -f
 @cd $(libdir)/libxc;   $(make) -s -f Makefile.loc clean_all > /dev/null ; rm -f Makefile ; cd ../..
 @cd $(libdir)/iotk;    $(make) -s -f Makefile.loc clean_all > /dev/null ; rm -f Makefile ; cd ../..
 @cd $(libdir)/netcdf;  $(make) -s -f Makefile.loc clean_all > /dev/null ; rm -f Makefile ; cd ../..
 @cd $(libdir)/etsf_io; $(make) -s -f Makefile.loc clean_all > /dev/null ; rm -f Makefile ; cd ../..
 @cd $(libdir)/archive; $(make) -s -f Makefile.loc clean_all > /dev/null ; rm -f Makefile *gz *stamp ; cd ../..
 echo "[CLEAN] Libs EXT (clean_all) ... done" 
endef
define lib_mod_clean
 find . \( -name '*.a' -o -name '*.la' -o -name '*.mod' \) -type f -print | \
       grep -v netcdf | grep -v xc | grep -v iotk | grep -v typesize | grep -v etsf_io | xargs rm -f 
 echo "[CLEAN] Libraries ... done" 
 echo "[CLEAN] Modules ... done" 
endef
define xclean
 for exe in $(EXE); do rm -f $(bindir)/$$exe; done
 for exe in $(INTERFCS); do rm -f $(bindir)/$$exe; done
 cd $(bindir) ; rm -f etsf_io  ncgen ncgen3 nc-config nccopy ncdump  iotk iotk.x ; cd ..
 echo "[CLEAN] Targets ... done" 
endef
define conf_clean
 rm -f $(CFGFILES)
 rm -f config.status config.log
 rm -fr autom4te.cache
 echo "[CLEAN] Autoconf files ... done" 
endef
