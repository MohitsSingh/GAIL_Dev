%% Pricing an American Option with Monte Carlo Method
% An American Option is a type of option that can be exercised at any time 
% during its life. It is therefore more valuable than a European Option.
%
% There are two different types of options, *calls* and *puts*:
%
% * A call gives the holder the right to buy an asset at a certain price 
% within a specific period of time. Buyers of calls hope that the stock 
% will increase substantially before the option expires.
% * A put gives the holder the right to sell an asset at a certain price 
% within a specific period of time. Buyers of puts hope that the price of 
% the stock will fall before the option expires.
%
% However, we will only price the American put option and disregard the call
% option, because when dividends are ignored, the American call option is
% the same as the European call option.

%% The Payoffs of the American Option
%
% Call Option:
%
% \[\max(S(\tau)-K, 0)\]
%
% Put option:
%
% \[\max(K-S(t), 0)\]
%
% where:
%
% \(S(t)\) = the stock price at time t
%
% \(K\) = strike price
%
% \(\tau\) = the exercise time
%
% We apply the Longstaff and Schwartz Least Squares Method to price the 
% option. This method calculates the predicted future payoffs based on the 
% stock price paths generated, e.g. by geometric Brownian Motions. At each 
% time, we compare the predicted payoff of continuing with the payoff  
% exercising  option immediately. This determines whether or not an option 
% should be exercised. After this recursive process, the final American 
% option price is estimated as the average payoffs of all the paths.

%% Generate American Option Price using Monte Carlo Method
% The _optPrice_ , a MATLAB(R) class, generates the prices for options. 
% Using Monte Carlo Method. The _optPrice_ uses has many properties that 
% determine the option to be priced and the method for pricing it. The 
% _optPrice_ is based on a number of superclasses:
superclasses(optPrice)

%%
% To calculate the American option price, we first need to construct several parametrer values:
%Set the values used in Longstaff and Schwartz's paper:
initPrice = [36 38 40 42 44];
volatility = [0.2 0.4 0.2 0.4 0.2];
year = [1 2 1 2 1];

n=5;                                            % number of sampling
for i=1:n   
%Payoff Parameters:
inp.payoffParam.optType = {'american'};         % american Option
inp.payoffParam.putCallType = {'put'};          % put
inp.payoffParam.strike = 40;                    % strike price

%Asset Path Parameters: 
inp.assetParam.initPrice = initPrice(i);        % initial Asset Prices
inp.assetParam.interest = 0.06;                 % 1% interest rate
inp.assetParam.volatility = volatility(i);      % volatility

%Option Price Parameters
inp.priceParam.cubMethod = 'IID_MC';            % type of pricing scheme
inp.priceParam.absTol = 0.05;                   % 5% absolute tolerance
inp.priceParam.relTol = 0;                      

%Stochastic Process
inp.timeDim.timeVector = 1/50:1/50:year(i);     % Defining the Time as one trimester.

%%
% Then we generate a class that evaluates the option price.
tic, AmericanOption = optPrice(inp), toc

%%
% Now we generate the American option price using Independent Identically Distributed (IID) sampling
tic, iid_AmericanOptionPrice(i) = genOptPrice(AmericanOption);
, toc
end
iid_AmericanOptionPrice

%%
% Then we will check if the values we get are same as the results shown in
% Lonstaff and Schwartz's paper
LSResult = [4.472 7.669 2.313 6.243 1.118];
difference = abs(LSResult - iid_AmericanOptionPrice)
%%
% The function _genOptPrice_ is calledfrom the IID Monte Carlo method for 
% Finance in <https://code.google.com/p/gail/ GAIL> Repository(meanMC_g).

%% Plot of Payoffs Generated by Monte Carlo Method
% The plot of payoffs is generated below, which is a cumulative probability
% graph.
plot(AmericanOption,1e4)

%% References
%
% Longstaff, Francis, and Eduardo Schwartz. "Valuing American Option by 
% Simulation: A Simple Least-Squares Approach." Web. 28 July 2015.
%
% "American Option Definition | Investopedia." Investopedia. 18 Nov. 2003. 
% Web. 28 July 2015.