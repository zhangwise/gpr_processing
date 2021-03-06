function [sonicnew,depthnew]=cscali(sonic,depth,cst,csz)
% [sonicnew,depthnew]=cscali(sonic,depth,cst,csz)
%
% cscali is a function that will take time-depth pairs from checkshots or
% VSP data and calibrate the sonic log to these times.  It is important
% that the sonic log does not contain any null values (interpolate if the
% log is not continous).  The depth log should be the same length as the
% sonic log.
%
% sonic - the sonic log before calibration
% depth - the depth log corresponding to the sonic log
% cst   - a vector of time for each checkshot or VSP measurement
% csz   - a vector of time for each checkshot or VSP measurement
%
% sonicnew - new calibrated sonic
% depthnew - new depth vector starting at 0
%
% H.J.E. Lloyd November 2013
%
% NOTE: It is illegal for you to use this software for a purpose other
% than non-profit education or research UNLESS you are employed by a CREWES
% Project sponsor. By using this software, you are agreeing to the terms
% detailed in this software's Matlab source file.
 
% BEGIN TERMS OF USE LICENSE
%
% This SOFTWARE is maintained by the CREWES Project at the Department
% of Geology and Geophysics of the University of Calgary, Calgary,
% Alberta, Canada.  The copyright and ownership is jointly held by 
% its author (identified above) and the CREWES Project.  The CREWES 
% project may be contacted via email at:  crewesinfo@crewes.org
% 
% The term 'SOFTWARE' refers to the Matlab source code, translations to
% any other computer language, or object code
%
% Terms of use of this SOFTWARE
%
% 1) Use of this SOFTWARE by any for-profit commercial organization is
%    expressly forbidden unless said organization is a CREWES Project
%    Sponsor.
%
% 2) A CREWES Project sponsor may use this SOFTWARE under the terms of the 
%    CREWES Project Sponsorship agreement.
%
% 3) A student or employee of a non-profit educational institution may 
%    use this SOFTWARE subject to the following terms and conditions:
%    - this SOFTWARE is for teaching or research purposes only.
%    - this SOFTWARE may be distributed to other students or researchers 
%      provided that these license terms are included.
%    - reselling the SOFTWARE, or including it or any portion of it, in any
%      software that will be resold is expressly forbidden.
%    - transfering the SOFTWARE in any form to a commercial firm or any 
%      other for-profit organization is expressly forbidden.
%
% END TERMS OF USE LICENSE

if csz(1)~=0
    csz=[0;csz(:)];
    cst=[0;cst(:)];
else
    csz=csz(:);
    cst=cst(:);
end
t=0:.0005:max(cst)*3;

if depth(1)~=0
tnot=pchip(csz,cst,depth(1));
dz=depth(2)-depth(1);
z=0:dz:max(depth);
snew=zeros(size(z));
snew(1:near(z,depth(1)))=10^6/(depth(1)/tnot);
ind=near(z,depth(1)):length(z);
snew(ind)=pchip(depth,sonic,z(ind));
else
    snew=sonic(:);
    z=depth(:);
end


for k=2:length(cst)
[tz,zt,vins]=sonic2tz(snew(:),z(:),-10000);
tz=tz/2;
tlog=pchip(zt,tz,csz(k));
iz1=near(z,csz(k-1));iz1=iz1(1);
iz2=near(z,csz(k));iz2=(iz2(end));
snew(iz1:iz2)=snew((iz1:iz2))+10^6./((csz(k)-csz(k-1))/(cst(k)-tlog));
end
sonicnew=snew(:);
depthnew=z(:);