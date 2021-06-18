library(readxl)
library(sandwich)
library(lmtest)
library(stargazer)

Input <- read_excel("~/Master in Economics/MFT/Mexico/Input.xlsx", sheet = "Diff", col_types = c("skip", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric"))

# Benchmark article estimates the following regression:
# e_{t+1} = b_0 + b_1 DD1_t + b_2 RPC_t + b_3 RAC_{t+1} + b_4 Equity_{t+1} + b_3 Risk_t
# With this specification, authors 'account' for endogeneity issues. 
# But, what if there are dynamics in the variables?
# Why not estimate a VAR in levels (in this specification, all variables are in first difference)? 


linearMod <- lm(E ~ ID + RP + RA + Equity + DiffRisk - 1, data=Input)
linearMod2 <- lm(E ~ ID + RP + RA + Equity2 + DiffRisk - 1 , data=Input)
linearMod3 <- lm(E ~ ID + RP + RA + Equity3 + DiffRisk - 1 , data=Input)



#summary(linearMod)

# Compute Newey & West (1987, 1994) heteroscedasticity
# and autocorrelation consistent (HAC) covariance matrix estimators.

NWVar <- NeweyWest(linearMod, diagnostics = TRUE)
NWVar2 <- NeweyWest(linearMod2, diagnostics = TRUE)
NWVar3 <- NeweyWest(linearMod3, diagnostics = TRUE)


# Use HAC var-cov matrix for inference

mytest <- coeftest(linearMod, vcov = NWVar )
mytest2 <- coeftest(linearMod2, vcov = NWVar2 )
mytest3 <- coeftest(linearMod3, vcov = NWVar3 )


# Summarize results of all regressions into a single (pretty) table
mytable <- stargazer(mytest, mytest2, mytest3, type="text", keep.stat = "n")


myTEXtable <- stargazer(mytest, mytest2, mytest3, type="latex", 
                        title = "Maybe without a title",
                        style = "default",
                        out = "MyTable.tex",
                        covariate.labels = c("Interest Rate Differential", "Cross Risk Premium", "Risk Appetite", "Equity", "Equity2", "Equity3", "Stock Market Risk"),
                        align = TRUE,
                        header = FALSE,
                        keep.stat = c("n", "ser"),
                        label = "tab: lin reg")






mean(Input$Equity)

mean(Input$Equity2)

mean(Input$Equity3)

mean(Input$ID)

mean(Input$RP)

mean(Input$DiffRisk)













