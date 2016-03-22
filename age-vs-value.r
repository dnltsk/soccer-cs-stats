#install.packages("RJDBC")
#install.packages("properties")
#install.packages("ggplot2")
library("RJDBC")
library("properties")
library("ggplot2")

setwd("D:/Projekte/soccer-cs-stats/")

dbConfig <- read.properties("db-config.properties")

# how-to connect to Heroku Postgres: http://stackoverflow.com/questions/15853167/problems-connecting-remotely-to-postgresql-on-heroku-from-r-using-rpostgresql
pgsql <- JDBC("org.postgresql.Driver", "postgresql-9.4.1208.jre6.jar", "`")
testdb <- dbConnect(pgsql, 
                    paste("jdbc:postgresql://", dbConfig$host, ":", dbConfig$port, "/", dbConfig$base, sep=""), 
                    user=dbConfig$user,
                    password=dbConfig$pass,
                    ssl="true",
                    sslfactory="org.postgresql.ssl.NonValidatingFactory")

ageValues <- dbGetQuery(testdb, "SELECT  p.id, p.full_name, v.date, (v.date - p.birth_date)/365.0 as age, v.value_in_mio FROM player p, player_market_value v where p.id = v.id_player order by p.id, v.date")

ggplot(ageValues, aes(age, value_in_mio, group=id, color=full_name)) +
  geom_line() +
  theme(legend.position="none") +
  ggtitle("Player's age vs. Player's market value")



ggplot(ageValues, aes(as.Date(date), value_in_mio, group=id, color=full_name)) +
  geom_line() +
  scale_x_date() +
  theme(legend.position="none") +
  ggtitle("Date vs. Player's market value")