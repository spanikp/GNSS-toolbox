function h = gaussian(m,n,sigma)
[h1, h2] = meshgrid(-(m-1)/2:(m-1)/2, -(n-1)/2:(n-1)/2);
hg = exp(-(h1.^2+h2.^2)/(2*sigma^2));
h = hg./sum(hg(:));