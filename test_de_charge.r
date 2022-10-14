#!usr/bien/env Rscript
charge_r = read.csv("/home/***/total.csv")
colnames(charge_r) = c("Temps", "Instance")
install.packages("data.table")
install.packages("ggplot2")
install.packages("dplyr")
library(data.table)
library(ggplot2)
library("dplyr")
charge_rbis=setDT(charge_r)[,list(Count=.N),names(charge_r)]
charge <- charge_rbis %>%
  group_by(Instance) %>%
  dplyr::mutate(Requests = cumsum(Count))
charge=data.frame(charge)
print(charge)
pdf(file="charge.pdf")
ggplot(data=charge, aes(x=Temps, y=Requests, group = Instance, color = Instance))+geom_line()
pdf(file="charge_bis.pdf")
ggplot(data=charge, aes(x=Temps, y=Count, group = Instance, color = Instance))+geom_line()
