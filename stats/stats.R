library(magrittr)
library(tidyverse)
library(rstatix)

data <- read.csv('results_min.csv', stringsAsFactors=TRUE)
data$session <- factor(data$session, levels = c("pretest", "training1", "training2", "posttest"))

anova <- anova_test(data = data, dv = "stepsize_mean" , wid = "subject_id", between = "session")
tukey <- tukey_hsd(data, stepsize_mean ~ factor(session))

print(get_anova_table(anova))
print(tukey)

plot(data$session, data$stepsize_mean, main="Step sizes at staircase minima")

