function y = piecewiseLinear(x,p)
borders = linspace(0,90,length(p)/2+1);
y = nan(size(x));
for i = 1:length(borders)-1
    selx = x >= borders(i) & x <= borders(i+1);
    y(selx) = p(i) + p(i+1)*x(selx);
end

% % Constrains to make line connected
% for i = 1:length(p)/2-1
%     p(2*i-1)*x(borders(i)+1) + p(2*i) - p(2*i+1)*x(borders(i)+1) - p(2*i+2) == 0;
% end
