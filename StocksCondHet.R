library(readxl)
library(tseries)
library(timeSeries)
library(forecast)
library(tsDyn)
library(aTSA)
library(fBasics)
library(fGarch)
library(timeDate)
library(data.table)


# I extracted IPC (Indice de Precios y Cotizaciones) from Datastream.

## Import data
Stocks <- read_excel("~/Master in Economics/MFT/Mexico/GARCH/Stocks.xlsx")
## Exploratoy analysis

IPC <- ts(Stocks$IPC, start = c(2000,1), end = c(2020,12), frequency = 12 )
lIPC <- log(IPC)
dlIPC <- diff(lIPC) 

par(mfrow=c(3,1))
plot(IPC, main = "IPC", ylab="")
plot(lIPC, main = "Log IPC", ylab="")
plot(dlIPC, main = "Dif Log IPC", ylab="")

## Estimate an ARIMA(p,D,q)

par(mfrow=c(2,1))
Acf(dlIPC, main = "d.log.IPC")
Pacf(dlIPC, main="d.log.IPC")
# ACF and PACF do not suggest any lag-length; so I use p = q = 1; D = 1 because IPC is I(1)

arimaIPC = arima(dlIPC,order=c(1,0,1))
checkresiduals(arimaIPC)  # Residuals are white noise: p-val of Ljung-Box = 0.2677



## ARCH TEST: 
arch_test = arch.test(arimaIPC) # Confirms the presence of Heteroskedasticity with both tests

# The ARCH Engle's test is constructed based on the fact that if the residuals 
# (defined as $e[t]$) are heteroscedastic, the squared residuals ($e^2[t]$) 
# are autocorrelated. The first type of test is to examine whether the squares
# of residuals are a sequence of white noise, which is called Portmanteau Q 
# test and similar to the Ljung-Box test on the squared residuals. 

# The second type of test proposed by Engle (1982) is the Lagrange Multiplier
# test which is to fit a linear regression model for the squared residuals and
# examine whether the fitted model is significant. So the null hypothesis is 
# that the squared residuals are a sequence of white noise, namely, the 
# residuals are homoscedastic.

Resids <- arimaIPC$residuals
par(mfrow=c(3,1))
plot(Resids)
Acf(Resids^2)
Pacf(Resids^2)
# ACF suggests there is autocorrelation in the squared residuals; ACF suggests p=7, PAF suggests q=7.
# However, I will estimate a more parsimonious GARCH (see below).

## Estimate a GARCH(p, q) Stocks
# In order to determine the appropriate values for p & q I will estimate 
# a GARCH model for different combinations of them and select the best one 
# considering AIC.

Result=data.frame(Model="m",AIC=0)
q=0
for (i in 1:5){
  for (j in 1:5){
    q=q+1
    fit=garchFit(substitute(~garch(p,q),list(p=i,q=j)),data=Resids,trace=F)
    
    Result=rbind(Result,data.frame(Model=paste("m-",i,"-",j),AIC=fit@fit$ics[1]))
    
  }
}

Result[which.min(Result$AIC),]       # Best fit: GARCH(2,2)

# Now I estimate the model: 
fit_Garch=garchFit(~garch(2,2), data=arimaIPC$residuals,trace=F)
summary(fit_Garch)
# Ljung-box tests confirm that there is no autocorrelation in the residuals; LM-Test 
# yields a similar conclusion; then GARCH(2,2) is a valid model.

CondHet <- ts(fit_Garch@h.t, start = c(2000,1), end = c(2020,12), frequency = 12 )
CondHet <- CondHet*100                 # scale it
CondHet <-window(CondHet, start = c(2004,12), end = c(2020,12), frequency=12)
# CondHet is the estimated conditional heteroskedasticity or, in words of my project: 
# expected stock risk.

plot(CondHet)
dt <- data.table(CondHet)

write.csv(dt,"C:/Users/USUARIO/Documents/Master in Economics/MFT/Mexico/StockRisk.csv",row.names = TRUE)


