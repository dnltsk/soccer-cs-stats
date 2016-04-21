require("properties")
require("RPostgreSQL")
require("ggplot2")

setwd("D:/Projekte/soccer-cs-stats/market-value")

dbConfig <- read.properties("../db-config.properties")

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname=dbConfig$dbname,host=dbConfig$host,port=dbConfig$port,user=dbConfig$user,password=dbConfig$pass) 

ageValues <- dbGetQuery(con, "SELECT  p.id, p.full_name, p.position_vertical, v.date, (v.date - p.birth_date)/365.0 as age, v.value_in_mio FROM player p, player_market_value v where p.id = v.id_player order by p.id, v.date")

ggplot(ageValues, aes(age, value_in_mio, group=id, color=position_vertical)) +
  geom_line() +
  theme(legend.position="bottom") +
  ggtitle("Player's age vs. Player's market value")


ggplot(ageValues, aes(as.Date(date), value_in_mio, group=id, color=position_vertical)) +
  geom_line() +
  scale_x_date() +
  theme(legend.position="bottom") +
  ggtitle("Date vs. Player's market value")


yearValues <- dbGetQuery(con, "SELECT  p.id, p.full_name, p.position_vertical, EXTRACT(YEAR FROM v.date) as year, max(v.value_in_mio) as value_in_mio
                               FROM player p, player_market_value v
                               WHERE p.id = v.id_player 
                               GROUP BY p.id, p.full_name, p.position_vertical, year")

ggplot(yearValues, aes(year, value_in_mio, group=interaction(year, position_vertical), colour=position_vertical)) +
  geom_boxplot(position=position_dodge(width=0.9), width=1) +
  stat_summary(fun.y=median, geom="line", position=position_dodge(width=0.9), 
               aes(group=position_vertical)) +
  stat_summary(fun.y=median, geom="point", size=2,  position=position_dodge(width=0.9), 
               aes(group=position_vertical)) +
  scale_x_continuous(breaks=unique(yearValues$year)) +
  theme(legend.position="bottom") +
  ggtitle("median market value by year and position")


#cleanup
dbDisconnect(con)