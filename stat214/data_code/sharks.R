library(tidyverse)
library(ROCR)

sharks <- read_csv("sharks.csv", col_types=cols() )

threatened <- c("Critically Endangered","Endangered","Vulnerable")
nonthreatened <- c("Least Concern","Near Threatened")
sharks <- sharks %>% mutate( Threatened = case_when( Category %in% threatened ~ 1, Category %in% nonthreatened ~ 0 ))

sharks.fit <- glm( Threatened ~ log(Weight), data = sharks, family = binomial )
summary( sharks.fit )
pchisq( sharks.fit$null.deviance - sharks.fit$deviance, 1, lower.tail=F)
ggplot( sharks, aes(log(Weight),Threatened)) + 
  geom_point() + 
  geom_smooth( method=glm, method.args = list(family = "binomial"))

link <- family(sharks.fit)$link
linkinv <- family(sharks.fit)$linkinv
new <- data.frame( Weight = c(1800,270000))
( responses <- predict( sharks.fit, new, type="response") )
links <- predict( sharks.fit, new, type="link", se.fit=TRUE)
( predictions <- tibble( Weight = new$Weight ) %>%
    mutate( logWeight = log(new$Weight) ) %>%  
    mutate( Link.lwr = links$fit - 1.96*links$se.fit ) %>% 
    mutate( Link = links$fit ) %>% 
    mutate( Link.upr = links$fit + 1.96*links$se.fit) )
( predictions <- predictions %>% 
    mutate( Response.lwr = linkinv(Link.lwr) ) %>% 
    mutate( Response = linkinv(Link) ) %>%  
    mutate( Response.upr = linkinv(Link.upr)) )

# vcov( sharks.fit )

( boundary <- -sharks.fit$coefficients[[1]] / sharks.fit$coefficients[[2]] )
ggplot( sharks, aes(log(Weight),Threatened)) + 
  geom_point() + 
  geom_smooth( method=glm, method.args = list(family = "binomial")) +
  geom_vline(xintercept=boundary, linetype="dashed", color="red")
( sharks <- sharks %>% mutate( Classifier = as.numeric( log(Weight) > boundary )) )
sharks.table <- table( sharks$Threatened, sharks$Classifier )
rownames( sharks.table ) <- c("Not threatened", "Threatened")
colnames( sharks.table ) <- c("Not predicted to be threatened", "Predicted to be threatened" )
sharks.table 
mean( sharks$Threatened == sharks$Classifier )
mean( sharks$Threatened != sharks$Classifier )

sharks <- sharks %>% mutate(pi.hat = sharks.fit$fitted.values) 
sharks %>% group_by(Threatened) %>% summarize( N = n(), pi.average = mean(pi.hat)) 
ggplot( sharks, aes(pi.hat))+geom_histogram()+facet_wrap(~Threatened)+xlim(0,1)

(sharks.null <- mean( sharks$Threatened ))
( sharks.R2.M <- 1 - (sharks.fit$deviance / sharks.fit$null.deviance ) )
( sharks.R2.S <- sum( (sharks.fit$fitted.values - sharks.null)^2 ) / sum( (sharks$Threatened - sharks.null)^2 ) )

