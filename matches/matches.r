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
              	select m.id, m.date, m.home, m.guest, home_goals, guest_goals, (home_goals - guest_goals) diff_goals,
                            p.full_name, p.position_vertical, p.nationality,
                            (select value_in_mio from player_market_value v where v.id_player = p.id and v.date <= m.date order by v.date desc limit 1) as current_value
                            from match m, player_in_match pm, player p
                            where --m.date < '2011-01-01' and
                            m.id = pm.id_match
                            and p.id = pm.id_player
              )
              select x.id, x.date, x.home, x.guest, x.home_goals, x.guest_goals, x.diff_goals,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.home = x2.nationality) as h_complete_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.guest = x2.nationality) as g_complete_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.home = x2.nationality and x2.position_vertical = 'KEEPER') as h_keeper_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.home = x2.nationality and x2.position_vertical = 'DEFENSE') as h_defense_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.home = x2.nationality and x2.position_vertical = 'MIDFIELD') as h_midfield_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.home = x2.nationality and x2.position_vertical = 'OFFENSE') as h_offense_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.guest = x2.nationality and x2.position_vertical = 'KEEPER') as g_keeper_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.guest = x2.nationality and x2.position_vertical = 'DEFENSE') as g_defense_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.guest = x2.nationality and x2.position_vertical = 'MIDFIELD') as g_midfield_value,
              (select COALESCE(sum(current_value), 0) from x as x2 where x.id = x2.id and x.guest = x2.nationality and x2.position_vertical = 'OFFENSE') as g_offense_value
              from x
              group by id, date, home, guest, home_goals, guest_goals, diff_goals")

M.small <- cor(matches[, c("home_goals", "guest_goals", "diff_goals",
                     "h_complete_value", "g_complete_value")])

png(height=500, width=500, file="corrplot_complete.png")
corrplot(M.small, 
         method="circle", 
         mar=c(0,0,2,0),
         addCoef.col="gold",
         title="correlation plot of GOALS vs. MARKET VALUES of whole team")
dev.off()


matches.nums <- matches[, c("home_goals", "guest_goals", "diff_goals",
                            "h_keeper_value", "h_defense_value", "h_midfield_value", "h_offense_value",
                            "g_keeper_value", "g_defense_value", "g_midfield_value", "g_offense_value")]
M <- cor(matches.nums)

png(height=600, width=600, file="corrplot_positions.png")
corrplot(M, 
         method="circle", 
         mar=c(0,0,2,0),
         addCoef.col="gold",
         title="correlation plot of GOALS vs. aggregated MARKET VALUES on position")
dev.off()


#
# PREDICTION
#
# Inspired from http://www.r-bloggers.com/using-neural-networks-for-credit-scoring-a-simple-example/
#
install.packages("neuralnet")
require("neuralnet")

perc <- NROW(matches.nums)*0.75
trainset <- matches.nums[1:perc, ]
testset <- matches.nums[(perc+1):NROW(matches.nums), ]

# train
nn <- neuralnet(diff_goals ~ h_keeper_value + h_defense_value + h_midfield_value + h_offense_value + g_keeper_value + g_defense_value + g_midfield_value + g_offense_value,
                data=trainset, hidden=8, lifesign = "minimal", linear.output = FALSE, threshold = 0.1)
plot(nn)

# test
temp_test <- testset[, c("h_keeper_value", "h_defense_value", "h_midfield_value", "h_offense_value", "g_keeper_value", "g_defense_value", "g_midfield_value", "g_offense_value")]
test_result <- compute(nn, temp_test)

#report
results <- data.frame(actual = testset$diff_goals, 
                      prediction = test_result$net.result)
results
plot(results)



#cleanup
dbDisconnect(con)
