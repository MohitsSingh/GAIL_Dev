%% meanMC_g
% Monte Carlo method to estimate the mean of a random variable
%% Syntax
% tmu = *meanMC_g*(Yrand)
%
% tmu = *meanMC_g*(Yrand,abstol,reltol,alpha)
%
% tmu = *meanMC_g*(Yrand,'abstol',abstol,'reltol',reltol,'alpha',alpha)
%
% [tmu, out_param] = *meanMC_g*(Yrand,in_param)
%% Description
%
% tmu = *meanMC_g*(Yrand) estimates the mean, mu, of a random variable Y to
%  within a specified generalized error tolerance, 
%  tolfun:=max(abstol,reltol*| mu |), i.e., | mu - tmu | <= tolfun with
%  probability at least 1-alpha, where abstol is the absolute error
%  tolerance, and reltol is the relative error tolerance. Usually the
%  reltol determines the accuracy of the estimation, however, if the | mu |
%  is rather small, the abstol determines the accuracy of the estimation.
%  The default values are abstol=1e-2, reltol=1e-1, and alpha=1%. Input
%  Yrand is a function handle that accepts a positive integer input n and
%  returns an n x 1 vector of IID instances of the random variable Y.
%
% tmu = *meanMC_g*(Yrand,abstol,reltol,alpha) estimates the mean of a
%  random variable Y to within a specified generalized error tolerance
%  tolfun with guaranteed confidence level 1-alpha using all ordered
%  parsing inputs abstol, reltol, alpha.
%   
% tmu = *meanMC_g*(Yrand,'abstol',abstol,'reltol',reltol,'alpha',alpha)
%  estimates the mean of a random variable Y to within a specified
%  generalized error tolerance tolfun with guaranteed confidence level
%  1-alpha. All the field-value pairs are optional and can be supplied in
%  different order, if a field is not supplied, the default value is used.
%
% [tmu, out_param] = *meanMC_g*(Yrand,in_param) estimates the mean of a
%  random variable Y to within a specified generalized error tolerance
%  tolfun with the given parameters in_param and produce the estimated
%  mean tmu and output parameters out_param. If a field is not specified,
%  the default value is used.
%
% *Input Arguments*
%
% * Yrand --- the function for generating n IID instances of a random
%  variable Y whose mean we want to estimate. Y is often defined as a
%  function of some random variable X with a simple distribution. The
%  input of Yrand should be the number of random variables n, the output
%  of Yrand should be n function values. For example, if Y = X.^2 where X
%  is a standard uniform random variable, then one may define Yrand =
%  @(n) rand(n,1).^2.
%
% * in_param.abstol --- the absolute error tolerance, which should be
%  positive, default value is 1e-2.
%
% * in_param.reltol --- the relative error tolerance, which should be
%  between 0 and 1, default value is 1e-1.
%
% * in_param.alpha --- the uncertainty, which should be a small positive
%  percentage. default value is 1%.
%
% *Optional Input Arguments*
%
% * in_param.fudge --- standard deviation inflation factor, which should
%  be larger than 1, default value is 1.2.
%
% * in_param.nSig --- initial sample size for estimating the sample
%  variance, which should be a moderate large integer at least 30, the
%  default value is 1e4.
%
% * in_param.n1 --- initial sample size for estimating the sample mean,
%  which should be a moderate large positive integer at least 30, the
%  default value is 1e4.
%
% * in_param.tbudget --- the time budget in seconds to do the two-stage
%  estimation, which should be positive, the default value is 100 seconds.
%
% * in_param.nbudget --- the sample budget to do the two-stage
%  estimation, which should be a large positive integer, the default
%  value is 1e9.
%
% *Output Arguments*
%
% * tmu --- the estimated mean of Y.
%
% * out_param.tau --- the iteration step.
%
% * out_param.n --- the sample size used in each iteration.
%
% * out_param.nremain --- the remaining sample budget to estimate mu. It was
%  calculated by the sample left and time left.
%
% * out_param.ntot --- total sample used.
%
% * out_param.hmu --- estimated mean in each iteration.
%
% * out_param.tol --- the reliable upper bound on error for each iteration.
%
% * out_param.var --- the sample variance.
%
% <html>
% <ul type="square">
%  <li>out_param.exit --- the state of program when exiting:</li>
%   <ul type="circle">
%    <li>0   Success</li>
%    <li>1   Not enough samples to estimate the mean</li>
%   </ul>
% </ul>
% </html>
%
% * out_param.kurtmax --- the upper bound on modified kurtosis.
%
% * out_param.time --- the time elapsed in seconds.
%
% <html>
% <ul type="square">
%  <li>out_param.flag --- parameter checking status:</li>
%   <ul type="circle">
%    <li>1   checked by meanMC_g</li>
%   </ul>
% </ul>
% </html>
%
%%  Guarantee
% This algorithm attempts to calculate the mean, mu, of a random variable
% to a prescribed error tolerance, tolfun:= max(abstol,reltol*| mu |), with
% guaranteed confidence level 1-alpha. If the algorithm terminated without
% showing any warning messages and provide an answer tmu, then the follow
% inequality would be satisfied:
% 
% Pr(| mu - tmu | <= tolfun) >= 1-alpha
% 
% The cost of the algorithm, N_tot, is also bounded above by N_up, which is
% defined in terms of abstol, reltol, nSig, n1, fudge, kurtmax, beta. And
% the following inequality holds:
% 
% Pr (N_tot <= N_up) >= 1-beta
%
% Please refer to our paper for detailed arguments and proofs.
%
%% Examples
%
%%
% *Example 1*

% Calculate the mean of x^2 when x is uniformly distributed in
% [0 1], with the absolute error tolerance = 1e-3 and uncertainty 5%.

  in_param.reltol=0; in_param.abstol = 1e-3;in_param.reltol = 0;
  in_param.alpha = 0.05; Yrand=@(n) rand(n,1).^2;
  tmu = meanMC_g(Yrand,in_param)

%%
% *Example 2*

% Calculate the mean of exp(x) when x is uniformly distributed in
% [0 1], with the absolute error tolerance 1e-3.

  tmu = meanMC_g(@(n)exp(rand(n,1)),1e-3,0)

%%
% *Example 3*

% Calculate the mean of cos(x) when x is uniformly distributed in
% [0 1], with the relative error tolerance 1e-2 and uncertainty 0.05.

  tmu = meanMC_g(@(n)cos(rand(n,1)),'reltol',1e-2,'abstol',0,...
      'alpha',0.05)
%% See Also
%
% <html>
% <a href="help_funappx_g.html">funappx_g</a>
% </html>
%
% <html>
% <a href="help_integral_g.html">integral_g</a>
% </html>
%
% <html>
% <a href="help_cubMC_g.html">cubMC_g</a>
% </html>
%
% <html>
% <a href="help_meanMCBer_g.html">meanMCBer_g</a>
% </html>
%
% <html>
% <a href="help_cubSobol_g.html">cubSobol_g</a>
% </html>
%
% <html>
% <a href="help_cubLattice_g.html">cubLattice_g</a>
% </html>
%
%% References
%
% [1]  F. J. Hickernell, L. Jiang, Y. Liu, and A. B. Owen, _Guaranteed
% conservative fixed width confidence intervals via Monte Carlo
% sampling,_ Monte Carlo and Quasi-Monte Carlo Methods 2012 (J. Dick, F.
% Y. Kuo, G. W. Peters, and I. H. Sloan, eds.), Springer-Verlag, Berlin,
% 2014. arXiv:1208.4318 [math.ST]
%          
% [2]  Sou-Cheng T. Choi, Yuhan Ding, Fred J. Hickernell, Lan Jiang,
% Lluis Antoni Jimenez Rugama, Xin Tong, Yizhi Zhang and Xuan Zhou,
% GAIL: Guaranteed Automatic Integration Library (Version 2.1) [MATLAB
% Software], 2015. Available from http://code.google.com/p/gail/
%
% [3] Sou-Cheng T. Choi, _MINRES-QLP Pack and Reliable Reproducible
% Research via Supportable Scientific Software,_ Journal of Open Research
% Software, Volume 2, Number 1, e22, pp. 1-7, 2014.
%
% [4] Sou-Cheng T. Choi and Fred J. Hickernell, _IIT MATH-573 Reliable
% Mathematical Software_ [Course Slides], Illinois Institute of
% Technology, Chicago, IL, 2013. Available from
% http://code.google.com/p/gail/ 
%
% [5] Daniel S. Katz, Sou-Cheng T. Choi, Hilmar Lapp, Ketan Maheshwari,
% Frank Loffler, Matthew Turk, Marcus D. Hanwell, Nancy Wilkins-Diehr,
% James Hetherington, James Howison, Shel Swenson, Gabrielle D. Allen,
% Anne C. Elster, Bruce Berriman, Colin Venters, _Summary of the First
% Workshop On Sustainable Software for Science: Practice And Experiences
% (WSSSPE1),_ Journal of Open Research Software, Volume 2, Number 1, e6,
% pp. 1-21, 2014.
%
% If you find GAIL helpful in your work, please support us by citing the
% above papers, software, and materials.
%
