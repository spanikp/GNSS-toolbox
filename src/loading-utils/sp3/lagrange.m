function xi = lagrange(x,y,xr)
validateattributes(x,{'double'},{'size',[NaN,1]},1);
validateattributes(y,{'double'},{'size',size(x)},1);

if nnz(xr < min(x) | xr > max(x))
    warning('Values will be extrapolated, xr out of x-bounds!')
end

xi = NaN(length(xr),1);
for i = 1:length(xr)
    Dx = xr(i) - x;
    Dxx = ones(10,1)*x';
    frac_d = Dxx-Dxx';
    
    Pn = zeros(1,10);
    for j = 1:10
        sel = true(1,10);
        sel(j) = 0;
        Pn(j) = y(j)*prod(Dx(sel))/prod(frac_d(sel,j));
    end
    
    xi(i) = sum(Pn);
end