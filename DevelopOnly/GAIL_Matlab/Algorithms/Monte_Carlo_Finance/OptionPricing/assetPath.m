classdef assetPath < brownianMotion

%% assetPath
% is a class of discretized stochastic processes that model the values of
% an asset with respect to time. Browniam motions are used to construct
% these asset paths.
% 
%7/4/2016

% Example 1
% >> obj = assetPath
% obj = 
%   assetPath with properties:
% 
%                 inputType: 'n'
%        timeDim_timeVector: [1 2 3]
%         timeDim_startTime: 1
%           timeDim_endTime: 3
%          timeDim_initTime: 0
%         timeDim_initValue: 10
%        wnParam_sampleKind: 'IID'
%       wnParam_distribName: 'Gaussian'
%          wnParam_xDistrib: 'Uniform'
%      bmParam_assembleType: 'diff'
%       assetParam_pathType: 'GBM'
%      assetParam_initPrice: 10
%       assetParam_interest: 0.0100
%     assetParam_volatility: 0.5000

% Authors: Fred J. Hickernell, Xiaoyang Zhao, Tianci Zhu

%% Properties
% This process inherits properties from the |brownianMotion| class.  Below
% are values assigned to that are abstractly defined in that class plus
% some properties particulary for this class.

   properties (SetAccess=public) %so they can only be set by the constructor
      assetParam = struct('pathType','GBM', ... %type of asset path
         'initPrice', 10, ... %initial asset price
         'interest', 0.01, ... %interest rate
         'volatility', 0.5,... %volatility      
         'drift', 0,... %drift
         'nAsset', 1,... %number of assets 
         'corrMat', 1,...%A transpose  
         'dividend',0,...% dividend
         'Vinst',0.04,...%instantaneous variance
         'Vlong',0.04,...%long term variance
         'kappa',0.5,...%mean reversion speed
         'nu',1,...%volatility of variance
         'rho',-0.9)%correlation of the Brownian motions
   end
   
   properties (Constant, Hidden) %do not change & not seen

      allowPathType = {'GBM','QE_m','QE'} 
         %kinds of asset paths that we can generate
   end
   
   properties (Constant)
       psiC=1.5,% Between 1 and two. Threshold for different estimation distributions
%        gamma1=0.5%For PredictorCorrector
%        gamma2=0.5%For PredictorCorrector
   end
   
   properties (Dependent = true)
       sqCorr
   end
 


%% Methods
% The constructor for |assetPath| uses the |brownianMotion| constructor and
% then parses the other properties. The function |genStockPaths| generates
% the asset paths based on |whiteNoise| paths.

   methods
        
      % Creating an asset path process
      function obj = assetPath(varargin)         
         obj@brownianMotion(varargin{:}) %parse basic input
         if nargin>0
            val=varargin{1};
            if isa(val,'assetPath')
               obj.assetParam = val.assetParam;
               if nargin == 1
                  return
               end
            end
            if isfield(obj.restInput,'assetParam')
               val = obj.restInput.assetParam;
               obj.assetParam = val;
               obj.restInput = rmfield(obj.restInput,'assetParam');
            end
         end
         obj.timeDim = struct('initTime',0, ...
            'initValue',obj.assetParam.initPrice,...
            'dim',obj.assetParam.nAsset* ...
            (1+(strcmp(obj.assetParam.pathType,'QE')|strcmp(obj.assetParam.pathType,'QE_m')))); %add extra BM for variance process
      end
           
      % Set the properties of the payoff object
      function set.assetParam(obj,val)
         if isfield(val,'pathType') %data for type of option
            assert(any(strcmp(val.pathType,obj.allowPathType)))
            obj.assetParam.pathType=val.pathType; %row
         end
         if isfield(val,'nAsset') %data for number of assets
            validateattributes(val.nAsset,{'numeric'}, ...
               {'nonnegative'})
            obj.assetParam.nAsset=val.nAsset; %row
         end
         if isfield(val,'initPrice') %data for type of option
            validateattributes(val.initPrice,{'numeric'}, ...
               {'nonnegative'})
           if numel(val.initPrice) == obj.assetParam.nAsset
                obj.assetParam.initPrice=val.initPrice(:);
           else
              obj.assetParam.initPrice ...
                    =repmat(val.initPrice(1),obj.assetParam.nAsset,1);
           end  
         end
         if isfield(val,'interest') %data for type of option
            validateattributes(val.interest,{'numeric'}, ...
               {'nonnegative'})
            obj.assetParam.interest=val.interest(:); 
         end
         if isfield(val,'volatility') %data for type of option
            validateattributes(val.volatility,{'numeric'}, ...
               {'nonnegative'})
           if numel(val.volatility) == obj.assetParam.nAsset
            obj.assetParam.volatility=val.volatility(:); %row
           else
                obj.assetParam.volatility ...
                    =repmat(val.volatility(1),obj.assetParam.nAsset,1);
           end
         end
         if isfield(val,'corrMat') %data for A
            validateattributes(val.corrMat,{'numeric'}, ...
               {'nonnegative'})
            obj.assetParam.corrMat=val.corrMat; %row
         end
         if isfield(val,'drift') %data for type of option
            validateattributes(val.drift,{'numeric'}, ...
               {'scalar'})
            obj.assetParam.drift=val.drift; %row
         end
         if isfield(val,'dividend')
             validateattributes(val.dividend,{'numeric'},...
                 {'nonnegative'})
             obj.assetParam.dividend=val.dividend;
         end
         if isfield(val,'Vinst')
             validateattributes(val.Vinst,{'numeric'},...
                 {'scalar'})
             obj.assetParam.Vinst=val.Vinst;
         end
         if isfield(val,'Vlong')
             validateattributes(val.Vlong,{'numeric'},...
                 {'scalar'})
             obj.assetParam.Vlong=val.Vlong;
         end
         if isfield(val,'kappa')
             validateattributes(val.kappa,{'numeric'},...
                 {'scalar'})
             obj.assetParam.kappa=val.kappa;
         end
         if isfield(val,'nu')
             validateattributes(val.nu,{'numeric'},...
                 {'scalar'})
             obj.assetParam.nu=val.nu;
         end
         if isfield(val,'rho')
             validateattributes(val.rho,{'numeric'},...
                 {'scalar'})
             obj.assetParam.rho=val.rho;
         end
                  
      end
      
      % Generate square root of correlation matrix
       function val = get.sqCorr(obj)
          [U,S] = svd(obj.assetParam.corrMat);
          val = sqrt(S)*U';
       end
     
      % Generate asset paths
      function [paths]=genPaths(obj,val)
         bmpaths = genPaths@brownianMotion(obj,val);
         nPaths = size(bmpaths,1);             
         if strcmp(obj.assetParam.pathType,'GBM')
            tempc=zeros(nPaths,obj.timeDim.nSteps);
            paths=zeros(nPaths,obj.timeDim.nCols);
            % size_GBM = size(paths)
            for idx=1:obj.assetParam.nAsset
              colRange = ...
                 ((idx-1)*obj.timeDim.nSteps+1):idx*obj.timeDim.nSteps;
              for j=1:obj.timeDim.nSteps
                 tempc(:,j)=bmpaths(:,j:obj.timeDim.nSteps:obj.timeDim.nCols) ...
                    * obj.sqCorr(:,idx);
              end
              paths(:,colRange) = obj.assetParam.initPrice(idx) * ...
                 exp(bsxfun(@plus,(obj.assetParam.interest ...
                 - obj.assetParam.volatility(idx).^2/2) ...
                 .* obj.timeDim.timeVector, obj.assetParam.volatility(idx)...
                 .* tempc));
             end
         end
         if strcmp(obj.assetParam.pathType,'QE_m')
             dT = obj.timeDim.timeIncrement(1);
             gamma1 = (1-exp(obj.assetParam.kappa*dT)+obj.assetParam.kappa*dT)...
                 /(obj.assetParam.kappa*dT*(1-exp(obj.assetParam.kappa*dT)));
             gamma2 = -(-expm1(dT*obj.assetParam.kappa)+obj.assetParam.kappa*dT*exp(obj.assetParam.kappa*dT))...
                 /(obj.assetParam.kappa*dT*(-expm1(dT*obj.assetParam.kappa)));
             K1 = gamma1*dT*(obj.assetParam.rho*obj.assetParam.kappa/obj.assetParam.nu-0.5) - obj.assetParam.rho/obj.assetParam.nu;
             K2 = gamma2*dT*(obj.assetParam.rho*obj.assetParam.kappa/obj.assetParam.nu-0.5) + obj.assetParam.rho/obj.assetParam.nu;
             K3 = gamma1*dT*(1 - obj.assetParam.rho^2);
             K4 = gamma2*dT*(1 - obj.assetParam.rho^2);
             c1 = (obj.assetParam.interest-obj.assetParam.dividend)*dT;
             
%change Ntime to timeDim.nSteps ***********************************%    
             Ntime = obj.timeDim.nSteps;
             paths = zeros(nPaths,Ntime);
             lnS1 = zeros(nPaths,Ntime+1);
             % set S(0) adjust with dividend 
             lnS1(:,1)= log(obj.assetParam.initPrice...
                 *exp(-obj.assetParam.dividend*obj.timeDim.endTime));            
             
             V2 = zeros(nPaths,Ntime+1);
             V2(:,1) = obj.assetParam.Vinst; % set V0
            
             UV1 = rand(nPaths,Ntime);
             
             if Ntime==1
                 dW2=bmpaths(:,1);
             else
                normpath1=bmpaths(:,1:Ntime-1);
                normpath2=bmpaths(:,2:Ntime);
                normpathdiff1=normpath2-normpath1;
                dW2=[normpath1(:,1) normpathdiff1]/sqrt(dT);
             end
             
             if Ntime==1
                 Z=bmpaths(:,Ntime+1);
             else
                normpath3=bmpaths(:,Ntime+1:2*Ntime-1);
                normpath4=bmpaths(:,Ntime+2:2*Ntime);
                normpathdiff2=normpath4-normpath3;
                Z=[normpath3(:,1) normpathdiff2]/sqrt(dT);
             end
%*******************************************************************
% set U=V-Vlong
             U = zeros(nPaths,Ntime+1);
             U(:,1)=V2(:,1) - obj.assetParam.Vlong; % set U0
             VRing = zeros(nPaths,Ntime+1);
             k1 = exp(-obj.assetParam.kappa*dT);

             for i=2:Ntime+1 %obj.timeDim.nSteps             % time loop
                 m = obj.assetParam.Vlong+U(:,i-1).*k1;% mean (moment matching)
                 s2 =(U(:,i-1)+obj.assetParam.Vlong).*k1./obj.assetParam.kappa...
                     *(-expm1(-dT*obj.assetParam.kappa))+obj.assetParam.Vlong...
                     /2/obj.assetParam.kappa*(-expm1(-dT*obj.assetParam.kappa))^2;   % var (moment matching)
                 psi = s2./m.^2;   % psi_tilde compared to psiC
                 binv2 = psi./(2*sqrt(1-psi.*obj.assetParam.nu^2/2).*(1+sqrt(1-psi*obj.assetParam.nu^2/2)));
                 a = m.*binv2 ./ (1 +obj.assetParam.nu^2*binv2);
                 
                 % Non-Central Chi squared approximation for psi < psiC
                 I1 = find(obj.assetParam.nu==0 |obj.assetParam.nu^2*psi<=obj.psiC);                 
                 if isempty(I1)
                 else                     
                     U(I1,i) = -obj.assetParam.Vlong + m(I1)./(1+obj.assetParam.nu^2*binv2(I1))...
                         .*(1+obj.assetParam.nu*Z(I1,i-1).*sqrt(binv2(I1))).^2;
                     VRing(I1,i) = (m(I1)./(1+obj.assetParam.nu^2*binv2(I1))).*(obj.assetParam.nu*binv2(I1)...
                         .*(Z(I1,i-1).^2-1)+2*sqrt(binv2(I1)).*Z(I1,i-1));                    
                 end
                 p = (obj.assetParam.nu^2*psi - 1)./(obj.assetParam.nu^2*psi + 1);               % for switching rule
                 U(UV1(:,i-1)<=p & (obj.assetParam.nu^2*psi>obj.psiC),i) = -obj.assetParam.Vlong; % case u<=p & psi>psiC
                 I1b = find((UV1(:,i-1)>p) & (obj.assetParam.nu^2*psi>obj.psiC));% find is faster here!
                 beta = (1 - p)./m;                      % for switching rule
                 if isempty(I1b)
                 else    % Psi^(-1)
                     U(I1b,i) = -obj.assetParam.Vlong + log((1-p(I1b))./(1-UV1(I1b,i-1)))./beta(I1b);
                 end
                 % log Euler Predictor-Corrector step
                 Gammas = (-expm1(-dT*obj.assetParam.kappa))/obj.assetParam.kappa/dT*U(I1,i-1)+gamma2*obj.assetParam.nu*VRing(I1,i);
                 
                 A = obj.assetParam.rho*(gamma2*dT*obj.assetParam.kappa+1)-0.5*gamma2*dT*obj.assetParam.nu*obj.assetParam.rho^2; % scalar
                 denominator = 1 + obj.assetParam.nu^2*binv2(I1)-2*obj.assetParam.nu*binv2(I1).*m(I1)*A;
                 term1 = c1 + 0.5*gamma2*dT*obj.assetParam.rho^2*(obj.assetParam.Vlong + U(I1,i))./denominator + VRing(I1,i)*A./denominator... %K0 + K1V(t) + K2V(t+delta)
                      + 0.5*log(1-2*obj.assetParam.nu*A*a(I1))-0.5*gamma1*dT*(1-obj.assetParam.rho^2)*(obj.assetParam.Vlong+U(I1,i-1))-0.5*gamma2*dT*(obj.assetParam.Vlong+U(I1,i))...
                     +obj.assetParam.rho*(gamma2*dT*obj.assetParam.kappa+1)*(obj.assetParam.Vlong+U(I1,i)).*(obj.assetParam.nu*binv2(I1)-2*binv2(I1).*m(I1)*A)./denominator;
                 if isempty(I1)
                 else
                     lnS1(I1,i) = lnS1(I1,i-1) + term1 + sqrt(dT*(1-obj.assetParam.rho^2)*(obj.assetParam.Vlong+Gammas)).*dW2(I1,i-1);
                 end
                
                 I2 = find(obj.assetParam.nu^2*psi>obj.psiC);;
                 K0 = c1-log(p(I2)+beta(I2).*(1-p(I2))./(beta(I2)-A/obj.assetParam.nu));
                 if isempty(I2)
                 else
                     lnS1(I2,i) = lnS1(I2,i-1) + K0 + obj.assetParam.Vlong*(K1+K2) + K1*U(I2,i-1)...
                         + K2*U(I2,i) + dW2(I2,i-1).*sqrt(K3*U(I2,i-1) + K4*U(I2,i) + obj.assetParam.Vlong*(K3+K4));
                 end
             end
             paths(:,:) = exp(lnS1(:,2:end));
         end

         if strcmp(obj.assetParam.pathType,'QE')
             dT = obj.timeDim.timeIncrement(1);
             gamma1 = (1-exp(obj.assetParam.kappa*dT)+obj.assetParam.kappa*dT)...
                 /(obj.assetParam.kappa*dT*(1-exp(obj.assetParam.kappa*dT)));
             gamma2 = -(-expm1(dT*obj.assetParam.kappa)+obj.assetParam.kappa*dT*exp(obj.assetParam.kappa*dT))...
                 /(obj.assetParam.kappa*dT*(-expm1(dT*obj.assetParam.kappa)));          
             c1 = (obj.assetParam.interest-obj.assetParam.dividend)*dT;% interest and dividend adjustment 
             K0 = c1 - obj.assetParam.rho*obj.assetParam.kappa*obj.assetParam.Vlong*dT/obj.assetParam.nu;
             K1 = gamma1*dT*(obj.assetParam.rho*obj.assetParam.kappa/obj.assetParam.nu-0.5) - obj.assetParam.rho/obj.assetParam.nu;
             K2 = gamma2*dT*(obj.assetParam.rho*obj.assetParam.kappa/obj.assetParam.nu-0.5) + obj.assetParam.rho/obj.assetParam.nu;
             K3 = gamma1*dT*(1 - obj.assetParam.rho^2);
             K4 = gamma2*dT*(1 - obj.assetParam.rho^2);
       %change Ntime to timeDim.nSteps ***********************************%    
             Ntime = obj.timeDim.nSteps;
             paths = zeros(nPaths,Ntime);
             lnS1 = zeros(nPaths,Ntime+1);
             lnS1(:,1)= log(obj.assetParam.initPrice...  % set S(0) adjust with dividend 
                 *exp(-obj.assetParam.dividend*obj.timeDim.endTime));            
             
             V2 = zeros(nPaths,Ntime+1);
             V2(:,1) = obj.assetParam.Vinst; % set V0
             UV1 = rand(nPaths,Ntime);  
             
             if Ntime==1
                 dW2=bmpaths(:,1);
             else
                normpath1=bmpaths(:,1:Ntime-1);
                normpath2=bmpaths(:,2:Ntime);
                normpathdiff1=normpath2-normpath1;
                dW2=[normpath1(:,1) normpathdiff1]/sqrt(dT);
             end
             
             if Ntime==1
                 Z=bmpaths(:,Ntime+1);
             else
                normpath3=bmpaths(:,Ntime+1:2*Ntime-1);
                normpath4=bmpaths(:,Ntime+2:2*Ntime);
                normpathdiff2=normpath4-normpath3;
                Z=[normpath3(:,1) normpathdiff2]/sqrt(dT);
             end

%****************************************************************
% set U=V-Vlong
             U = zeros(nPaths,Ntime+1);
             U(:,1)=V2(:,1) - obj.assetParam.Vlong; % set U0
             VRing = zeros(nPaths,Ntime+1);
             k1 = exp(-obj.assetParam.kappa*dT);
             for i=2:Ntime+1;%obj.timeDim.nSteps             % time loop
                 m = obj.assetParam.Vlong+U(:,i-1).*k1;% mean (moment matching)
                 s2 =(U(:,i-1)+obj.assetParam.Vlong).*k1./obj.assetParam.kappa...
                     *(-expm1(-dT*obj.assetParam.kappa))+obj.assetParam.Vlong...
                     /2/obj.assetParam.kappa*(-expm1(-dT*obj.assetParam.kappa))^2;   % var (moment matching)
                 psi = s2./m.^2;   % psi_tilde compared to psiC
                 binv2 = psi./(2*sqrt(1-psi.*obj.assetParam.nu^2/2).*(1+sqrt(1-psi*obj.assetParam.nu^2/2)));

                % Non-Central Chi squared approximation for psi < psiC
                I1 = find(obj.assetParam.nu==0 |obj.assetParam.nu^2*psi<=obj.psiC);
                if isempty(I1)
                else
                    U(I1,i) = -obj.assetParam.Vlong + m(I1)./(1+obj.assetParam.nu^2*binv2(I1))...
                        .*(1+obj.assetParam.nu*Z(I1,i-1).*sqrt(binv2(I1))).^2;
                    VRing(I1,i) = (m(I1)./(1+obj.assetParam.nu^2*binv2(I1))).*(obj.assetParam.nu*binv2(I1)...
                        .*(Z(I1,i-1).^2-1)+2*sqrt(binv2(I1)).*Z(I1,i-1));
                end
                p = (obj.assetParam.nu^2*psi - 1)./(obj.assetParam.nu^2*psi + 1);               % for switching rule
                U(UV1(:,i-1)<=p & (obj.assetParam.nu^2*psi>obj.psiC),i) = -obj.assetParam.Vlong; % case u<=p & psi>psiC
                I1b = find((UV1(:,i-1)>p) & (obj.assetParam.nu^2*psi>obj.psiC));% find is faster here!

                beta = (1 - p)./m;                      % for switching rule
                if isempty(I1b)
                else    % Psi^(-1)
                    U(I1b,i) = -obj.assetParam.Vlong + log((1-p(I1b))./(1-UV1(I1b,i-1)))./beta(I1b);
                end
                % log Euler Predictor-Corrector step
                Gammas = (-expm1(-dT*obj.assetParam.kappa))/obj.assetParam.kappa/dT*U(I1,i-1)+gamma2*obj.assetParam.nu*VRing(I1,i);
                if isempty(I1)
                else
                    lnS1(I1,i) = lnS1(I1,i-1) + c1 - obj.assetParam.Vlong*dT/2 - dT/2*Gammas + obj.assetParam.rho*(obj.assetParam.kappa*dT*exp(obj.assetParam.kappa*dT)...
                        /(expm1(dT*obj.assetParam.kappa))*VRing(I1,i))+sqrt(dT*(1-obj.assetParam.rho^2)*(obj.assetParam.Vlong+Gammas)).*dW2(I1,i-1);
                end
                I2 = ~I1;
                if isempty(I2)
                else
                    lnS1(I2,i) = lnS1(I2,i-1) + K0 + obj.assetParam.Vlong*(K1+K2) + K1*U(I2,i-1)...
                        + K2*U(I2,i) + dW2(I2,i-1).*sqrt(K3*U(I2,i-1) + K4*U(I2,i) + obj.assetParam.Vlong*(K3+K4));
                end
             end          
             paths(:,:) = exp(lnS1(:,2:end));   
         end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      end
   end
  

   methods (Access = protected)

      function propList = getPropertyList(obj)
          if strcmp(obj.assetParam.pathType,'GBM')
            propList = getPropertyList@brownianMotion(obj);
            propList.assetParam_pathType = obj.assetParam.pathType;
            propList.assetParam_initPrice = obj.assetParam.initPrice;
            propList.assetParam_interest = obj.assetParam.interest;
            propList.assetParam_volatility = obj.assetParam.volatility;
            if obj.assetParam.drift ~=0
                propList.assetParam_drift = obj.assetParam.drift;
            end
            propList.assetParam_nAsset = obj.assetParam.nAsset;
         else
            propList = getPropertyList@brownianMotion(obj);
            propList.assetParam_pathType = obj.assetParam.pathType;
            propList.assetParam_initPrice = obj.assetParam.initPrice;
            propList.assetParam_interest = obj.assetParam.interest;
            propList.assetParam_dividend = obj.assetParam.dividend;
            propList.assetParam_Vinst = obj.assetParam.Vinst;
            propList.assetParam_Vlong = obj.assetParam.Vlong;
            propList.assetParam_kappa = obj.assetParam.kappa;
            propList.assetParam_nu = obj.assetParam.nu;
            propList.assetParam_rho = obj.assetParam.rho;
          end              
          
      end

   end

end
