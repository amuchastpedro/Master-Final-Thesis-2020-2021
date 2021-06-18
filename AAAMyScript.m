clear all; clear session; close all; clc
addpath(genpath('C:\Users\USUARIO\Documents\Master in Economics\MFT\Matlab_Toolbox'))

%% Set up the Import Options and import the data

[y, xlstext] = xlsread("C:\Users\USUARIO\Documents\Master in Economics\MFT\Mexico\Input.xlsx",'Level');


%% First difference
% =======================================================================
[yd, xlstextd] = xlsread("C:\Users\USUARIO\Documents\Master in Economics\MFT\Mexico\Input.xlsx",'Diff');
% Plot first differences 
y1d(:,1) = yd(:,1)    ; 
y1d(:,2) = yd(:,2)    ; 
y1d(:,3) = yd(:,3)    ; 
y1d(:,4) = yd(:,4)    ; 
y1d(:,5) = yd(:,5)    ; 
y1d(:,6) = yd(:,8)    ; 
figure('Color','white')
for i=1:1:Ynvar
    subplot(3,2,i)
    plot(y1d(:,i))
    title('Dif',y1vnames{i})
end


%% Transform variables
% =======================================================================
% Define variables 
y1vnames      = {'Exchange Rate', 'Interest Rate Differential', 'Stock Market Risk Premium', 'Risk Apetite', 'Equity' ,'Stock Market Risk'};
Ynvar = length(y1vnames);

% Construct endo
nobs = size(y,1);

y1 = zeros(nobs,Ynvar)  ;      % y1 is the first matrix of endog variables I 
                               % will use; I may try with different ones later on

y1(:,1) = y(:,1)    ;          % Exchange rate 
y1(:,2) = y(:,2)    ;          % Interest rate differential
y1(:,3) = y(:,3)    ;          % Cross risk premium
y1(:,4) = y(:,4)    ;          % Risk aversion
y1(:,5) = y(:,5)    ;          % Equity
y1(:,6) = y(:,8)    ;          % Stock market expected risk

% Plot levels
figure('Color','white')
for i=1:1:Ynvar
    subplot(3,2,i)
    plot(y1(:,i))
    title(y1vnames{i})
end

%% Benchmark VAR
% =======================================================================

% Determine lag legth: 
[lag1, lag1SC] = VARlag(y1,12,1);             % Akaike (AIC) and Schwarz Bayesian 
                                              % Criterion (SBC)criterion

% Estimate the var with optimal lag:
[var1, var1opt]= VARmodel(y1,lag1,1);

wnr = zeros(12,12);             % Creates a matrix in which I will store the results of Ljung-Box tests.

for i=1:1:Ynvar
    [h, pValue] = lbqtest(var1.resid(:,i),'lags',[1,2,3,4,5,6,7,8,9,10,11,12]);
    wnr(1+2*(i-1),:) = pValue;
    wnr(2*i,:) = h;
end
% I test for each estimated equation, with different lag legths. I fail to
% reject in all cases.

% h = 0 indicates that there is not enough evidence to reject the null
% hypothesis that the residuals are not autocorrelated (i.e. residuals are
% white noise and thus the model is valid).

% Plot residuals

figure('Color','white')
for i=1:1:Ynvar
    subplot(2,3,i)
    plot(var1.resid(:,i))
    title(y1vnames(i))
end
% all residuals look like white noise, though there are some outliers :)

% ACF of residuals
figure('Color','white')
for i=1:1:Ynvar
    subplot(3,2,i)
    autocorr(var1.resid(:,i))
end

var1opt.vnames = y1vnames ;             % Some labels
var1opt.nsteps = 60;                    % # of periods to plot in IRF's
var1opt.ndraws = 500;                   % # of rotations for bootstrap
var1opt.quality = 1;
var1opt.FigSize = [26,8];
var1opt.frequency = 'm';                % Data at monthly freq



%% Impulse Response (benchmark)
% =======================================================================

var1opt.ident     = 'sign'; % identification method for IRFs ('short' zero
                            % short-run restr, 'long' zero long-run restr,
                            % 'sign' sign restr, 'iv' external instrument)
                                  
% Define sign restrictions : positive 1, negative -1, unrestricted 0
%    shock1  shock2 ...
SIGN = [ 0,-1,-1,1,-1,1;   % Exchange Rate
         0,0,0,0,0,0;      % Interest Rate Differential
         0,0,0,0,0,0;      % Stock Market Risk Premium
         0,0,0,0,0,0;      % Risk Apetite
         0,0,0,0,0,0;      % Equity
         0,0,0,0,0,0];     % Stock Market Risk                            


var1opt.sr_hor = 6;                  % # number of steps the restrictions are imposed for:
var1opt.pctg = 68;                   % Conf lvl for bootstrap (Uhlig)
SRout = SR(var1,SIGN,var1opt);       % Computes IRFs


% Important:                SRout.IRmed(t,resp,imp) 
% imp: is the shock
% resp: is the variable that responds
% t: moment of time


%% Plot figures for MFT
% =======================================================================
% (i) Shock on INTEREST RATE DIFFERENTIAL
% Figure XXX in main text
figure('Color','white')
    subplot(2,1,1)
        PlotSwathe(SRout.IRmed(:,1,2),[SRout.IRinf(:,1,2) SRout.IRsup(:,1,2)]); hold on
        plot(zeros(var1opt.nsteps),'--k');
        title('Exchange Rate')
        axis tight
var1opt.sr_hor = 1;                 % In the second panel I check how persistency 
SRout = SR(var1,SIGN,var1opt);      % changes when SR hold only 2 periods.
    subplot(2,1,2)
        PlotSwathe(SRout.IRmed(:,1,2),[SRout.IRinf(:,1,2) SRout.IRsup(:,1,2)]); hold on
        plot(zeros(var1opt.nsteps),'--k');
        title('Exchange Rate')
        axis tight
        
% Figures XXX in appendix X
var1opt.sr_hor = 6;            
SRout = SR(var1,SIGN,var1opt); 
figure('Color','white')
for ii=1:Ynvar
    subplot(3,2,ii)
    PlotSwathe(SRout.IRmed(:,ii,2),[SRout.IRinf(:,ii,2) SRout.IRsup(:,ii,2)]); hold on
    plot(zeros(var1opt.nsteps),'--k');
    title(y1vnames{ii})
    axis tight
end

var1opt.sr_hor = 1;            
SRout = SR(var1,SIGN,var1opt); 
figure('Color','white')
for ii=1:Ynvar
    subplot(3,2,ii)
    PlotSwathe(SRout.IRmed(:,ii,2),[SRout.IRinf(:,ii,2) SRout.IRsup(:,ii,2)]); hold on
    plot(zeros(var1opt.nsteps),'--k');
    title(y1vnames{ii})
    axis tight
end



% (ii) Shock on CROSS RISK PREMIUM
% Figure XXX in main text
figure('Color','white')
    subplot(2,1,1)
        PlotSwathe(SRout.IRmed(:,1,3),[SRout.IRinf(:,1,3) SRout.IRsup(:,1,3)]); hold on
        plot(zeros(var1opt.nsteps),'--k');
        title('Exchange Rate')
        axis tight
var1opt.sr_hor = 1;                     % In the second panel I check how persistency 
SRout = SR(var1,SIGN,var1opt);          % changes when SR hold only 2 periods.
    subplot(2,1,2)
        PlotSwathe(SRout.IRmed(:,1,3),[SRout.IRinf(:,1,3) SRout.IRsup(:,1,3)]); hold on
        plot(zeros(var1opt.nsteps),'--k');
        title('Exchange Rate')
        axis tight
        
        
% Figures XXX in appendix
var1opt.sr_hor = 6;
SRout = SR(var1,SIGN,var1opt);
figure('Color','white') % Shock on cross risk premium
for ii=1:Ynvar
    subplot(3,2,ii)
    PlotSwathe(SRout.IRmed(:,ii,3),[SRout.IRinf(:,ii,3) SRout.IRsup(:,ii,3)]); hold on
    plot(zeros(var1opt.nsteps),'--k');
    title(y1vnames{ii})
    axis tight
end
var1opt.sr_hor = 1;
SRout = SR(var1,SIGN,var1opt);
for ii=1:Ynvar
    subplot(3,2,ii)
    PlotSwathe(SRout.IRmed(:,ii,3),[SRout.IRinf(:,ii,3) SRout.IRsup(:,ii,3)]); hold on
    plot(zeros(var1opt.nsteps),'--k');
    title(y1vnames{ii})
    axis tight
end



%% Robstness checks
% =======================================================================
% (i) Lag length
% Conclusion (spoiler alert): 2 and 3 not valid; 4, 5, 6 and 7 valid.
% Length = 2 = lag1SC
[var2, var2opt]= VARmodel(y1,lag1SC,1);

wnr2 = zeros(12,12);   
for i=1:1:Ynvar
    [h, pValue] = lbqtest(var2.resid(:,i),'lags',[1,2,3,4,5,6,7,8,9,10,11,12]);
    wnr2(1+2*(i-1),:) = pValue;
    wnr2(2*i,:) = h;
end
% I test for each estimated equation, with different lag legths. I fail to
% reject in all cases, except in the last equation -> model with 2 lags is
% not valid

% h = 0 indicates that there is not enough evidence to reject the null
% hypothesis that the residuals are not autocorrelated (i.e. residuals are
% white noise and thus the model is valid).

% ACF of residuals
figure('Color','white')
for i=1:1:Ynvar
    subplot(3,2,i)
    autocorr(var2.resid(:,i))
    title(y1vnames{i})
end
% ACFs confirm Ljung-Box test

% Length = 3
[var3, var3opt]= VARmodel(y1,3,1);

wnr3 = zeros(12,12);

for i=1:1:Ynvar
    [h, pValue] = lbqtest(var3.resid(:,i),'lags',[1,2,3,4,5,6,7,8,9,10,11,12]);
    wnr3(1+2*(i-1),:) = pValue;
    wnr3(2*i,:) = h;
end
% Problems in equation 2 and 6 -> model with 3 lags is not valid
% ACF of residuals
figure('Color','white')
for i=1:1:Ynvar
    subplot(3,2,i)
    autocorr(var3.resid(:,i))
    title(y1vnames{i})
end
% ACFs confirm Ljung-Box test

% Length = 5
[var5, var5opt]= VARmodel(y1,5,1);

wnr5 = zeros(12,12);
for i=1:1:Ynvar
    [h, pValue] = lbqtest(var5.resid(:,i),'lags',[1,2,3,4,5,6,7,8,9,10,11,12]);
    wnr5(1+2*(i-1),:) = pValue;
    wnr5(2*i,:) = h;
end
% I test for each estimated equation, with different lag legths. I fail to
% reject in all cases -> model with 5 lags is valid

% Length = 6
[var6, var6opt]= VARmodel(y1,6,1);

wnr6 = zeros(12,12);
for i=1:1:Ynvar
    [h, pValue] = lbqtest(var6.resid(:,i),'lags',[1,2,3,4,5,6,7,8,9,10,11,12]);
    wnr6(1+2*(i-1),:) = pValue;
    wnr6(2*i,:) = h;
end
% I test for each estimated equation, with different lag legths. I fail to
% reject in all cases -> model with 6 lags is valid

% Length = 7
[var7, var7opt]= VARmodel(y1,7,1);

wnr7 = zeros(12,12);
for i=1:1:Ynvar
    [h, pValue] = lbqtest(var7.resid(:,i),'lags',[1,2,3,4,5,6,7,8,9,10,11,12]);
    wnr7(1+2*(i-1),:) = pValue;
    wnr7(2*i,:) = h;
end
% I test for each estimated equation, with different lag legths. I fail to
% reject in all cases -> model with 7 lags is valid


%% Different measures of EQUITY
% =======================================================================
% (i) Equity2
y2 = y1;
y2(:,5) = y(:,6);          
lage2 = VARlag(y2,12,1);             % Akaike (AIC)

% Estimate the var with optimal lag:
% VARmodel(ENDO,nlag,const,EXOG,nlag_ex).
[vare2, vare2opt]= VARmodel(y2,lage2,1);

wnre2 = zeros(12,12);             % Creates a matrix in which I will store the results of Ljung-Box tests.
for i=1:1:Ynvar
    [h, pValue] = lbqtest(vare2.resid(:,i),'lags',[1,2,3,4,5,6,7,8,9,10,11,12]);
    wnre2(1+2*(i-1),:) = pValue;
    wnre2(2*i,:) = h;
end
% Valid model

vare2opt.vnames = y1vnames ;
vare2opt.nsteps = 60;
vare2opt.ndraws = 500;
vare2opt.quality = 1;
vare2opt.FigSize = [26,8];
vare2opt.frequency = 'm';
vare2opt.ident     = 'sign';
vare2opt.sr_hor = 6;    
vare2opt.pctg = 68;
SRoute2 = SR(vare2,SIGN,vare2opt);

% Shock on INTEREST RATE DIFFERENTIAL
figure('Color','white')
for ii=1:Ynvar
    subplot(3,2,ii)
    PlotSwathe(SRoute2.IRmed(:,ii,2),[SRoute2.IRinf(:,ii,2) SRoute2.IRsup(:,ii,2)]); hold on
    plot(zeros(vare2opt.nsteps),'--k');
    title(y1vnames{ii})
    axis tight
end
% IRF are similar to the benchmark VAR

% Shock on CROSS RISK PREMIUM
figure('Color','white') % Shock on cross risk premium
for ii=1:Ynvar
    subplot(3,2,ii)
    PlotSwathe(SRoute2.IRmed(:,ii,3),[SRoute2.IRinf(:,ii,3) SRoute2.IRsup(:,ii,3)]); hold on
    plot(zeros(vare2opt.nsteps),'--k');
    title(y1vnames{ii})
    axis tight
end
% IRF are similar to the benchmark VAR





% (ii) Equity3
y3 = y1;
y3(:,5) = y(:,7);          % Equity3

lage3 = VARlag(y3,12,1);             % Akaike (AIC)

% Estimate the var with optimal lag:
[vare3, vare3opt]= VARmodel(y3,lage3,1);

wnre3 = zeros(12,12);
for i=1:1:Ynvar
    [h, pValue] = lbqtest(vare3.resid(:,i),'lags',[1,2,3,4,5,6,7,8,9,10,11,12]);
    wnre3(1+2*(i-1),:) = pValue;
    wnre3(2*i,:) = h;
end
% Valid model

vare3opt.vnames = y1vnames ;
vare3opt.nsteps = 60;
vare3opt.ndraws = 500;
vare3opt.quality = 1;
vare3opt.FigSize = [26,8];
vare3opt.frequency = 'm';
vare3opt.ident     = 'sign';
vare3opt.sr_hor = 6;    
vare3opt.pctg = 68;
SRoute3 = SR(vare3,SIGN,vare3opt);

% Shock on INTEREST RATE DIFFERENTIAL
figure('Color','white')
for ii=1:Ynvar
    subplot(3,2,ii)
    PlotSwathe(SRoute3.IRmed(:,ii,2),[SRoute3.IRinf(:,ii,2) SRoute3.IRsup(:,ii,2)]); hold on
    plot(zeros(vare3opt.nsteps),'--k');
    title(y1vnames{ii})
    axis tight
end
% IRF are similar to the benchmark VAR

% Shock on CROSS RISK PREMIUM
figure('Color','white') % Shock on cross risk premium
for ii=1:Ynvar
    subplot(3,2,ii)
    PlotSwathe(SRoute3.IRmed(:,ii,3),[SRoute3.IRinf(:,ii,3) SRoute3.IRsup(:,ii,3)]); hold on
    plot(zeros(vare3opt.nsteps),'--k');
    title(y1vnames{ii})
    axis tight
end
% IRF are similar to the benchmark VAR





