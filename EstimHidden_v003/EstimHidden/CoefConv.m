function [gD,NormgD] = CoefConv(W0,Dtab,M,s0,FTtrue)

global lesZ lesY

if nargin<5, FTtrue=0; end

% if FTtrue==0 compute empirical Fourier Transform
% using fname as the error density
% 
% if FTtrue~=0 compute Fourier Transform
% of the normalized true density 

N = 2^M; % power used for FFT

freq = -(2*(0:N-1)'-N)/N*pi; 
% Dmax = max(Dtab);

Dfreq = freq*Dtab; % N x nD

if ~FTtrue
    [Re,Im] = FTempiric(Dfreq,lesZ,lesY);
    Xk = (Re+i*Im)./feval(['FT' W0],Dfreq,s0^2);
else
    Xk = feval(['FT' W0],Dfreq,s0^2);
end; 

xj = ifft(Xk,[],1); % N x nD
gD = diag((-1).^(0:N-1))*xj*diag(sqrt(Dtab)); % N x nD normalizedby sqrt(D)

Xk = conj(Xk);
xj = ifft(Xk,[],1);
hD = diag((-1).^(0:N-1))*xj*diag(sqrt(Dtab));

gD = real([hD(end:-1:2,:);gD]); % the FT coefs are real.

if nargout<2, NormgD=nan; return; end;


%%%% After follow extra .... only used for article


if ~isempty(Z)
    NormgD = -sum(abs(gD).^2,1); % contrast
else
    if ~strmatch('stable',ername), NormgD = nan; return, end;
%     we compute the squared bias
    switch (ername)
        case 'normal'
            NormgD = erfc(s0*pi*Dtab)/2/s0/sqrt(pi);
        case 'mixgauss'
            NormgD = zeros(size(Dtab));
        case 'chi2_3'
            K = pi*Dtab/sqrt(6);
            NormgD = 3*pi/4-6/4*atan(K)-K.*(5+3*K.^2)./(1+K.^2).^2/2;
            NormgD = sqrt(6)*NormgD;
        case 'unif'
            NormgD = 1/3/pi^2/s0^2./Dtab/2;
        case 'exprnd'
            spD = pi*Dtab;
            NormgD = atan(spD)/pi;
        case 'symexp'
            spD = s0*pi*Dtab/sqrt(2);
            NormgD = 1/2/sqrt(2)/s0 - Dtab/2./(1+spD.^2) - atan(spD)/sqrt(2)/pi/s0;
        case 'gamma2'
            pD = pi*Dtab/sqrt(6);
            NormgD = (2*pD.^3-3*pD)/3./(1+pD.^2).^3 +0.5*(atan(1./pD) - pD./(1+pD.^2)); 
            NormgD = NormgD*sqrt(6)/2/pi;
        case 'gamma15'
            pD = pi*Dtab/sqrt(15/4);
            NormgD = 1 - pD./sqrt(1+pD.^2) - pD./(1+pD.^2).^2; 
            NormgD = NormgD*sqrt(15/4)/2/pi;
        case 'gamma25'
            pD = pi*Dtab/sqrt(35/4);
            NormgD = 2/3 - pD./sqrt(1+pD.^2) + ...
                (pD.^3-pD)./(1+pD.^2).^4 + ...
                pD.^3./(1+pD.^2).^(3/2)/3;
            NormgD = NormgD*sqrt(35/4)/2/pi;
        case 'cauchy'
            NormgD = exp(-2*pi*Dtab*s0)/s0;
        case 'stable14'
            pD = pi*Dtab;
            NormgD=exp(-2*pD.^0.25).*(2*pD.^0.75+3*pD.^0.5+3*pD.^0.25+1.5)/pi;
        case 'stable12'
            pD = pi*Dtab;
            NormgD=exp(-2*pD.^0.5).*(pD.^0.5+0.5)/pi;
        case 'stable34'
            pD = pi*Dtab;
            NormgD = 0.8465818119e-1*pD.*(...
                15.74960994*exp(-2*pD.^(3/4))./pD.^(3/4)+...
                4.166824566*gammainc(0.3333333333, 2*pD.^(3/4))./pD);
        otherwise 
            NormgD = nan*zeros(size(Dtab));
    end;
end;

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


