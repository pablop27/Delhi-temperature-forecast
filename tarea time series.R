# libraries I might use
library(vars)
library(mFilter)
library(tseries)
library(TSstudio)
library(forecast)
library(tidyverse)
library(ggplot2)
library(seasonal)
library(lubridate)
library(dplyr)
library(doBy)
library(fGarch)
library(rugarch)
# organize the training data
delhitrain<-DailyDelhiClimateTrain[1:1461,]
# daily train data
dtrtemp<-ts(delhitrain$meantemp,start=c(2013,1,1),frequency=365)
dtrhum<-ts(delhitrain$humidity,start=c(2013,1,1),frequency=365)
dtrwsp<-ts(delhitrain$wind_speed,start=c(2013,1,1),frequency=365)
dtrprss<-ts(delhitrain$meanpressure,start=c(2013,1,1),frequency=365)
ku<-cbind(dtrtemp,dtrhum,dtrwsp,dtrprss)
# daily test data
dtstemp<-ts(DailyDelhiClimateTest$meantemp,start=c(2017,1,1),frequency=365)
dtshum<-ts(DailyDelhiClimateTest$humidity,start=c(2017,1,1),frequency=365)
dtswsp<-ts(DailyDelhiClimateTest$wind_speed,start=c(2017,1,1),frequency=365)
dtsprss<-ts(DailyDelhiClimateTest$meanpressure,start=c(2017,1,1),frequency=365)
ko<-cbind(dtstemp,dtshum,dtswsp,dtsprss)
# organize all the data(train and test) by month
all<-rbind(DailyDelhiClimateTrain,DailyDelhiClimateTest)
all<-all %>% mutate(date=ymd(date),month=month(date),year=year(date))
rmonthly<-summaryBy(meantemp+wind_speed+humidity+meanpressure~month+year,FUN=c(mean),data=all)
colnames(monthly)<-c("month","year","temp","windsp","humidity","pressure")
monthly[,"date"]<-make_date(year=monthly$year,month=monthly$month)
monthly<-monthly[order(as.Date(monthly$date, format="%d%Y%m/%d")),]
# create monthly training and test data
train<-monthly[1:46,]
test<-monthly[47:52,]
# training data
mtrtemp<-ts(train$temp,start=c(2013,1,1),frequency=12)
mtrhum<-ts(train$humidity,start=c(2013,1,1),frequency=12)
mtrwsp<-ts(train$windsp,start=c(2013,1,1),frequency=12)
mtrprss<-ts(train$pressure,start=c(2013,1,1),frequency=12)
za<-cbind(mtrtemp,mtrhum,mtrwsp,mtrprss)
# test data
mtstemp<-ts(test$temp,start=c(2016,11,1),frequency=12)
mtshum<-ts(test$humidity,start=c(2016,11,1),frequency=12)
mtswsp<-ts(test$windsp,start=c(2016,11,1),frequency=12)
mtsprss<-ts(test$pressure,start=c(2016,11,1),frequency=12)
zu<-cbind(mtstemp,mtshum,mtswsp,mtsprss)
# decompose the monthly data
mtrtemp %>% decompose(type="multiplicative") %>% autoplot()
mtrtemp %>% decompose(type="additive") %>% autoplot()
mtrtemp%>%seas(x11="")%>%autoplot()
# fit models
# find lambda for possible transformations
ld<-BoxCox.lambda(dtrtemp)
lm<-BoxCox.lambda(mtrtemp)
# SES
# given the decomposition, I think this model is not adequate for this data
# Holt
hd<-holt(dtrtemp,h=114)
hm<-holt(mtrtemp,h=6)
htd<-holt(dtrtemp,h=114,lambda =ld,biasadj = TRUE)
htm<-holt(mtrtemp,h=6,lambda =lm,biasadj = TRUE)
# Holt with a damped trend
hdd<-holt(dtrtemp,h=114,damped=TRUE)
hdm<-holt(mtrtemp,h=6,damped=TRUE)
hdtd<-holt(dtrtemp,h=114,damped=TRUE,lambda =ld,biasadj = TRUE)
hdtm<-holt(mtrtemp,h=6,damped=TRUE,lambda =lm,biasadj = TRUE)
# Holt-Winters not transformed
hwam<-hw(mtrtemp,h=6,seasonal="additive")
hwmm<-hw(mtrtemp,h=6,seasonal="multiplicative")
hwdam<-hw(mtrtemp,h=6,seasonal="additive",damped=TRUE)
hwdmm<-hw(mtrtemp,h=6,seasonal="multiplicative",damped=TRUE)
# Holt-Winters transformed
hwtam<-hw(mtrtemp,h=6,seasonal="additive",lambda=lm,biasadj = TRUE)
hwtdam<-hw(mtrtemp,h=6,seasonal="additive",damped=TRUE,lambda=lm,biasadj = TRUE)
# ARIMA
# ARIMA not transformed
ad<-auto.arima(dtrtemp)
adf<-forecast(ad,h=114)
am<-auto.arima(mtrtemp)
amf<-forecast(am,h=6)
# ARIMA transformed data
atd<-auto.arima(dtrtemp,lambda=ld,biasadj = TRUE)
atdf<-forecast(atd,h=114)
atm<-auto.arima(mtrtemp,lambda=lm,biasadj=TRUE)
atmf<-forecast(atm,h=6)
# GARCH
gs<-ugarchspec(mean.model = list(armaOrder = c(1,1)),variance.model = list(model = "sGARCH"), distribution.model = "norm")
gd<-ugarchfit(data=dtrtemp,spec=gs)
gdf<-ugarchforecast(gd,n.ahead=114)
gdf<-ts(fitted(gdf),start=c(2017,1,1),frequency=365)
gm<-ugarchfit(data=mtrtemp,spec=gs)
gmf<-ugarchforecast(gm,n.ahead=6)
gmf<-ts(fitted(gmf),start=c(2016,11,1),frequency=12)

#VAR
VARselect(ku,lag.max=20,type="const")
VARselect(ku,lag.max=20,type="trend")
VARselect(za,lag.max=20,type="const")
VARselect(za,lag.max=20,type="trend")
vdc<-VAR(ku,p=4,type="const")
vdt<-VAR(ku,p=6,type="trend")
vdcf<-forecast(vdc,h=114)
vdtf<-forecast(vdt,h=114)
vmc<-VAR(za,p=7,type="const")
vmt<-VAR(za,p=7,type="trend")
vmcf<-forecast(vmc,h=6)
vmtf<-forecast(vmt,h=6)
sol<-data.frame(vdcf)
sol<-dplyr::filter(sol,Series=="dtrtemp")
sal<-data.frame(vdtf)
sal<-dplyr::filter(sal,Series=="dtrtemp")
sel<-data.frame(vmcf)
sel<-dplyr::filter(sel,Series=="mtrtemp")
sul<-data.frame(vmtf)
sul<-dplyr::filter(sul,Series=="mtrtemp")
vard1<-ts(sol$Point.Forecast,start=c(2017,1,1),frequency=365)
vard2<-ts(sal$Point.Forecast,start=c(2017,1,1),frequency=365)
varm1<-ts(sel$Point.Forecast,start=c(2016,11,1),frequency=12)
varm2<-ts(sul$Point.Forecast,start=c(2016,11,1),frequency=12)
# graphs of the daily time series and various forecasts
autoplot(dtrtemp)+autolayer(hd,series="Holt",PI=FALSE)+autolayer(htd,series="Holt transformed",PI=FALSE)+autolayer(hdd,series="Holt damped",PI=FALSE)+autolayer(hdtd,series="Holt damped transformed",PI=FALSE)+autolayer(adf,series="ARIMA",PI=FALSE)+autolayer(atdf,series="ARIMA transformed",PI=FALSE)+autolayer(gdf,series="GARCH")+autolayer(vard1,series="VAR const")+autolayer(vard2,series="VAR trend")+autolayer(dtstemp,series="test data")
autoplot(dtrtemp)+autolayer(hd,series="Holt",PI=FALSE)+autolayer(hdd,series="Holt damped",PI=FALSE)+autolayer(dtstemp,series="test data")
autoplot(dtrtemp)+autolayer(htd,series="Holt transformed",PI=FALSE)+autolayer(hdtd,series="Holt damped transformed",PI=FALSE)+autolayer(dtstemp,series="test data")
autoplot(dtrtemp)+autolayer(adf,series="ARIMA",PI=FALSE)+autolayer(atdf,series="ARIMA transformed",PI=FALSE)+autolayer(dtstemp,series="test data")
autoplot(dtrtemp)+autolayer(gdf,series="GARCH")+autolayer(vard1,series="VAR const")+autolayer(vard2,series="VAR trend")+autolayer(dtstemp,series="test data")

# graphs of the monthly series and various forecasts
autoplot(mtrtemp)+autolayer(hm,series="Holt",PI=FALSE)+autolayer(htm,series="Holt transformed",PI=FALSE)+autolayer(hdm,series="Holt damped",PI=FALSE)+autolayer(hdtm,series="Holt damped transformed",PI=FALSE)+autolayer(amf,series="ARIMA",PI=FALSE)+autolayer(atmf,series="ARIMA transformed",PI=FALSE)+autolayer(gmf,series="GARCH")+autolayer(varm1,series="VAR const")+autolayer(varm2,series="VAR trend")+autolayer(mtstemp,series="test data")+autolayer(hwam,series="HW additive",PI=FALSE)+autolayer(hwmm,series="HW multiplicative",PI=FALSE)+autolayer(hwdam,series="HW additve damped",PI=FALSE)+autolayer(hwdmm,series="HW multiplicative damped",PI=FALSE)+autolayer(hwtam,series="HW transformed additive",PI=FALSE)+autolayer(hwtdam,series="HW transformed additive damped",PI=FALSE)
autoplot(mtrtemp)+autolayer(mtstemp,series="test data")+autolayer(hm,series="Holt",PI=FALSE)+autolayer(hdm,series="Holt damped",PI=FALSE)+autolayer(htm,series="Holt transformed",PI=FALSE)+autolayer(hdtm,series="Holt damped transformed",PI=FALSE)+autolayer(gmf,series="GARCH")+autolayer(varm1,series="VAR const")+autolayer(varm2,series="VAR trend")
autoplot(mtrtemp)+autolayer(mtstemp,series="test data")+autolayer(amf,series="ARIMA",PI=FALSE)+autolayer(atmf,series="ARIMA transformed",PI=FALSE)
autoplot(mtrtemp)+autolayer(mtstemp,series="test data")+autolayer(hwdam,series="HW additve damped",PI=FALSE)+autolayer(hwdmm,series="HW multiplicative damped",PI=FALSE)+autolayer(hwtdam,series="HW transformed additive damped",PI=FALSE)
autoplot(mtrtemp)+autolayer(mtstemp,series="test data")+autolayer(hwam,series="HW additive",PI=FALSE)+autolayer(hwmm,series="HW multiplicative",PI=FALSE)+autolayer(hwtam,series="HW transformed additive",PI=FALSE)

# calculate accuracy
# daily
accuracy(hd,dtstemp)
accuracy(hdd,dtstemp)
accuracy(htd,dtstemp)
accuracy(hdtd,dtstemp)
accuracy(vard1,dtstemp)
accuracy(vard2,dtstemp)
accuracy(gdf,dtstemp)
accuracy(adf,dtstemp)
accuracy(atdf,dtstemp)
# In this case, the ARIMA with the transformed data made the best forecast, according to the RMSE, MAE AND MAPE in the test data.
# It was followed by the normal ARIMA, VAR with constant, VAR with trend, Holt, Holt damped, GARCH, Holt with transformed data and
# Holt damped with transformed data.
# monthly
accuracy(hm,mtstemp)
accuracy(hdm,mtstemp)
accuracy(htm,mtstemp)
accuracy(hdtm,mtstemp)
accuracy(varm1,mtstemp)
accuracy(varm2,mtstemp)
accuracy(gmf,mtstemp)
accuracy(amf,mtstemp)
accuracy(atmf,mtstemp)
accuracy(hwam,mtstemp)
accuracy(hwmm,mtstemp)
accuracy(hwdam,mtstemp)
accuracy(hwdmm,mtstemp)
accuracy(hwtam,mtstemp)
accuracy(hwtdam,mtstemp)
# For the monthly data, the best forecast was made by the Holt-Winters' model with damped trend and additive seasonality. In the RMSE, MAE & MAPE it had the lowest values.
# It was followed by Holt-Winters with transformed data, damped trend and additive seasonality, ARIMA with transformed data, normal ARIMA, Holt-Winters with transformed data
# and additive seasonality, Holt-Winters with additive seasonality, Holt-Winters with damped trend and multiplicative seasonality,Holt-Winters with multiplicative seasonality,
# Holt with transformed data and damped trend,Holt with damped trend, VAR with trend, VAR with const, GARCH, Holt and Holt with transformed data. 