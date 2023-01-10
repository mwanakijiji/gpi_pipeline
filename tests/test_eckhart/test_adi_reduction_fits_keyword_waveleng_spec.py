import os
import gpipy

recipename = 'gpi2_adi_fits_keyword_waveleng_spec.xml'
file_string = "_keyword_waveleng"
nfiles_expected = 91 # 45 spdc frames, 45 spdc_adi frames, 1 spdc_adi_resadi frame

def test_spec(pipeline, test_dir):
    """ End to end test for GPI spectral reductions

    Simple checks of spectral extraction products 
    """
    
    stem = "/home/prunelle/gpi2_pipeline_development/data/Reduced/140422"

    status, outrecipe, outfiles = pipeline.run_recipe( os.path.join(test_dir, recipename), rescanDB=True)
    
    assert status=='Success', RuntimeError("Recipe {} failed.".format(recipename))
    
    # Did we get the output files we expected?
    assert len(outfiles)==nfiles_expected, "Number of output files does not match expected value."
    assert stem+"/S20140422S0341"+file_string+"_spdc-adim.fits" in outfiles, "Output files didn't contain one of the intermediate ADI images."
    assert stem+"/S20140422S0365"+file_string+"_spdc-adim_resadi.fits" in outfiles, "Output files didn't contain the final residual ADI image."    
 
    # Are the contents of that file what we expected?
    cube = gpipy.read( stem+"/S20140422S0365"+file_string+"_spdc-adim_resadi.fits" )
   
    # ADI residual frame should still be the same IFS type as the original FITS file 
    assert cube.filetype=='Spectral Cube', "Wrong output file type"
    
    # TODO write tests here that check sat spot keyword values in headers for one of the individual files

    # TODO write more tests here looking at actual pixel values, to
    # verify the planet is detected as expected
