;-----------------------------------------
; parsergui__define.pro 
;
; PARSER: select files to process and create a list of DRFs to be executed by the pipeline.
;
;
;
; author : 2010-02 J.Maire created
; 2010-08-19 : JM added parsing of arclamp images



;;--------------------------------------------------------------------------------
; NOTES
;   This is a rather complicated program, with lots of overlapping data
;   structures. Be careful and read closely when editing!
;
;   Module arguments are stored in the PrimitiveInfo structure in memory. 
;   Right now this gets overwritten frequently (whenever you change a template),
;   which is annoying, and should probably be fixed.
;
;
;   MORE NOTES TO BE ADDED LATER!
;
;
;    self.PrimitiveInfo            a parsed DRSConfig.xml file, produced by
;                            the ConfigParser. This contains knowledge of
;                            all the modules and their arguments, stored as
;                            a bunch of flat lists. It's not a particularly
;                            elegant data structure, but it's too late to change
;                            now!  Much of the complexity with indices is a
;                            result of indexing into this in various ways.
;
;    self.nbModuleSelec        number of modules in current DRF list
;    self.currModSelec        list of modules in current DRF list
;    self.order                list of PIPELINE ORDER values for those modules
;
;    self.curr_mod_indsort    indices into curr_mod_avai in alphabetical order?
;                            in other words, matching the displayed order in the
;                            Avail Table
;
;    self.indmodtot2avail    indices for
;
;
;
;--------------------------------------------------------------------------------
;
;--------------------------------------------------------------------------------
; main object init routine for parsergui. Just calls the parent one, and sets
; the debug flag as needed. 
function  parsergui::init, groupleader, _extra=_extra
	self.DEBUG = gpi_get_setting('enable_parser_debug', /bool, default=0) ; print extra stuff?
	self.xname='parsergui'
	if self.debug then message,/info, 'Parser init'
	return, self->drfgui::init(groupleader, _extra=_extra)
end

;--------------------------------------------------------------------------------
; initialize object data. Is called from the parent object class' init method

pro parsergui::init_data, _extra=_extra

	if self.debug then message,/info, 'Parser init data'
	self->drfgui::init_data ; inherited from DRFGUI class

	self.currDRFSelec=      ptr_new(/ALLOCATE_HEAP)
	self.drf_summary=       ptr_new(/ALLOCATE_HEAP)

end

;--------------------------------------------------------------------------------
;	
;	;--------------------------------------------------------------------------------
;	;  Change the list of Available Modules to match the currently selected
;	;  Reduction Type
;	;
;	;  ARGUMENTS:
;	;          typestr       string, name of the mode type to use
;	;          seqval        integer, which sequence in that type to use.
;	;
;	pro parsergui::changemodsetting, typestr,seqval
;	
;	    type=(*self.PrimitiveInfo).reductiontype ; list of type for each module
;	
;	    if strmatch(typestr, 'On-Line Reduction') then begin
;	        if seqval eq 1 then typetab=['ASTR','SPEC']
;	        if seqval eq 2 then typetab=['ASTR','POL']
;	        if seqval eq 3 then typetab=['CAL','SPEC']
;	    endif else begin
;	        typetab = strcompress(STRSPLIT( typestr ,'-' , /EXTRACT ),/rem)
;	    endelse 
;	
;	    ; build a list of all available modules
;	    ; the logic here is somewhat tricky and unclear.
;	    indall=where(strmatch(type,'*ALL*',/fold_case),cm)          ; find ones that are 'all'
;	    indastr=where(strmatch(type,'*'+typetab[0]+'*',/fold_case),cm)  ; find ones that match the first typestr
;	    indspec=where(strmatch(type,'*'+typetab[1]+'*',/fold_case),cm)  ; find ones that match the second typestr
;	    if typetab[1] eq 'SPEC' then comp='POL' else comp='SPEC'
;	    indpol=indall[where(strmatch(type[indall],'*'+comp+'*',/fold_case),cm)] ; find ones in ALL that are also in the complementary set
;	    *self.indmodtot2avail=[intersect(indall,indpol,/xor_flag),intersect(indastr,indspec)]
;	    *self.indmodtot2avail=(*self.indmodtot2avail)[where(*self.indmodtot2avail ne -1)]
;	    cm=n_elements(*self.indmodtot2avail)
;	
;	    if cm ne 0 then begin
;	        self.nbcurrmod=cm
;	        *self.curr_mod_avai=strarr(cm)
;	
;	        for i=0,cm-1 do begin
;	            (*self.curr_mod_avai)[i]=((*self.PrimitiveInfo).names)[(*self.indmodtot2avail)[i]]
;	            *self.indarg=where(   ((*self.PrimitiveInfo).argmodnum) eq ([(*self.indmodtot2avail)[i]]+1)[0], carg)
;	        endfor    
;	
;	    endif
;	
;	    ;;sort in alphabetical order
;	    *self.curr_mod_indsort=sort(*self.curr_mod_avai)
;	    (*self.curr_mod_avai)=(*self.curr_mod_avai)[*self.curr_mod_indsort]
;	
;	    ;;standard recipes
;	    selectype= self.currtype;widget_info(self.typeid,/DROPLIST_SELECT)
;	
;	;;standard recipes
;	(*self.currModSelec)=strarr(5);(['','','','',''])
;	
;	
;	end    
;	
;--------------------------------------------------------------------------------
pro parsergui::extractparam, modnum 
;   modnum is the index of the selected module in the CURRENTLY ACTIVE LIST for
;   this mode
    *self.indarg=where(   ((*self.PrimitiveInfo).argmodnum) eq ([(*self.indmodtot2avail)[(*self.curr_mod_indsort)[modnum]]]+1)[0], carg)
end

   
;	;event handler
;	;-----------------------------------------
;	pro parsergui::changetype, selectype, storage,notemplate=notemplate
;	
;	    typefield=*self.template_types
;	
;		self.reductiontype = (*self.template_types)[selectype]         
;		selecseq=0
;		self.currseq=selecseq
;		(*self.currModSelec)=''
;		self.nbmoduleSelec=0
;		self->changemodsetting, typefield[selectype],selecseq+1
;	
;		self.selectype=selectype
;		self.selecseq=selecseq
;	
;	
;		case selectype of 
;			0:typename='astr_spec_'
;			1:typename='astr_pol_'
;			2:typename='cal_spec_'
;			3:typename='cal_pol_'
;			4:typename='online_'
;		endcase
;		if ~keyword_set(notemplate) then begin
;			self.LoadedRecipeFile = self.templatedir+path_sep()+'template_recipe_'+typename+'1.xml'
;			;self->loaddrf, /nodata
;		endif
;	  
;	end
;	
;	
;-----------------------------------------
pro parsergui::addfile, filenames, mode=mode
    ; Add a new file to the Input FITS files list. 

    widget_control,self.top_base,get_uvalue=storage  
    index = (*storage.splitptr).selindex
    cindex = (*storage.splitptr).findex
    file = (*storage.splitptr).filename
    pfile = (*storage.splitptr).printname
    datefile = (*storage.splitptr).datefile

	t0 = systime(/seconds)

    ;-- can we add more files now?
    if (file[n_elements(file)-1] ne '') then begin
        self->Log,'Sorry, maximum number of files reached. You cannot add any additional files/directories.'
        return
    endif

    for i=0,n_elements(filenames)-1 do begin   ; Check for duplicate
        if (total(file eq filenames[i]) ne 0) then filenames[i] = ''
    endfor


    w = where(filenames ne '', wcount) ; avoid blanks
    if wcount eq 0 then void=dialog_message('No new files. Please add new files before parsing.')
    if wcount eq 0 then return
    filenames = filenames[w]

    if ((cindex+n_elements(filenames)) gt n_elements(file)) then begin
        nover = cindex+n_elements(filenames)-n_elements(file)
        self->Log,'WARNING: You tried to add more files than the file number limit, currently '+strc(n_elements(file))+". Adjust pipeline setting 'max_files_per_drf' in your config file if you want to load larger datasets at once." +$
            strtrim(nover,2)+' files ignored.'
        filenames = filenames[0:n_elements(filenames)-1-nover]
    endif

    file[cindex:cindex+n_elements(filenames)-1] = filenames

    for i=0,n_elements(filenames)-1 do begin
        tmp = strsplit(filenames[i],path_sep(),/extract)
        pfile[cindex+i] = tmp[n_elements(tmp)-1]+'    '
    endfor

    self.inputdir=strjoin(tmp[0:n_elements(tmp)-2],path_sep())
    if !VERSION.OS_FAMILY ne 'Windows' then self.inputdir = "/"+self.inputdir 


    self->Log, "Loading and parsing files..."
	;print, "time 1: ", systime(/seconds) - t0
    ;-- Update information in the structs
    cindex = cindex+n_elements(filenames)
    (*storage.splitptr).selindex = max([0,cindex-1])
    (*storage.splitptr).findex = cindex
    (*storage.splitptr).filename = file
    (*storage.splitptr).printname = pfile
    (*storage.splitptr).datefile = datefile 

    ;;TEST DATA SANITY
    ;;ARE THEY VALID  GEMINI & GPI & IFS DATA?
	
    if gpi_get_setting('strict_validation',/bool)  then begin

        validtelescop=bytarr(cindex)
        validinstrum=bytarr(cindex)
        validinstrsub=bytarr(cindex)

        for ff=0, cindex-1 do begin
			;print, "time 2, file "+strc(ff)+": ", systime(/seconds) - t0
			if self.debug then message,/info, 'Verifying keywords for file '+file[ff]
			if self.debug then message,/info, '  This code needs to be made more efficient...'
            validtelescop[ff]=self->validkeyword( file[ff], 1,'TELESCOP','Gemini*',storage) 
            validinstrum[ff]= self->validkeyword( file[ff], 1,'INSTRUME','GPI',storage)
            validinstrsub[ff]=self->validkeyword( file[ff], 1,'INSTRSUB','IFS',storage)            
			;print, "time 3, file "+strc(ff)+": ", systime(/seconds) - t0
        endfor  

        indnonvaliddata0=[where(validtelescop eq 0),where(validinstrum eq 0),where(validinstrsub eq 0)]
        indnonvaliddata=indnonvaliddata0[uniq(indnonvaliddata0,sort( indnonvaliddata0 ))]
        indnonvaliddata2=where(indnonvaliddata ne -1, cnv)
        if cnv gt 0 then begin
            indnonvaliddata3=indnonvaliddata[indnonvaliddata2]
            nonvaliddata=file[indnonvaliddata3]
            self->Log,'WARNING: non-valid data have been detected and removed:'+nonvaliddata
            indvaliddata=intersect(indnonvaliddata3,indgen(cindex),countvalid,/xor)
             ;correct for a strange side effect with the intersect function above : test for instance: print, intersect([0],[0],ac,/xor)
            if n_elements(indnonvaliddata3) eq cindex then countvalid = 0
            if countvalid eq 0 then file=''
            if countvalid gt 0 then file=file[indvaliddata]

                cindex = countvalid
                (*storage.splitptr).selindex = max([0,cindex-1])
                (*storage.splitptr).findex = cindex
                (*storage.splitptr).filename = file
                pfile=file
                (*storage.splitptr).printname = pfile
                (*storage.splitptr).datefile = datefile 
            endif
      
    endif else begin ;if data are test data don't remove them but inform a bit
        for ff=0, cindex-1 do begin
			if self.debug then message,/info, 'Checking for valid headers: '+file[ff]
			;print, "time 2, file "+strc(ff)+": ", systime(/seconds) - t0
			validtelescop=self->validkeyword( file[ff], 1,'TELESCOP','Gemini',storage)
			;print, "time 2a, file "+strc(ff)+": ", systime(/seconds) - t0
			validinstrum =self->validkeyword( file[ff], 1,'INSTRUME','GPI',storage)
			;print, "time 2b, file "+strc(ff)+": ", systime(/seconds) - t0
			validinstrsub=self->validkeyword( file[ff], 1,'INSTRSUB','IFS',storage)
			;print, "time 3, file "+strc(ff)+": ", systime(/seconds) - t0
		endfor
    endelse
    (*self.currModSelec)=strarr(5)
    (*self.currDRFSelec)=strarr(10)


	if self.debug then message,/info, 'Now analyzing data based on keywords'
    widget_control,storage.fname,set_value=pfile ; update displayed filename information - temporary, just show filename

    if cindex gt 0 then begin ;assure that data are selected

        self.nbdrfSelec=0
        ;; RESOLVE FILTER(S) AND OBSTYPE(S)
        tmp = self->get_obs_keywords(file[0])
        finfo = replicate(tmp,cindex)

        for jj=0,cindex-1 do begin
            finfo[jj] = self->get_obs_keywords(file[jj])
              ;;we want Xenon&Argon considered as the same 'lamp' object for Y,K1,K2bands (for H&J, better to do separately to keep only meas. from Xenon)
                if (~strmatch(finfo[jj].filter,'[HJ]')) && (strmatch(finfo[jj].object,'Xenon') || strmatch(finfo[jj].object,'Argon')) then $
                    finfo[jj].object='Lamp'
            ;; we also want Flat considered for wavelength solution in Y band
                 if strmatch(finfo[jj].object,'Flat*')  &&  strmatch(finfo[jj].filter,'Y') then $
                    finfo[jj].object='Lamp'
            pfile[jj] = pfile[jj]+"     "+finfo[jj].dispersr +" "+finfo[jj].filter+" "+finfo[jj].obstype+" "+string(finfo[jj].itime,format='(F5.1)')+"  "+finfo[jj].object
        endfor
        widget_control,storage.fname,set_value=pfile ; update displayed filename information - filenames plus parsed keywords


        (*storage.splitptr).printfname=pfile

		; Mark filter as irrelevant for Dark exposures
		wdark = where(strlowcase(finfo.obstype) eq 'dark', dct)
		if dct gt 0 then finfo[wdark].filter='-'

        if (n_elements(file) gt 0) && (strlen(file[0]) gt 0) then begin

            ; save starting date and time for use in DRF filenames
            caldat,systime(/julian),month,day,year, hour,minute,second
            datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')
            hourstr = string(hour,minute,format='(i2.2,i2.2)')  
            datetimestr=datestr+'-'+hourstr
          
            current = {gpi_obs}

            ;categorize by filter
            uniqfilter  = uniqvals(finfo.filter, /sort)
            ;uniqfilter = ['H', 'Y', 'J', "K1", "K2"] ; H first since it's primary science wvl?
            uniqobstype = uniqvals(strlowcase(finfo.obstype), /sort)
                ; TODO - sort right order for obstype 
           ; uniqobstype = uniqvals(finfo.obstype, /sort)

		    uniqprisms = uniqvals(finfo.dispersr)
            ;uniqprisms = ['Spectral', 'Wollaston', 'Open']
            ;uniqocculters = ['blank','fpm']
            uniqocculters = uniqvals(finfo.occulter)
            ;update for new keyword conventions:
            tmpobsclass=finfo.obsclass
            for itmp=0,n_elements(tmpobsclass)-1 do begin
              if strmatch((finfo.obstype)[itmp],'*Object*',/fold) then (finfo[itmp].obsclass) = 'Science'
              if strmatch((finfo.obstype)[itmp],'*Standard*',/fold) then begin
                if strmatch((finfo.dispersr)[itmp],'*SPEC*',/fold) then (finfo[itmp].obsclass) = 'SPECSTD'
                if strmatch((finfo.dispersr)[itmp],'*POL*',/fold) or strmatch((finfo.dispersr)[itmp],'*WOLL*',/fold)  then $
					(finfo[itmp].obsclass) = 'POLARSTD'
              endif
              if strmatch((finfo.astromtc)[itmp],'*TRUE*',/fold) then (finfo[itmp].obsclass) = 'Astromstd'
            endfor
            uniqobsclass = uniqvals(finfo.obsclass, /sort)
            uniqitimes = uniqvals(finfo.itime, /sort)
            uniqobjects = uniqvals(finfo.object, /sort)



            nbfilter=n_elements(uniqfilter)
            message,/info, "Now adding "+strc(n_elements(finfo))+" files. "
            message,/info, "Input files include data from these FILTERS: "+strjoin(uniqfilter, ", ")
            
            ;for each filter category, categorize by obstype
            for ff=0,nbfilter-1 do begin
                current.filter = uniqfilter[ff]
                indffilter =  where(finfo.filter eq current.filter)
                filefilt = file[indffilter]
                
                ;categorize by obstype
                uniqsortedobstype = uniqvals(strlowcase((finfo.obstype)[indffilter]))

                ;add  wav solution if not present and if flat-field should be reduced as wav sol
                void=where(strmatch(uniqsortedobstype,'*arc*',/fold),cwv)
                void=where(strmatch(uniqsortedobstype,'flat*',/fold),cflat)
                if ( cwv eq 0) && (cflat eq 1) && (self.flatreduc eq 1) then begin
                    indfobstypeflat =  where(strmatch((finfo.obstype)[indffilter],'flat*',/fold)) 
                    uniqsortedobstype = [uniqsortedobstype ,'wavecal']
                endif
                   
                nbobstype=n_elements(uniqsortedobstype)
                    
                ;;here we have to sequence the drf queue: 
                ;; assign to each obstype an order:
                sequenceorder=intarr(nbobstype)
                sortedsequencetab=['Dark', 'Arc', 'Flat','Object']

                for fc=0,nbobstype-1 do begin
                   wm = where(strmatch(sortedsequencetab, uniqsortedobstype[fc]+'*',/fold),mct)
                   ;if mct eq 1 then sequenceorder[fc]= mct[0]
                   if mct eq 1 then sequenceorder[fc]= wm[0]
                endfor
                indnotdefined=where(sequenceorder eq -1,cnd)
                if cnd ge 1  then sequenceorder[indnotdefined]=nbobstype-1
                indsortseq=sort(sequenceorder)

                
                ;;for each filter and each obstype, create a drf
                for fc=0,nbobstype-1 do begin
                    ;get files corresponding to one filt and one obstype
                    current.obstype = uniqsortedobstype[indsortseq[fc]]
;                    
                    ;categorize by PRISM
                    for fd=0,n_elements(uniqprisms)-1 do begin
                        current.dispersr = uniqprisms[fd]
                     
                        for fo=0,n_elements(uniqocculters)-1 do begin
                            current.occulter=uniqocculters[fo]
                            
                            for fobs=0,n_elements(uniqobsclass)-1 do begin
                                current.obsclass=uniqobsclass[fobs]
                                
                                for fitime=0,n_elements(uniqitimes)-1 do begin

                                    current.itime = uniqitimes[fitime]    ; in seconds, now
                                    ;current.exptime = uniqitimes[fitime] ; in seconds
                                    
                                    for fobj=0,n_elements(uniqobjects)-1 do begin
                                        current.object = uniqobjects[fobj]
                                        ;these following 2 lines for adding Y-band flat-field in wav.solution measurement
                                        currobstype=current.obstype
                                        if (self.flatreduc eq 1)  && (current.filter eq 'Y') &&$
                                        (current.obstype eq 'Wavecal')  then currobstype='[WF][al][va][et]*'
                          
                                        indfobject = where(finfo.filter eq current.filter and $
                                                    ;finfo.obstype eq current.obstype and $
                                                    strmatch(finfo.obstype, currobstype,/fold) and $                                                    
                                                    strmatch(finfo.dispersr,current.dispersr+"*",/fold) and $
                                                    strmatch(finfo.occulter,current.occulter+"*",/fold) and $
                                                    finfo.obsclass eq current.obsclass and $
                                                    finfo.itime eq current.itime and $
                                                    finfo.object eq current.object, cobj)
                                                    
										if self.debug then begin
											message,/info, 'Now testing the following parameters: ('+strc(cobj)+' files match) '
											help, current,/str
										endif

										;if cobj gt 0 then stop
                      
    
                                        if cobj eq 0 then continue ; this particular combination of filter, obstype, dispersr, occulter, class, time, object has no files. 

										; otherwise, try to match it:
                                        file_filt_obst_disp_occ_obs_itime_object = file[indfobject]
                         

                                        ;identify which templates to use
                                        print,  current.obstype ; uniqsortedobstype[indsortseq[fc]]
                                        self->Log, "found sequence of type="+current.obstype+", prism="+current.dispersr+", filter="+current.filter+ "with "+strc(cobj)+" files."

                                        case strupcase(current.obstype) of
                                        'DARK':begin
                                            ;detectype=3
                                            ;detecseq=2                        
											templatename='Dark'
                                        end
                                        'ARC': begin 
                                            if  current.dispersr eq 'WOLLASTON' then begin 
                                                ;detectype=4
                                                ;detecseq=2  
												templatename='Create Polarized Flat-field'
                                            endif else begin                                                          
                                                ;detectype=3
                                                ;if current.filter eq 'Y' then  detecseq=9 else $
                                                ;detecseq=3                  
												templatename='Wavelength Solution'
                                            endelse                     
                                        end
                                        'FLAT': begin
                                            if  current.dispersr eq 'WOLLASTON' then begin 
                                                ; handle polarization flats
                                                ; differently: compute **both**
                                                ; extraction files and flat
                                                ; fields from these data, in two
                                                ; passes


												templatename1 = self->lookup_template_filename("Calibrate Polarization Spots Locations")
												templatename2 = self->lookup_template_filename('Create Polarized Flat-field')
                                                self->create_recipe_from_template, templatename1, file_filt_obst_disp_occ_obs_itime_object, current, datetimestr=datetimestr
                                                self->create_recipe_from_template, templatename2, file_filt_obst_disp_occ_obs_itime_object, current, datetimestr=datetimestr


                                                ;continue        aaargh can't continue inside a case. stupid IDL
                                                detectype = -1
                                                ;detectype=4
                                                ;detecseq=1  
                                            endif else begin              
                                                ;detectype=3
                                                ;detecseq=1   
												templatename='Flat-field Extraction'
                                            endelse                             
                                        end
                                        'OBJECT': begin
											case strupcase(current.dispersr) of 
											'WOLLASTON': begin 
                                                ;detectype=2
                                                ;detecseq=1  
												templatename='Basic Polarization Sequence'
                                            end 
											'PRISM': begin 
                                                if  current.occulter eq 'blank'  then begin ;means no occulter
                                                    ;if binaries:
                                                    if strmatch(current.obsclass, 'AstromSTD',/fold) then begin
                                                       ;detectype=3
                                                       ;detecseq=8  
													   templatename="Lenslet scale and orientation"
                                                    endif
                                                    if strmatch(current.obsclass, 'Science',/fold) then begin
                                                       ;detectype=1
                                                       ;detecseq=4  
													   templatename="Rotate and combine extended object"
                                                    endif
                                                    if ~strmatch(current.obsclass, 'AstromSTD',/fold) && ~strmatch(current.obsclass, 'Science',/fold) then begin
                                                       ;detectype=3
                                                       ;detecseq=7  
													   templatename='Satellite Flux Ratios'
                                                    endif
                                                endif else begin 
                                                    if n_elements(file_filt_obst_disp_occ_obs_itime_object) GE 5 then begin
                                                        ;detectype=1
                                                        ;detecseq=3 
														templatename='Calibrated Data-cube extraction, ADI reduction'
                                                    endif else begin
                                                        ;detectype=1
                                                        ;detecseq=1 
														templatename="Simple Datacube Extraction"
                                                    endelse
                                                endelse
                                            end 
											'OPEN': begin
                                                ;detectype=6
                                                ;detecseq=1  
 												templatename="Simple Undispersed Image Extraction"
											end
                                            endcase
                                        end     
                                        else: begin 
                                            ;if strmatch(uniqsortedobstype[fc], '*laser*') then begin
                                            if strmatch(uniqsortedobstype[indsortseq[fc]], '*laser*') then begin
												;detectype=1
												;detecseq=1 
												templatename="Simple Datacube Extraction"
                                            endif else begin
                                               self->Log, "Not sure what to do about obstype '"+uniqsortedobstype[indsortseq[fc]]+"'. Going to try the 'Fix Keywords' recipe but that's just a guess."
                                              ;add missing keywords
                                              ;detectype=3
                                              ;detecseq=5
											  templatename='Add set of missing keywords'
                                            endelse
                                        end
                                        endcase

                                        if detectype eq -1 then continue

										; Now create the actual DRF based on a
										; template:
										templatename = self->lookup_template_filename(templatename)
										self->create_recipe_from_template, templatename, file_filt_obst_disp_occ_obs_itime_object, current, datetimestr=datetimestr


                                        ;typetab=['astr_spec_','astr_pol_','cal_spec_','cal_pol_','online_', 'undispersed_']
                                        ;typename=typetab[detectype-1]           
                                        ;drf_to_load = self.templatedir+path_sep()+'template_recipe_'+typename+strc(detecseq)+'.xml'
                    					;if keyword_set(mode) && (mode eq 2) then if (total(strmatch(remcharf(file_filt_obst_disp_occ_obs_itime_object,path_sep()),remcharf(file[cindex-1]+'*',path_sep()))) eq 0) then continue
                                        ;self->create_recipe_from_template, drf_to_load, file_filt_obst_disp_occ_obs_itime_object, current, datetimestr=datetimestr, mode=mode

                                    endfor ;loop on object
                                endfor ;loop on itime
                            endfor ;loop on obsclass
                        endfor ;loop on fo occulteur    
                    endfor  ;loop on fd disperser
                endfor ;loop on fc obstype
            endfor ;loop on ff filter
        endif ;cond on n_elements(file) 
    endif ;condition on cindex>0, assure there are data to process

    

    void=where(file ne '',cnz)
    self->Log,strtrim(cnz,2)+' files added.'
    ;self->Log,'resolved FILTER band: '+self.filter


end
;-----------------------------------------
;	pro parsergui::cleanfilelist, fitsfiles=fitsfiles
;	    widget_control,self.top_base,get_uvalue=storage
;	      if ~keyword_set(fitsfiles) then begin
;	          
;	            (*storage.splitptr).findex = 0
;	            (*storage.splitptr).selindex = 0
;	            (*storage.splitptr).filename[*] = ''
;	            (*storage.splitptr).printname[*] = '' 
;	            (*storage.splitptr).printfname[*] = '' 
;	            (*storage.splitptr).datefile[*] = ''  
;	             widget_control,storage.fname,set_value=(*storage.splitptr).printname          
;	            self->Log,'All items removed.'
;	       endif else begin
;	             oldind=(*storage.splitptr).findex
;	            (*storage.splitptr).findex = n_elements(fitsfiles)
;	            (*storage.splitptr).selindex = 0            
;	            (*storage.splitptr).filename[0:n_elements(fitsfiles)-1] = fitsfiles
;	
;	            if n_elements(where((*storage.splitptr).printname) ne '') gt n_elements(fitsfiles) then begin
;	              pn=(*storage.splitptr).printfname
;	            (*storage.splitptr).printname[*] = '' 
;	            (*storage.splitptr).printfname[*] = '' 
;	              (*storage.splitptr).printname[0:n_elements(fitsfiles)-1]= pn[oldind-n_elements(fitsfiles):oldind-1]
;	               (*storage.splitptr).printfname[0:n_elements(fitsfiles)-1]= pn[oldind-n_elements(fitsfiles):oldind-1]
;	                widget_control,storage.fname,set_value=(*storage.splitptr).printfname
;	            endif
;	            (*storage.splitptr).datefile[*] = '' 
;	            self->Log,'All items corresponding to old sequences removed.'
;	       endelse     
;	
;	
;	end



;-----------------------------------------
; lookup template filename
;
;   Given a template descriptive name, return the filename that matches.
function parsergui::lookup_template_filename, requestedname

	wm = where(  strmatch( (*self.templates).name, requestedname,/fold_case), ct)

	if ct eq 0 then begin
        ret=dialog_message("ERROR: Could not find any matching template file for name='"+requestedname+"'. Cannot load template.",/error,/center,dialog_parent=ev.top)
		return, ""
	endif else if ct gt 1 then begin
        ret=dialog_message("WARNING: Found multiple matching template files for name='"+requestedname+"'. Going to load the first one, from file="+((*self.templates)[wm[0]]).filename,/information,/center,dialog_parent=ev.top)
	endif
	wm = wm[0]

	return, ((*self.templates)[wm[0]]).filename



end


;-----------------------------------------
pro parsergui::create_recipe_from_template, templatename, fitsfiles, current, datetimestr=datetimestr ;, mode=mode

	; load the DRF, save with new filenames
    ;self->loaddrf, templatename ,  /nodata

    if keyword_set(templatename) then self.LoadedRecipeFile=templatename
    if self.LoadedRecipeFile eq '' then return

    ;widget_control,self.top_base,get_uvalue=storage  
    

	if ~file_test(self.LoadedRecipeFile, /read) then begin
        message, "Requested recipe file does not exist: "+self.LoadedRecipeFile,/info
		return
	endif

	;catch, parse_error
	parse_error=0
	if parse_error eq 0 then begin
		drf = obj_new('drf', self.LoadedRecipeFile)
	endif else begin
        message, "Could not parse Recipe File: "+self.LoadedRecipeFile,/info
		;stop
        return
	endelse
	catch,/cancel


    ;drf_contents = drf->get_contents()
    ;drf_module_names = drf_contents.modules.name

    
	;ptr_free, self.drf_summary
	;ptr_free, self.current_drf
    ;self.drf_summary = ptr_new(drf_summary)
	;self.current_drf = ptr_new(drf)


	; set the data files in that recipe to the requested ones
	drf->set_datafiles, fitsfiles 

    drf_summary = drf->get_summary()

	; Generate output file name
	prefixname=string(self.nbdrfSelec+1, format="(I03)")
	outputfilename=datetimestr+"_"+prefixname+'_drf.waiting.xml'

    if widget_info(self.autoqueue_id ,/button_set)  then chosenpath=self.queuedir else chosenpath=self.drfpath

	outputfilename = chosenpath + path_sep() + outputfilename
	message,/info, 'Outputting file to :' + outputfilename

	drf->save, outputfilename

    ;self->savedrf, fitsfiles, prefix=self.nbdrfSelec+1, datetimestr=datetimestr



	; append into table for display on scree
    new_drf_properties = [gpi_shorten_path(outputfilename), drf_summary.name,   drf_summary.reductiontype, $
        current.filter, current.obstype, current.dispersr, current.occulter, current.obsclass, string(current.itime,format='(F7.1)'), current.object, strc(drf_summary.nfiles)] 

    if self.nbdrfSelec eq 0 then (*self.currDRFSelec)= new_drf_properties else $
        (*self.currDRFSelec)=[[(*self.currDRFSelec)],[new_drf_properties]]

    self.nbdrfSelec+=1

    widget_control, self.tableSelected, ysize=((size(*self.currDRFSelec))[2] > 20 )
    widget_control, self.tableSelected, set_value=(*self.currDRFSelec)[0:10,*]
    widget_control, self.tableSelected, background_color=rebin(*self.table_BACKground_colors,3,2*11,/sample)    

   ;if keyword_set(mode) && (mode eq 2) then self->cleanfilelist, fitsfiles=fitsfiles
end


;-----------------------------------------
; actual event handler: 
pro parsergui::event,ev

    ;get type of event
    widget_control,ev.id,get_uvalue=uval

    ;get storage
    widget_control,ev.top,get_uvalue=storage

    if size(uval,/TNAME) eq 'STRUCT' then begin
        ; TLB event, either resize or kill_request
        case tag_names(ev, /structure_name) of

        'WIDGET_KILL_REQUEST': begin ; kill request
            if confirm(group=ev.top,message='Are you sure you want to close the Data Parser GUI?',$
                label0='Cancel',label1='Close') then obj_destroy, self
        end
        'WIDGET_BASE': begin ; resize event
            print, "RESIZE not yet supported - will be eventually "

        end
        else: print, tag_names(ev, /structure_name)


        endcase
        return
    endif

    ; Mouse-over help text display:
      if (tag_names(ev, /structure_name) EQ 'WIDGET_TRACKING') then begin 
        if (ev.ENTER EQ 1) then begin 
              case uval of 
              'FNAME':textinfo='Press "Add Files" or "Wildcard" buttons to add FITS files to process.'
              'tableselec':textinfo='Select a Recipe file and click Queue, Open, or Delete below to act on that recipe.' ; Left-click to see or change the DRF | Right-click to remove the selected DRF from the current DRF list.'
              'text_status':textinfo='Status log message display window.'
              'ADDFILE': textinfo='Click to add files to current input list.'
              'WILDCARD': textinfo='Click to add files to input list using a wildcard (*.fits etc)'
              'REMOVE': textinfo='Click to highlight a file, then press this button to remove that currently highlighted file from the input list.'
              'REMOVEALL': textinfo='Click to remove all files from the input list'
              'DRFGUI': textinfo='Click to load currently selected Recipe into the Recipe Editor'
              'Delete': textinfo='Click to delete the currently selected Recipe. (Cannot be undone!)'
              'QueueAll': textinfo='Click to add all DRFs to the execution queue.'
              'QueueOne': textinfo='Click to add the currently selected Recipe to the execution queue.'
              'QUIT': textinfo='Click to close this window.'
              else:
              endcase
              widget_control,self.textinfoid,set_value=textinfo
          ;widget_control, event.ID, SET_VALUE='Press to Quit'   
        endif else begin 
              widget_control,self.textinfoid,set_value=''
          ;widget_control, event.id, set_value='what does this button do?'   
        endelse 
        return
    endif
      
    ; Menu and button events: 
    case uval of 

    'tableselec':begin      
            IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TABLE_CELL_SEL') && (ev.sel_top ne -1) THEN BEGIN  ;LEFT CLICK
                selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
                ;;uptade arguments tab
                if n_elements((*self.currDRFSelec)) eq 0 then return
                self.nbDRFSelec=n_elements((*self.currDRFSelec)[0,*])
                ;print, self.nbDRFSelec
                ; FIXME check error condition for nothing selected here. 
                indselected=selection[1]
                if indselected lt self.nbDRFSelec then self.selection =(*self.currDRFSelec)[0,indselected]
                ;if indselected lt self.nbDRFSelec then begin 
                    ;print, "Starting DRFGUI with "+ (*self.currDRFSelec)[0,indselected]
                    ;gpidrfgui, drfname=(*self.currDRFSelec)[0,indselected], self.top_base
                ;endif  
                     
            ENDIF 
;            IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_CONTEXT') THEN BEGIN  ;RIGHT CLICK
;                  selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
;                  indselected=selection[1]
;                  if (indselected ge 0) AND  (indselected lt self.nbDRFSelec) AND (self.nbDRFSelec gt 1) then begin
;                      if indselected eq 0 then (*self.currDRFSelec)=(*self.currDRFSelec)[*,indselected+1:self.nbDRFSelec-1]
;                      if indselected eq (self.nbDRFSelec-1) then (*self.currDRFSelec)=(*self.currDRFSelec)[*,0:indselected-1]
;                      if (indselected ne 0) AND (indselected ne self.nbDRFSelec-1) then (*self.currDRFSelec)=[[(*self.currDRFSelec)[*,0:indselected-1]],[(*self.currDRFSelec)[*,indselected+1:self.nbDRFSelec-1]]]
;                      self.nbDRFSelec-=1
;                     
;                      (*self.order)=(*self.currDRFSelec)[3,*]
;                      
;                       widget_control,   self.tableSelected,  set_value=(*self.currDRFSelec)[0:2,*], SET_TABLE_SELECT =[-1,self.nbDRFSelec-1,-1,self.nbDRFSelec-1]
;                       widget_control,   self.tableSelected, SET_TABLE_VIEW=[0,0]
;                  endif     
;            ENDIF
    end      
    'ADDFILE' : begin
        ;-- Ask the user to select more input files:
		if self.last_used_input_dir eq '' then self.last_used_input_dir = self->get_input_dir()

        result=dialog_pickfile(path=self.last_used_input_dir,/multiple,/must_exist,$
                title='Select Raw Data File(s)', filter=['*.fits','*.fits.gz'])
        result = strtrim(result,2)

        if result[0] ne '' then begin
			self.last_used_input_dir = file_dirname(result[0])
			self->AddFile, result
		endif

    end
    'flatreduction':begin
         self.flatreduc=widget_info(self.calibflatid,/DROPLIST_SELECT)
    end
    'WILDCARD' : begin
        index = (*storage.splitptr).selindex
        cindex = (*storage.splitptr).findex
        file = (*storage.splitptr).filename
        pfile = (*storage.splitptr).printname
        datefile = (*storage.splitptr).datefile
    
        defdir=self->get_input_dir()

        caldat,systime(/julian),month,day,year
        datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')
        
        if (file[n_elements(file)-1] eq '') then begin
            command=textbox(title='Input a Wildcard-listing Command (*,?,[..-..])',$
                group_leader=ev.top,label='',cancel=cancelled,xsize=500,$
                value=defdir+'*'+datestr+'*')
        endif else begin
            self->Log,'Sorry, you cannot add files/directories any more.'
            cancelled = 1
        endelse

        if cancelled then begin
            result = ''
        endif else begin
            result=file_search(command)
        endelse
        result = strtrim(result,2)
        for i=0,n_elements(result)-1 do $
            if (total(file eq result[i]) ne 0) then result[i] = ''
;        for i=0,n_elements(result)-1 do begin
;            tmp = strsplit(result[i],'.',/extract)
;            if (n_elements(tmp) lt 5) then result[i] = ''
;        endfor
        w = where(result ne '')
        if (w[0] ne -1) then begin
            result = result[w]

;            if ((cindex+n_elements(result)) gt n_elements(file)) then begin
;                nover = cindex+n_elements(result)-n_elements(file)
;                self->Log,'WAR: exceeding file number limit. '+$
;                    strtrim(nover,2)+' files ignored.'
;                result = result[0:n_elements(result)-1-nover]
;            endif
;            file[cindex:cindex+n_elements(result)-1] = result
;
;            for i=0,n_elements(result)-1 do begin
;                tmp = strsplit(result[i],path_sep(),/extract)
;                pfile[cindex+i] = tmp[n_elements(tmp)-1]+'    '
;            endfor
;
;            widget_control,storage.fname,set_value=pfile
;
;            cindex = cindex+n_elements(result)
;            (*storage.splitptr).selindex = max([0,cindex-1])
;            (*storage.splitptr).findex = cindex
;            (*storage.splitptr).filename = file
;            (*storage.splitptr).printname = pfile
;            (*storage.splitptr).datefile = datefile 
;
;            self->Log,strtrim(n_elements(result),2)+' files added.'
        endif else begin
            self->Log,'search failed (no match).'
        endelse
        
        self->AddFile, result
        
    end
    'FNAME' : begin
        (*storage.splitptr).selindex = ev.index
    end
    'REMOVE' : begin
        self->removefile, storage, file
    end
    'REMOVEALL' : begin
        if confirm(group=ev.top,message='Remove all items from the list?',$
            label0='Cancel',label1='Proceed') then begin
            (*storage.splitptr).findex = 0
            (*storage.splitptr).selindex = 0
            (*storage.splitptr).filename[*] = ''
            (*storage.splitptr).printname[*] = '' 
            (*storage.splitptr).datefile[*] = '' 
            widget_control,storage.fname,set_value=(*storage.splitptr).printname
            self->Log,'All items removed.'
        endif
    end
    'sortmethod': begin
        sortfieldind=widget_info(self.sortfileid,/DROPLIST_SELECT)
    end

    'sortdata': begin
        sortfieldind=widget_info(self.sortfileid,/DROPLIST_SELECT)
        file = (*storage.splitptr).filename
        pfile = (*storage.splitptr).printname
        cindex = (*storage.splitptr).findex 
        datefile = (*storage.splitptr).datefile 

        wgood = where(strc(file) ne '',goodct)
        if goodct eq 0 then begin
            self->Log, "No file have been selected - nothing to sort!"
            return

        endif

        case (self.sorttab)[sortfieldind] of 
                'obs. date/time': begin
                    juldattab=dblarr(cindex)
                    for i=0,cindex-1 do begin
                      dateobs=self->resolvekeyword( file[i], 1,'DATE-OBS')
                      timeobs=self->resolvekeyword( file[i], 1,'TIME-OBS')
                      if (dateobs[0] ne 0) &&  (timeobs[0] ne 0) then begin
                        ;head=headfits( timeobsfile[0])
                        dateo=strsplit(dateobs,'-',/EXTRACT)
                        timeo=strsplit(timeobs,':',/EXTRACT)
                        ;juldattab[i] = JULDAY(date[1], date[2], date[0], time[0], time[1], time[2])
                        JULDATE, [float(dateo),float(timeo)], tmpjul
                        juldattab[i]=tmpjul
                      endif else begin
                          self->Log, "DATE-OBS and TIME-OBS not found."
                      endelse
                    endfor
             
                    indsort=sort(juldattab)
                  end
                'OBSID': begin
                     obsid=strarr(cindex)
                    for i=0,cindex-1 do begin
                      obsid[i]=self->resolvekeyword( file[i], 1,'OBSID')
                    endfor
                    indsort=sort(obsid)
                end
                'alphabetic filename':  begin
                     alpha=strarr(cindex)
                    for i=0,cindex-1 do begin
                      alpha[i]= file[i]
                    endfor
                    indsort=sort(alpha)
                end
                'file creation date':begin
                     ctime=findgen(cindex)
                    for i=0,cindex-1 do begin
                      ctime[i]= (file_info(file[i])).ctime
                    endfor
                    indsort=sort(ctime)
                end
        endcase
        file[0:n_elements(indsort)-1]= file[indsort]
        pfile[0:n_elements(indsort)-1]= pfile[indsort]
        datefile[0:n_elements(indsort)-1]= datefile[indsort]
        (*storage.splitptr).filename = file
        (*storage.splitptr).printname = pfile
        (*storage.splitptr).datefile = datefile
        widget_control,storage.fname,set_value=pfile
    end
    
    'outputdir': begin
        result = DIALOG_PICKFILE(TITLE='Select a OUTPUT Directory', /DIRECTORY,/MUST_EXIST)
        if result ne '' then begin
            self.outputdir = result
            widget_control, self.outputdir_id, set_value=self.outputdir
            self->log,'Output Directory changed to:'+self.outputdir
        endif
    end
    'logdir': begin
        result= DIALOG_PICKFILE(TITLE='Select a LOG Path', /DIRECTORY,/MUST_EXIST)
        if result ne '' then begin
            self.logdir =result
            widget_control, self.logdir_id, set_value=self.logdir
            self->log,'Log path changed to: '+self.logdir
        endif
    end
    'Delete': begin
        selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
        indselected=selection[1]
        if indselected lt 0 or indselected ge self.nbDRFselec then return ; nothing selected
        self.selection=(*self.currDRFSelec)[0,indselected]


        if confirm(group=self.top_base,message=['Are you sure you want to delete the file ',self.selection+"?"], label0='Cancel',label1='Delete', title="Confirm Delete") then begin
            self->Log, 'Deleted file '+self.selection
            file_delete, self.selection,/allow_nonexist

            if self.nbDRFSelec gt 1 then begin
                indices = indgen(self.nbDRFSelec)
                new_indices = indices[where(indices ne indselected)]
                (*self.currDRFSelec) = (*self.currDRFSelec)[*, new_indices]
                (*self.order)=(*self.currDRFSelec)[3,*]
                self.nbDRFSelec-=1
            endif else begin
                self.nbDRFSelec=0
                (*self.currDRFSelec)[*] = ''
                (*self.order)=0
            endelse
    
            ;if (indselected ge 0) AND  (indselected lt self.nbDRFSelec) AND (self.nbDRFSelec ge 1) then begin
                  ;if indselected eq 0 then (*self.currDRFSelec)=(*self.currDRFSelec)[*,indselected+1:self.nbDRFSelec-1]
                  ;if indselected eq (self.nbDRFSelec-1) then (*self.currDRFSelec)=(*self.currDRFSelec)[*,0:indselected-1]
                  ;if (indselected ne 0) AND (indselected ne self.nbDRFSelec-1) then (*self.currDRFSelec)=[[(*self.currDRFSelec)[*,0:indselected-1]],[(*self.currDRFSelec)[*,indselected+1:self.nbDRFSelec-1]]]
                 
                  
            widget_control,   self.tableSelected,  set_value=(*self.currDRFSelec)[*,*], SET_TABLE_SELECT =[-1,-1,-1,-1] ; no selection
            widget_control,   self.tableSelected, SET_TABLE_VIEW=[0,0]
              ;endif     

        endif
    end
    'DRFGUI': begin
        if self.selection eq '' then return
            gpidrfgui, drfname=self.selection, self.top_base
    end


    'QueueAll'  : begin
                self->Log, "Adding all DRFs to queue in "+self.queuedir
                for ii=0,self.nbdrfSelec-1 do begin
                    if (*self.currDRFSelec)[0,ii] ne '' then begin
                          self->queue, (*self.currDRFSelec)[0,ii]
                      endif
                endfor      
                self->Log,'All DRFs have been succesfully added to the queue.'
              end
    'QueueOne'  : begin
        if self.selection eq '' then begin
              self->Log, "Nothing is currently selected!"
              return ; nothing selected
        endif else begin
            self->queue, self.selection
            self->Log,'Queued '+self.selection
        endelse
    end
    'QUIT'    : begin
        if confirm(group=ev.top,message='Are you sure you want to close the Data Parser GUI?',$
            label0='Cancel',label1='Close', title='Confirm close') then obj_destroy, self
    end
    'direct':begin
        if widget_info(self.autoqueue_id ,/button_set)  then chosenpath=self.queuedir else chosenpath=self.drfpath
        self->Log,'All DRFs will be created in '+chosenpath
    end
      'about': begin
              tmpstr=about_message()
              ret=dialog_message(tmpstr,/information,/center,dialog_parent=ev.top)
    end ;; case: 'about'
    else: begin
        addmsg, storage.info, 'Unknown event in event handler - ignoring it!'+uval
        message,/info, 'Unknown event in event handler - ignoring it!'+uval

    end
endcase

end
;--------------------------------------
; Save a DRF to a file on disk.
;   
;   files        string array of FITS files for input to this DRF
;
;   prefix=        prefix for filename
;   datetimestr=    middle part of filename
;                   (supplied so all parsed DRFs match in timestamp)
;
;   /template    save this as a template
;
;	pro parsergui::savedrf, files, template=template, prefix=prefix, datetimestr=datetimestr
;	
;	    ; Determine input FITS files
;	    index = where(files ne '',count)
;	    selectype=self.currtype
;	
;	    if keyword_set(template) then begin
;	      templatesflag=1 
;	      index=0
;	      files=''
;	      drfpath=self.templatedir
;	    endif else begin
;	      templatesflag=0
;	      drfpath=self.drfpath
;	    endelse  
;	    if (count eq 0) && (templatesflag eq 0) then begin
;	      self->Log,'file list is empty.'
;	      if (selectype eq 4) then self->Log,'Please select any file in the data input directory.'
;	      return
;	    endif
;	
;	    files = files[index]
;	
;	    ; Determine filename to use for output
;	    if templatesflag then begin
;	      (*self.drf_summary).filename = self.LoadedRecipeFile ;to check
;	    endif else begin     
;	      if ~keyword_set(datetimestr) then begin
;	            caldat,systime(/julian),month,day,year, hour,minute,second
;	          datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')
;	          hourstr = string(hour,minute,format='(i2.2,i2.2)')  
;	          datetimestr=datestr+'-'+hourstr
;	      endif
;	      if keyword_set(prefix) then prefixname=string(prefix, format="(I03)") else prefixname=''
;	      (*self.drf_summary).filename=datetimestr+"_"+prefixname+'_drf.waiting.xml'
;	    endelse
;	
;	    ;get drf filename and set drfpath:
;	    ;if ~keyword_set(nopickfile) then begin
;	        ;newdrffilename = DIALOG_PICKFILE(TITLE='Save Data Reduction File (DRF) as', /write,/overwrite, filter='*.xml',file=(*self.drf_summary).filename,path=drfpath, get_path=newdrfpath)
;	        ;if newdrffilename eq "" then return ; user cancelled the save as dialog, so don't save anything.
;	        ;self.drfpath  = newdrfpath ; MDP change - update the default directory to now match whatever the user selected in the dialog box.
;	    ;endif else newdrffilename = (*self.drf_summary).filename
;	    ;newdrffilename = (*self.drf_summary).filename
;	    
;	    if (self.nbmoduleSelec ne '') && ( (*self.drf_summary).filename ne '') then begin
;	        if widget_info(self.autoqueue_id ,/button_set)  then chosenpath=self.queuedir else chosenpath=self.drfpath
;	
;			if ~self->check_output_path_exists(chosenpath) then return
;	
;	        message,/info, "Writing to "+chosenpath+path_sep()+(*self.drf_summary).filename 
;	        OpenW, lun, chosenpath+path_sep()+(*self.drf_summary).filename, /Get_Lun
;	        PrintF, lun, '<?xml version="1.0" encoding="UTF-8"?>' 
;	     
;	           
;	        if selectype eq 4 then begin
;	            PrintF, lun, '<DRF logdir="'+self.logdir+'" ReductionType="OnLine">'
;	        endif else begin
;	            PrintF, lun, '<DRF logdir="'+self.logdir+'" ReductionType="'+(*self.template_types)[selectype] +'" Name="'+(*self.drf_summary).name+'" >'
;	        endelse
;	
;	        PrintF, lun, '<dataset InputDir="'+self.inputdir+'" Name="" OutputDir="'+self.outputdir+'">' 
;	     
;	        FOR j=0,N_Elements(file)-1 DO BEGIN
;	            tmp = strsplit(file[j],path_sep(),/extract)
;	            PrintF, lun, '   <fits FileName="' + tmp[n_elements(tmp)-1] + '" />'
;	            ;PrintF, lun, '   <fits FileName="' + file[j] + '" />'
;	        ENDFOR
;	    
;	        PrintF, lun, '</dataset>'
;	        FOR j=0,self.nbmoduleSelec-1 DO BEGIN
;	            self->extractparam, float((*self.currModSelec)[4,j])
;	            strarg=''
;	            if (*self.indarg)[0] ne -1 then begin
;	                  argn=((*self.PrimitiveInfo).argname)[[*self.indarg]]
;	                  argd=((*self.PrimitiveInfo).argdefault)[[*self.indarg]]
;	                  for i=0,n_elements(argn)-1 do begin
;	                      strarg+=argn[i]+'="'+argd[i]+'" '
;	                  endfor
;	              endif
;	              
;	        
;	            PrintF, lun, '<module name="' + (*self.currModSelec)[0,j] + '" '+ strarg +'/>'
;	        ENDFOR
;	        PrintF, lun, '</DRF>'
;	        Free_Lun, lun
;	        self->Log,'Saved  '+(*self.drf_summary).filename+ " in "+chosenpath
;	        
;	        ;display last paramtab
;	                    indselected=self.nbmoduleSelec-1
;	                   self->extractparam, float((*self.currModSelec)[4,indselected])    
;	                  *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
;	                  if (*self.indarg)[0] ne -1 then begin
;	                      (*self.currModSelecParamTab)[*,0]=((*self.PrimitiveInfo).argname)[[*self.indarg]]
;	                      (*self.currModSelecParamTab)[*,1]=((*self.PrimitiveInfo).argdefault)[[*self.indarg]]
;	                      (*self.currModSelecParamTab)[*,2]=((*self.PrimitiveInfo).argdesc)[[*self.indarg]]
;	                  endif
;	              
;	        
;	    endif
;	end
;-------------------------------------
;	pro parsergui::loaddrf, filename, storage, nodata=nodata, silent=silent
;		
;	    if keyword_set(filename) then self.LoadedRecipeFile=filename
;	
;	    if self.LoadedRecipeFile eq '' then return
;	
;	    widget_control,self.top_base,get_uvalue=storage  
;	
;	    
;	
;		if ~file_test(self.LoadedRecipeFile, /read) then begin
;	        message, "Requested recipe file does not exist: "+self.LoadedRecipeFile,/info
;			return
;		endif
;	
;		catch, parse_error
;		if parse_error eq 0 then begin
;			drf = obj_new('drf', self.LoadedRecipeFile)
;		endif else begin
;	        message, "Could not parse Recipe File: "+self.LoadedRecipeFile,/info
;			;stop
;	        return
;		endelse
;		catch,/cancel
;	
;	
;	    drf_summary = drf->get_summary()
;	    drf_contents = drf->get_contents()
;	
;	    drf_module_names = drf_contents.modules.name
;	
;	    
;		ptr_free, self.drf_summary
;		ptr_free, self.current_drf
;	    self.drf_summary = ptr_new(drf_summary)
;		self.current_drf = ptr_new(drf)
;	
;	
;	    ; if requested, load the filenames in that DRF
;	;	    ; (for Template use, don't load the data)
;	;	    if ~keyword_set(nodata) then  begin
;	;	        self.inputdir=drf_contents.inputdir
;	;	         ;;get list of files in the drf
;	;	         if strcmp((drfmodules.fitsfilenames)[0],'') ne 1  then begin
;	;	            (*storage.splitptr).filename = drf_contents.fitsfilenames
;	;	            (*storage.splitptr).printname = drf_contents.fitsfilenames
;	;	            widget_control,storage.fname,set_value=(*storage.splitptr).printname
;	;	        endif
;	;	    endif
;	
;	
;	;	    ;if necessary, update reduction type to match whatever is in that DRF (and update available modules list too)
;	;	    if self.reductiontype ne drf_summary.reductiontype then begin
;	;	        selectype=where(*self.template_types eq drf_summary.reductiontype, matchct)
;	;	        if matchct eq 0 then message,"ERROR: no match for "+self.reductiontype
;	;	        self.currtype=selectype
;	;	        self->changetype, selectype[0], /notemplate
;	;	    endif
;	;	    
;	;	
;	;	    ; Now load the modules of the selected DRF:
;	;	    self.nbmoduleSelec=0
;	;	    indseqini=intarr(n_elements(drf_module_names))
;	;	    seq=((*self.PrimitiveInfo).names)[(*self.indmodtot2avail)[*self.curr_mod_indsort]] 
;	;	    ; seq is list of currently available modules, in alphabetical order
;	;	    
;	;	    for ii=0,n_elements(drf_module_names)-1 do begin
;	;	         indseqini[ii]=where(strmatch(seq,(drf_module_names)[ii],/fold_case), matchct)
;	;	         ; indseqini is indices of the DRF's modules into the seq array.
;	;	         if matchct eq 0 then message,/info,"ERROR: no match for module="+ (drf_module_names)[ii]
;	;	    endfor
;	;	
;	;	    
;	;	    for ii=0,n_elements(drf_module_names)-1 do begin
;	;	        if self.nbmoduleSelec eq 0 then (*self.currModSelec)=([(drf_module_names)[0],'','','','']) $  
;	;	        else  (*self.currModSelec)=([[(*self.currModSelec)],[[(drf_module_names)[ii],'','','','']]])
;	;	        self.nbmoduleSelec+=1
;	;	
;	;	        ;does this module need calibration file?
;	;	        ind=where(strmatch(tag_names((drf_contents.modules)[ii]),'CALIBRATIONFILE'), matchct)
;	;	        if ind ne [-1] then begin
;	;	                   (*self.currModSelec)[2,self.nbmoduleSelec-1]=((drf_contents.modules)[ii]).calibrationfile
;	;	        endif
;	;	        (*self.currModSelec)[3,self.nbmoduleSelec-1]=((*self.PrimitiveInfo).order)[(*self.indmodtot2avail)[(*self.curr_mod_indsort)[indseqini[ii]]]] 
;	;	
;	;	 
;	;	    endfor
;	;	
;	;	    ;sort *self.currModSelec with ORDER 
;	;	    (*self.order)=float((*self.currModSelec)[3,*])
;	;	
;	;	; MDP edit: Do not re-sort loaded DRFs - just use exactly what is in the
;	;	; template.     
;	;	    (*self.currModSelec)[4,*]=strc(indseqini)
;	;	;        ;;todo:check out there are no duplicate order (sinon la table d argument va se meler) 
;	;	;        (*self.currModSelec)=(*self.currModSelec)[*,sort(*self.order)]  
;	;	;        (*self.currModSelec)[4,*]=strc(indseqini[sort(*self.order)])
;	;	;        (*self.order)=(*self.currModSelec)[3,*]
;	;	
;	;	
;	;	    if self.debug then if not array_equal(seq[indseqini], (*self.currModSelec)[0,*]) then message, "Module arrays appear confused"
;	;	    
;	;	    for ii=0,n_elements(drf_module_names)-1 do begin
;	;	        if self.debug then print, "-----"
;	;	        if self.debug then print, drf_module_names[ii]," / ",  (*self.currModSelec)[0,ii]
;	;	        if drf_module_names[ii] ne (*self.currModSelec)[0,ii] then message,"Module names don't match..."
;	;	        self->extractparam, float((*self.currModSelec)[4,ii])  ; loads indarg
;	;	
;	;	        if self.debug then print, "   has argument(s): "+ strjoin(((*self.PrimitiveInfo).argname)[[*self.indarg]], ", " )
;	;	
;	;	        *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
;	;	        if (*self.indarg)[0] ne -1 then begin
;	;	            (*self.currModSelecParamTab)[*,0]=((*self.PrimitiveInfo).argname)[[*self.indarg]]
;	;	            (*self.currModSelecParamTab)[*,1]=((*self.PrimitiveInfo).argdefault)[[*self.indarg]]
;	;	            (*self.currModSelecParamTab)[*,2]=((*self.PrimitiveInfo).argdesc)[[*self.indarg]]
;	;	        endif
;	;	        tag=tag_names((drf_contents.modules)[ii])
;	;	        for jj=0,n_elements(*self.indarg)-1 do begin
;	;	            indtag=where(strmatch( tag ,(*self.currModSelecParamTab)[jj,0],/fold), matchct)
;	;	                if matchct eq 0 then begin
;	;	                    message,"ERROR: no match in DRF for module parameter='"+(*self.currModSelecParamTab)[jj,0]+"'",/info
;	;	                    message,"of module='"+(drf_module_names)[ii]+"'",/info
;	;	                    message,"Check whether the parameter list in the DRF file '"+self.loadedRecipeFile+"' has the correct parameters for that module! ",/info
;	;	                endif else begin
;	;		        	    argtab=((*self.PrimitiveInfo).argdefault)
;	;		    	        argtab[(*self.indarg)[jj]]=((drf_contents.modules)[ii]).(indtag[0]) ;use parentheses as Facilities exist to process structures in a general way using tag numbers rather than tag names
;	;			            ((*self.PrimitiveInfo).argdefault)=argtab
;	;					endelse
;	;	        ;    (*self.currModSelecParamTab)[jj,1]=
;	;	        endfor
;	;	        if self.debug then print, "   has value(s): "+ strjoin(((*self.PrimitiveInfo).argdefault)[[*self.indarg]], ", " )
;	;	    endfor
;	;	
;	;	    ;display last paramtab
;	;	    indselected=self.nbmoduleSelec-1
;	;	    *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
;	;	    if (*self.indarg)[0] ne -1 then begin
;	;	        (*self.currModSelecParamTab)[*,0]=((*self.PrimitiveInfo).argname)[[*self.indarg]]
;	;	        (*self.currModSelecParamTab)[*,1]=((*self.PrimitiveInfo).argdefault)[[*self.indarg]]
;	;	        (*self.currModSelecParamTab)[*,2]=((*self.PrimitiveInfo).argdesc)[[*self.indarg]]
;	;	    endif
;	    ;obj_destroy, ConfigParser
;	    ;obj_destroy, Parser
;	
;	end
;	
;------------------------------------------------
pro parsergui::cleanup

    ptr_free, self.currDRFselec

    self->drfgui::cleanup ; will destroy all widgets
end


;------------------------------------------------
function parsergui::init_widgets,  _extra=_Extra  ;drfname=drfname,  ;,groupleader,group,proj


    ;create base widget. 
    ;   Resize to be large on desktop monitors, or shrink to fit on laptops.
    ;-----------------------------------------
    screensize=get_screen_size()

    if screensize[1] lt 900 then begin
      nlines_status=12
      nlines_fname=10
      nlines_modules=7
      nlines_args=6
    endif else begin
      nlines_status=12
      nlines_fname=10
      nlines_modules=10
      nlines_args=6
    endelse
    CASE !VERSION.OS_FAMILY OF  
        ; **NOTE** Mac OS X reports an OS family of 'unix' not 'MacOS'
       'unix': begin 
		   resource_name='GPI_DRP_Parser'
        
       end
       'Windows'   :begin
		   bitmap=self.dirpro+path_sep()+'gpi.bmp'
       end

    ENDCASE
    self.top_base=widget_base(title='GPI Data Parser: Create a Set of Data Reduction Recipes', /BASE_ALIGN_LEFT,/column, MBAR=bar,/tlb_size_events, /tlb_kill_request_events, resource_name=resource_name, bitmap=bitmap )

    parserbase=self.top_base
    ;create Menu
    file_menu = WIDGET_BUTTON(bar, VALUE='File', /MENU) 
    file_bttn2=WIDGET_BUTTON(file_menu, VALUE='Quit Parser', UVALUE='QUIT')


    ;create file selector
    ;-----------------------------------------
    DEBUG_SHOWFRAMES=0
    top_basefilebutt=widget_base(parserbase,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES, /base_align_center)
    label = widget_label(top_basefilebutt, value="Input FITS Files:")
    button=widget_button(top_basefilebutt,value="Add File(s)",uvalue="ADDFILE", $
        xsize=90,ysize=30, /tracking_events);,xoffset=10,yoffset=115)
    button=widget_button(top_basefilebutt,value="Wildcard",uvalue="WILDCARD", $
        xsize=90,ysize=30, /tracking_events);,xoffset=110,yoffset=115)
    button=widget_button(top_basefilebutt,value="Remove",uvalue="REMOVE", $
        xsize=90,ysize=30, /tracking_events);,xoffset=210,yoffset=115)
    button=widget_button(top_basefilebutt,value="Remove All",uvalue="REMOVEALL", $
        xsize=90,ysize=30, /tracking_events);,xoffset=310,yoffset=115)
    ;top_basefilebutt2=widget_base(top_basefilebutt,/BASE_ALIGN_LEFT,/row,frame=DEBUG_SHOWFRAMES)
    top_basefilebutt2=top_basefilebutt
    self.sorttab=['obs. date/time','alphabetic filename','file creation date']
    self.sortfileid = WIDGET_DROPLIST( top_basefilebutt2, title='Sort data by:',  Value=self.sorttab,uvalue='sortmethod')
    drfbrowse = widget_button(top_basefilebutt2,  $
                            XOFFSET=174 ,SCR_XSIZE=80, ysize= 30 $; ,SCR_YSIZE=23  $
                            ,/ALIGN_CENTER ,VALUE='Sort data',uvalue='sortdata')                          
        
    top_baseident=widget_base(parserbase,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES)
    ; file name list widget
    fname=widget_list(top_baseident,xsize=106,scr_xsize=580, ysize=nlines_fname,$
            xoffset=10,yoffset=150,uvalue="FNAME", /TRACKING_EVENTS,resource_name='XmText')

    ; add 5 pixel space between the filename list and controls
    top_baseborder=widget_base(top_baseident,xsize=5,units=0, frame=DEBUG_SHOWFRAMES)

    ; add the options controls
    top_baseidentseq=widget_base(top_baseident,/BASE_ALIGN_LEFT,/column,  frame=DEBUG_SHOWFRAMES)
    top_baseborder=widget_base(top_baseidentseq,ysize=1,units=0)          
    top_baseborder2=widget_base(top_baseidentseq,/BASE_ALIGN_LEFT,/row)
    drflabel=widget_label(top_baseborder2,Value='Output Dir=         ')
    self.outputdir_id = WIDGET_TEXT(top_baseborder2, $
                xsize=34,ysize=1,$
                /editable,units=0,value=self.outputdir )    

    drfbrowse = widget_button(top_baseborder2,  $
                        XOFFSET=174 ,SCR_XSIZE=75 ,SCR_YSIZE=23  $
                        ,/ALIGN_CENTER ,VALUE='Change...',uvalue='outputdir')
;    top_baseborder3=widget_base(top_baseidentseq,/BASE_ALIGN_LEFT,/row)
;    drflabel=widget_label(top_baseborder3,Value='Log Path=           ')
;    self.logdir_id = WIDGET_TEXT(top_baseborder3, $
;                xsize=34,ysize=1,$
;                /editable,units=0 ,value=self.logdir)
;    drfbrowse = widget_button(top_baseborder3,  $
;                        XOFFSET=174 ,SCR_XSIZE=75 ,SCR_YSIZE=23  $
;                        ,/ALIGN_CENTER ,VALUE='Change...',uvalue='logdir') 
;                        
    calibflattab=['Flat-field extraction','Flat-field & Wav. solution extraction']
    ;the following line commented as it will not be used (uncomment line in post_init if you absolutely want it)
   ; self.calibflatid = WIDGET_DROPLIST( top_baseidentseq, title='Reduction of flat-fields:  ', frame=0, Value=calibflattab, uvalue='flatreduction')
        ;one nice logo 
	button_image = READ_BMP(self.dirpro+path_sep()+'gpi.bmp', /RGB) 
	button_image = TRANSPOSE(button_image, [1,2,0]) 
	button = WIDGET_BUTTON(top_baseident, VALUE=button_image,  $
      SCR_XSIZE=100 ,SCR_YSIZE=95, sensitive=1 ,uvalue='about')                  
    

	; what colors to use for cell backgrounds? Alternate rows between
	; white and off-white pale blue
	self.table_BACKground_colors = ptr_new([[255,255,255],[240,240,255]])

	col_labels = ['Recipe File','Recipe Name','Recipe Type','IFSFILT','OBSTYPE','DISPERSR','OCCULTER','OBSCLASS','ITIME','OBJECT', '# FITS']
	xsize=n_elements(col_labels)
	self.tableSelected = WIDGET_TABLE(parserbase, $; VALUE=data, $ ;/COLUMN_MAJOR, $ 
		COLUMN_LABELS=col_labels,/resizeable_columns, $
		xsize=xsize,ysize=20,uvalue='tableselec',value=(*self.currDRFSelec), /TRACKING_EVENTS,$
		/NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =nlines_modules,scr_xsize=1150, COLUMN_WIDTHS=[340,200,100,50,62,62,62,62,62,62, 50],frame=1,/ALL_EVENTS,/CONTEXT_EVENTS, $
		background_color=rebin(*self.table_BACKground_colors,3,2*11,/sample)    ) ;,/COLUMN_MAJOR                

	; Create the status log window 
	tmp = widget_label(parserbase, value="   " )
	tmp = widget_label(parserbase, value="History: ")
	info=widget_text(parserbase,/scroll, xsize=160,scr_xsize=800,ysize=nlines_status, /ALIGN_LEFT, uval="text_status",/tracking_events);xoffset=5,yoffset=5)
	self.widget_log = info

    ;;create execute and quit button
    ;-----------------------------------------
    top_baseexec=widget_base(parserbase,/BASE_ALIGN_LEFT,/row)
    button2b=widget_button(top_baseexec,value="Queue all Recipes",uvalue="QueueAll", /tracking_events)
    button2b=widget_button(top_baseexec,value="Queue selected Recipes only",uvalue="QueueOne", /tracking_events)
    directbase = Widget_Base(top_baseexec, UNAME='directbase' ,COLUMN=1 ,/NONEXCLUSIVE, frame=0)
    self.autoqueue_id =    Widget_Button(directbase, UNAME='direct'  $
		,/ALIGN_LEFT ,VALUE='Queue all generated recipes automatically',uvalue='direct' )
	
	if gpi_get_setting('parsergui_auto_queue',/bool) then widget_control,self.autoqueue_id, /set_button   

    space = widget_label(top_baseexec,uvalue=" ",xsize=100,value='  ')
    button2b=widget_button(top_baseexec,value="Open in Recipe Editor",uvalue="DRFGUI", /tracking_events)
    button2b=widget_button(top_baseexec,value="Delete selected Recipe",uvalue="Delete", /tracking_events)

    space = widget_label(top_baseexec,uvalue=" ",xsize=200,value='  ')
    button3=widget_button(top_baseexec,value="Close Data Parser GUI",uvalue="QUIT", /tracking_events, resource_name='red_button')

    self.textinfoid=widget_label(parserbase,uvalue="textinfo",xsize=900,value='  ')
    ;-----------------------------------------
    maxfilen=gpi_get_setting('parsergui_max_files',/int, default=200) ;550
    filename=strarr(maxfilen)
    printname=strarr(maxfilen)
    printfname=strarr(maxfilen)
    datefile=lonarr(maxfilen)
    findex=0
    selindex=0
    splitptr=ptr_new({filename:filename,printname:printname,printfname:printfname,$
      findex:findex,selindex:selindex,datefile:datefile, maxfilen:maxfilen})

    ;make and store data storage
    ;-----------------------------------------
    ; info        : widget ID for information text box
    ; fname        : widget ID for filename text box
    ; rb        : widget ID for merge selector
    ; splitptr  ; structure (pointer)
    ;   filename  : array for filename
    ;   printname : array for printname
    ;   findex    : current index to write filename
    ;   selindex  : index for selected file
    ; group,proj    : group and project name(given parameter)
    ;-----------------------------------------
    group=''
    proj=''
    storage={info:info,fname:fname,$
        splitptr:splitptr,$
        group:group,proj:proj, $
        self:self}
    widget_control,parserbase,set_uvalue=storage,/no_copy

    self->log, "This GUI helps you to parse a set of FITS data files to generate useful reduction recipes."
    self->log, "Add files to be processed, and recipes will be automatically created based on FITS keywords."
    return, parserbase

end


;-----------------------
pro parsergui::post_init, _extra=_extra
end

;-----------------------
PRO parsergui__define


    state = {  parsergui,                 $
              typetab:strarr(5),$
              loadedinputdir:'',$
              calibflatid:0L,$
              flatreduc:0,$
              autoqueue_id:0L,$
              selectype:0,$
              currtype:0,$
              currseq:0,$
              nbdrfSelec:0,$
              selection: '', $
			  DEBUG:0, $
			  current_drf: ptr_new(), $
			  last_used_input_dir: '', $ ; save the most recently used directory. Start there again on subsequent file additions
              currDRFSelec: ptr_new(), $
           INHERITS drfgui}


end
