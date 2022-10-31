import os
import gpipy

recipename = 'generic_SpecTest_eckhart.xml'
nfiles_expected = 4

def test_betapic(pipeline, test_dir):
    """ End to end test for GPI spectral reductions

    Simple checks of spectral extraction products 
    """
    print('yes')
    stem = "/home/prunelle/gpi2_pipeline_development/data/Reduced/140422"
    
    status, outrecipe, outfiles = pipeline.run_recipe( os.path.join(test_dir, recipename), rescanDB=True)

    assert status=='Success', RuntimeError("Recipe {} failed.".format(recipename))
    
    # Did we get the output files we expected?
    assert len(outfiles)==nfiles_expected, "Number of output files does not match expected value."
    assert stem+"/S20140422S0338_spdc.fits" in outfiles, "Output files didn't contain one of the _spdc cubes."
    
    """  
    # Are the contents of that file what we expected?
    cube = gpipy.read( "./S20131118S0064_median.fits")
    assert cube.filetype=='Spectral Cube', "Wrong output file type"
    """
    # TODO write tests here that check sat spot keyword values in headers for one of the individual files

    # TODO write more tests here looking at actual pixel values, to
    # verify the planet is detected as expected

    assert 1<2
