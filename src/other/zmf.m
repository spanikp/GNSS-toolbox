function y = zmf(x,breaks)
% Z-shaped membership function
% See: https://www.mathworks.com/help/fuzzy/zmf.html

% Unpack breaks
a = breaks(1);
b = breaks(2);

sel_pre_a = x <= a;
sel_ab1 = x >= a & x <= (a+b)/2;
sel_ab2 = x >= (a+b)/2 & x <= b ;
sel_post_b = x >= b;

y = nan(size(x));
y(sel_pre_a) = 1;
y(sel_ab1) = 1 - 2*((x(sel_ab1) - a)/(b - a)).^2;
y(sel_ab2) = 2*((x(sel_ab2) - b)/(b - a)).^2;
y(sel_post_b) = 0;
