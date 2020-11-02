function map = polarmap(addWhiteEnds)
if nargin == 0
    addWhiteEnds = false;
end

map = [repmat([0,0,1],[100,1]); repmat([1 1 1],[5,1]); repmat([1,0,0],[100,1])];
r = repmat(abs(linspace(1,-1,size(map,1))),[3,1])';
map = map.*r + 1 - r;

if addWhiteEnds
    map = [[1 1 1]; map; [1 1 1]];
end
