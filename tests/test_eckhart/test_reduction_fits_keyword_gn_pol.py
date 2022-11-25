import os
import gpipy

recipename = 'gpi2_fits_keyword_gn_pol.xml'
nfiles_expected = 1

def test_pol(pipeline, test_dir):
    """ End to end test for GPI polarimetric reductions

    Simple checks of spectral extraction products 
    """
    
    stem = "/home/prunelle/gpi2_pipeline_development/data/Reduced/181121"
    
    status, outrecipe, outfiles = pipeline.run_recipe( os.path.join(test_dir, recipename), rescanDB=True)
    
    assert status=='Success', RuntimeError("Recipe {} failed.".format(recipename))
    
    # Did we get the output files we expected?
    assert len(outfiles)==nfiles_expected, "Number of output files does not match expected value."
    assert stem+"/test_telescop_S20181121S0114_podc.fits" in outfiles, "Output files didn't contain one of the _podc cubes."
    
    # Are the contents of that file what we expected?
    cube = gpipy.read( stem+"/test_telescop_S20181121S0114_podc.fits")
    
    assert cube.filetype=='Stokes Cube', "Wrong output file type"
    
    # TODO write tests here that check sat spot keyword values in headers for one of the individual files

    # TODO write more tests here looking at actual pixel values, to
    # verify the planet is detected as expected
