%% Pricing Options Using Quasi-Monte Carlo Sampling
% Most of our Monte Carlo methods have relied on independent and
% identically distributed (IID) samples.  But we can often compute the
% answer faster by using _low discrepancy_ or _highly stratified_ samples.
% This demo shows the advantages for some of the option pricing problems
% that have been studied using IID sampling.

%% Different sampling strategies
% We consider the problem of sampling uniformly on the unit cube, \([0,1]^d\). 
% For illustration we choose \(d = 2\).  Here are \(n=256\) IID samples

InitializeWorkspaceDisplay %initialize the workspace and the display parameters
d = 2; %dimension
n = 256; %number of samples
xIID = rand(n,d); %uniform (quasi-)random numbers
plot(xIID(:,1),xIID(:,2),'b.') %plot the points 
xlabel('$x_1$') %and label
ylabel('$x_2$') %the axes
title('IID points')
axis square %make the aspect ratio equal to one

%%
% Since the points are IID, there are gaps and clusters.  The points do not
% know about the locations of each other.
%
% One way to sample more _evenly_ is to use Sobol' points.  Here is a plot
% of the same number of _scrambled and shifted_ Sobol' points. They are
% also random, but not IID.

figure
sob = scramble(sobolset(d),'MatousekAffineOwen'); %create a scrambled Sobol object
xSobol = net(sob,n); %the first n points of a Sobol' sequence
plot(xSobol(:,1),xSobol(:,2),'b.') %plot the points 
xlabel('$x_1$') %and label
ylabel('$x_2$') %the axes
title('Sobol'' points')
axis square %make the aspect ratio equal to one

%%
% Now the gaps and clusters are smaller are smaller.  The points _do_ know
% about the locations of each other.
%
% Another set of evenly distributed points are node sets of _integration
% lattices_.  They have more recognizable structure than Sobol' points.
% Here is an example.

figure
sob = scramble(sobolset(d),'MatousekAffineOwen'); %create a scrambled Sobol object
xLattice = mod(bsxfun(@plus,gail.lattice_gen(1,n,d),rand(1,d)),1); %the first n rank-1 lattice node sets, shifted
plot(xLattice(:,1),xLattice(:,2),'b.') %plot the points 
xlabel('$x_1$') %and label
ylabel('$x_2$') %the axes
title('Rank-1 lattice node set')
axis square %make the aspect ratio equal to one

%% Pricing the Asian Geometric Mean Call Option
% Now we set up the parameters for option pricing.  We consider first the
% Asian Geometric Mean Call with weeky monitoring for three months

inp.timeDim.timeVector = 1/52:1/52:1/4; %weekly monitoring for three months
inp.assetParam.initPrice = 100; %initial stock price
inp.assetParam.interest = 0.02; %risk-free interest rate
inp.assetParam.volatility = 0.5; %volatility
inp.payoffParam.strike = 100; %strike price
inp.payoffParam.optType = {'gmean'}; %looking at an arithmetic mean option
inp.payoffParam.putCallType = {'call'}; %looking at a put option
inp.priceParam.absTol = 0.005; %absolute tolerance of a one cent
inp.priceParam.relTol = 0; %zero relative tolerance

%% 
% The first method that we try is simple IID sampling

AMeanCallIID = optPrice(inp) %construct an optPrice object 
[AMeanCallIIDPrice,AoutIID] = genOptPrice(AMeanCallIID);
fprintf(['The price of the Asian geometric mean call option using IID ' ...
   'sampling is \n   $%3.3f +/- $%2.3f and this took %3.6f seconds\n'], ...
   AMeanCallIIDPrice,AMeanCallIID.priceParam.absTol,AoutIID.time)

%%
% Note that in this case we know the correct answer, and our IID Monte
% Carlo gives the correct answer.
% 
% Next we try Sobol' sampling and see a big speed up:

AMeanCallSobol = optPrice(AMeanCallIID); %make a copy of the IID optPrice object
AMeanCallSobol.priceParam.cubMethod = 'Sobol' %change to Sobol sampling
[AMeanCallSobolPrice,AoutSobol] = genOptPrice(AMeanCallSobol);
fprintf(['The price of the Asian geometric mean call option using Sobol'' ' ...
   'sampling is\n   $%3.3f +/- $%2.3f and this took %3.6f seconds,\n' ...
   'which is only %1.4f the time required by IID sampling\n'], ...
   AMeanCallSobolPrice,AMeanCallSobol.priceParam.absTol,AoutSobol.time, ...
   AoutSobol.time/AoutIID.time)

%%
% Again the answer provided is correct.  For a greater speed up, we may use
% the PCA construction, which reduces the effective dimension of the
% problem.

AMeanCallSobol.bmParam.assembleType = 'PCA'; %change to a PCA construction
[AMeanCallSobolPrice,AoutSobol] = genOptPrice(AMeanCallSobol);
fprintf(['The price of the Asian geometric mean call option using Sobol'' ' ...
   'sampling and PCA is\n   $%3.3f +/- $%2.3f and this took %3.6f seconds,\n' ...
   'which is only %1.4f the time required by IID sampling\n'], ...
   AMeanCallSobolPrice,AMeanCallSobol.priceParam.absTol,AoutSobol.time, ...
   AoutSobol.time/AoutIID.time)

%% 
% Another option is to use lattice sampling.

AMeanCallLattice = optPrice(AMeanCallSobol); %make a copy of the IID optPrice object
AMeanCallLattice.priceParam.cubMethod = 'lattice' %change to Sobol sampling
[AMeanCallLatticePrice,AoutLattice] = genOptPrice(AMeanCallLattice);
fprintf(['The price of the Asian geometric mean call option using lattice ' ...
   'sampling is\n   $%3.3f +/- $%2.3f and this took %3.6f seconds,\n' ...
   'which is only %1.4f the time required by IID sampling\n'], ...
   AMeanCallLatticePrice,AMeanCallLattice.priceParam.absTol,AoutLattice.time, ...
   AoutLattice.time/AoutIID.time)

%% 
% Note that the time is also less than for IID, but similar to that for
% Sobol' sampling.
%
% _Author: Fred J. Hickernell_
