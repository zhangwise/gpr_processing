function [Obs,isautoregressive,X] = DeconvSimul(name,n,W0,s0,B,s)

densitycase = (nargin<5);
if nargin<6, s=[]; end

% Draw random observations for 
%
%   density deconvolution with observations Z=X+s0.e0 where X i.i.d f
% or 
%   regression with errors in variable with
%   observations Z=X+s0.e0 with X i.i.d. f and Y=b(X)+s(X).e
% or 
%   autoregression with errors in variable with
%   observations Z=X+s0.e0 with X satisfies X[i+1]=b(X[i])+s(X[i]).e[i+1]
%
% name = model name
% n = sample size
% W0 = type of convolution noise e0 (known)
% s0 = standard deviation of convolution noise e0 (known)
% B = type of regression noise e (unknown)
% s = standard deviation of regression noise e (unknown) 
%   (if s is missing use default values of previous papers)
%
% The model is assumed to be a density convolution model 
% if only 4 parameters are given to the function
%
% Return
% Z the density observations
% Y the regression observations 
% and
% (u,v) the coordinates of 
%       the true f (density deconvolution case)
%       or
%       the true b (regression case)
% (u,w) the coordinates of the true s (regression case)
%
% W0 the noise type to use for estimation (usefull only to test
% misspecification of noise type)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the unobservable X
if densitycase % ONLY for DENSITY CASES
    if strmatch('dependent',name) 
        % special case for dependent data
        X = feval(name(1:10),str2num(name(12:end)),n);
        switch (name(1:10))
            case 'dependent1'
                name='normal';
            case 'dependent2'
                name='mixgauss';
        end;
    elseif strmatch('GARCH',name)
        % W0 is alpha
        % s0 is beta
        X = GARCH(n,W0,s0,2000);
    else
        % general density case
        X = feval(name,1,n,1); 
    end;
    isautoregressive = 0;
else % ONLY for REGRESSION and AUTO-REGRESSION CASES
    [X,isautoregressive] = RegressionAbs(name,n,s); % UNOBSERVABLE
end; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the OBSERVABLE noisy Z
if strmatch('Wmix',W0)
  e0 = Wmix(1,length(X),1,str2num(W0(7:end)));
  switch(W0(5))
    case '1'
      W0 = 'symexp';
    case '2'
      W0 = 'normal';
  end;
else
  e0 = feval(W0(1:6),1,length(X)); 
end;

Z = X + s0*e0;

Obs.isauto = nan;
Obs.Z = Z;
Obs.W0 = W0;
Obs.s0 = s0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if densitycase, Obs.Y=nan; return, end; % STOP because density case 


% REGRESSION CASE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the noisy Y
if isautoregressive
    Obs.Y = Z(2:end);
    Obs.Z = Z(1:end-1);
    X = X(1:end-1);
    Obs.isauto = 1;
else
    if strmatch('Wmix',B)
      e = Wmix(1,length(X),1,str2num(B(7:end)));
      switch(B(5))
        case '1'
          B = 'symexp'
        case '2'
          B = 'normal'
      end;
    else
      e = feval(B,1,length(X));
    end;
    Obs.Y = drift0(X,name) + s*volatility0(X,name).*e; % OBSERVABLE constructed on the UNOBSERVABLE
                            % s=1 as volatility use already default values
    Obs.isauto = 0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%












%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [X,isautoregressive] = RegressionAbs(name,n,s)

if nargin<3, s=[]; end

% Return 
%   the abscissa of the 'regression with errors in variable' model
% or
%   the autoregressive trajectory 

isautoregressive = 0;

switch(name)
    case {'fan','truong'}
        X = 0.25*randn(n,1)+0.5;
    case {'RM9','RM10','RM11'}
        X = 4*rand(n,1)-2;
    otherwise % AUTOREGRESSIVE MODELS
        isautoregressive = 1;
        X = zeros(1001+n,1);
        N = randn(size(X));
        for i=1:n+1000
        	X(i+1)=drift0(X(i),name)+s*volatility0(X(i),name)*N(i);
        end
        X = X(1001:end);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is part of the package EstimHidden devoted to the estimation of 
%
% 1/ the density of X in a convolution model where Z=X+noise1 is observed 
%
% 2/ the functions b (drift) and s^2 (volatility) in an "errors in variables" 
%    model where Z and Y are observed and assumed to follow:
%           Z=X+noise1 and Y=b(X)+s(X)*noise2.
%
% 3/ the functions b (drift) and s^2 (volatility) in an stochastic
%    volatility model where Z is observed and follows:
%           Z=X+noise1 and X_{i+1} = b(X_i) + s(X_i)*noise2
%
% in any cases the density of noise1 is known. We consider three cases for
% this density : Gaussian ('normal'), Laplace ('symexp') and log(Chi2)
% ('logchi2)
%
% See function DeconvEstimate.m and examples in files ExampleDensity.m and
% ExampleRegression.m
%
% Authors : F. COMTE and Y. ROZENHOLC 
%
%
% For more information, see the following references:
%
% DENSITY DECONVOLUTION
%%%%%%%%%%%%%%%%%%%%%%%
%
% 1/ "Penalized contrast estimator for density deconvolution", 
%    The Canadian Journal of Statistics, 34, 431-452, 2006.
%    b y  F .  C O M T E ,  Y .  R O Z E N H O L C ,  and M . - L .  T A U P I N 
%
% 2/ "Finite sample  penalization in adaptive density deconvolution", 
%    Journal of Statistical Computation and Simulation. 
%    Available online.
%    b y  F .  C O M T E ,  Y .  R O Z E N H O L C ,  and M . - L .  T A U P I N 
%
% 3/ "Adaptive density estimation for general ARCH models", 
%    Preprint HAL-CNRS : hal-00101417  at http://hal.archives-ouvertes.fr/
%    b y  F .  C O M T E ,  J. DEDECKER, and  M . - L .  T A U P I N . 
%
% REGRESSION and AUTO-REGRESSION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 4/ "Nonparametric estimation of the regression function in an
%    errors-in-variables model", 
%    Statistica Sinica, 17, n�3, 1065-1090, 2007. 
%    b y  F .  C O M T E  and M . - L .  T A U P I N 
%
% 5/ "Adaptive estimation of the dynamics of a discrete time stochastic
%    volatility model", 
%    Preprint HAL-CNRS : hal-00170740 at http://hal.archives-ouvertes.fr/
%    by F .  C O M T E, C. LACOUR, and Y. R O Z E N H O L C . 
%
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %
 % Y o u  c a n  u s e  t h i s  s o f t w a r e  f o r  N O N - C O M M E R C I A L  U S E  O N L Y .  
 %
 % Y o u  c a n  d i s t r i b u t e  t h i s  s o f w a r e  u n c h a n g e d  a n d  o n l y  u n c h a n g e d ,  w h i c h  i m p l i e s 
 % i n c l u d i n g  a l l  f i l e s  f o u n d  i n  t h e  f o l d e r  c o i n t a i n n i n g  t h i s  f i l e . 
 %
 % T h i s  s o f t w a r e ,  a n d  a n y  p a r t  o f  i t ,  i s  p r o p o s e d  f o r  N O N - C O M M E R C I A L  U S E  
 % O N L Y .  
 %
 % P l e a s e ,  c o n t a c t  t h e  a u t h o r  f o r  a n d  b e f o r e  a n y  n o n - a c a d e m i c  u s e 
 % o f  t h i s  s o f t w a r e . 
 %
 % T o  r e p r o d u c e  t h i s  c o d e  o r  a n y  p a r t  o f  t h i s  c o d e  i n  t h e  o r i g i n a l  l a n g u a g e  
 % o r  i n  a n y  o t h e r  l a n g u a g e ,  f o r  c o m m e r c i a l  u s e ,  p l e a s e  c o n t a c t  t h e  A u t h o r 
 %
 % F o r  a c a d e m i c  p u r p o s e ,  c i t e  this package and t h e  c o n n e c t e d  p a p e r s . 
 %
 % C o r r e s p o n d i n g  a u t h o r  :  Y .  R o z e n h o l c ,  y v e s . r o z e n h o l c @ u n i v - p a r i s 5 . f r 
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Examples in files ExampleDensity.m and ExampleRegression.m
% 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 













