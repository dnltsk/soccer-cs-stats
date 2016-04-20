require("properties")
require("RPostgreSQL")
require("ggplot2")

setwd("D:/Projekte/soccer-cs-stats/")

dbConfig <- read.properties("db-config.properties")

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

#cleanup
dbDisconnect(con)