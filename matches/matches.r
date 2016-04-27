require("properties")
require("RPostgreSQL")
require("ggplot2")
require("Cairo")
require("corrplot")

setwd("/projects/soccer-cs-stats/matches")

dbConfig <- read.properties("../db-config.properties")

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname=dbConfig$dbname,host=dbConfig$host,port=dbConfig$port,user=dbConfig$user,password=dbConfig$pass) 

matches <- dbGetQuery(con, 
              "with x as (
              	select m.id, m.date, m.home, m.guest, home_goals, guest_goals,
                            p.full_name, p.position_vertical, p.nationality,
                            (select value_in_mio from player_market_value v where v.id_player = p.id and v.date <= m.date order by v.date desc limit 1) as current_value
                            from match m, player_in_match pm, player p
                            where --m.date < '2011-01-01' and
                            m.id = pm.id_match
                            and p.id = pm.id_player
              )
              select x.id, x.date, x.home, x.guest, x.home_goals, x.guest_goals,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.home = x2.nationality and x2.position_vertical = 'KEEPER') as g_keeper_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.home = x2.nationality and x2.position_vertical = 'DEFENSE') as g_defense_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.home = x2.nationality and x2.position_vertical = 'MIDFIELD') as g_midfield_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.home = x2.nationality and x2.position_vertical = 'OFFENSE') as g_offense_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.guest = x2.nationality and x2.position_vertical = 'KEEPER') as h_keeper_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.guest = x2.nationality and x2.position_vertical = 'DEFENSE') as h_defense_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.guest = x2.nationality and x2.position_vertical = 'MIDFIELD') as h_midfield_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.guest = x2.nationality and x2.position_vertical = 'OFFENSE') as h_offense_value
              from x
              group by id, date, home, guest, home_goals, guest_goals")

names(matches)
M <- cor(matches[, c("home_goals", "guest_goals",
                     "h_keeper_value", "h_defense_value", "h_midfield_value", "h_offense_value",
                     "g_keeper_value", "g_defense_value", "g_midfield_value", "g_offense_value")])

png(height=600, width=600, file="corrplot.png")
corrplot(M, 
         method="circle", 
         mar=c(0,0,2,0),
         title="correlation plot of GOALS vs. aggregated MARKET VALUES on position")
dev.off()

#cleanup
dbDisconnect(con)