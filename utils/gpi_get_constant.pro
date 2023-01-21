function gpi_get_constant, settingname, frame_header=frame_header, expand_path=expand_path, integer=int, bool=bool, string=string, rescan=rescan,silent=silent, default=default, double=double
;+
; NAME: gpi_get_constant
; 
;	Look up a constant value for GPI, from the pipeline config
;	directory constants file. 	 
;
;	The contents of the file is just a tab-delimited name=value
;	mapping.  Values are assumed to be doubles unless user overrides.
;
; INPUTS:
;	settingname		name of string to look up in that config file
;
; KEYWORD:
;       frame_header=           Header of the FITS file, which allows function to determine
;                                 if GPI1 or GPI2 constants are needed
; 	/int			Cast result to integer before returning
;       /string                 Leave value as string
; 	/bool			Cast result to boolean (byte) before returning
;
; 	/rescan			Reload the input files from disk instead of using cached
; 			        values
; 	default=		Value to return, for the case when no information is
; 				available in the configuration files.
;	/silent			Don't print any warning messages if setting not found.
;       /double                 Null op if anything else is set (for
;                               backwards compatibility)
; OUTPUTS:
;	returns the value stored in the file
;
; HISTORY:
;       2013-08-19 - ds - Split off from gpi_get_setting.pro
;-
  compile_opt defint32, strictarr, logical_predicate

  common GPI_CONSTANTS, allconstants

  ;; erase variables to force re-reading config files from disk
  if keyword_set(rescan) then  delvarx, allconstants

  global_constants_file = gpi_get_directory("GPI_DRP_CONFIG_DIR")+path_sep()+"pipeline_constants.txt"

  ;;-------- load global settings
  if n_elements(allconstants) eq 0 then begin
     if ~(keyword_set(silent)) then message,/info,"Reading in constants file: "+global_constants_file
     if ~file_test(global_constants_file) then $
        message,"Pipeline constants File does not exist! Check your pipeline config: "+global_constants_file
     ;;FIXME make this more robust to any whitespace as separator
     readcol, global_constants_file, format='A,A', comment='#', names, values, count=count, /silent
     if count eq 0 then begin
        if ~(keyword_set(silent)) then $
           message,/info,'WARNING: Could not load the pipeline configuration file from '+global_constants_file
        return, 'ERROR'
     endif
     allconstants = {parameters:names, values: values}
  endif
  
  ;;now retrieve the desired parameteri

  ;;check if FITS file is from GPI2.0; if it is, certain constants will have different vals and will have a '_gpi2' suffix in name 
  constants_list = ["observatory_lat","observatory_lon","primary_diam","secondary_diam"] ; affected list of keywords with different GPI1/GPI2 values
  cond_gpi2 = gpi_get_keyword(*frame_header.pri_header,*frame_header.ext_header,"PROJECT") ; check header for keyword PROJECT (only GPI2.0 files have it)
  cond_match = FIX(TOTAL(STRMATCH(constants_list,settingname))) EQ FIX(1) ; if there is a match between settingname and affected constants
  ; if search for 'PROJECT' keyword did not return null, and if settingname is in the affected list
  IF ((cond_gpi2 NE LONG(0)) && (cond_match EQ LONG(1))) THEN BEGIN
    settingname=settingname+"_gpi2"
    message,/info,"GPI2 frame detected; adding suffix '_gpi2' to constant name"
  ENDIF

  wm = where(strmatch(allconstants.parameters, settingname, /fold_case), ct)
  if ct eq 0 then begin
     ;; no match found!
     if n_elements(default) gt 0 then begin
        ;; If we have a default, use that
        if ~(keyword_set(silent)) then message,/info,'No setting found for '+settingname+"; using default value="+strtrim(default,2)
        return, default
     endif else begin
        ;; Otherwise alert the user we have no good setting
        if ~(keyword_set(silent)) then begin
           message,/info,"-----------------------------------------"
           message,/info, "ERROR: could not find a setting named "+settingname
           message,/info, "Check your constants file: "+global_constants_file
           message,/info,"-----------------------------------------"
        endif
        return, 'ERROR'
     endelse
  endif else begin
     result = allconstants.values[wm[0]]
  endelse


  ;;---- optional postprocessing
  if keyword_set(int) then result=fix(result)
  if keyword_set(bool) then result=byte(fix(result))
  if ~keyword_set(int) && ~keyword_set(bool) && ~keyword_set(string) then result=double(result)

  return, result
  
end
