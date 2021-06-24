function y = piecewiseConstant(x,p)
borders = linspace(min(x),max(x),length(p)+1);
y = nan(size(x));
for i = 1:(length(borders)-1)
    selx = x >= borders(i) & x <= borders(i+1);
    y(selx) = p(i);
end

