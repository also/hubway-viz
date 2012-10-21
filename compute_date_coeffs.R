filename = commandArgs(TRUE)[1]
data = read.table(filename)
x = data[,1]
y = data[,2]
m = lm(y ~ x + I(x^2))
write.table(m$coefficients, col.names=FALSE, row.names=FALSE)
