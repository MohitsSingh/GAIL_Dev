#!/bin/sh

cd /home/gail/GAIL_tests/repo/gail-development/
# GIT
# Pulling the latest repository before testing
# /usr/local/bin/git --git-dir /home/gail/GAIL_tests/repo/gail-development/.git checkout .
/usr/local/bin/git --git-dir /home/gail/GAIL_tests/repo/gail-development/.git pull
# /usr/local/bin/git --git-dir /home/gail/GAIL_tests/repo/gail-development/.git checkout .

# MATLAB
# Generate files necessary for creating HTML documentation
cd GAIL_Matlab/Documentation/
g++ -std=c++11 autodoc.cpp -o autodoc
./autodoc
sleep 5

rm -f autodoc
mv -f help_cubLattice_g_raw.m help_cubLattice_g.m
mv -f help_cubMC_g_raw.m help_cubMC_g.m
mv -f help_cubSobol_g_raw.m help_cubSobol_g.m
mv -f help_funappx_g_raw.m help_funappx_g.m
mv -f help_funmin_g_raw.m help_funmin_g.m
mv -f help_integral_g_raw.m help_integral_g.m
mv -f help_meanMCBer_g_raw.m help_meanMCBer_g.m
mv -f help_meanMC_g_raw.m help_meanMC_g.


scp gail@karlin.math.iit.edu:/home/gail/GAIL_tests/repo/gail-development/GAIL_Matlab/Documentation .
scp -r schoi32@anubis.e1.iit.edu:~/Documentation .

#cd /home/gail/GAIL_tests/repo/gail-development/
#git add /home/gail/GAIL_tests/repo/gail-development/GAIL_Matlab/Documentation
#git add /home/gail/GAIL_tests/repo/gail-development/GAIL_Matlab/Documentation/html
#git commit -m 'Update automatically generated Matlab files for HTML documentation'
#git push origin develop

# matlab < ./Developers_only/GAIL_Publish.m 

 